"""The catalogue API."""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from api import playlists
from api.db import engine, get_session
from api.models import Episode, Show
from api.schemas import EpisodePage, EpisodeWithShow, HealthOut, ShowOut, ShowWithEpisodes
from api.vod_client import VodClient

DB = Annotated[AsyncSession, Depends(get_session)]


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
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


@app.get("/health")
async def health(session: DB) -> HealthOut:
    shows = await session.scalar(select(func.count()).select_from(Show))
    episodes = await session.scalar(select(func.count()).select_from(Episode))
    return HealthOut(status="ok", shows=shows or 0, episodes=episodes or 0)


@app.get("/shows", response_model=list[ShowOut])
async def list_shows(session: DB) -> list[Show]:
    result = await session.scalars(select(Show).order_by(Show.key))
    return list(result)


@app.get("/shows/{key}", response_model=ShowWithEpisodes)
async def read_show(key: str, session: DB) -> Show:
    show = await session.scalar(select(Show).where(Show.key == key))
    if show is None:
        raise HTTPException(status_code=404, detail=f"no show {key!r}")
    return show


@app.get("/episodes", response_model=EpisodePage)
async def list_episodes(
    session: DB,
    show: str | None = None,
    season: int | None = None,
    q: Annotated[str | None, Query(description="substring of the title")] = None,
    playable: Annotated[bool | None, Query(description="only ones with a VOD")] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> EpisodePage:
    query = select(Episode).join(Show)

    if show:
        query = query.where(Show.key == show)
    if season is not None:
        query = query.where(Episode.season == season)
    if q:
        query = query.where(Episode.title.ilike(f"%{q}%"))
    if playable is not None:
        query = query.where(Episode.vod_url.is_not(None) if playable else Episode.vod_url.is_(None))

    total = await session.scalar(select(func.count()).select_from(query.subquery())) or 0
    rows = await session.scalars(
        query.order_by(Show.key, Episode.season, Episode.episode).limit(limit).offset(offset)
    )
    return EpisodePage(
        total=total,
        limit=limit,
        offset=offset,
        items=[EpisodeWithShow.model_validate(row) for row in rows.unique()],
    )


@app.get("/episodes/{episode_id}", response_model=EpisodeWithShow)
async def read_episode(episode_id: int, session: DB) -> Episode:
    episode = await session.get(Episode, episode_id)
    if episode is None:
        raise HTTPException(status_code=404, detail=f"no episode {episode_id}")
    return episode
