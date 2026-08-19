"""Catalogue routes: query string in, DTO out.

No decisions here. They live in `service.py`, and the queries in
`repository.py`.
"""

from typing import Annotated

from fastapi import APIRouter, Query

from api.clients.vod import VodClient
from api.modules.catalogue.deps import Catalogue, MayIngest
from api.modules.catalogue.models import Episode, Show
from api.modules.catalogue.schemas import (
    EpisodePage,
    EpisodeWithShow,
    IngestReport,
    IngestRequest,
    IngestShowRequest,
    ShowReport,
    SyncReport,
    ShowOut,
    ShowPage,
    ShowSummary,
    ShowWithEpisodes,
)

router = APIRouter(tags=["catalogue"])


@router.get("/shows", response_model=ShowPage)
async def list_shows(
    catalogue: Catalogue,
    q: Annotated[str | None, Query(description="substring of the title")] = None,
    series: Annotated[bool | None, Query(description="true: several episodes; false: a film")] = None,
    kind: Annotated[
        str | None, Query(description="what the source called it: film, series, cartoon, anime")
    ] = None,
    order: Annotated[str, Query(pattern="^(key|added|title|newest|oldest)$")] = "key",
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> ShowPage:
    rows, total = await catalogue.show_page(
        title_like=q, series=series, kind=kind, order=order, limit=limit, offset=offset
    )
    return ShowPage(
        total=total,
        limit=limit,
        offset=offset,
        items=[
            ShowSummary(
                **ShowOut.model_validate(show).model_dump(),
                episode_count=episodes,
                playable_count=playable,
                year=show.year,
                imdb_rating=show.imdb_rating,
                genres=show.genres,
            )
            for show, episodes, playable in rows
        ],
    )


@router.get("/shows/{key}", response_model=ShowWithEpisodes)
async def read_show(key: str, catalogue: Catalogue) -> Show:
    return await catalogue.show(key)


@router.get("/episodes", response_model=EpisodePage)
async def list_episodes(
    catalogue: Catalogue,
    show: str | None = None,
    season: int | None = None,
    q: Annotated[str | None, Query(description="substring of the title")] = None,
    playable: Annotated[bool | None, Query(description="only ones with a VOD")] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> EpisodePage:
    episodes, total = await catalogue.episode_page(
        show=show, season=season, title_like=q, playable=playable, limit=limit, offset=offset
    )
    return EpisodePage(
        total=total,
        limit=limit,
        offset=offset,
        items=[EpisodeWithShow.model_validate(episode) for episode in episodes],
    )


@router.get("/episodes/{episode_id}", response_model=EpisodeWithShow)
async def read_episode(episode_id: int, catalogue: Catalogue) -> Episode:
    return await catalogue.episode(episode_id)


@router.post(
    "/ingest/episodes", response_model=IngestReport, status_code=201, dependencies=[MayIngest]
)
async def ingest(body: IngestRequest, catalogue: Catalogue) -> IngestReport:
    """Where crawled episodes come in.

    The sender registers playlists with the VOD service and passes the ids here.
    The API stores them and reads that service; it never writes to it.
    """
    return await catalogue.ingest(body.items)


@router.post(
    "/ingest/shows", response_model=ShowReport, status_code=201, dependencies=[MayIngest]
)
async def describe(body: IngestShowRequest, catalogue: Catalogue) -> ShowReport:
    """What the crawl knew about the titles themselves — year, genres, IMDb.

    Separate from the episodes on purpose: an episode is a thing to play and
    this is a thing to read, they arrive from different passes of the crawl, and
    neither should have to wait for the other.
    """
    return await catalogue.describe(body.items)


@router.post("/sync/vods", response_model=SyncReport, dependencies=[MayIngest])
async def sync_vods(
    catalogue: Catalogue,
    since: Annotated[
        int | None, Query(description="rewind: read the list again from this id")
    ] = None,
) -> SyncReport:
    """Read the VOD service from where we left off.

    Nobody pushes episodes here: the VOD service owns playable things, and this
    walks its list and files what it finds. Anyone may ask for the walk — the
    seeder does, the moment it finishes registering — and asking twice is
    harmless, because the cursor is where the work is remembered.
    """
    async with VodClient() as vods:
        return await catalogue.sync_vods(vods, since=since)
