"""Wiring for playlists — and the one file that has met both modules.

`PlaylistService` asks for an `ActivityRecorder`; `ActivityService` happens to
be one. Neither of them knows that, which is the point: the composition root is
where cross-module knowledge is allowed to live, and it's four lines long.
"""

from typing import Annotated

from fastapi import Depends

from api.core.deps import DB
from api.modules.activity.service import ActivityService
from api.modules.playlists.service import PlaylistService


def playlist_service(session: DB) -> PlaylistService:
    return PlaylistService(session, ActivityService(session))


Playlists = Annotated[PlaylistService, Depends(playlist_service)]
