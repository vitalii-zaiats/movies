"""Every SQL query in the API lives here.

Routes don't build queries and services don't either — they ask a repository.
The point isn't ceremony: it's that "how do we find an episode" has exactly one
answer, and it's greppable.
"""

from collections.abc import Sequence

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from api.models import Episode, Playlist, PlaylistItem, Show


class ShowRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def all(self) -> list[Show]:
        rows = await self._session.scalars(select(Show).order_by(Show.key))
        return list(rows)

    async def by_key(self, key: str) -> Show | None:
        return await self._session.scalar(select(Show).where(Show.key == key))

    async def add(self, key: str, title: str) -> Show:
        show = Show(key=key, title=title)
        self._session.add(show)
        await self._session.flush()
        return show

    async def count(self) -> int:
        return await self._session.scalar(select(func.count()).select_from(Show)) or 0


class EpisodeRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, episode_id: int) -> Episode | None:
        return await self._session.get(Episode, episode_id)

    async def by_source_url(self, source_url: str) -> Episode | None:
        return await self._session.scalar(
            select(Episode).where(Episode.source_url == source_url)
        )

    async def page(
        self,
        *,
        show: str | None = None,
        season: int | None = None,
        title_like: str | None = None,
        playable: bool | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[Episode], int]:
        """Filtered episodes plus the total that matched, before paging."""
        query = select(Episode).join(Show)

        if show:
            query = query.where(Show.key == show)
        if season is not None:
            query = query.where(Episode.season == season)
        if title_like:
            query = query.where(Episode.title.ilike(f"%{title_like}%"))
        if playable is not None:
            query = query.where(
                Episode.vod_id.is_not(None) if playable else Episode.vod_id.is_(None)
            )

        total = await self._session.scalar(select(func.count()).select_from(query.subquery()))
        rows = await self._session.scalars(
            query.order_by(Show.key, Episode.season, Episode.episode).limit(limit).offset(offset)
        )
        return list(rows.unique()), total or 0

    async def for_show(
        self, show_id: int, *, season: int | None = None, playable_only: bool = True
    ) -> list[Episode]:
        query = select(Episode).where(Episode.show_id == show_id)
        if season is not None:
            query = query.where(Episode.season == season)
        if playable_only:
            query = query.where(Episode.vod_id.is_not(None))

        rows = await self._session.scalars(query.order_by(Episode.season, Episode.episode))
        return list(rows.unique())

    async def add(self, show_id: int, source_url: str) -> Episode:
        episode = Episode(show_id=show_id, source_url=source_url)
        self._session.add(episode)
        await self._session.flush()
        return episode

    async def count(self) -> int:
        return await self._session.scalar(select(func.count()).select_from(Episode)) or 0


class PlaylistRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def all(self) -> list[Playlist]:
        rows = await self._session.scalars(select(Playlist).order_by(Playlist.id))
        return list(rows)

    async def get(self, playlist_id: int) -> Playlist | None:
        return await self._session.get(Playlist, playlist_id)

    async def add(self, name: str, items: Sequence[PlaylistItem] = ()) -> Playlist:
        playlist = Playlist(name=name)
        playlist.items = list(items)
        self._session.add(playlist)
        await self._session.flush()
        return playlist

    async def delete(self, playlist: Playlist) -> None:
        await self._session.delete(playlist)

    async def refresh(self, playlist: Playlist) -> Playlist:
        await self._session.refresh(playlist)
        return playlist
