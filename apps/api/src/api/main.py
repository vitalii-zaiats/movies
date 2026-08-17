"""The app: middleware, routers, and one place where a refusal becomes a status.

Everything else is in `modules/`. A new feature is a new folder and a line in
`modules/__init__.py` — this file shouldn't have to grow for it.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from api.clients.vod import VodClient
from api.core.database import engine
from api.errors import CatalogueError, Conflict, Forbidden, Invalid, NotFound, Unauthorized
from api.modules import ROUTERS
from api.modules.accounts.transport import TOKEN_HEADER, SessionMiddleware
from api.modules.catalogue.deps import Catalogue
from api.settings import settings

STATUS = {
    NotFound: 404,
    Conflict: 409,
    Invalid: 400,
    Unauthorized: 401,
    Forbidden: 403,
}


class HealthOut(BaseModel):
    status: str
    shows: int
    episodes: int


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    # Read-only: the API looks VODs up, it never registers them.
    app.state.vod = VodClient()
    yield
    await app.state.vod.aclose()
    await engine.dispose()


def create_app() -> FastAPI:
    app = FastAPI(title="catalogue api", version="0.2.0", lifespan=lifespan)

    # Cookies and the wildcard don't mix, and pretending otherwise is how an
    # API ends up letting any page on the internet make requests as whoever is
    # reading it. So the two cases are kept honestly apart:
    #
    #   `*` (default)     open to anyone, no credentials. A cross-origin caller
    #                     authenticates with a bearer token, which it can only
    #                     have if someone gave it one.
    #   a named list      credentials allowed, so the session cookie works from
    #                     those origins and nowhere else.
    #
    # In the deployed stack neither matters much: nginx puts the app and /api on
    # one origin, and same-origin requests never ask CORS for permission.
    named = settings.cors_origins != ["*"]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=named,
        allow_methods=["*"],
        allow_headers=["*"],
        expose_headers=[TOKEN_HEADER],
    )
    # Outermost of the two, so the token it attaches survives an error response.
    app.add_middleware(SessionMiddleware)

    for router in ROUTERS:
        app.include_router(router)

    @app.exception_handler(CatalogueError)
    async def domain_error(request: Request, exc: CatalogueError) -> JSONResponse:
        """One place where a refusal becomes a status code."""
        return JSONResponse(
            {"detail": str(exc)}, status_code=STATUS.get(type(exc), 400)
        )

    @app.get("/health", tags=["ops"])
    async def health(catalogue: Catalogue) -> HealthOut:
        shows, episodes = await catalogue.counts()
        return HealthOut(status="ok", shows=shows, episodes=episodes)

    return app


app = create_app()
