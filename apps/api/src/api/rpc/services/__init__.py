"""The servicers, one per proto service.

One file per module, mirroring `api/modules/` — a servicer is that module's
router with a different envelope, and the two should be found in the same shape
of folder.
"""

from api.rpc.services.accounts import AccountsService
from api.rpc.services.catalogue import CatalogueService
from api.rpc.services.playlists import PlaylistsService
from api.rpc.services.watching import WatchingService

__all__ = ["AccountsService", "CatalogueService", "PlaylistsService", "WatchingService"]
