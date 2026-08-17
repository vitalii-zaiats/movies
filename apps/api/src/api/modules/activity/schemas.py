"""What the activity module hands out."""

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field

from api.core.schemas import ORMModel, Page
from api.modules.catalogue.schemas import EpisodeWithShow


class ProgressReport(BaseModel):
    """The player checking in. Sent often — keep it small."""

    position_seconds: float = Field(ge=0)
    duration_seconds: float | None = Field(default=None, gt=0)
    # Leave it out and the 95% rule decides. Send it when the player *knows*,
    # because "the video element fired `ended`" beats any threshold.
    completed: bool | None = None


class ProgressOut(ORMModel):
    episode_id: int
    position_seconds: float
    duration_seconds: float | None
    completed: bool
    ratio: float | None
    last_watched_at: datetime


class HistoryEntry(ProgressOut):
    episode: EpisodeWithShow


class HistoryPage(Page):
    items: list[HistoryEntry]


class EventOut(ORMModel):
    id: int
    type: str
    subject_type: str | None
    subject_id: int | None
    payload: dict[str, Any] | None
    created_at: datetime


class EventPage(Page):
    items: list[EventOut]
