"""Signing in, signing up, and the guest that exists before either.

The flow this file is built around:

    no token        →  `guest()`   mints a user *and* a session in one go
    token           →  `identify()` returns that user, or nothing if it's stale
    guest + email   →  `claim()`   fills in the same row and rotates the token
    email + password→  `login()`   a second session on an existing row

`claim` is the interesting one. It never creates a user, so the history, the
progress and the playlists a guest built up stay attached — the account was
always there, it just had nobody's name on it.
"""

import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.models import utcnow
from api.core.security import hash_password, new_token, token_digest, verify_password
from api.errors import Conflict, Forbidden, Invalid, NotFound, Unauthorized
from api.modules.accounts.models import AuthSession, DeviceLink, Role, User
from api.modules.accounts.repository import DeviceLinkRepository, SessionRepository, UserRepository
from api.settings import settings

MIN_PASSWORD = 8


# How long a television has to be approved before its code stops meaning
# anything. Long enough to find a phone and unlock it, short enough that a code
# left on a screen in a shared flat goes stale on its own.
LINK_TTL = timedelta(minutes=10)

# No O or 0, no I or 1: this is read off a screen across a room, and sometimes
# read aloud.
LINK_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
LINK_LENGTH = 6


@dataclass(frozen=True, slots=True)
class DeviceRequest:
    """What a television is handed when it asks to be signed in.

    The code goes on the screen and into the QR; the secret stays in the
    device and is the only thing that can collect the session afterwards.
    """

    code: str
    secret: str
    expires_at: datetime


@dataclass(frozen=True, slots=True)
class DeviceStatus:
    """A pending pairing, as the page about to approve it needs to see it.

    A DTO rather than the row itself: two presentation layers read this, and
    handing them a live `DeviceLink` would mean both of them knowing which of
    its columns are safe to show — `secret_digest` is right there.
    """

    code: str
    device_name: str | None
    approved: bool
    expires_at: datetime

    @classmethod
    def of(cls, link: DeviceLink) -> "DeviceStatus":
        return cls(
            code=link.code,
            device_name=link.device_name,
            approved=not link.pending,
            expires_at=link.expires_at,
        )


@dataclass(frozen=True, slots=True)
class Credential:
    """A user plus the one and only time we'll ever say their token out loud."""

    user: User
    token: str


