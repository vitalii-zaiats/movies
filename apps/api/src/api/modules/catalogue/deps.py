"""Wiring for the catalogue, plus the one guard that's specific to it."""

from typing import Annotated

from fastapi import Depends, Header

from api.core.deps import DB
from api.errors import Forbidden
from api.modules.accounts.deps import Viewer
from api.modules.catalogue.service import CatalogueService
from api.settings import settings


def catalogue_service(session: DB) -> CatalogueService:
    return CatalogueService(session)


Catalogue = Annotated[CatalogueService, Depends(catalogue_service)]


async def may_ingest(
    user: Viewer,
    x_api_key: Annotated[str | None, Header()] = None,
) -> None:
    """Who's allowed to push episodes in.

    Open when `API_INGEST_TOKEN` is unset, because that's the LAN default the
    seeder runs against and quietly breaking `docker compose run seed` would be
    a rude way to introduce roles. Set the token and the door takes exactly two
    keys: that header, or an admin session.
    """
    if settings.ingest_token is None:
        return
    if x_api_key is not None and x_api_key == settings.ingest_token:
        return
    if user is not None and user.is_admin:
        return
    raise Forbidden("ingest needs the API key or an admin session")


MayIngest = Depends(may_ingest)
