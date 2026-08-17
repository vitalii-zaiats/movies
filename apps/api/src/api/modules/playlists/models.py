"""Playlists and their items."""

import enum

from sqlalchemy import Enum, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from api.core.models import Base, TimestampMixin
from api.modules.catalogue.models import Episode


class Visibility(str, enum.Enum):
    """Who a playlist is for.

    `public` is an editorial act, not a sharing one: a public playlist is a
    collection the whole install sees, so only an admin can make one. Somebody
    else's `private` playlist stays a 404 either way.
    """

    private = "private"
    public = "public"


class Playlist(Base, TimestampMixin):
    """An ordered queue of episodes. This is what a screen actually plays."""

    __tablename__ = "playlists"

    id: Mapped[int] = mapped_column(primary_key=True)
    name: Mapped[str] = mapped_column(String(200))

    visibility: Mapped[Visibility] = mapped_column(
        Enum(Visibility, name="playlist_visibility", native_enum=False, length=20),
        default=Visibility.private,
        server_default=Visibility.private.value,
        index=True,
    )

    # Nullable for one reason only: the playlists that existed before users did.
    # Those show up for admins and nobody else — see `PlaylistRepository.owned`.
    # Everything created from here on has an owner, guest or not.
    owner_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=True
    )

    items: Mapped[list["PlaylistItem"]] = relationship(
        back_populates="playlist",
        cascade="all, delete-orphan",
        order_by="PlaylistItem.position",
        lazy="selectin",
    )

    @property
    def is_public(self) -> bool:
        return self.visibility is Visibility.public

    @property
    def count(self) -> int:
        """How many episodes are queued.

        On the model rather than assembled in a DTO helper, so any schema that
        embeds a playlist — a home-screen section, say — can read it straight
        off the row like every other field.
        """
        return len(self.items)


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
