"""Recording what happened, and answering "where was I?".

Two entry points matter to the rest of the app:

`report` is what a player calls, often. It upserts one row and — only on the
transitions that mean something — appends one event. A heartbeat every ten
seconds writes state, not history.

`record` is what *other modules* call to put something in the feed. It takes a
plain string, not this module's enum, so a module can name its own events
without importing anything from here: see `playlists/ports.py`, which describes
this method from the caller's side. It also doesn't commit — the caller is in
the middle of its own transaction, and "the playlist was created but the event
wasn't" is not a state worth allowing.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Any

from api.core.models import utcnow
from api.errors import Invalid, NotFound
from api.modules.activity.models import ActivityEvent, EventType, WatchProgress
from api.modules.activity.repository import EventRepository, ProgressRepository
from api.modules.catalogue.service import CatalogueService

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

    from api.modules.catalogue.models import Episode

# Nobody watches the credits. Past this, call it finished and offer the next one.
COMPLETE_AT = 0.95


@dataclass(slots=True)
class ActivityService:
    session: AsyncSession

    @property
    def progress(self) -> ProgressRepository:
        return ProgressRepository(self.session)

    @property
    def events(self) -> EventRepository:
        return EventRepository(self.session)

    @property
    def catalogue(self) -> CatalogueService:
        return CatalogueService(self.session)

    # --- writing ------------------------------------------------------------

    async def record(
        self,
        user_id: int,
        event: str,
        *,
        subject_type: str | None = None,
        subject_id: int | None = None,
        payload: dict[str, Any] | None = None,
    ) -> ActivityEvent:
        """Append to the feed inside the caller's transaction. No commit."""
        return await self.events.add(
            ActivityEvent(
                user_id=user_id,
                type=event,
                subject_type=subject_type,
                subject_id=subject_id,
                payload=payload,
            )
        )

    async def report(
        self,
        user_id: int,
        episode_id: int,
        *,
        position_seconds: float,
        duration_seconds: float | None = None,
        completed: bool | None = None,
    ) -> WatchProgress:
        """The player checking in. Idempotent, and safe to call constantly."""
        if position_seconds < 0:
            raise Invalid("position_seconds can't be negative")

        # Raises NotFound if there's no such episode — the catalogue's answer,
        # not a second copy of the same check.
        episode = await self.catalogue.episode(episode_id)

        now = utcnow()
        row = await self.progress.for_episode(user_id, episode_id)
        if row is None:
            row = await self.progress.add(
                WatchProgress(user_id=user_id, episode_id=episode_id, position_seconds=0.0)
            )
            await self.record(
                user_id,
                EventType.episode_started.value,
                subject_type="episode",
                subject_id=episode_id,
                payload=_episode_payload(episode),
            )

        row.position_seconds = position_seconds
        if duration_seconds:
            row.duration_seconds = duration_seconds
        row.last_watched_at = now

        # `completed_at` is set once. Scrubbing back to the start doesn't undo
        # having watched the thing, and re-watching shouldn't re-fire the event.
        if not row.completed and _is_done(row, completed):
            row.completed_at = now
            await self.record(
                user_id,
                EventType.episode_finished.value,
                subject_type="episode",
                subject_id=episode_id,
                payload=_episode_payload(episode),
            )

        await self.session.commit()
        return row

    async def forget(self, user_id: int, episode_id: int) -> None:
        """Drop one episode from history. The events stay — those are a log."""
        row = await self.progress.for_episode(user_id, episode_id)
        if row is None:
            raise NotFound(f"no progress for episode {episode_id}")
        await self.progress.delete(row)
        await self.session.commit()

    # --- reading ------------------------------------------------------------

    async def history(
        self, user_id: int, *, limit: int = 50, offset: int = 0, completed: bool | None = None
    ) -> tuple[list[WatchProgress], int]:
        return await self.progress.history(
            user_id, limit=limit, offset=offset, completed=completed
        )

    async def continue_watching(self, user_id: int, *, limit: int = 20) -> list[WatchProgress]:
        return await self.progress.unfinished(user_id, limit=limit)

    async def resume(self, user_id: int, episode_id: int) -> WatchProgress:
        row = await self.progress.for_episode(user_id, episode_id)
        if row is None:
            raise NotFound(f"no progress for episode {episode_id}")
        return row

    async def feed(
        self, user_id: int, *, limit: int = 50, offset: int = 0, types: list[str] | None = None
    ) -> tuple[list[ActivityEvent], int]:
        return await self.events.feed(user_id, limit=limit, offset=offset, types=types)


def _is_done(row: WatchProgress, explicit: bool | None) -> bool:
    """The player's word first, the ratio second.

    A client that knows the video ended says so; one that only reports a
    position gets the 95% rule. With no runtime at all we can't tell, so we
    don't guess.
    """
    if explicit is not None:
        return explicit
    ratio = row.ratio
    return ratio is not None and ratio >= COMPLETE_AT


def _episode_payload(episode: Episode) -> dict[str, Any]:
    """Enough to render the feed entry without joining anything back."""
    return {
        "title": episode.title,
        "season": episode.season,
        "episode": episode.episode,
        "show_key": episode.show.key,
        "show_title": episode.show.title,
    }
