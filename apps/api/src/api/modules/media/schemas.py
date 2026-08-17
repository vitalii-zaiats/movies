"""What the media module hands out."""

from datetime import datetime

from pydantic import computed_field

from api.core.schemas import ORMModel, Page
from api.modules.media import storage


class MediaOut(ORMModel):
    id: int
    digest: str
    # The name on disk, read off the model's property. Content-addressed, so
    # it's also the cache key that lets this be served immutably.
    filename: str
    content_type: str
    size_bytes: int
    width: int | None
    height: int | None
    original_name: str | None
    created_at: datetime

    @computed_field
    @property
    def url(self) -> str:
        """Composed, not stored — the same reason an episode's `vod_url` is.

        Where files are served from is a deployment detail, and freezing it into
        a row means every old banner points at the wrong host after a move.
        """
        return storage.url_for(self.filename)


class MediaPage(Page):
    items: list[MediaOut]
