from google.protobuf.internal import containers as _containers
from google.protobuf.internal import enum_type_wrapper as _enum_type_wrapper
from google.protobuf import descriptor as _descriptor
from google.protobuf import message as _message
from collections.abc import Iterable as _Iterable, Mapping as _Mapping
from typing import ClassVar as _ClassVar, Optional as _Optional, Union as _Union

DESCRIPTOR: _descriptor.FileDescriptor

class Role(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    ROLE_UNSPECIFIED: _ClassVar[Role]
    ROLE_USER: _ClassVar[Role]
    ROLE_ADMIN: _ClassVar[Role]

class ShowOrder(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    SHOW_ORDER_UNSPECIFIED: _ClassVar[ShowOrder]
    SHOW_ORDER_KEY: _ClassVar[ShowOrder]
    SHOW_ORDER_ADDED: _ClassVar[ShowOrder]
    SHOW_ORDER_TITLE: _ClassVar[ShowOrder]
    SHOW_ORDER_NEWEST: _ClassVar[ShowOrder]
    SHOW_ORDER_OLDEST: _ClassVar[ShowOrder]

class SectionKind(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    SECTION_KIND_UNSPECIFIED: _ClassVar[SectionKind]
    SECTION_KIND_HERO: _ClassVar[SectionKind]
    SECTION_KIND_RAIL: _ClassVar[SectionKind]
    SECTION_KIND_GRID: _ClassVar[SectionKind]
    SECTION_KIND_BANNER: _ClassVar[SectionKind]

class PlaylistVisibility(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    PLAYLIST_VISIBILITY_UNSPECIFIED: _ClassVar[PlaylistVisibility]
    PLAYLIST_VISIBILITY_PRIVATE: _ClassVar[PlaylistVisibility]
    PLAYLIST_VISIBILITY_PUBLIC: _ClassVar[PlaylistVisibility]

class PlaylistScope(int, metaclass=_enum_type_wrapper.EnumTypeWrapper):
    __slots__ = ()
    PLAYLIST_SCOPE_UNSPECIFIED: _ClassVar[PlaylistScope]
    PLAYLIST_SCOPE_VISIBLE: _ClassVar[PlaylistScope]
    PLAYLIST_SCOPE_MINE: _ClassVar[PlaylistScope]
    PLAYLIST_SCOPE_PUBLIC: _ClassVar[PlaylistScope]
ROLE_UNSPECIFIED: Role
ROLE_USER: Role
ROLE_ADMIN: Role
SHOW_ORDER_UNSPECIFIED: ShowOrder
SHOW_ORDER_KEY: ShowOrder
SHOW_ORDER_ADDED: ShowOrder
SHOW_ORDER_TITLE: ShowOrder
SHOW_ORDER_NEWEST: ShowOrder
SHOW_ORDER_OLDEST: ShowOrder
SECTION_KIND_UNSPECIFIED: SectionKind
SECTION_KIND_HERO: SectionKind
SECTION_KIND_RAIL: SectionKind
SECTION_KIND_GRID: SectionKind
SECTION_KIND_BANNER: SectionKind
PLAYLIST_VISIBILITY_UNSPECIFIED: PlaylistVisibility
PLAYLIST_VISIBILITY_PRIVATE: PlaylistVisibility
PLAYLIST_VISIBILITY_PUBLIC: PlaylistVisibility
PLAYLIST_SCOPE_UNSPECIFIED: PlaylistScope
PLAYLIST_SCOPE_VISIBLE: PlaylistScope
PLAYLIST_SCOPE_MINE: PlaylistScope
PLAYLIST_SCOPE_PUBLIC: PlaylistScope

class User(_message.Message):
    __slots__ = ("public_id", "display_name", "email", "role", "is_guest", "created_at", "last_seen_at")
    PUBLIC_ID_FIELD_NUMBER: _ClassVar[int]
    DISPLAY_NAME_FIELD_NUMBER: _ClassVar[int]
    EMAIL_FIELD_NUMBER: _ClassVar[int]
    ROLE_FIELD_NUMBER: _ClassVar[int]
    IS_GUEST_FIELD_NUMBER: _ClassVar[int]
    CREATED_AT_FIELD_NUMBER: _ClassVar[int]
    LAST_SEEN_AT_FIELD_NUMBER: _ClassVar[int]
    public_id: str
    display_name: str
    email: str
    role: Role
    is_guest: bool
    created_at: str
    last_seen_at: str
    def __init__(self, public_id: _Optional[str] = ..., display_name: _Optional[str] = ..., email: _Optional[str] = ..., role: _Optional[_Union[Role, str]] = ..., is_guest: _Optional[bool] = ..., created_at: _Optional[str] = ..., last_seen_at: _Optional[str] = ...) -> None: ...

class Identity(_message.Message):
    __slots__ = ("token", "user")
    TOKEN_FIELD_NUMBER: _ClassVar[int]
    USER_FIELD_NUMBER: _ClassVar[int]
    token: str
    user: User
    def __init__(self, token: _Optional[str] = ..., user: _Optional[_Union[User, _Mapping]] = ...) -> None: ...

class WhoAmIRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class StartGuestRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class ClaimRequest(_message.Message):
    __slots__ = ("email", "password", "display_name")
    EMAIL_FIELD_NUMBER: _ClassVar[int]
    PASSWORD_FIELD_NUMBER: _ClassVar[int]
    DISPLAY_NAME_FIELD_NUMBER: _ClassVar[int]
    email: str
    password: str
    display_name: str
    def __init__(self, email: _Optional[str] = ..., password: _Optional[str] = ..., display_name: _Optional[str] = ...) -> None: ...

class LoginRequest(_message.Message):
    __slots__ = ("email", "password")
    EMAIL_FIELD_NUMBER: _ClassVar[int]
    PASSWORD_FIELD_NUMBER: _ClassVar[int]
    email: str
    password: str
    def __init__(self, email: _Optional[str] = ..., password: _Optional[str] = ...) -> None: ...

class LogoutRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class LogoutResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class RenameRequest(_message.Message):
    __slots__ = ("display_name",)
    DISPLAY_NAME_FIELD_NUMBER: _ClassVar[int]
    display_name: str
    def __init__(self, display_name: _Optional[str] = ...) -> None: ...

class Show(_message.Message):
    __slots__ = ("id", "key", "title", "poster", "created_at", "is_film")
    ID_FIELD_NUMBER: _ClassVar[int]
    KEY_FIELD_NUMBER: _ClassVar[int]
    TITLE_FIELD_NUMBER: _ClassVar[int]
    POSTER_FIELD_NUMBER: _ClassVar[int]
    CREATED_AT_FIELD_NUMBER: _ClassVar[int]
    IS_FILM_FIELD_NUMBER: _ClassVar[int]
    id: int
    key: str
    title: str
    poster: str
    created_at: str
    is_film: bool
    def __init__(self, id: _Optional[int] = ..., key: _Optional[str] = ..., title: _Optional[str] = ..., poster: _Optional[str] = ..., created_at: _Optional[str] = ..., is_film: _Optional[bool] = ...) -> None: ...

class ShowSummary(_message.Message):
    __slots__ = ("show", "episode_count", "playable_count")
    SHOW_FIELD_NUMBER: _ClassVar[int]
    EPISODE_COUNT_FIELD_NUMBER: _ClassVar[int]
    PLAYABLE_COUNT_FIELD_NUMBER: _ClassVar[int]
    show: Show
    episode_count: int
    playable_count: int
    def __init__(self, show: _Optional[_Union[Show, _Mapping]] = ..., episode_count: _Optional[int] = ..., playable_count: _Optional[int] = ...) -> None: ...

class ShowDetails(_message.Message):
    __slots__ = ("show", "original_title", "kind", "year", "year_end", "audio", "quality", "description", "duration", "age_rating", "genres", "countries", "directors", "starring", "imdb_id", "imdb_rating", "imdb_votes", "imdb_url")
    SHOW_FIELD_NUMBER: _ClassVar[int]
    ORIGINAL_TITLE_FIELD_NUMBER: _ClassVar[int]
    KIND_FIELD_NUMBER: _ClassVar[int]
    YEAR_FIELD_NUMBER: _ClassVar[int]
    YEAR_END_FIELD_NUMBER: _ClassVar[int]
    AUDIO_FIELD_NUMBER: _ClassVar[int]
    QUALITY_FIELD_NUMBER: _ClassVar[int]
    DESCRIPTION_FIELD_NUMBER: _ClassVar[int]
    DURATION_FIELD_NUMBER: _ClassVar[int]
    AGE_RATING_FIELD_NUMBER: _ClassVar[int]
    GENRES_FIELD_NUMBER: _ClassVar[int]
    COUNTRIES_FIELD_NUMBER: _ClassVar[int]
    DIRECTORS_FIELD_NUMBER: _ClassVar[int]
    STARRING_FIELD_NUMBER: _ClassVar[int]
    IMDB_ID_FIELD_NUMBER: _ClassVar[int]
    IMDB_RATING_FIELD_NUMBER: _ClassVar[int]
    IMDB_VOTES_FIELD_NUMBER: _ClassVar[int]
    IMDB_URL_FIELD_NUMBER: _ClassVar[int]
    show: Show
    original_title: str
    kind: str
    year: int
    year_end: int
    audio: str
    quality: str
    description: str
    duration: str
    age_rating: str
    genres: _containers.RepeatedScalarFieldContainer[str]
    countries: _containers.RepeatedScalarFieldContainer[str]
    directors: _containers.RepeatedScalarFieldContainer[str]
    starring: _containers.RepeatedScalarFieldContainer[str]
    imdb_id: str
    imdb_rating: float
    imdb_votes: int
    imdb_url: str
    def __init__(self, show: _Optional[_Union[Show, _Mapping]] = ..., original_title: _Optional[str] = ..., kind: _Optional[str] = ..., year: _Optional[int] = ..., year_end: _Optional[int] = ..., audio: _Optional[str] = ..., quality: _Optional[str] = ..., description: _Optional[str] = ..., duration: _Optional[str] = ..., age_rating: _Optional[str] = ..., genres: _Optional[_Iterable[str]] = ..., countries: _Optional[_Iterable[str]] = ..., directors: _Optional[_Iterable[str]] = ..., starring: _Optional[_Iterable[str]] = ..., imdb_id: _Optional[str] = ..., imdb_rating: _Optional[float] = ..., imdb_votes: _Optional[int] = ..., imdb_url: _Optional[str] = ...) -> None: ...

class Track(_message.Message):
    __slots__ = ("vod_id", "audio", "playlist")
    VOD_ID_FIELD_NUMBER: _ClassVar[int]
    AUDIO_FIELD_NUMBER: _ClassVar[int]
    PLAYLIST_FIELD_NUMBER: _ClassVar[int]
    vod_id: int
    audio: str
    playlist: str
    def __init__(self, vod_id: _Optional[int] = ..., audio: _Optional[str] = ..., playlist: _Optional[str] = ...) -> None: ...

class Episode(_message.Message):
    __slots__ = ("id", "season", "episode", "episode_end", "title", "poster", "source_url", "vod_id", "vod_url", "playlist", "tracks")
    ID_FIELD_NUMBER: _ClassVar[int]
    SEASON_FIELD_NUMBER: _ClassVar[int]
    EPISODE_FIELD_NUMBER: _ClassVar[int]
    EPISODE_END_FIELD_NUMBER: _ClassVar[int]
    TITLE_FIELD_NUMBER: _ClassVar[int]
    POSTER_FIELD_NUMBER: _ClassVar[int]
    SOURCE_URL_FIELD_NUMBER: _ClassVar[int]
    VOD_ID_FIELD_NUMBER: _ClassVar[int]
    VOD_URL_FIELD_NUMBER: _ClassVar[int]
    PLAYLIST_FIELD_NUMBER: _ClassVar[int]
    TRACKS_FIELD_NUMBER: _ClassVar[int]
    id: int
    season: int
    episode: int
    episode_end: int
    title: str
    poster: str
    source_url: str
    vod_id: int
    vod_url: str
    playlist: str
    tracks: _containers.RepeatedCompositeFieldContainer[Track]
    def __init__(self, id: _Optional[int] = ..., season: _Optional[int] = ..., episode: _Optional[int] = ..., episode_end: _Optional[int] = ..., title: _Optional[str] = ..., poster: _Optional[str] = ..., source_url: _Optional[str] = ..., vod_id: _Optional[int] = ..., vod_url: _Optional[str] = ..., playlist: _Optional[str] = ..., tracks: _Optional[_Iterable[_Union[Track, _Mapping]]] = ...) -> None: ...

class EpisodeWithShow(_message.Message):
    __slots__ = ("episode", "show")
    EPISODE_FIELD_NUMBER: _ClassVar[int]
    SHOW_FIELD_NUMBER: _ClassVar[int]
    episode: Episode
    show: Show
    def __init__(self, episode: _Optional[_Union[Episode, _Mapping]] = ..., show: _Optional[_Union[Show, _Mapping]] = ...) -> None: ...

class ShowWithEpisodes(_message.Message):
    __slots__ = ("show", "episodes")
    SHOW_FIELD_NUMBER: _ClassVar[int]
    EPISODES_FIELD_NUMBER: _ClassVar[int]
    show: ShowDetails
    episodes: _containers.RepeatedCompositeFieldContainer[Episode]
    def __init__(self, show: _Optional[_Union[ShowDetails, _Mapping]] = ..., episodes: _Optional[_Iterable[_Union[Episode, _Mapping]]] = ...) -> None: ...

class PageInfo(_message.Message):
    __slots__ = ("total", "limit", "offset")
    TOTAL_FIELD_NUMBER: _ClassVar[int]
    LIMIT_FIELD_NUMBER: _ClassVar[int]
    OFFSET_FIELD_NUMBER: _ClassVar[int]
    total: int
    limit: int
    offset: int
    def __init__(self, total: _Optional[int] = ..., limit: _Optional[int] = ..., offset: _Optional[int] = ...) -> None: ...

class HealthRequest(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class HealthResponse(_message.Message):
    __slots__ = ("status", "shows", "episodes")
    STATUS_FIELD_NUMBER: _ClassVar[int]
    SHOWS_FIELD_NUMBER: _ClassVar[int]
    EPISODES_FIELD_NUMBER: _ClassVar[int]
    status: str
    shows: int
    episodes: int
    def __init__(self, status: _Optional[str] = ..., shows: _Optional[int] = ..., episodes: _Optional[int] = ...) -> None: ...

class ListShowsRequest(_message.Message):
    __slots__ = ("q", "series", "order", "limit", "offset")
    Q_FIELD_NUMBER: _ClassVar[int]
    SERIES_FIELD_NUMBER: _ClassVar[int]
    ORDER_FIELD_NUMBER: _ClassVar[int]
    LIMIT_FIELD_NUMBER: _ClassVar[int]
    OFFSET_FIELD_NUMBER: _ClassVar[int]
    q: str
    series: bool
    order: ShowOrder
    limit: int
    offset: int
    def __init__(self, q: _Optional[str] = ..., series: _Optional[bool] = ..., order: _Optional[_Union[ShowOrder, str]] = ..., limit: _Optional[int] = ..., offset: _Optional[int] = ...) -> None: ...

class ListShowsResponse(_message.Message):
    __slots__ = ("page", "items")
    PAGE_FIELD_NUMBER: _ClassVar[int]
    ITEMS_FIELD_NUMBER: _ClassVar[int]
    page: PageInfo
    items: _containers.RepeatedCompositeFieldContainer[ShowSummary]
    def __init__(self, page: _Optional[_Union[PageInfo, _Mapping]] = ..., items: _Optional[_Iterable[_Union[ShowSummary, _Mapping]]] = ...) -> None: ...

class StreamShowsRequest(_message.Message):
    __slots__ = ("q", "series", "order", "limit")
    Q_FIELD_NUMBER: _ClassVar[int]
    SERIES_FIELD_NUMBER: _ClassVar[int]
    ORDER_FIELD_NUMBER: _ClassVar[int]
    LIMIT_FIELD_NUMBER: _ClassVar[int]
    q: str
    series: bool
    order: ShowOrder
    limit: int
    def __init__(self, q: _Optional[str] = ..., series: _Optional[bool] = ..., order: _Optional[_Union[ShowOrder, str]] = ..., limit: _Optional[int] = ...) -> None: ...

class GetShowRequest(_message.Message):
    __slots__ = ("key",)
    KEY_FIELD_NUMBER: _ClassVar[int]
    key: str
    def __init__(self, key: _Optional[str] = ...) -> None: ...

class ListEpisodesRequest(_message.Message):
    __slots__ = ("show", "season", "q", "playable", "limit", "offset")
    SHOW_FIELD_NUMBER: _ClassVar[int]
    SEASON_FIELD_NUMBER: _ClassVar[int]
    Q_FIELD_NUMBER: _ClassVar[int]
    PLAYABLE_FIELD_NUMBER: _ClassVar[int]
    LIMIT_FIELD_NUMBER: _ClassVar[int]
    OFFSET_FIELD_NUMBER: _ClassVar[int]
    show: str
    season: int
    q: str
    playable: bool
    limit: int
    offset: int
    def __init__(self, show: _Optional[str] = ..., season: _Optional[int] = ..., q: _Optional[str] = ..., playable: _Optional[bool] = ..., limit: _Optional[int] = ..., offset: _Optional[int] = ...) -> None: ...

class ListEpisodesResponse(_message.Message):
    __slots__ = ("page", "items")
    PAGE_FIELD_NUMBER: _ClassVar[int]
    ITEMS_FIELD_NUMBER: _ClassVar[int]
    page: PageInfo
    items: _containers.RepeatedCompositeFieldContainer[EpisodeWithShow]
    def __init__(self, page: _Optional[_Union[PageInfo, _Mapping]] = ..., items: _Optional[_Iterable[_Union[EpisodeWithShow, _Mapping]]] = ...) -> None: ...

class GetEpisodeRequest(_message.Message):
    __slots__ = ("id",)
    ID_FIELD_NUMBER: _ClassVar[int]
    id: int
    def __init__(self, id: _Optional[int] = ...) -> None: ...

class HomeSection(_message.Message):
    __slots__ = ("id", "kind", "title", "kicker", "link", "show", "playlist", "artwork", "items")
    class ArtworkEntry(_message.Message):
        __slots__ = ("key", "value")
        KEY_FIELD_NUMBER: _ClassVar[int]
        VALUE_FIELD_NUMBER: _ClassVar[int]
        key: str
        value: str
        def __init__(self, key: _Optional[str] = ..., value: _Optional[str] = ...) -> None: ...
    ID_FIELD_NUMBER: _ClassVar[int]
    KIND_FIELD_NUMBER: _ClassVar[int]
    TITLE_FIELD_NUMBER: _ClassVar[int]
    KICKER_FIELD_NUMBER: _ClassVar[int]
    LINK_FIELD_NUMBER: _ClassVar[int]
    SHOW_FIELD_NUMBER: _ClassVar[int]
    PLAYLIST_FIELD_NUMBER: _ClassVar[int]
    ARTWORK_FIELD_NUMBER: _ClassVar[int]
    ITEMS_FIELD_NUMBER: _ClassVar[int]
    id: int
    kind: SectionKind
    title: str
    kicker: str
    link: str
    show: Show
    playlist: Playlist
    artwork: _containers.ScalarMap[str, str]
    items: _containers.RepeatedCompositeFieldContainer[EpisodeWithShow]
    def __init__(self, id: _Optional[int] = ..., kind: _Optional[_Union[SectionKind, str]] = ..., title: _Optional[str] = ..., kicker: _Optional[str] = ..., link: _Optional[str] = ..., show: _Optional[_Union[Show, _Mapping]] = ..., playlist: _Optional[_Union[Playlist, _Mapping]] = ..., artwork: _Optional[_Mapping[str, str]] = ..., items: _Optional[_Iterable[_Union[EpisodeWithShow, _Mapping]]] = ...) -> None: ...

class Home(_message.Message):
    __slots__ = ("sections",)
    SECTIONS_FIELD_NUMBER: _ClassVar[int]
    sections: _containers.RepeatedCompositeFieldContainer[HomeSection]
    def __init__(self, sections: _Optional[_Iterable[_Union[HomeSection, _Mapping]]] = ...) -> None: ...

class GetHomeRequest(_message.Message):
    __slots__ = ("preview",)
    PREVIEW_FIELD_NUMBER: _ClassVar[int]
    preview: bool
    def __init__(self, preview: _Optional[bool] = ...) -> None: ...

class Progress(_message.Message):
    __slots__ = ("episode_id", "position_seconds", "duration_seconds", "completed", "ratio", "last_watched_at")
    EPISODE_ID_FIELD_NUMBER: _ClassVar[int]
    POSITION_SECONDS_FIELD_NUMBER: _ClassVar[int]
    DURATION_SECONDS_FIELD_NUMBER: _ClassVar[int]
    COMPLETED_FIELD_NUMBER: _ClassVar[int]
    RATIO_FIELD_NUMBER: _ClassVar[int]
    LAST_WATCHED_AT_FIELD_NUMBER: _ClassVar[int]
    episode_id: int
    position_seconds: float
    duration_seconds: float
    completed: bool
    ratio: float
    last_watched_at: str
    def __init__(self, episode_id: _Optional[int] = ..., position_seconds: _Optional[float] = ..., duration_seconds: _Optional[float] = ..., completed: _Optional[bool] = ..., ratio: _Optional[float] = ..., last_watched_at: _Optional[str] = ...) -> None: ...

class HistoryEntry(_message.Message):
    __slots__ = ("progress", "episode")
    PROGRESS_FIELD_NUMBER: _ClassVar[int]
    EPISODE_FIELD_NUMBER: _ClassVar[int]
    progress: Progress
    episode: EpisodeWithShow
    def __init__(self, progress: _Optional[_Union[Progress, _Mapping]] = ..., episode: _Optional[_Union[EpisodeWithShow, _Mapping]] = ...) -> None: ...

class ReportProgressRequest(_message.Message):
    __slots__ = ("episode_id", "position_seconds", "duration_seconds", "completed")
    EPISODE_ID_FIELD_NUMBER: _ClassVar[int]
    POSITION_SECONDS_FIELD_NUMBER: _ClassVar[int]
    DURATION_SECONDS_FIELD_NUMBER: _ClassVar[int]
    COMPLETED_FIELD_NUMBER: _ClassVar[int]
    episode_id: int
    position_seconds: float
    duration_seconds: float
    completed: bool
    def __init__(self, episode_id: _Optional[int] = ..., position_seconds: _Optional[float] = ..., duration_seconds: _Optional[float] = ..., completed: _Optional[bool] = ...) -> None: ...

class GetProgressRequest(_message.Message):
    __slots__ = ("episode_id",)
    EPISODE_ID_FIELD_NUMBER: _ClassVar[int]
    episode_id: int
    def __init__(self, episode_id: _Optional[int] = ...) -> None: ...

class ForgetProgressRequest(_message.Message):
    __slots__ = ("episode_id",)
    EPISODE_ID_FIELD_NUMBER: _ClassVar[int]
    episode_id: int
    def __init__(self, episode_id: _Optional[int] = ...) -> None: ...

class ForgetProgressResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class ListHistoryRequest(_message.Message):
    __slots__ = ("completed", "limit", "offset")
    COMPLETED_FIELD_NUMBER: _ClassVar[int]
    LIMIT_FIELD_NUMBER: _ClassVar[int]
    OFFSET_FIELD_NUMBER: _ClassVar[int]
    completed: bool
    limit: int
    offset: int
    def __init__(self, completed: _Optional[bool] = ..., limit: _Optional[int] = ..., offset: _Optional[int] = ...) -> None: ...

class ListHistoryResponse(_message.Message):
    __slots__ = ("page", "items")
    PAGE_FIELD_NUMBER: _ClassVar[int]
    ITEMS_FIELD_NUMBER: _ClassVar[int]
    page: PageInfo
    items: _containers.RepeatedCompositeFieldContainer[HistoryEntry]
    def __init__(self, page: _Optional[_Union[PageInfo, _Mapping]] = ..., items: _Optional[_Iterable[_Union[HistoryEntry, _Mapping]]] = ...) -> None: ...

class ContinueWatchingRequest(_message.Message):
    __slots__ = ("limit",)
    LIMIT_FIELD_NUMBER: _ClassVar[int]
    limit: int
    def __init__(self, limit: _Optional[int] = ...) -> None: ...

class ContinueWatchingResponse(_message.Message):
    __slots__ = ("items",)
    ITEMS_FIELD_NUMBER: _ClassVar[int]
    items: _containers.RepeatedCompositeFieldContainer[HistoryEntry]
    def __init__(self, items: _Optional[_Iterable[_Union[HistoryEntry, _Mapping]]] = ...) -> None: ...

class Playlist(_message.Message):
    __slots__ = ("id", "name", "visibility", "created_at", "count", "mine")
    ID_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    VISIBILITY_FIELD_NUMBER: _ClassVar[int]
    CREATED_AT_FIELD_NUMBER: _ClassVar[int]
    COUNT_FIELD_NUMBER: _ClassVar[int]
    MINE_FIELD_NUMBER: _ClassVar[int]
    id: int
    name: str
    visibility: PlaylistVisibility
    created_at: str
    count: int
    mine: bool
    def __init__(self, id: _Optional[int] = ..., name: _Optional[str] = ..., visibility: _Optional[_Union[PlaylistVisibility, str]] = ..., created_at: _Optional[str] = ..., count: _Optional[int] = ..., mine: _Optional[bool] = ...) -> None: ...

class PlaylistItem(_message.Message):
    __slots__ = ("id", "position", "episode")
    ID_FIELD_NUMBER: _ClassVar[int]
    POSITION_FIELD_NUMBER: _ClassVar[int]
    EPISODE_FIELD_NUMBER: _ClassVar[int]
    id: int
    position: int
    episode: EpisodeWithShow
    def __init__(self, id: _Optional[int] = ..., position: _Optional[int] = ..., episode: _Optional[_Union[EpisodeWithShow, _Mapping]] = ...) -> None: ...

class PlaylistDetail(_message.Message):
    __slots__ = ("playlist", "items")
    PLAYLIST_FIELD_NUMBER: _ClassVar[int]
    ITEMS_FIELD_NUMBER: _ClassVar[int]
    playlist: Playlist
    items: _containers.RepeatedCompositeFieldContainer[PlaylistItem]
    def __init__(self, playlist: _Optional[_Union[Playlist, _Mapping]] = ..., items: _Optional[_Iterable[_Union[PlaylistItem, _Mapping]]] = ...) -> None: ...

class ListPlaylistsRequest(_message.Message):
    __slots__ = ("scope",)
    SCOPE_FIELD_NUMBER: _ClassVar[int]
    scope: PlaylistScope
    def __init__(self, scope: _Optional[_Union[PlaylistScope, str]] = ...) -> None: ...

class ListPlaylistsResponse(_message.Message):
    __slots__ = ("items",)
    ITEMS_FIELD_NUMBER: _ClassVar[int]
    items: _containers.RepeatedCompositeFieldContainer[Playlist]
    def __init__(self, items: _Optional[_Iterable[_Union[Playlist, _Mapping]]] = ...) -> None: ...

class GetPlaylistRequest(_message.Message):
    __slots__ = ("id",)
    ID_FIELD_NUMBER: _ClassVar[int]
    id: int
    def __init__(self, id: _Optional[int] = ...) -> None: ...

class CreatePlaylistRequest(_message.Message):
    __slots__ = ("name",)
    NAME_FIELD_NUMBER: _ClassVar[int]
    name: str
    def __init__(self, name: _Optional[str] = ...) -> None: ...

class CreateFromShowRequest(_message.Message):
    __slots__ = ("show", "season", "name", "playable_only")
    SHOW_FIELD_NUMBER: _ClassVar[int]
    SEASON_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    PLAYABLE_ONLY_FIELD_NUMBER: _ClassVar[int]
    show: str
    season: int
    name: str
    playable_only: bool
    def __init__(self, show: _Optional[str] = ..., season: _Optional[int] = ..., name: _Optional[str] = ..., playable_only: _Optional[bool] = ...) -> None: ...

class UpdatePlaylistRequest(_message.Message):
    __slots__ = ("id", "name", "visibility")
    ID_FIELD_NUMBER: _ClassVar[int]
    NAME_FIELD_NUMBER: _ClassVar[int]
    VISIBILITY_FIELD_NUMBER: _ClassVar[int]
    id: int
    name: str
    visibility: PlaylistVisibility
    def __init__(self, id: _Optional[int] = ..., name: _Optional[str] = ..., visibility: _Optional[_Union[PlaylistVisibility, str]] = ...) -> None: ...

class DeletePlaylistRequest(_message.Message):
    __slots__ = ("id",)
    ID_FIELD_NUMBER: _ClassVar[int]
    id: int
    def __init__(self, id: _Optional[int] = ...) -> None: ...

class DeletePlaylistResponse(_message.Message):
    __slots__ = ()
    def __init__(self) -> None: ...

class AddItemRequest(_message.Message):
    __slots__ = ("playlist_id", "episode_id")
    PLAYLIST_ID_FIELD_NUMBER: _ClassVar[int]
    EPISODE_ID_FIELD_NUMBER: _ClassVar[int]
    playlist_id: int
    episode_id: int
    def __init__(self, playlist_id: _Optional[int] = ..., episode_id: _Optional[int] = ...) -> None: ...

class RemoveItemRequest(_message.Message):
    __slots__ = ("playlist_id", "item_id")
    PLAYLIST_ID_FIELD_NUMBER: _ClassVar[int]
    ITEM_ID_FIELD_NUMBER: _ClassVar[int]
    playlist_id: int
    item_id: int
    def __init__(self, playlist_id: _Optional[int] = ..., item_id: _Optional[int] = ...) -> None: ...

class ReorderRequest(_message.Message):
    __slots__ = ("playlist_id", "item_ids")
    PLAYLIST_ID_FIELD_NUMBER: _ClassVar[int]
    ITEM_IDS_FIELD_NUMBER: _ClassVar[int]
    playlist_id: int
    item_ids: _containers.RepeatedScalarFieldContainer[int]
    def __init__(self, playlist_id: _Optional[int] = ..., item_ids: _Optional[_Iterable[int]] = ...) -> None: ...
