"""Progress rows and the event log."""

import enum
from datetime import datetime
from typing import Any

from sqlalchemy import JSON, DateTime, Float, ForeignKey, String, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from api.core.models import Base, TimestampMixin, UpdatedAtMixin, utcnow
from api.modules.catalogue.models import Episode


class EventType(str, enum.Enum):
    """The events *this* module produces.

    Not a registry of every event in the app, and deliberately so: the column
    behind it is a plain `String`, and `record()` takes a plain string, so a
    module names its own events in its own folder — `playlists/events.py` is the
    other one today. A shared enum would mean every feature that wants a feed
    entry has to come here and add a line, which is the coupling this module
    exists to avoid.
    """

    episode_started = "episode.started"
    episode_finished = "episode.finished"


class WatchProgress(Base, TimestampMixin, UpdatedAtMixin):
    """Where one person stopped in one episode."""

    __tablename__ = "watch_progress"
    __table_args__ = (
        UniqueConstraint("user_id", "episode_id", name="uq_progress_user_episode"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    episode_id: Mapped[int] = mapped_column(
        ForeignKey("episodes.id", ondelete="CASCADE"), index=True
    )

    position_seconds: Mapped[float] = mapped_column(Float, default=0.0)
    # What the player reported the runtime to be. Nullable because the VOD
    # service doesn't always know it before the first segment is parsed.
    duration_seconds: Mapped[float | None] = mapped_column(Float, nullable=True)

    # Set once and left alone: re-watching an episode shouldn't erase the fact
    # that it was finished. Ordering the history uses `last_watched_at` instead.
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, default=None
    )
    last_watched_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, server_default=func.now(), index=True
    )

    episode: Mapped[Episode] = relationship(lazy="joined")

    @property
    def completed(self) -> bool:
        return self.completed_at is not None

    @property
    def ratio(self) -> float | None:
        """How far in, 0…1 — or nothing when the runtime is still unknown."""
        if not self.duration_seconds:
            return None
        return min(self.position_seconds / self.duration_seconds, 1.0)


class ActivityEvent(Base, TimestampMixin):
    """One thing that happened, kept forever.

    `subject_type` / `subject_id` instead of a foreign key per feature: the feed
    has to be able to mention an episode today and a show, a comment or a rating
    later without this table growing a column each time. Nothing joins on it —
    the row carries enough in `payload` to be rendered on its own, which is also
    what keeps history readable after the thing it mentions is deleted.
    """

    __tablename__ = "activity_events"

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)

    type: Mapped[str] = mapped_column(String(50), index=True)
    subject_type: Mapped[str | None] = mapped_column(String(30), nullable=True)
    subject_id: Mapped[int | None] = mapped_column(nullable=True)
    payload: Mapped[dict[str, Any] | None] = mapped_column(JSON, nullable=True)
