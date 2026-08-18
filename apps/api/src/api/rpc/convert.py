"""DTO in, protobuf out.

The DTOs are the ones the HTTP layer serialises — `EpisodeWithShow`, `ShowOut`,
`PlaylistDetail`. Going through them rather than straight off the SQLAlchemy row
is the point: `playlist`, `vod_url` and `imdb_url` are composed in one place, and
that place shouldn't have to be written twice because a second transport turned
up.

Optional scalars are the one thing to be careful with. A proto3 `optional` field
is absent until it is assigned, and assigning `None` raises — so `_set` skips
what it hasn't got, and "the source page had no poster" arrives as a field the
client can ask `hasPoster()` about instead of an empty string it has to guess at.
"""

from datetime import datetime
from typing import Any

from contracts import catalogue_pb2 as pb

from api.modules.accounts.models import Role
from api.modules.accounts.schemas import UserOut
from api.modules.activity.schemas import HistoryEntry, ProgressOut
from api.modules.catalogue.schemas import (
    EpisodeOut,
    EpisodeWithShow,
    ShowDetails,
    ShowOut,
    ShowSummary,
    TrackOut,
)
from api.modules.curation.models import SectionKind
from api.modules.playlists.models import Visibility
from api.modules.playlists.schemas import PlaylistDetail, PlaylistItemOut, PlaylistOut

# --- enums, both ways -------------------------------------------------------
# Written out rather than derived from the names: the proto is a contract with
# clients we don't build, and renaming a Python enum member should break this
# table loudly instead of quietly changing what a phone receives.

ROLES: dict[Role, "pb.Role.ValueType"] = {
    Role.user: pb.ROLE_USER,
    Role.admin: pb.ROLE_ADMIN,
}

VISIBILITIES: dict[Visibility, "pb.PlaylistVisibility.ValueType"] = {
    Visibility.private: pb.PLAYLIST_VISIBILITY_PRIVATE,
    Visibility.public: pb.PLAYLIST_VISIBILITY_PUBLIC,
}

VISIBILITY_FROM: dict[int, Visibility] = {value: key for key, value in VISIBILITIES.items()}

SECTION_KINDS: dict[SectionKind, "pb.SectionKind.ValueType"] = {
    SectionKind.hero: pb.SECTION_KIND_HERO,
    SectionKind.rail: pb.SECTION_KIND_RAIL,
    SectionKind.grid: pb.SECTION_KIND_GRID,
    SectionKind.banner: pb.SECTION_KIND_BANNER,
}

# What the service layer calls these. Unspecified means "the default the REST
# layer has", so a client that sets nothing gets the same answer either way.
SHOW_ORDERS: dict[int, str] = {
    pb.SHOW_ORDER_UNSPECIFIED: "key",
    pb.SHOW_ORDER_KEY: "key",
    pb.SHOW_ORDER_ADDED: "added",
    pb.SHOW_ORDER_TITLE: "title",
    pb.SHOW_ORDER_NEWEST: "newest",
    pb.SHOW_ORDER_OLDEST: "oldest",
}

PLAYLIST_SCOPES: dict[int, str] = {
    pb.PLAYLIST_SCOPE_UNSPECIFIED: "visible",
    pb.PLAYLIST_SCOPE_VISIBLE: "visible",
    pb.PLAYLIST_SCOPE_MINE: "mine",
    pb.PLAYLIST_SCOPE_PUBLIC: "public",
}


def _set(message: Any, **fields: Any) -> None:
    """Assign the fields that have a value, leave the rest unset."""
    for name, value in fields.items():
        if value is not None:
            setattr(message, name, value)


def _stamp(value: datetime) -> str:
    """ISO-8601, because that is what every client already parses.

    A `google.protobuf.Timestamp` would be more typed and less useful: the same
    row goes out as this exact string over HTTP, and two spellings of one
    instant is a bug waiting for the day somebody compares them.
    """
    return value.isoformat()


# --- accounts ---------------------------------------------------------------


