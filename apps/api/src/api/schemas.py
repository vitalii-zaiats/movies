"""What the API hands out."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, computed_field

from api.models import Episode, Playlist, Show


class ShowOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    key: str
    title: str
    poster: str | None
    created_at: datetime


class EpisodeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    season: int
    episode: int
    episode_end: int | None
    title: str
    poster: str | None
    source_url: str
    vod_id: int | None
    vod_url: str | None

    @computed_field
    @property
    def playlist(self) -> str | None:
        """The one URL a player needs — our VOD's, never the origin's."""
        return f"{self.vod_url}/index.m3u8" if self.vod_url else None


class EpisodeWithShow(EpisodeOut):
    show: ShowOut


class ShowWithEpisodes(ShowOut):
    episodes: list[EpisodeOut]


class PlaylistItemOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    position: int
    episode: EpisodeWithShow


class PlaylistOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    created_at: datetime
    count: int


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


class Page(BaseModel):
    total: int
    limit: int
    offset: int


class EpisodePage(Page):
    items: list[EpisodeWithShow]


def episode_out(episode: Episode) -> EpisodeWithShow:
    return EpisodeWithShow.model_validate(episode)


def show_out(show: Show) -> ShowWithEpisodes:
    return ShowWithEpisodes.model_validate(show)


def playlist_out(playlist: Playlist) -> PlaylistOut:
    return PlaylistOut(
        id=playlist.id,
        name=playlist.name,
        created_at=playlist.created_at,
        count=len(playlist.items),
    )


def playlist_detail(playlist: Playlist) -> PlaylistDetail:
    return PlaylistDetail(
        id=playlist.id,
        name=playlist.name,
        created_at=playlist.created_at,
        count=len(playlist.items),
        items=[PlaylistItemOut.model_validate(item) for item in playlist.items],
    )
