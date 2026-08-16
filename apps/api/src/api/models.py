"""The catalogue schema.

A show has episodes; an episode points at a VOD by URL. The API never stores a
stream URL of its own — the playlist belongs to the VOD service, and all we keep
is the link to it.
"""

from datetime import UTC, datetime

from sqlalchemy import DateTime, ForeignKey, Integer, String, UniqueConstraint, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


def _now() -> datetime:
    return datetime.now(UTC)


class Show(Base):
    __tablename__ = "shows"

    id: Mapped[int] = mapped_column(primary_key=True)
    key: Mapped[str] = mapped_column(String(120), unique=True, index=True)
    title: Mapped[str] = mapped_column(String(300))
    poster: Mapped[str | None] = mapped_column(String(1000), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_now, server_default=func.now()
    )

    episodes: Mapped[list["Episode"]] = relationship(
        back_populates="show", cascade="all, delete-orphan", lazy="selectin"
    )


class Episode(Base):
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

    # The whole point: a link into our own VOD service, never an upstream URL.
    vod_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    vod_url: Mapped[str | None] = mapped_column(String(1000), nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_now, server_default=func.now()
    )

    show: Mapped[Show] = relationship(back_populates="episodes", lazy="joined")


class Playlist(Base):
    """An ordered queue of episodes. This is what a screen actually plays."""

    __tablename__ = "playlists"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_now, server_default=func.now()
    )

    items: Mapped[list["PlaylistItem"]] = relationship(
        back_populates="playlist",
        cascade="all, delete-orphan",
        order_by="PlaylistItem.position",
        lazy="selectin",
    )


class PlaylistItem(Base):
    __tablename__ = "playlist_items"
    __table_args__ = (
        # The same episode twice in one playlist is a mistake, not a feature.
        UniqueConstraint("playlist_id", "episode_id", name="uq_playlist_episode"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    playlist_id: Mapped[int] = mapped_column(
        ForeignKey("playlists.id", ondelete="CASCADE"), index=True
    )
    episode_id: Mapped[int] = mapped_column(ForeignKey("episodes.id", ondelete="CASCADE"))
    # Dense and 0-based; rewritten on every mutation so gaps can't accumulate.
    position: Mapped[int] = mapped_column(Integer)

    playlist: Mapped[Playlist] = relationship(back_populates="items")
    episode: Mapped[Episode] = relationship(lazy="joined")
