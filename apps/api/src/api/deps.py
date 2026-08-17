"""Wiring: a request gets a session, a session gets services."""

from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.db import get_session
from api.services import CatalogueService, PlaylistService

DB = Annotated[AsyncSession, Depends(get_session)]


def catalogue_service(session: DB) -> CatalogueService:
    return CatalogueService(session)


def playlist_service(session: DB) -> PlaylistService:
    return PlaylistService(session)


Catalogue = Annotated[CatalogueService, Depends(catalogue_service)]
Playlists = Annotated[PlaylistService, Depends(playlist_service)]
