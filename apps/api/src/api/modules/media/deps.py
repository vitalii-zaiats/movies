"""Wiring for media."""

from typing import Annotated

from fastapi import Depends

from api.core.deps import DB
from api.modules.media.service import MediaService


def media_service(session: DB) -> MediaService:
    return MediaService(session)


Media = Annotated[MediaService, Depends(media_service)]
