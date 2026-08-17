"""Users and their sessions.

A guest and a member are the same table. The difference is `claimed_at`: until
it's set there's no email and no password, and the only way in is the token the
guest is holding. Claiming fills those three columns in on the row that already
owns the history — no copying, no merging, no "import your guest data" screen.

Roles are orthogonal to that. A guest is a `user`; an admin is a `user` row with
`role = admin`. Nothing stops a claimed account from being either.
"""

import enum
import uuid
from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from api.core.models import Base, TimestampMixin, utcnow


class Role(str, enum.Enum):
    user = "user"
    admin = "admin"


def _public_id() -> str:
    return uuid.uuid4().hex


class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True)
    # What the outside world is allowed to see. Sequential ids leak how many
    # users exist and make one guessable from another; this doesn't.
    public_id: Mapped[str] = mapped_column(String(32), unique=True, index=True, default=_public_id)

    display_name: Mapped[str] = mapped_column(String(80))
    # Both null until the account is claimed — see the module docstring.
    email: Mapped[str | None] = mapped_column(String(320), unique=True, index=True, nullable=True)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)

    # A varchar with a check constraint, not a Postgres enum: adding a role
    # later shouldn't need `ALTER TYPE` in a migration. The server default is
    # there so a row inserted by hand can't land without one.
    role: Mapped[Role] = mapped_column(
        Enum(Role, name="user_role", native_enum=False, length=20),
        default=Role.user,
        server_default=Role.user.value,
    )
    claimed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, default=None
    )
    last_seen_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, server_default=func.now()
    )

    sessions: Mapped[list["AuthSession"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )

    @property
    def is_guest(self) -> bool:
        return self.claimed_at is None

    @property
    def is_admin(self) -> bool:
        return self.role is Role.admin


class AuthSession(Base, TimestampMixin):
    """One issued token. Rows, not JWTs, so logging out actually logs out."""

    __tablename__ = "auth_sessions"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)

    # The SHA-256 of the token we handed over, never the token itself: reading
    # this table gets you nothing you can log in with.
    token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)

    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    last_used_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, server_default=func.now()
    )
    # Enough to tell "my phone" from "the TV" on a sessions screen later.
    user_agent: Mapped[str | None] = mapped_column(String(300), nullable=True)

    user: Mapped[User] = relationship(back_populates="sessions", lazy="joined")

    def is_live(self, now: datetime | None = None) -> bool:
        return self.expires_at > (now or utcnow())
