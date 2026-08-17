"""The catalogue API.

Routes only translate: query string in, DTO out. Decisions live in `services`,
queries in `repositories`.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from api import playlists
from api.db import engine
from api.deps import Catalogue
from api.errors import CatalogueError, Conflict, Invalid, NotFound
from api.schemas import (
    EpisodePage,
    EpisodeWithShow,
    HealthOut,
    IngestReport,
    IngestRequest,
    ShowOut,
    ShowWithEpisodes,
)
from api.vod_client import VodClient

STATUS = {NotFound: 404, Conflict: 409, Invalid: 400}


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # Read-only: the API looks VODs up, it never registers them.
    app.state.vod = VodClient()
    yield
    await app.state.vod.aclose()
    await engine.dispose()


app = FastAPI(title="catalogue api", version="0.1.0", lifespan=lifespan)

# The dashboard and the remote are served from another port (and, on a phone,
# another host). Open CORS is fine for a LAN tool; put auth in front before this
# ever faces anything wider.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(playlists.router)


@app.exception_handler(CatalogueError)
async def domain_error(request: Request, exc: CatalogueError) -> JSONResponse:
    """One place where a refusal becomes a status code."""
    return JSONResponse({"detail": str(exc)}, status_code=STATUS.get(type(exc), 400))


@app.get("/health")
async def health(catalogue: Catalogue) -> HealthOut:
    shows, episodes = await catalogue.counts()
    return HealthOut(status="ok", shows=shows, episodes=episodes)


@app.get("/shows", response_model=list[ShowOut])
async def list_shows(catalogue: Catalogue):
    return await catalogue.all_shows()


@app.get("/shows/{key}", response_model=ShowWithEpisodes)
async def read_show(key: str, catalogue: Catalogue):
    return await catalogue.show(key)


@app.get("/episodes", response_model=EpisodePage)
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


@app.get("/episodes/{episode_id}", response_model=EpisodeWithShow)
async def read_episode(episode_id: int, catalogue: Catalogue):
    return await catalogue.episode(episode_id)


@app.post("/ingest/episodes", response_model=IngestReport, status_code=201)
async def ingest(body: IngestRequest, catalogue: Catalogue) -> IngestReport:
    """Where crawled episodes come in.

    The sender registers playlists with the VOD service and passes the ids here.
    The API stores them and reads that service; it never writes to it.
    """
    return await catalogue.ingest(body.items)
