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

from dataclasses import dataclass
from datetime import timedelta

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.models import utcnow
from api.core.security import hash_password, new_token, token_digest, verify_password
from api.errors import Conflict, Forbidden, Invalid, NotFound, Unauthorized
from api.modules.accounts.models import AuthSession, Role, User
from api.modules.accounts.repository import SessionRepository, UserRepository
from api.settings import settings

MIN_PASSWORD = 8


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
