"""Every service, wired, with no request in sight.

Each module's `deps.py` does this for FastAPI: one dependency per service, all of
them sharing the session that request opened. None of that wiring is HTTP's
business, though — a CLI, a scheduled job or a test needs the same graph — so
here it is once more, over a session the caller owns:

    async with services() as api:
        await api.curation.create_section(kind=SectionKind.rail, title="Best of 2026")

Presentation layers sit above this and nowhere else. `api.main` drives it over
HTTP and `api.cli` from a terminal; neither knows anything the other doesn't,
because the decisions are all one layer down.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from dataclasses import dataclass

from sqlalchemy.ext.asyncio import AsyncSession

from api.core.database import Session
from api.modules.accounts.service import AccountService
from api.modules.activity.service import ActivityService
from api.modules.catalogue.service import CatalogueService
from api.modules.curation.service import CurationService
from api.modules.media.service import MediaService
from api.modules.playlists.service import PlaylistService


@dataclass(frozen=True, slots=True)
class Services:
    """One session's worth of services, already pointed at each other."""

    session: AsyncSession
    accounts: AccountService
    activity: ActivityService
    catalogue: CatalogueService
    media: MediaService
    playlists: PlaylistService
    curation: CurationService


def build(session: AsyncSession) -> Services:
    """The graph, over a session somebody else opened and will close.

    The order below is the dependency order, and it's the same one `deps.py`
    arrives at by composing its dependencies — if the two ever disagree, this
    file is the one that's wrong.
    """
    activity = ActivityService(session)
    catalogue = CatalogueService(session)
    media = MediaService(session)
    playlists = PlaylistService(session, activity)

    return Services(
        session=session,
        accounts=AccountService(session),
        activity=activity,
        catalogue=catalogue,
        media=media,
        playlists=playlists,
        curation=CurationService(session, catalogue, playlists, media),
    )


@asynccontextmanager
async def services() -> AsyncIterator[Services]:
    """The same graph over a session of its own — what a script wants.

    The session is closed on the way out; the engine is not, because a process
    that does two of these shouldn't pay for two pools. Dispose of it yourself
    when the process is done — `api.cli` does.
    """
    async with Session() as session:
        yield build(session)
