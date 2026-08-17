"""Every query about playlists.

Note that `owner_id` is a query argument, not a filter the service remembers to
apply afterwards. Ownership that lives in the WHERE clause can't be forgotten by
the next route somebody adds.
"""

from collections.abc import Sequence

from sqlalchemy import select

from api.core.repository import Repository
from api.modules.playlists.models import Playlist, PlaylistItem, Visibility


class PlaylistRepository(Repository[Playlist]):
    model = Playlist

    async def owned_by(self, owner_id: int) -> list[Playlist]:
        rows = await self.session.scalars(
            select(Playlist).where(Playlist.owner_id == owner_id).order_by(Playlist.id)
        )
        return list(rows)

    async def public(self) -> list[Playlist]:
        """The curated collections — everyone sees these, signed in or not."""
        rows = await self.session.scalars(
            select(Playlist)
            .where(Playlist.visibility == Visibility.public)
            .order_by(Playlist.id)
        )
        return list(rows)

    async def visible_to(self, owner_id: int) -> list[Playlist]:
        """Theirs plus everyone's public ones, which is what a library shows."""
        rows = await self.session.scalars(
            select(Playlist)
            .where(
                (Playlist.owner_id == owner_id)
                | (Playlist.visibility == Visibility.public)
            )
            .order_by(Playlist.id)
        )
        return list(rows)

    async def all(self) -> list[Playlist]:
        """Admin only. Includes the ownerless rows from before users existed."""
        rows = await self.session.scalars(select(Playlist).order_by(Playlist.id))
        return list(rows)

    async def create(
        self, name: str, owner_id: int, items: Sequence[PlaylistItem] = ()
    ) -> Playlist:
        playlist = Playlist(name=name, owner_id=owner_id)
        playlist.items = list(items)
        return await self.add(playlist)

    async def refresh(self, playlist: Playlist) -> Playlist:
        await self.session.refresh(playlist)
        return playlist
