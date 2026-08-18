"""Browsing: shows, episodes, and the front page.

All of it open, and all of it asking `viewer` rather than `user` — a catalogue
that gets crawled shouldn't leave a guest row behind per request. That's the
same split the HTTP routes make, for the same reason.
"""

from collections.abc import AsyncIterator, Sequence
from typing import Any

import grpc
from contracts import catalogue_pb2 as pb
from contracts import catalogue_pb2_grpc as stubs

from api.errors import Forbidden
from api.modules.accounts.models import User
from api.modules.catalogue.schemas import (
    EpisodeOut,
    EpisodeWithShow,
    ShowDetails,
    ShowOut,
    ShowSummary,
)
from api.modules.curation.service import ResolvedSection
from api.modules.playlists.schemas import playlist_out
from api.rpc import convert
from api.rpc.calls import call

# What a listing hands out when the caller says nothing, and the most it will
# hand out however loudly they ask. The same two numbers the query parameters
# have on the HTTP side.
DEFAULT_LIMIT = 50
MAX_LIMIT = 200
# One page of the walk behind `StreamShows`. Larger than a screenful because
# nobody reading that stream is looking at these one at a time.
CHUNK = 200


def _limit(asked: int, *, default: int = DEFAULT_LIMIT, most: int = MAX_LIMIT) -> int:
    """Zero means "didn't say", which is not the same as "none, please"."""
    return min(asked or default, most)


def _summary(row: tuple[Any, int, int]) -> pb.ShowSummary:
    show, episodes, playable = row
    return convert.show_summary(
        ShowSummary(
            **ShowOut.model_validate(show).model_dump(),
            episode_count=episodes,
            playable_count=playable,
        )
    )


def _section(resolved: ResolvedSection, user: User | None) -> pb.HomeSection:
    section = resolved.section
    message = pb.HomeSection(
        id=section.id,
        kind=convert.SECTION_KINDS[section.kind],
        title=section.title,
        items=[
            convert.episode_with_show(EpisodeWithShow.model_validate(episode))
            for episode in resolved.episodes
        ],
    )
    if section.kicker is not None:
        message.kicker = section.kicker
    if section.link is not None:
        message.link = section.link
    if section.show is not None:
        message.show.CopyFrom(convert.show(ShowOut.model_validate(section.show)))
    if section.playlist is not None:
        message.playlist.CopyFrom(convert.playlist(playlist_out(section.playlist, user)))
    for placement, url in resolved.artwork.items():
        message.artwork[placement.value] = url
    return message


class CatalogueService(stubs.CatalogueServicer):
    async def Health(
        self, request: pb.HealthRequest, context: grpc.aio.ServicerContext
    ) -> pb.HealthResponse:
        async with call(context) as rpc:
            shows, episodes = await rpc.services.catalogue.counts()
        return pb.HealthResponse(status="ok", shows=shows, episodes=episodes)

    async def ListShows(
        self, request: pb.ListShowsRequest, context: grpc.aio.ServicerContext
    ) -> pb.ListShowsResponse:
        limit, offset = _limit(request.limit), request.offset
        async with call(context) as rpc:
            rows, total = await rpc.services.catalogue.show_page(
                title_like=request.q if request.HasField("q") else None,
                series=request.series if request.HasField("series") else None,
                order=convert.SHOW_ORDERS[request.order],
                limit=limit,
                offset=offset,
            )
            items = [_summary(row) for row in rows]
        return pb.ListShowsResponse(page=convert.page(total, limit, offset), items=items)

    async def StreamShows(
        self, request: pb.StreamShowsRequest, context: grpc.aio.ServicerContext
    ) -> AsyncIterator[pb.ShowSummary]:
        """The catalogue, a page at a time on our side and a row at a time on
        theirs.

        This is the one method that holds its session for longer than a query:
        a walk taken over one session sees one catalogue, where a session per
        chunk would let rows shift underneath the reader between pages.
        """
        wanted = request.limit
        sent = 0

        async with call(context) as rpc:
            offset = 0
            while True:
                rows, total = await rpc.services.catalogue.show_page(
                    title_like=request.q if request.HasField("q") else None,
                    series=request.series if request.HasField("series") else None,
                    order=convert.SHOW_ORDERS[request.order],
                    limit=CHUNK,
                    offset=offset,
                )
                if not rows:
                    return

                for row in rows:
                    yield _summary(row)
                    sent += 1
                    if wanted and sent >= wanted:
                        return

                offset += len(rows)
                if offset >= total:
                    return

    async def GetShow(
        self, request: pb.GetShowRequest, context: grpc.aio.ServicerContext
    ) -> pb.ShowWithEpisodes:
        async with call(context) as rpc:
            show = await rpc.services.catalogue.show(request.key)
            details = convert.show_details(ShowDetails.model_validate(show))
            episodes = _episodes(show.episodes)
        return pb.ShowWithEpisodes(show=details, episodes=episodes)

    async def ListEpisodes(
        self, request: pb.ListEpisodesRequest, context: grpc.aio.ServicerContext
    ) -> pb.ListEpisodesResponse:
        limit, offset = _limit(request.limit), request.offset
        async with call(context) as rpc:
            episodes, total = await rpc.services.catalogue.episode_page(
                show=request.show if request.HasField("show") else None,
                season=request.season if request.HasField("season") else None,
                title_like=request.q if request.HasField("q") else None,
                playable=request.playable if request.HasField("playable") else None,
                limit=limit,
                offset=offset,
            )
            items = [
                convert.episode_with_show(EpisodeWithShow.model_validate(episode))
                for episode in episodes
            ]
        return pb.ListEpisodesResponse(page=convert.page(total, limit, offset), items=items)

    async def GetEpisode(
        self, request: pb.GetEpisodeRequest, context: grpc.aio.ServicerContext
    ) -> pb.EpisodeWithShow:
        async with call(context) as rpc:
            episode = await rpc.services.catalogue.episode(request.id)
            return convert.episode_with_show(EpisodeWithShow.model_validate(episode))

    async def GetHome(
        self, request: pb.GetHomeRequest, context: grpc.aio.ServicerContext
    ) -> pb.Home:
        async with call(context) as rpc:
            # `viewer`, even for the preview: asking to see unpublished rows is
            # not a reason to hand somebody an account.
            user = await rpc.viewer()
            if request.preview and (user is None or not user.is_admin):
                raise Forbidden("preview is for admins")

            sections = await rpc.services.curation.home(preview=request.preview)
            return pb.Home(sections=[_section(section, user) for section in sections])


def _episodes(rows: Sequence[Any]) -> list[pb.Episode]:
    return [convert.episode(EpisodeOut.model_validate(row)) for row in rows]
