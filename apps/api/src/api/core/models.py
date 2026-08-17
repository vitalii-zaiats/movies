"""The declarative base and the columns every table repeats.

Each module owns its own tables; this file owns only what they have in common,
so `Base` has exactly one definition and Alembic has exactly one metadata.
"""

from datetime import UTC, datetime

from sqlalchemy import DateTime, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


def utcnow() -> datetime:
    """Aware, always. A naive datetime in this schema is a bug in waiting."""
    return datetime.now(UTC)


class TimestampMixin:
    """`created_at` on everything, so any row can be ordered by when it appeared.

    The Python default and the server default are both there on purpose: the app
    writes one, and a hand-written `INSERT` during a migration still gets the
    other.
    """

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, server_default=func.now()
    )


class UpdatedAtMixin:
    """For rows that get rewritten in place — progress, profiles, settings."""

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=utcnow,
        server_default=func.now(),
        onupdate=utcnow,
    )
