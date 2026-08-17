"""What the playlists module hands out."""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

from pydantic import BaseModel

from api.core.schemas import ORMModel
from api.modules.catalogue.schemas import EpisodeWithShow
from api.modules.playlists.models import Playlist, Visibility

if TYPE_CHECKING:
    # A type position only: who's asking is passed in, never looked up here.
    from api.modules.accounts.models import User


class PlaylistItemOut(ORMModel):
    id: int
    position: int
    episode: EpisodeWithShow


class PlaylistOut(ORMModel):
    id: int
    name: str
    visibility: Visibility
    created_at: datetime
    count: int
    # Whether the caller may change this one. Not a permission the client
    # enforces — the service does that — but the answer it needs to decide
    # whether to draw the controls at all. A button that can only ever return
    # 404 is worse than no button.
    mine: bool = False


class PlaylistDetail(PlaylistOut):
    items: list[PlaylistItemOut]


class PlaylistCreate(BaseModel):
    name: str


class PlaylistFromShow(BaseModel):
    show: str
    season: int | None = None
    name: str | None = None
    # Episodes without a VOD can't be played; keeping them would break auto-next.
    playable_only: bool = True


class PlaylistAddItem(BaseModel):
    episode_id: int


class PlaylistReorder(BaseModel):
    item_ids: list[int]


class PlaylistUpdate(BaseModel):
    """Rename it, publish it, or take it down. Anything not sent is untouched."""

    name: str | None = None
    visibility: Visibility | None = None


# Both read straight off the row now that `count` is a property on the model,
# plus the one thing the row can't know on its own: who's asking. Kept as named
# functions because `playlist_detail(x, user)` says more at a call site than
# `PlaylistDetail.model_validate(x)` does.
def playlist_out(playlist: Playlist, user: User | None = None) -> PlaylistOut:
    dto = PlaylistOut.model_validate(playlist)
    dto.mine = _editable(playlist, user)
    return dto


def playlist_detail(playlist: Playlist, user: User | None = None) -> PlaylistDetail:
    dto = PlaylistDetail.model_validate(playlist)
    dto.mine = _editable(playlist, user)
    return dto


def _editable(playlist: Playlist, user: User | None) -> bool:
    """The same rule `PlaylistService._owned` enforces, said out loud.

    Visibility isn't ownership: a public list is everyone's to watch and its
    owner's to change. If the two ever disagree, the service is the one that
    counts — this only decides what a client bothers to offer.
    """
    if user is None:
        return False
    return playlist.owner_id == user.id or user.is_admin
