"""What the curation module hands out.

Composed from the neighbouring modules' published DTOs — `ShowOut`,
`EpisodeWithShow`, `PlaylistOut` — rather than from their models. That's the
seam where reuse is the right answer: a DTO is already a contract, and
re-declaring the shape of a show here would only mean two places to change it.
"""

from datetime import datetime

from pydantic import BaseModel, Field, model_validator

from api.core.schemas import ORMModel
from api.modules.catalogue.schemas import EpisodeWithShow, ShowOut
from api.modules.curation.models import Placement, SectionKind
from api.modules.playlists.schemas import PlaylistOut


class ArtworkOut(ORMModel):
    id: int
    placement: Placement
    url: str
    media_id: int | None


class PlacementInfo(BaseModel):
    """What to upload, so an admin isn't guessing at crop sizes."""

    placement: Placement
    width: int
    height: int
    ratio: str


class SectionOut(ORMModel):
    id: int
    kind: SectionKind
    title: str
    kicker: str | None
    link: str | None
    position: int
    visible: bool
    item_limit: int
    show: ShowOut | None
    playlist: PlaylistOut | None
    artwork: list[ArtworkOut]
    created_at: datetime


class HomeSection(BaseModel):
    """A section as the home screen wants it: filled in and ready to draw."""

    id: int
    kind: SectionKind
    title: str
    kicker: str | None
    link: str | None
    show: ShowOut | None
    playlist: PlaylistOut | None
    # placement → URL, already merged: the section's own picture wins over the
    # one belonging to the show or playlist it points at.
    artwork: dict[Placement, str]
    items: list[EpisodeWithShow]


class HomeOut(BaseModel):
    sections: list[HomeSection]


class SectionCreate(BaseModel):
    kind: SectionKind = SectionKind.rail
    title: str = Field(min_length=1, max_length=200)
    kicker: str | None = Field(default=None, max_length=200)
    link: str | None = Field(default=None, max_length=500)
    show_id: int | None = None
    playlist_id: int | None = None
    item_limit: int = Field(default=14, ge=1, le=100)
    visible: bool = True


class SectionUpdate(BaseModel):
    """Every field optional, and "not sent" is distinct from "set to null".

    `model_dump(exclude_unset=True)` is what makes that true, and it's why the
    service takes a dict of changes rather than a pile of `| None` arguments
    it would have to second-guess.
    """

    kind: SectionKind | None = None
    title: str | None = Field(default=None, min_length=1, max_length=200)
    kicker: str | None = Field(default=None, max_length=200)
    link: str | None = Field(default=None, max_length=500)
    show_id: int | None = None
    playlist_id: int | None = None
    item_limit: int | None = Field(default=None, ge=1, le=100)
    visible: bool | None = None


class SectionReorder(BaseModel):
    section_ids: list[int]


class ArtworkUpsert(BaseModel):
    subject_type: str = Field(pattern="^(show|playlist|section)$")
    subject_id: int
    placement: Placement
    url: str | None = Field(default=None, max_length=1000)
    media_id: int | None = None

    @model_validator(mode="after")
    def one_source(self) -> "ArtworkUpsert":
        """An uploaded file or a link. Both is ambiguous, neither is empty."""
        if (self.url is None) == (self.media_id is None):
            raise ValueError("give exactly one of url or media_id")
        return self
