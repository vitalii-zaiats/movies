"""Everything under `/me` — the routes that only make sense for one person.

All of them take `CurrentUser`, so hitting any of them without a token mints a
guest and hands the token back. Watching starts before signing up; that's the
whole design.
"""

from typing import Annotated

from fastapi import APIRouter, Query

from api.modules.accounts.deps import CurrentUser
from api.modules.activity.deps import Activity
from api.modules.activity.models import WatchProgress
from api.modules.activity.schemas import (
    EventOut,
    EventPage,
    HistoryEntry,
    HistoryPage,
    ProgressOut,
    ProgressReport,
)

router = APIRouter(prefix="/me", tags=["activity"])


@router.put("/progress/{episode_id}", response_model=ProgressOut)
async def report_progress(
    episode_id: int, body: ProgressReport, user: CurrentUser, activity: Activity
) -> WatchProgress:
    return await activity.report(
        user.id,
        episode_id,
        position_seconds=body.position_seconds,
        duration_seconds=body.duration_seconds,
        completed=body.completed,
    )


@router.get("/progress/{episode_id}", response_model=ProgressOut)
async def read_progress(episode_id: int, user: CurrentUser, activity: Activity) -> WatchProgress:
    """Where to seek to when the player opens. 404 means "start at zero"."""
    return await activity.resume(user.id, episode_id)


@router.delete("/progress/{episode_id}", status_code=204)
async def forget_progress(episode_id: int, user: CurrentUser, activity: Activity) -> None:
    await activity.forget(user.id, episode_id)


@router.get("/history", response_model=HistoryPage)
async def history(
    user: CurrentUser,
    activity: Activity,
    completed: Annotated[bool | None, Query(description="only finished, or only not")] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> HistoryPage:
    rows, total = await activity.history(
        user.id, limit=limit, offset=offset, completed=completed
    )
    return HistoryPage(
        total=total,
        limit=limit,
        offset=offset,
        items=[HistoryEntry.model_validate(row) for row in rows],
    )


@router.get("/continue", response_model=list[HistoryEntry])
async def continue_watching(
    user: CurrentUser,
    activity: Activity,
    limit: Annotated[int, Query(ge=1, le=50)] = 20,
) -> list[WatchProgress]:
    """The rail on the home screen: started, not finished, newest first."""
    return await activity.continue_watching(user.id, limit=limit)


@router.get("/activity", response_model=EventPage)
async def feed(
    user: CurrentUser,
    activity: Activity,
    type: Annotated[list[str] | None, Query(description="filter by event type")] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> EventPage:
    events, total = await activity.feed(user.id, limit=limit, offset=offset, types=type)
    return EventPage(
        total=total,
        limit=limit,
        offset=offset,
        items=[EventOut.model_validate(event) for event in events],
    )
