"""Read-only gRPC client for the VOD service.

The API looks VODs up; it never registers them. Whoever crawled a stream is the
one who knows it exists, so creation belongs on that side of the fence — see
`apps/seeder`. Keeping `CreateVod` out of this client is what makes that rule
hold instead of being a comment.
"""

import grpc
from contracts import vod_pb2, vod_pb2_grpc

from api.settings import settings


class VodUnavailable(RuntimeError):
    """The VOD service didn't answer."""


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

    async def get(self, vod_id: int) -> vod_pb2.Vod | None:
        try:
            return await self._stub.GetVod(vod_pb2.GetVodRequest(id=vod_id))
        except grpc.aio.AioRpcError as exc:
            if exc.code() is grpc.StatusCode.NOT_FOUND:
                return None
            raise VodUnavailable(f"{self._target}: {exc.details() or exc.code().name}") from exc
