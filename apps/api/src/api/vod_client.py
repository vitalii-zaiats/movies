"""gRPC client for the VOD service.

The API knows the VOD service only through the contract in `contracts` — no
imports across services, no shared database.
"""

from dataclasses import dataclass

import grpc
from contracts import vod_pb2, vod_pb2_grpc

from api.settings import settings


class VodUnavailable(RuntimeError):
    """The VOD service didn't answer."""


@dataclass(frozen=True, slots=True)
class VodRef:
    id: int
    url: str
    created: bool


class VodClient:
    def __init__(self, target: str | None = None) -> None:
        self._target = target or settings.vod_grpc_target
        self._channel: grpc.aio.Channel | None = None

    async def __aenter__(self) -> "VodClient":
        self._channel = grpc.aio.insecure_channel(self._target)
        return self

    async def __aexit__(self, *_: object) -> None:
        await self.aclose()

    async def aclose(self) -> None:
        if self._channel is not None:
            await self._channel.close()
            self._channel = None

    @property
    def _stub(self) -> vod_pb2_grpc.VodServiceStub:
        if self._channel is None:
            self._channel = grpc.aio.insecure_channel(self._target)
        return vod_pb2_grpc.VodServiceStub(self._channel)

    async def create(
        self, playlist_url: str, title: str | None = None, poster: str | None = None
    ) -> VodRef:
        """Register a playlist and get back the id we'll store. Idempotent."""
        request = vod_pb2.CreateVodRequest(
            playlist_url=playlist_url,
            metadata=vod_pb2.Metadata(title=title, poster=poster),
        )
        try:
            response = await self._stub.CreateVod(request)
        except grpc.aio.AioRpcError as exc:
            raise VodUnavailable(f"{self._target}: {exc.details() or exc.code().name}") from exc
        return VodRef(id=response.vod.id, url=response.vod.url, created=response.created)

    async def get(self, vod_id: int) -> vod_pb2.Vod | None:
        try:
            return await self._stub.GetVod(vod_pb2.GetVodRequest(id=vod_id))
        except grpc.aio.AioRpcError as exc:
            if exc.code() is grpc.StatusCode.NOT_FOUND:
                return None
            raise VodUnavailable(f"{self._target}: {exc.details() or exc.code().name}") from exc
