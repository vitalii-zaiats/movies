"""Progress and history — the calls that only make sense for one person.

All of them take `user`, so a client with no token gets a guest and the token
back with the answer. Watching starts before signing up; that's the design, and
it's the same one `/me` follows over HTTP.
"""

import grpc
from contracts import catalogue_pb2 as pb
from contracts import catalogue_pb2_grpc as stubs

from api.modules.activity.schemas import HistoryEntry, ProgressOut
from api.rpc import convert
from api.rpc.calls import call

DEFAULT_LIMIT = 50
MAX_LIMIT = 200
CONTINUE_LIMIT = 20
CONTINUE_MAX = 50


class WatchingService(stubs.WatchingServicer):
    async def ReportProgress(
        self, request: pb.ReportProgressRequest, context: grpc.aio.ServicerContext
    ) -> pb.Progress:
        async with call(context) as rpc:
            user = await rpc.user()
            row = await rpc.services.activity.report(
                user.id,
                request.episode_id,
                position_seconds=request.position_seconds,
                duration_seconds=(
                    request.duration_seconds if request.HasField("duration_seconds") else None
                ),
                completed=request.completed if request.HasField("completed") else None,
            )
            return convert.progress(ProgressOut.model_validate(row))

    async def GetProgress(
        self, request: pb.GetProgressRequest, context: grpc.aio.ServicerContext
    ) -> pb.Progress:
        """NOT_FOUND is the answer "start at zero" — the service raises it."""
        async with call(context) as rpc:
            user = await rpc.user()
            row = await rpc.services.activity.resume(user.id, request.episode_id)
            return convert.progress(ProgressOut.model_validate(row))

    async def ForgetProgress(
        self, request: pb.ForgetProgressRequest, context: grpc.aio.ServicerContext
    ) -> pb.ForgetProgressResponse:
        async with call(context) as rpc:
            user = await rpc.user()
            await rpc.services.activity.forget(user.id, request.episode_id)
        return pb.ForgetProgressResponse()

    async def ListHistory(
        self, request: pb.ListHistoryRequest, context: grpc.aio.ServicerContext
    ) -> pb.ListHistoryResponse:
        limit = min(request.limit or DEFAULT_LIMIT, MAX_LIMIT)
        offset = request.offset
        async with call(context) as rpc:
            user = await rpc.user()
            rows, total = await rpc.services.activity.history(
                user.id,
                limit=limit,
                offset=offset,
                completed=request.completed if request.HasField("completed") else None,
            )
            items = [
                convert.history_entry(HistoryEntry.model_validate(row)) for row in rows
            ]
        return pb.ListHistoryResponse(page=convert.page(total, limit, offset), items=items)

    async def ContinueWatching(
        self, request: pb.ContinueWatchingRequest, context: grpc.aio.ServicerContext
    ) -> pb.ContinueWatchingResponse:
        limit = min(request.limit or CONTINUE_LIMIT, CONTINUE_MAX)
        async with call(context) as rpc:
            user = await rpc.user()
            rows = await rpc.services.activity.continue_watching(user.id, limit=limit)
            items = [
                convert.history_entry(HistoryEntry.model_validate(row)) for row in rows
            ]
        return pb.ContinueWatchingResponse(items=items)
