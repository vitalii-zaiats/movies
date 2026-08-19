"""Every SQL query about shows and episodes.

Routes don't build queries and services don't either — they ask a repository.
The point isn't ceremony: it's that "how do we find an episode" has exactly one
answer, and it's greppable.
"""

from sqlalchemy import func, select

from api.core.repository import Repository
from api.modules.catalogue.models import Episode, Show


class ShowRepository(Repository[Show]):
    model = Show

    async def all(self) -> list[Show]:
        rows = await self.session.scalars(select(Show).order_by(Show.key))
        return list(rows)

    async def by_key(self, key: str) -> Show | None:
        return await self.session.scalar(select(Show).where(Show.key == key))

    async def create(self, key: str, title: str, poster: str | None = None) -> Show:
        return await self.add(Show(key=key, title=title, poster=poster))

    async def page(
        self,
        *,
        title_like: str | None = None,
        series: bool | None = None,
        kind: str | None = None,
        order: str = "key",
        limit: int = 50,
        offset: int = 0,
    ) -> tuple[list[tuple[Show, int, int]], int]:
        """Shows with their episode counts, plus the total that matched.

        The counts come from one grouped subquery rather than a query per show —
        that difference is the whole reason this method exists.

        `series` and `kind` ask different questions and both are worth having.
        `series` is a *shape*: more than one episode is a series, exactly one is
        a film, and that is true however the row got here. `kind` is what the
        source called it — film, series, cartoon, anime — which is the only way
        to tell a cartoon from a film, because their shapes are identical.
        """
        counts = (
            select(
                Episode.show_id.label("show_id"),
                func.count().label("episodes"),
                func.count(Episode.vod_id).label("playable"),
            )
            .group_by(Episode.show_id)
            .subquery()
        )
        episodes = func.coalesce(counts.c.episodes, 0)
        playable = func.coalesce(counts.c.playable, 0)

        query = select(Show, episodes, playable).outerjoin(counts, counts.c.show_id == Show.id)

        if title_like:
            query = query.where(Show.title.ilike(f"%{title_like}%"))
        if series is not None:
            query = query.where(episodes > 1 if series else episodes == 1)
        if kind:
            query = query.where(Show.kind == kind)

        total = await self.session.scalar(select(func.count()).select_from(query.subquery()))
        rows = await self.session.execute(query.order_by(*_show_order(order)).limit(limit).offset(offset))
        return [(show, int(count), int(plays)) for show, count, plays in rows], total or 0


def _show_order(order: str):
    """How a browse list is sorted. Unknown names fall back to the stable one.

    `newest` and `oldest` are by release year, not by when we happened to sync
    it. That distinction matters: a bulk rebuild stamps every row with the same
    second, so `added` describes the order of one import and nothing else, while
    the year stays true however the catalogue was filled.
    """
    if order == "newest":
        # Nulls last either way: a title with no year is not the newest thing
        # here, and it isn't the oldest either.
        return Show.year.desc().nullslast(), Show.id.desc()
    if order == "oldest":
        return Show.year.asc().nullslast(), Show.id.asc()
    if order == "added":
        # Newest first, with the id as the tiebreak: a seed run stamps a whole
        # batch with the same second, and a page boundary must not wobble.
        return Show.created_at.desc(), Show.id.desc()
    if order == "title":
        return (Show.title,)
    return (Show.key,)


class EpisodeRepository(Repository[Episode]):
    model = Episode

    async def by_source_url(self, source_url: str) -> Episode | None:
        return await self.session.scalar(
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

        total = await self.session.scalar(select(func.count()).select_from(query.subquery()))
        rows = await self.session.scalars(
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

        rows = await self.session.scalars(query.order_by(Episode.season, Episode.episode))
        return list(rows.unique())
