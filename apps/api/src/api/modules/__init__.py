"""One folder per feature: its tables, its queries, its rules, its routes.

Adding a feature means adding a folder and one line in `ROUTERS` — never
touching four shared files that everything else also imports. That's the whole
reason the API was flipped from horizontal layers to vertical ones.

The order below is the dependency order, and it's a straight line:

    accounts   knows nobody
    catalogue  knows nobody
    media      knows accounts (who uploaded this)
    playlists  knows catalogue; needs *an* activity recorder, not this one
    activity   knows catalogue
    curation   knows catalogue, playlists and media — all through their services

The rule that keeps it a line rather than a web: a module's **service** is its
public face, its repository is private, and cross-module wiring happens in
`deps.py` and nowhere else.
"""

from fastapi import APIRouter

from api.modules.accounts.router import router as accounts_router
from api.modules.activity.router import router as activity_router
from api.modules.catalogue.router import router as catalogue_router
from api.modules.curation.router import router as curation_router
from api.modules.media.router import router as media_router
from api.modules.playlists.router import router as playlists_router

ROUTERS: tuple[APIRouter, ...] = (
    accounts_router,
    catalogue_router,
    playlists_router,
    activity_router,
    media_router,
    curation_router,
)

__all__ = ["ROUTERS"]