def user(dto: UserOut) -> pb.User:
    message = pb.User(
        public_id=dto.public_id,
        display_name=dto.display_name,
        role=ROLES[dto.role],
        is_guest=dto.is_guest,
        created_at=_stamp(dto.created_at),
        last_seen_at=_stamp(dto.last_seen_at),
    )
    _set(message, email=dto.email)
    return message


def identity(token: str, dto: UserOut) -> pb.Identity:
    return pb.Identity(token=token, user=user(dto))


# --- catalogue --------------------------------------------------------------


def show(dto: ShowOut) -> pb.Show:
    message = pb.Show(
        id=dto.id,
        key=dto.key,
        title=dto.title,
        created_at=_stamp(dto.created_at),
        is_film=dto.is_film,
    )
    _set(message, poster=dto.poster)
    return message


def show_summary(dto: ShowSummary) -> pb.ShowSummary:
    return pb.ShowSummary(
        show=show(dto),
        episode_count=dto.episode_count,
        playable_count=dto.playable_count,
    )


def show_details(dto: ShowDetails) -> pb.ShowDetails:
    message = pb.ShowDetails(show=show(dto))
    _set(
        message,
        original_title=dto.original_title,
        kind=dto.kind,
        year=dto.year,
        year_end=dto.year_end,
        audio=dto.audio,
        quality=dto.quality,
        description=dto.description,
        duration=dto.duration,
        age_rating=dto.age_rating,
        imdb_id=dto.imdb_id,
        imdb_rating=dto.imdb_rating,
        imdb_votes=dto.imdb_votes,
        imdb_url=dto.imdb_url,
    )
    message.genres.extend(dto.genres or [])
    message.countries.extend(dto.countries or [])
    message.directors.extend(dto.directors or [])
    message.starring.extend(dto.starring or [])
    return message


def track(dto: TrackOut) -> pb.Track:
    message = pb.Track(vod_id=dto.vod_id, playlist=dto.playlist)
    _set(message, audio=dto.audio)
    return message


def episode(dto: EpisodeOut) -> pb.Episode:
    message = pb.Episode(
        id=dto.id,
        season=dto.season,
        episode=dto.episode,
        title=dto.title,
        source_url=dto.source_url,
        tracks=[track(one) for one in dto.tracks],
    )
    _set(
        message,
        episode_end=dto.episode_end,
        poster=dto.poster,
        vod_id=dto.vod_id,
        vod_url=dto.vod_url,
        playlist=dto.playlist,
    )
    return message


def episode_with_show(dto: EpisodeWithShow) -> pb.EpisodeWithShow:
    return pb.EpisodeWithShow(episode=episode(dto), show=show(dto.show))


def page(total: int, limit: int, offset: int) -> pb.PageInfo:
    return pb.PageInfo(total=total, limit=limit, offset=offset)


# --- watching ---------------------------------------------------------------


def progress(dto: ProgressOut) -> pb.Progress:
    message = pb.Progress(
        episode_id=dto.episode_id,
        position_seconds=dto.position_seconds,
        completed=dto.completed,
        last_watched_at=_stamp(dto.last_watched_at),
    )
    _set(message, duration_seconds=dto.duration_seconds, ratio=dto.ratio)
    return message


def history_entry(dto: HistoryEntry) -> pb.HistoryEntry:
    return pb.HistoryEntry(
        progress=progress(dto),
        episode=episode_with_show(dto.episode),
    )


# --- playlists --------------------------------------------------------------


def playlist(dto: PlaylistOut) -> pb.Playlist:
    return pb.Playlist(
        id=dto.id,
        name=dto.name,
        visibility=VISIBILITIES[dto.visibility],
        created_at=_stamp(dto.created_at),
        count=dto.count,
        mine=dto.mine,
    )


def playlist_item(dto: PlaylistItemOut) -> pb.PlaylistItem:
    return pb.PlaylistItem(
        id=dto.id,
        position=dto.position,
        episode=episode_with_show(dto.episode),
    )


def playlist_detail(dto: PlaylistDetail) -> pb.PlaylistDetail:
    return pb.PlaylistDetail(
        playlist=playlist(dto),
        items=[playlist_item(item) for item in dto.items],
    )
