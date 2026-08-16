"""The gRPC face of the service — what apps/api talks to."""

import logging

import grpc
from contracts import vod_pb2, vod_pb2_grpc

from vod.store import Vod, VodStore

log = logging.getLogger(__name__)


class VodService(vod_pb2_grpc.VodServiceServicer):
    def __init__(self, store: VodStore, public_url: str) -> None:
        self._store = store
        self._public_url = public_url.rstrip("/")

    async def CreateVod(  # noqa: N802 — the name comes from the contract
        self, request: vod_pb2.CreateVodRequest, context: grpc.aio.ServicerContext
    ) -> vod_pb2.CreateVodResponse:
        playlist_url = request.playlist_url.strip()
        if not playlist_url:
            await context.abort(grpc.StatusCode.INVALID_ARGUMENT, "playlist_url is required")

        metadata = request.metadata
        vod, created = await self._store.create(
            playlist_url,
            title=metadata.title if metadata.HasField("title") else None,
            poster=metadata.poster if metadata.HasField("poster") else None,
        )
        return vod_pb2.CreateVodResponse(vod=self._message(vod), created=created)

    async def GetVod(  # noqa: N802
        self, request: vod_pb2.GetVodRequest, context: grpc.aio.ServicerContext
    ) -> vod_pb2.Vod:
        vod = await self._store.get(request.id)
        if vod is None:
            await context.abort(grpc.StatusCode.NOT_FOUND, f"no vod {request.id}")
        return self._message(vod)

    async def ListVods(  # noqa: N802
        self, request: vod_pb2.ListVodsRequest, context: grpc.aio.ServicerContext
    ) -> vod_pb2.ListVodsResponse:
        vods = await self._store.page(limit=request.limit or 50, after_id=request.after_id)
        return vod_pb2.ListVodsResponse(vods=[self._message(v) for v in vods])

    def _message(self, vod: Vod) -> vod_pb2.Vod:
        return vod_pb2.Vod(
            id=vod.id,
            playlist_url=vod.playlist_url,
            url=self.url_for(vod.id),
            metadata=vod_pb2.Metadata(title=vod.title, poster=vod.poster),
            created_at=vod.created_at,
        )

    def url_for(self, vod_id: int) -> str:
        return f"{self._public_url}/{vod_id}"
