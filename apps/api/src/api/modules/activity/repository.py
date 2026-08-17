"""Every query about progress and events."""

from sqlalchemy import func, select

from api.core.repository import Repository
from api.modules.activity.models import ActivityEvent, WatchProgress


class ProgressRepository(Repository[WatchProgress]):
    model = WatchProgress

    async def for_episode(self, user_id: int, episode_id: int) -> WatchProgress | None:
        return await self.session.scalar(
            select(WatchProgress).where(
                WatchProgress.user_id == user_id, WatchProgress.episode_id == episode_id
            )
        )

    async def history(
        self, user_id: int, *, limit: int = 50, offset: int = 0, completed: bool | None = None
    ) -> tuple[list[WatchProgress], int]:
        """Most recently watched first — that's what "history" means to a person."""
        query = select(WatchProgress).where(WatchProgress.user_id == user_id)
        if completed is not None:
            query = query.where(
                WatchProgress.completed_at.is_not(None)
                if completed
                else WatchProgress.completed_at.is_(None)
            )

        total = await self.session.scalar(select(func.count()).select_from(query.subquery()))
        rows = await self.session.scalars(
            query.order_by(WatchProgress.last_watched_at.desc()).limit(limit).offset(offset)
        )
        return list(rows.unique()), total or 0

    async def unfinished(self, user_id: int, *, limit: int = 20) -> list[WatchProgress]:
        """Started, not finished, and far enough in to be worth resuming."""
        rows = await self.session.scalars(
            select(WatchProgress)
            .where(
                WatchProgress.user_id == user_id,
                WatchProgress.completed_at.is_(None),
                WatchProgress.position_seconds > 0,
            )
            .order_by(WatchProgress.last_watched_at.desc())
            .limit(limit)
        )
        return list(rows.unique())


class EventRepository(Repository[ActivityEvent]):
    model = ActivityEvent

    async def feed(
        self, user_id: int, *, limit: int = 50, offset: int = 0, types: list[str] | None = None
    ) -> tuple[list[ActivityEvent], int]:
        query = select(ActivityEvent).where(ActivityEvent.user_id == user_id)
        if types:
            query = query.where(ActivityEvent.type.in_(types))

        total = await self.session.scalar(select(func.count()).select_from(query.subquery()))
        # By id, not by created_at: same order, and the primary key is already
        # the index that makes it free.
        rows = await self.session.scalars(
            query.order_by(ActivityEvent.id.desc()).limit(limit).offset(offset)
        )
        return list(rows), total or 0
