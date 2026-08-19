"""Every table in the API, in one import.

Alembic diffs `Base.metadata` against the database, and a model class that
nobody imported isn't in it — which autogenerate reports as "drop this table"
rather than as a mistake. So a new module means a new line here, and that's the
only thing this file is for.
"""

from api.core.models import Base
from api.modules.accounts.models import AuthSession, DeviceLink, User
from api.modules.activity.models import ActivityEvent, WatchProgress
from api.modules.catalogue.models import Episode, Show
from api.modules.curation.models import Artwork, Section
from api.modules.media.models import MediaFile
from api.modules.playlists.models import Playlist, PlaylistItem

__all__ = [
    "ActivityEvent",
    "Artwork",
    "AuthSession",
    "Base",
    "DeviceLink",
    "Episode",
    "MediaFile",
    "Playlist",
    "PlaylistItem",
    "Section",
    "Show",
    "User",
    "WatchProgress",
]
