"""Playlist rules: ordering, ownership, visibility, and what lands in the feed.

Every method takes the user who's asking, and every lookup goes through
`_owned` or `_readable`. Somebody else's private playlist comes back as a 404,
not a 403 — a 403 would confirm the id exists, and there's nothing to gain by
telling a stranger how many playlists their neighbour has.

What this module knows about the rest of the app, and how:

* the catalogue, through `CatalogueService` — its published face, never its
  repositories. The two are bound by a foreign key anyway, so the import is
  honest rather than avoidable.
* activity, through the `ActivityRecorder` port in `ports.py` — a structural
  protocol this module defines and `deps.py` satisfies. Nothing here imports
  that module.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass
from typing import TYPE_CHECKING, Literal

from api.errors import Conflict, Forbidden, Invalid, NotFound
from api.modules.catalogue.service import CatalogueService
from api.modules.playlists import events
from api.modules.playlists.models import Playlist, PlaylistItem, Visibility
from api.modules.playlists.ports import ActivityRecorder
from api.modules.playlists.repository import PlaylistRepository

if TYPE_CHECKING:
    # Type positions only. Keeping them out of the runtime import graph is the
    # cheap half of the answer to "why does this module import that one".
    from sqlalchemy.ext.asyncio import AsyncSession

    from api.modules.accounts.models import User

# `visible` is the default because it's what a library screen wants: mine, plus
# whatever the admins have published.
Scope = Literal["visible", "mine", "public"]


@dataclass(slots=True)
class PlaylistService:
    session: AsyncSession
    recorder: ActivityRecorder

    @property
    def playlists(self) -> PlaylistRepository:
        return PlaylistRepository(self.session)

    @property
    def catalogue(self) -> CatalogueService:
        return CatalogueService(self.session)

    async def all(self, user: User, *, scope: Scope = "visible") -> list[Playlist]:
        match scope:
            case "public":
                return await self.playlists.public()
            case "mine":
                return await self.playlists.owned_by(user.id)
            case _ if user.is_admin:
                # Includes the ownerless rows from before users existed.
                return await self.playlists.all()
            case _:
                return await self.playlists.visible_to(user.id)

    async def get(self, playlist_id: int, user: User) -> Playlist:
        return await self._readable(playlist_id, user)

    async def published(self, playlist_id: int) -> Playlist:
        """A playlist anybody may be shown, with no user to check against.

        This is what the home screen is allowed to point at, and the rule lives
        here rather than in the module doing the pointing: what `public` means
        is this module's business.
        """
        playlist = await self._find(playlist_id)
        if not playlist.is_public:
            raise Invalid("publish the playlist before showing it to everyone")
        return playlist

    async def create(self, name: str, user: User) -> Playlist:
        playlist = await self.playlists.create(name.strip() or "untitled", user.id)
        await self._announce(playlist, user, events.CREATED)
        await self.session.commit()
        return await self.playlists.refresh(playlist)

    async def from_show(
        self,
        user: User,
        *,
        show_key: str,
        season: int | None = None,
        name: str | None = None,
        playable_only: bool = True,
    ) -> Playlist:
        """A queue out of a whole show, or one season, already in order."""
        episodes = await self.catalogue.show_episodes(
            show_key, season=season, playable_only=playable_only
        )
        if not episodes:
            raise NotFound(f"no playable episodes for {show_key!r}")

        default = show_key if season is None else f"{show_key} S{season:02d}"
        playlist = await self.playlists.create(
            (name or default).strip(),
            user.id,
            [
                PlaylistItem(episode_id=episode.id, position=index)
                for index, episode in enumerate(episodes)
            ],
        )
        await self._announce(playlist, user, events.CREATED)
        await self.session.commit()
        return await self.playlists.refresh(playlist)

    async def update(
        self,
        playlist_id: int,
        user: User,
        *,
        name: str | None = None,
        visibility: Visibility | None = None,
    ) -> Playlist:
        playlist = await self._owned(playlist_id, user)

        if name is not None:
            playlist.name = name.strip() or playlist.name
        if visibility is not None and visibility is not playlist.visibility:
            # Publishing puts a collection on everyone's home screen, so it's an
            # admin's call. Taking one down again is the owner's too — nobody
            # should need an admin to unshare their own list.
            if visibility is Visibility.public and not user.is_admin:
                raise Forbidden("only an admin can publish a playlist")
            playlist.visibility = visibility
            if visibility is Visibility.public:
                await self._announce(playlist, user, events.PUBLISHED)

        await self.session.commit()
        return await self.playlists.refresh(playlist)

    async def delete(self, playlist_id: int, user: User) -> None:
        playlist = await self._owned(playlist_id, user)
        # Announced before the delete: after it, there's no name left to log.
        await self._announce(playlist, user, events.DELETED)
        await self.playlists.delete(playlist)
        await self.session.commit()

    async def add_item(self, playlist_id: int, episode_id: int, user: User) -> Playlist:
        playlist = await self._owned(playlist_id, user)

        episode = await self.catalogue.episode(episode_id)
        if any(item.episode_id == episode.id for item in playlist.items):
            raise Conflict("already in this playlist")

        playlist.items.append(PlaylistItem(episode_id=episode.id, position=len(playlist.items)))
        await self._announce(playlist, user, events.ITEM_ADDED, episode_id=episode.id)
        await self.session.commit()
        return await self.playlists.refresh(playlist)

    async def remove_item(self, playlist_id: int, item_id: int, user: User) -> Playlist:
        playlist = await self._owned(playlist_id, user)

        item = next((i for i in playlist.items if i.id == item_id), None)
        if item is None:
            raise NotFound(f"no item {item_id} in this playlist")

        episode_id = item.episode_id
        playlist.items.remove(item)
        _renumber(playlist)
        await self._announce(playlist, user, events.ITEM_REMOVED, episode_id=episode_id)
        await self.session.commit()
        return await self.playlists.refresh(playlist)

    async def reorder(self, playlist_id: int, item_ids: Sequence[int], user: User) -> Playlist:
        playlist = await self._owned(playlist_id, user)

        by_id = {item.id: item for item in playlist.items}
        if set(item_ids) != set(by_id):
            raise Invalid("item_ids must list every item exactly once")

        for position, item_id in enumerate(item_ids):
            by_id[item_id].position = position
        await self.session.commit()
        return await self.playlists.refresh(playlist)

    # --- internals ----------------------------------------------------------

    async def _owned(self, playlist_id: int, user: User) -> Playlist:
        """Write access. Public doesn't mean editable by whoever can see it."""
        playlist = await self._find(playlist_id)
        if playlist.owner_id != user.id and not user.is_admin:
            raise NotFound(f"no playlist {playlist_id}")
        return playlist

    async def _readable(self, playlist_id: int, user: User) -> Playlist:
        playlist = await self._find(playlist_id)
        if playlist.is_public or playlist.owner_id == user.id or user.is_admin:
            return playlist
        raise NotFound(f"no playlist {playlist_id}")

    async def _find(self, playlist_id: int) -> Playlist:
        playlist = await self.playlists.get(playlist_id)
        if playlist is None:
            raise NotFound(f"no playlist {playlist_id}")
        return playlist

    async def _announce(
        self, playlist: Playlist, user: User, event: str, **extra: object
    ) -> None:
        """Same transaction as the change itself, so the two can't disagree."""
        await self.recorder.record(
            user.id,
            event,
            subject_type="playlist",
            subject_id=playlist.id,
            payload={"name": playlist.name, **extra},
        )


def _renumber(playlist: Playlist) -> None:
    """Keep positions dense — the display walks them by index."""
    for position, item in enumerate(playlist.items):
        item.position = position
