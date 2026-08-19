"""The catalogue schema.

A show has episodes; an episode points at a VOD by id. The API never stores a
stream URL of its own — the playlist belongs to the VOD service, and all we keep
is the link to it.
"""

from typing import TYPE_CHECKING

from sqlalchemy import (
    JSON,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
    select,
)
from sqlalchemy.orm import Mapped, column_property, mapped_column, relationship

from api.core.models import Base, TimestampMixin, UpdatedAtMixin


class Show(Base, TimestampMixin):
    __tablename__ = "shows"

    id: Mapped[int] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    title: Mapped[str] = mapped_column(String(300))
    poster: Mapped[str | None] = mapped_column(String(1000), nullable=True)

    # --- what the crawl knew and the catalogue used to throw away -------------
    # None of this is the catalogue's own knowledge: it's what a source page
    # said, carried through so a client has something to show besides a title.
    # Every field is optional because every source is missing something.
    original_title: Mapped[str | None] = mapped_column(String(300), nullable=True)
    # What the source called this shape of thing: film, series, cartoon, anime.
    # Not the same question as `is_film`, which is only about how many episodes
    # arrived — a cartoon is a kind, one episode is a shape.
    kind: Mapped[str | None] = mapped_column(String(20), nullable=True, index=True)
    # Indexed because browsing is sorted by it — see `_show_order`.
    year: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    # A series that has finished running says when.
    year_end: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # Who dubbed it and how — "Postmodern | Професійний дубльований". One line,
    # because that's how the source writes it and splitting it would be a guess.
    # Unbounded, because a popular film lists every dub it ever got and the
    # source joins them all: the length is theirs to decide, not ours.
    audio: Mapped[str | None] = mapped_column(Text, nullable=True)
    quality: Mapped[str | None] = mapped_column(String(40), nullable=True)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    duration: Mapped[str | None] = mapped_column(String(60), nullable=True)
    age_rating: Mapped[str | None] = mapped_column(String(20), nullable=True)
    # Language-neutral keys — `action`, `sci-fi` — because what a genre is called
    # depends on who's reading, and that's the front end's business.
    genres: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
    countries: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
    directors: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)
    starring: Mapped[list[str] | None] = mapped_column(JSON, nullable=True)

    # IMDb, matched offline against their published datasets — the id is the
    # useful half, the rating is what the source claimed when it was crawled.
    imdb_id: Mapped[str | None] = mapped_column(String(12), nullable=True, index=True)
    imdb_rating: Mapped[float | None] = mapped_column(Float, nullable=True)
    imdb_votes: Mapped[int | None] = mapped_column(Integer, nullable=True)

    episodes: Mapped[list["Episode"]] = relationship(
        back_populates="show", cascade="all, delete-orphan", lazy="selectin"
    )

    if TYPE_CHECKING:
        # Attached below, once `Episode` exists to be counted.
        episode_count: int

    @property
    def is_film(self) -> bool:
        """One episode and no more is how a film arrives in a schema built for
        series. The shape is the only thing telling them apart, so the answer
        belongs here rather than in every client that has to draw one."""
        return self.episode_count == 1


class SyncCursor(Base, UpdatedAtMixin):
    """How far the catalogue has read somebody else's list.

    One row per source — today only the VOD service. A cursor is kept rather
    than derived because "the highest VOD id I have an episode for" answers a
    different question: a VOD the catalogue looked at and deliberately skipped
    would be looked at again forever.
    """

    __tablename__ = "sync_cursors"

    name: Mapped[str] = mapped_column(String(40), primary_key=True)
    position: Mapped[int] = mapped_column(Integer, default=0)


class Episode(Base, TimestampMixin):
    __tablename__ = "episodes"
    __table_args__ = (
        UniqueConstraint("show_id", "season", "episode", name="uq_episode_number"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    show_id: Mapped[int] = mapped_column(ForeignKey("shows.id", ondelete="CASCADE"), index=True)

    season: Mapped[int] = mapped_column(Integer)
    episode: Mapped[int] = mapped_column(Integer)
    # Some episodes are aired as a pair — "13-14".
    episode_end: Mapped[int | None] = mapped_column(Integer, nullable=True)

    title: Mapped[str] = mapped_column(String(300))
    poster: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    # Where the metadata came from, and what makes a re-seed idempotent.
    source_url: Mapped[str] = mapped_column(String(1000), unique=True, index=True)

    # The whole point: a handle into our own VOD service, never an upstream URL.
    # Only the id — the URL a browser should use depends on how the stack is
    # exposed today, so it's composed at response time instead of stored.
    vod_id: Mapped[int | None] = mapped_column(Integer, nullable=True)

    show: Mapped[Show] = relationship(back_populates="episodes", lazy="joined")
    tracks: Mapped[list["EpisodeTrack"]] = relationship(
        back_populates="episode", cascade="all, delete-orphan", lazy="selectin"
    )


class EpisodeTrack(Base, TimestampMixin):
    """One way to hear an episode: a VOD, and whose voice it carries.

    Some sources publish the same episode in several dubs — two studios, two
    files, two VODs. The episode is still one episode, so the choice lives
    beside it rather than duplicating the row: `Episode.vod_id` stays as the one
    a player gets by default, and this is everything it could have been instead.
    """

    __tablename__ = "episode_tracks"

    id: Mapped[int] = mapped_column(primary_key=True)
    episode_id: Mapped[int] = mapped_column(
        ForeignKey("episodes.id", ondelete="CASCADE"), index=True
    )
    # A VOD plays one thing, so it belongs to one episode and appears once.
    vod_id: Mapped[int] = mapped_column(Integer, unique=True, index=True)
    # "Стругачка", "DniproFilm" — whatever the source called the studio. None
    # when the source offered a second player but never said why.
    #
    # Unbounded, for the same reason `Show.audio` is: a source that publishes one
    # stream but knows of six dubs writes all six into one line, and a popular
    # film's line runs past 200 characters. How long that sentence is belongs to
    # whoever wrote it.
    audio: Mapped[str | None] = mapped_column(Text, nullable=True)
    # What language this track is *in*, as an ISO 639-1 code — which the dub's
    # name above never says, since a studio is not a language. It comes from the
    # crawler, because a site publishes in one language and nothing in the
    # stream itself declares one. Null where nobody could say: an original
    # soundtrack whose language the crawl never learned.
    #
    # Indexed because browsing filters on it.
    language: Mapped[str | None] = mapped_column(String(8), nullable=True, index=True)

    episode: Mapped[Episode] = relationship(back_populates="tracks")


# Attached here, after `Episode` exists to be counted. A correlated subquery and
# not `len(self.episodes)`: that collection is a lazy load, and a DTO reading it
# inside an async request is exactly where `MissingGreenlet` comes from — the
# count has to arrive with the row, not be fetched while serialising it.
# `correlate_except` because a query that already joins `episodes` — the episode
# listing does — would otherwise let this subquery correlate that table too, and
# a SELECT with nothing left in its FROM is an error, not a count.
Show.episode_count = column_property(  # type: ignore[assignment]
    select(func.count(Episode.id))
    .where(Episode.show_id == Show.id)
    .correlate_except(Episode)
    .scalar_subquery()
)