@dataclass(slots=True)
class AccountService:
    session: AsyncSession

    @property
    def users(self) -> UserRepository:
        return UserRepository(self.session)

    @property
    def sessions(self) -> SessionRepository:
        return SessionRepository(self.session)

    # --- identity -----------------------------------------------------------

    async def identify(self, token: str | None) -> User | None:
        """Resolve a token to a user. No token, no user, no exception.

        Callers decide what "nobody" means: a public route shrugs, a personal
        one mints a guest.
        """
        if not token:
            return None

        auth = await self.sessions.by_digest(token_digest(token))
        if auth is None:
            return None
        if not auth.is_live():
            # Expired sessions are dropped on sight rather than by a cron job we
            # don't have yet.
            await self.sessions.delete(auth)
            await self.session.commit()
            return None

        now = utcnow()
        auth.last_used_at = now
        auth.user.last_seen_at = now
        await self.session.commit()
        return auth.user

    async def guest(self, *, user_agent: str | None = None) -> Credential:
        """A brand new anonymous account, already logged in."""
        user = await self.users.add(User(display_name="Guest", role=Role.user))
        # The generated public_id is only available after the flush, and it's
        # what makes two guests on one screen tellable apart.
        user.display_name = f"Guest {user.public_id[:6]}"
        credential = await self._issue(user, user_agent=user_agent)
        await self.session.commit()
        return credential

    async def login(
        self, email: str, password: str, *, user_agent: str | None = None
    ) -> Credential:
        user = await self.users.by_email(email)
        # One message for "no such email" and "wrong password" on purpose: the
        # difference is only useful to somebody enumerating accounts.
        if user is None or not verify_password(password, user.password_hash):
            raise Unauthorized("wrong email or password")

        credential = await self._issue(user, user_agent=user_agent)
        await self.session.commit()
        return credential

    async def logout(self, token: str | None) -> None:
        if not token:
            return
        auth = await self.sessions.by_digest(token_digest(token))
        if auth is not None:
            await self.sessions.delete(auth)
            await self.session.commit()

    # --- becoming somebody --------------------------------------------------

    async def claim(
        self,
        user: User,
        *,
        email: str,
        password: str,
        display_name: str | None = None,
        user_agent: str | None = None,
    ) -> Credential:
        """Put a name on the guest account that's already been watching.

        Same row, so every episode this guest half-finished is still there when
        they come back on a laptop. The token is rotated because the old one was
        handed out under weaker terms — anyone who saw it had a whole account,
        not just a guest.
        """
        if not user.is_guest:
            raise Conflict("this account is already claimed")

        email = email.strip().lower()
        if len(password) < MIN_PASSWORD:
            raise Invalid(f"password must be at least {MIN_PASSWORD} characters")
        if await self.users.by_email(email) is not None:
            raise Conflict("that email is taken")

        user.email = email
        user.password_hash = hash_password(password)
        user.display_name = (display_name or "").strip() or email.split("@")[0]
        user.claimed_at = utcnow()

        await self.sessions.revoke_all(user.id)
        credential = await self._issue(user, user_agent=user_agent)
        try:
            await self.session.commit()
        except IntegrityError as exc:
            # Two claims racing for the same email. The unique index is the
            # referee; this just translates its verdict.
            await self.session.rollback()
            raise Conflict("that email is taken") from exc
        return credential

    async def register(
        self, *, email: str, password: str, display_name: str | None = None, role: Role = Role.user
    ) -> User:
        """A claimed account with no guest behind it.

        Not reachable over HTTP on purpose — the way in from a browser is to be
        a guest and then claim, which keeps the history. This exists so the
        first admin can be created from a shell before anyone has a session.
        """
        email = email.strip().lower()
        if len(password) < MIN_PASSWORD:
            raise Invalid(f"password must be at least {MIN_PASSWORD} characters")
        if await self.users.by_email(email) is not None:
            raise Conflict("that email is taken")

        user = await self.users.add(
            User(
                display_name=(display_name or "").strip() or email.split("@")[0],
                email=email,
                password_hash=hash_password(password),
                role=role,
                claimed_at=utcnow(),
            )
        )
        await self.session.commit()
        return user

    async def rename(self, user: User, display_name: str) -> User:
        name = display_name.strip()
        if not name:
            raise Invalid("display_name can't be empty")
        user.display_name = name[:80]
        await self.session.commit()
        return user

    # --- administration -----------------------------------------------------

    async def all_users(
        self, *, limit: int = 50, offset: int = 0, guests: bool | None = None
    ) -> tuple[list[User], int]:
        return await self.users.page(limit=limit, offset=offset, guests=guests)

    async def set_role(self, public_id: str, role: Role) -> User:
        user = await self.users.by_public_id(public_id)
        if user is None:
            raise NotFound(f"no user {public_id!r}")
        if user.is_guest and role is Role.admin:
            raise Invalid("claim the account before making it an admin")
        if user.is_admin and role is not Role.admin and await self.users.count_admins() == 1:
            # Locking yourself out of your own stack is a bad afternoon.
            raise Forbidden("that's the last admin")

        user.role = role
        await self.session.commit()
        return user

    # --- internals ----------------------------------------------------------

    # --- signing in a device that has no keyboard ---------------------------

    @property
    def links(self) -> DeviceLinkRepository:
        return DeviceLinkRepository(self.session)

    async def start_link(self, *, device_name: str | None = None) -> DeviceRequest:
        """Begin a pairing. Nobody is authenticated yet — that is the point."""
        secret = new_token()
        now = utcnow()

        # Codes are short, so collisions are possible rather than theoretical.
        for _ in range(5):
            code = "".join(secrets.choice(LINK_ALPHABET) for _ in range(LINK_LENGTH))
            if await self.links.by_code(code) is None:
                break
        else:  # pragma: no cover — five collisions in a row means something else
            raise Conflict("could not allocate a code")

        link = await self.links.add(
            DeviceLink(
                code=code,
                secret_digest=token_digest(secret),
                device_name=(device_name or None),
                expires_at=now + LINK_TTL,
            )
        )
        await self.session.commit()
        return DeviceRequest(code=link.code, secret=secret, expires_at=link.expires_at)

    async def link_for(self, code: str) -> DeviceStatus:
        """The pending request behind a code, for the page about to approve it."""
        return DeviceStatus.of(await self._live_link(code))

    async def approve_link(self, code: str, user: User) -> DeviceStatus:
        """Say yes, as somebody. This is the only step that needs an identity —
        and it is the phone's, not the television's."""
        link = await self._live_link(code)
        if not link.pending and link.user_id != user.id:
            raise Conflict("that code was already used by somebody else")

        link.user_id = user.id
        link.approved_at = utcnow()
        await self.session.commit()
        return DeviceStatus.of(link)

    async def _live_link(self, code: str) -> DeviceLink:
        """The row, for the two methods above. Everything else gets a DTO."""
        link = await self.links.by_code(code)
        if link is None:
            raise NotFound("no such code")
        if link.expired(utcnow()):
            raise Invalid("that code has expired")
        return link

    async def collect_link(
        self, secret: str, *, user_agent: str | None = None
    ) -> Credential | None:
        """The television asking whether it may come in yet.

        None means "not yet" — the ordinary answer while somebody walks to their
        phone. Anything else is final: a session, or a refusal.
        """
        link = await self.links.by_secret(token_digest(secret))
        if link is None:
            raise NotFound("unknown device")
        if link.expired(utcnow()):
            raise Invalid("that request has expired")
        # A token handed out twice is a token that can be stolen from the wire
        # and replayed. Once is once.
        if link.consumed_at is not None:
            raise Invalid("that request was already collected")
        if link.pending or link.user is None:
            return None

        credential = await self._issue(link.user, user_agent=user_agent)
        link.consumed_at = utcnow()
        await self.session.commit()
        return credential

    async def _issue(self, user: User, *, user_agent: str | None) -> Credential:
        token = new_token()
        await self.sessions.add(
            AuthSession(
                user_id=user.id,
                token_hash=token_digest(token),
                expires_at=utcnow() + timedelta(days=settings.session_ttl_days),
                user_agent=user_agent[:300] if user_agent else None,
            )
        )
        return Credential(user=user, token=token)
