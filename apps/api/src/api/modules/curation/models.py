"""Sections and artwork."""

import enum
from typing import Final

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Enum,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from api.core.models import Base, TimestampMixin, UpdatedAtMixin
from api.modules.catalogue.models import Show
from api.modules.media.models import MediaFile
from api.modules.playlists.models import Playlist


class SectionKind(str, enum.Enum):
    """How a section is drawn. The names match what the front end already has."""

    hero = "hero"
    rail = "rail"
    grid = "grid"
    # Artwork and a link, with no episodes under it — "the finale is on Friday".
    banner = "banner"


class Placement(str, enum.Enum):
    """Which shape of a picture this is.

    Different sizes of the same artwork, not different artworks: a hero needs a
    wide crop, a rail needs 16:9, a phone rail wants a square, and a logo is the
    title treatment that sits *over* the hero.
    """

    hero = "hero"
    tile = "tile"
    poster = "poster"
    square = "square"
    logo = "logo"


# What to hand an admin who's about to upload. Advisory — nothing is rejected
# for being the wrong shape, because a slightly-off banner beats no banner.
RECOMMENDED: Final[dict[Placement, tuple[int, int]]] = {
    Placement.hero: (1920, 820),
    Placement.tile: (640, 360),
    Placement.poster: (600, 900),
    Placement.square: (600, 600),
    Placement.logo: (800, 320),
}


class Section(Base, TimestampMixin, UpdatedAtMixin):
    """One row of the home screen."""

    __tablename__ = "sections"
    __table_args__ = (
        # A section shows one thing. Both filled is a section that can't be
        # drawn, and the database is a better place to say so than a code review.
        CheckConstraint(
            "NOT (show_id IS NOT NULL AND playlist_id IS NOT NULL)",
            name="ck_section_one_source",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)

    # A varchar with a check constraint, like `users.role` — adding a kind
    # later shouldn't mean `ALTER TYPE` inside a migration.
    kind: Mapped[SectionKind] = mapped_column(
        Enum(SectionKind, name="section_kind", native_enum=False, length=20),
        default=SectionKind.rail,
        server_default=SectionKind.rail.value,
    )
    title: Mapped[str] = mapped_column(String(200))
    # The small line above the title — "Most of anything here".
    kicker: Mapped[str | None] = mapped_column(String(200), nullable=True)
    # Where the whole block clicks through to. A path in this app, not a host.
    link: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # Dense and 0-based, rewritten on every reorder — the same rule playlist
    # items follow, and for the same reason.
    position: Mapped[int] = mapped_column(Integer, default=0, index=True)
    # Drafting a section and publishing it are different acts.
    visible: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true")
    # How many episodes to put under it. A rail isn't a catalogue page.
    item_limit: Mapped[int] = mapped_column(Integer, default=14, server_default="14")

    show_id: Mapped[int | None] = mapped_column(
        ForeignKey("shows.id", ondelete="CASCADE"), nullable=True, index=True
    )
    playlist_id: Mapped[int | None] = mapped_column(
        ForeignKey("playlists.id", ondelete="CASCADE"), nullable=True, index=True
    )

    show: Mapped[Show | None] = relationship(lazy="joined")
    playlist: Mapped[Playlist | None] = relationship(lazy="selectin")
    artwork: Mapped[list["Artwork"]] = relationship(
        back_populates="section", cascade="all, delete-orphan", lazy="selectin"
    )


class Artwork(Base, TimestampMixin, UpdatedAtMixin):
    """One picture, at one placement, for one thing.

    The subject is three nullable foreign keys rather than a generic
    `subject_type`/`subject_id` pair. That costs a column each time a fourth
    kind of thing wants artwork, and buys the thing that matters more here:
    deleting a show takes its banners with it instead of leaving rows that point
    at nothing.
    """

    __tablename__ = "artwork"
    __table_args__ = (
        # One hero per show, one tile per playlist. `PUT` upserts on exactly
        # these, which is why they're unique rather than merely tidy.
        UniqueConstraint("show_id", "placement", name="uq_artwork_show_placement"),
        UniqueConstraint("playlist_id", "placement", name="uq_artwork_playlist_placement"),
        UniqueConstraint("section_id", "placement", name="uq_artwork_section_placement"),
        # Written with CASE rather than Postgres' `::int` so the constraint
        # isn't the one thing tying this schema to one database.
        CheckConstraint(
            "(CASE WHEN show_id IS NULL THEN 0 ELSE 1 END)"
            " + (CASE WHEN playlist_id IS NULL THEN 0 ELSE 1 END)"
            " + (CASE WHEN section_id IS NULL THEN 0 ELSE 1 END) = 1",
            name="ck_artwork_one_subject",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    placement: Mapped[Placement] = mapped_column(
        Enum(Placement, name="artwork_placement", native_enum=False, length=20), index=True
    )

    # Either an upload or somebody else's server. `media_id` is the record of
    # which; `url` is what a client actually uses, resolved on write so reads
    # never have to branch.
    url: Mapped[str] = mapped_column(String(1000))
    media_id: Mapped[int | None] = mapped_column(
        ForeignKey("media_files.id", ondelete="SET NULL"), nullable=True, index=True
    )

    show_id: Mapped[int | None] = mapped_column(
        ForeignKey("shows.id", ondelete="CASCADE"), nullable=True, index=True
    )
    playlist_id: Mapped[int | None] = mapped_column(
        ForeignKey("playlists.id", ondelete="CASCADE"), nullable=True, index=True
    )
    section_id: Mapped[int | None] = mapped_column(
        ForeignKey("sections.id", ondelete="CASCADE"), nullable=True, index=True
    )

    media: Mapped[MediaFile | None] = relationship(lazy="joined")
    section: Mapped[Section | None] = relationship(back_populates="artwork")
