"""Wiring for curation — the composition root for this module's neighbours.

`CurationService` names what it needs as constructor arguments and nothing
else. This file is the only place that knows which concrete services satisfy
them, and it reuses the neighbours' own dependency functions rather than
rebuilding them, so everything ends up on the one session FastAPI opened for
this request.
"""

from typing import Annotated

from fastapi import Depends

from api.core.deps import DB
from api.modules.catalogue.deps import Catalogue
from api.modules.curation.service import CurationService
from api.modules.media.deps import Media
from api.modules.playlists.deps import Playlists


def curation_service(
    session: DB, catalogue: Catalogue, playlists: Playlists, media: Media
) -> CurationService:
    return CurationService(session, catalogue, playlists, media)


Curation = Annotated[CurationService, Depends(curation_service)]
