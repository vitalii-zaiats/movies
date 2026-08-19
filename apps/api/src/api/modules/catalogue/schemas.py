"""What the catalogue hands out."""

from datetime import datetime

from pydantic import BaseModel, computed_field

from api.core.schemas import ORMModel, Page
from api.settings import settings


class IngestEpisode(BaseModel):
    """One episode as whoever crawled it knows it.

    `vod_id` is something the sender registered with the VOD service; the API
    takes its word for it and never creates one itself.
    """

    show_key: str
    show_title: str | None = None
    # Artwork for the show row itself. Only ever fills a gap — a show that has a
    # poster keeps it, because a later crawl of a thumbnail shouldn't replace it.
    show_poster: str | None = None
    title: str
    season: int
    episode: int
    episode_end: int | None = None
    poster: str | None = None
    source_url: str
    vod_id: int | None = None
    # Which dub this particular VOD carries, when the source said.
    audio: str | None = None
    # And what language it is in, which the dub's name never says.
    language: str | None = None


class IngestRequest(BaseModel):
    items: list[IngestEpisode]


class IngestReport(BaseModel):
    shows: int
    created: int
    updated: int


class ShowOut(ORMModel):
    id: int
    key: str
    title: str
    poster: str | None
    created_at: datetime
    # A film, not a series — so a client knows to stop saying "S01E01" about
    # something that only ever had one.
    is_film: bool


class ShowDetails(ShowOut):
    """Everything the crawl knew, for the one screen that shows a title on its own.

    Kept off `ShowOut` on purpose: that one rides along inside every episode of
    every listing, and a synopsis per row is a page of prose nobody asked for.
    """

    original_title: str | None = None
    kind: str | None = None
    year: int | None = None
    year_end: int | None = None
    audio: str | None = None
    quality: str | None = None
    description: str | None = None
    duration: str | None = None
    age_rating: str | None = None
    genres: list[str] | None = None
    countries: list[str] | None = None
    directors: list[str] | None = None
    starring: list[str] | None = None
    imdb_id: str | None = None
    imdb_rating: float | None = None
    imdb_votes: int | None = None

    @computed_field
    @property
    def imdb_url(self) -> str | None:
        """Composed rather than stored — the id is the fact, the URL is a habit."""
        return f"https://www.imdb.com/title/{self.imdb_id}/" if self.imdb_id else None


class IngestShow(BaseModel):
    """What a crawl knows about a title, arriving after the title itself.

    Only ever fills in a show that exists: the episodes create the row, this
    describes it. Anything left None is left alone, so two sources can each say
    the part they know.
    """

    key: str
    original_title: str | None = None
    kind: str | None = None
    year: int | None = None
    year_end: int | None = None
    audio: str | None = None
    quality: str | None = None
    description: str | None = None
    duration: str | None = None
    age_rating: str | None = None
    genres: list[str] | None = None
    countries: list[str] | None = None
    directors: list[str] | None = None
    starring: list[str] | None = None
    imdb_id: str | None = None
    imdb_rating: float | None = None
    imdb_votes: int | None = None


class IngestShowRequest(BaseModel):
    items: list[IngestShow]


class ShowReport(BaseModel):
    updated: int
    unknown: int


class SyncReport(BaseModel):
    """What one walk of the VOD service came to, and where it stopped."""

    created: int
    updated: int
    # Registered, but saying too little to file — see `_from_vod`.
    skipped: int
    # The last VOD id read. Next time starts here.
    cursor: int


class ShowSummary(ShowOut):
    """A show as a browse list wants it: with how much of it is actually here,
    and the few facts a row can use.

    The counts are the server's job — the alternative is a page request per tile
    to learn a number, which is what the front end had to do before this existed.
    The same argument brought the year, the score and the genres along: they are
    what a row says under a title, and asking for them one row at a time is the
    request-per-tile problem wearing a different hat.

    What stays out is the synopsis and the cast. Those are a page of prose per
    row, which is why `ShowDetails` exists.
    """

    episode_count: int
    playable_count: int
    year: int | None = None
    imdb_rating: float | None = None
    genres: list[str] | None = None


class TrackOut(ORMModel):
    """One dub of an episode, as a player needs it."""

    vod_id: int
    audio: str | None
    language: str | None = None

    @computed_field
    @property
    def playlist(self) -> str:
        base = settings.vod_base.rstrip("/")
        return f"{base}/{self.vod_id}/index.m3u8"


class EpisodeOut(ORMModel):
    id: int
    season: int
    episode: int
    episode_end: int | None
    title: str
    poster: str | None
    source_url: str
    vod_id: int | None
    # Everything this episode can be played as. One entry is the ordinary case;
    # more than one means somebody dubbed it twice.
    tracks: list[TrackOut] = []

    @computed_field
    @property
    def vod_url(self) -> str | None:
        """Composed from the id rather than read from the row.

        The URL a browser should use depends on how the stack is exposed today,
        which is not something worth freezing into the database at seed time.
        """
        base = settings.vod_base.rstrip("/")
        return f"{base}/{self.vod_id}" if self.vod_id else None

    @computed_field
    @property
    def playlist(self) -> str | None:
        """The one URL a player needs — our VOD's, never the origin's."""
        return f"{self.vod_url}/index.m3u8" if self.vod_url else None


class EpisodeWithShow(EpisodeOut):
    show: ShowOut


class ShowWithEpisodes(ShowDetails):
    episodes: list[EpisodeOut]


class EpisodePage(Page):
    items: list[EpisodeWithShow]


class ShowPage(Page):
    items: list[ShowSummary]
