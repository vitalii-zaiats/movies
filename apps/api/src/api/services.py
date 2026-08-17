"""What the API does, said without HTTP and without SQL.

Routes translate requests; repositories translate storage; this is the layer in
between that actually decides things. Nothing here imports FastAPI, so any of it
can be called from a script or a test.
"""

from collections.abc import Sequence
from dataclasses import dataclass

from sqlalchemy.ext.asyncio import AsyncSession

from api.errors import Conflict, Invalid, NotFound
from api.models import Episode, Playlist, PlaylistItem, Show
from api.repositories import EpisodeRepository, PlaylistRepository, ShowRepository
from api.schemas import IngestEpisode, IngestReport


@dataclass(slots=True)
class CatalogueService:
    session: AsyncSession

    @property
    def shows(self) -> ShowRepository:
        return ShowRepository(self.session)

    @property
    def episodes(self) -> EpisodeRepository:
        return EpisodeRepository(self.session)

    async def counts(self) -> tuple[int, int]:
        return await self.shows.count(), await self.episodes.count()

    async def all_shows(self) -> list[Show]:
        return await self.shows.all()

    async def show(self, key: str) -> Show:
        show = await self.shows.by_key(key)
        if show is None:
            raise NotFound(f"no show {key!r}")
        return show

    async def episode_page(
        self,
        *,
        show: str | None,
        season: int | None,
        title_like: str | None,
        playable: bool | None,
        limit: int,
        offset: int,
    ) -> tuple[list[Episode], int]:
        return await self.episodes.page(
            show=show,
            season=season,
            title_like=title_like,
            playable=playable,
            limit=limit,
            offset=offset,
        )

    async def episode(self, episode_id: int) -> Episode:
        episode = await self.episodes.get(episode_id)
        if episode is None:
            raise NotFound(f"no episode {episode_id}")
        return episode

    async def ingest(self, items: Sequence[IngestEpisode]) -> IngestReport:
        """Take a batch of episodes from whoever crawled them.

        The API stores a VOD *id* it was told about; it never creates one. That
        direction is deliberate — registering a playlist is the crawler's job,
        and this service only ever reads the VOD service.
        """
        report = IngestReport(shows=0, created=0, updated=0)
        known: dict[str, Show] = {}

        for item in items:
            show = known.get(item.show_key)
            if show is None:
                show = await self.shows.by_key(item.show_key)
                if show is None:
                    show = await self.shows.add(
                        item.show_key, item.show_title or _pretty(item.show_key)
                    )
                    report.shows += 1
                known[item.show_key] = show

            episode = await self.episodes.by_source_url(item.source_url)
            if episode is None:
                episode = await self.episodes.add(show.id, item.source_url)
                report.created += 1
            else:
                report.updated += 1

            episode.season = item.season
            episode.episode = item.episode
            episode.episode_end = item.episode_end
            episode.title = item.title
            episode.poster = item.poster
            episode.vod_id = item.vod_id

        await self.session.commit()
        return report


@dataclass(slots=True)
class PlaylistService:
    session: AsyncSession

    @property
    def playlists(self) -> PlaylistRepository:
        return PlaylistRepository(self.session)

    @property
    def episodes(self) -> EpisodeRepository:
        return EpisodeRepository(self.session)

    async def all(self) -> list[Playlist]:
        return await self.playlists.all()

    async def get(self, playlist_id: int) -> Playlist:
        playlist = await self.playlists.get(playlist_id)
        if playlist is None:
            raise NotFound(f"no playlist {playlist_id}")
        return playlist

    async def create(self, name: str) -> Playlist:
        playlist = await self.playlists.add(name.strip() or "untitled")
        await self.session.commit()
        return await self.playlists.refresh(playlist)

    async def from_show(
        self,
        *,
        show_key: str,
        season: int | None = None,
        name: str | None = None,
        playable_only: bool = True,
    ) -> Playlist:
        """A queue out of a whole show, or one season, already in order."""
        show = await ShowRepository(self.session).by_key(show_key)
        if show is None:
            raise NotFound(f"no show {show_key!r}")

        episodes = await self.episodes.for_show(
            show.id, season=season, playable_only=playable_only
        )
        if not episodes:
            raise NotFound(f"no playable episodes for {show_key!r}")

        default = show_key if season is None else f"{show_key} S{season:02d}"
        playlist = await self.playlists.add(
            (name or default).strip(),
            [
                PlaylistItem(episode_id=episode.id, position=index)
                for index, episode in enumerate(episodes)
            ],
        )
        await self.session.commit()
        return await self.playlists.refresh(playlist)

    async def delete(self, playlist_id: int) -> None:
        await self.playlists.delete(await self.get(playlist_id))
        await self.session.commit()

    async def add_item(self, playlist_id: int, episode_id: int) -> Playlist:
        playlist = await self.get(playlist_id)

        episode = await self.episodes.get(episode_id)
        if episode is None:
            raise NotFound(f"no episode {episode_id}")
        if any(item.episode_id == episode.id for item in playlist.items):
            raise Conflict("already in this playlist")

        playlist.items.append(PlaylistItem(episode_id=episode.id, position=len(playlist.items)))
        await self.session.commit()
        return await self.playlists.refresh(playlist)

    async def remove_item(self, playlist_id: int, item_id: int) -> Playlist:
        playlist = await self.get(playlist_id)

        item = next((i for i in playlist.items if i.id == item_id), None)
        if item is None:
            raise NotFound(f"no item {item_id} in this playlist")

        playlist.items.remove(item)
        _renumber(playlist)
        await self.session.commit()
        return await self.playlists.refresh(playlist)

    async def reorder(self, playlist_id: int, item_ids: Sequence[int]) -> Playlist:
        playlist = await self.get(playlist_id)

        by_id = {item.id: item for item in playlist.items}
        if set(item_ids) != set(by_id):
            raise Invalid("item_ids must list every item exactly once")

        for position, item_id in enumerate(item_ids):
            by_id[item_id].position = position
        await self.session.commit()
        return await self.playlists.refresh(playlist)


def _renumber(playlist: Playlist) -> None:
    """Keep positions dense — the display walks them by index."""
    for position, item in enumerate(playlist.items):
        item.position = position


def _pretty(key: str) -> str:
    return key.replace("-", " ").title()
