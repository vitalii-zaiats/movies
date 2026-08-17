"""Registering playlists with the VOD service.

This is the only place in the repo that calls `CreateVod`. Whoever crawled a
stream is the one who knows it exists, so creation lives on this side of the
fence; the API only ever reads that service.
"""

from dataclasses import dataclass

import grpc
from contracts import vod_pb2, vod_pb2_grpc


class VodUnavailable(RuntimeError):
    """The VOD service didn't answer."""


@dataclass(frozen=True, slots=True)
class VodRef:
    id: int
    url: str
    created: bool


class VodWriter:
    def __init__(self, target: str) -> None:
        self._target = target
        self._channel: grpc.aio.Channel | None = None

    async def __aenter__(self) -> "VodWriter":
        self._channel = grpc.aio.insecure_channel(self._target)
        return self

    async def __aexit__(self, *_: object) -> None:
        if self._channel is not None:
            await self._channel.close()
            self._channel = None

    async def register(self, playlist_url: str, title: str | None = None) -> VodRef:
        """Idempotent on the playlist URL, so re-seeding returns the same id."""
        if self._channel is None:
            raise RuntimeError("use VodWriter as an async context manager")

        request = vod_pb2.CreateVodRequest(
            playlist_url=playlist_url, metadata=vod_pb2.Metadata(title=title)
        )
        try:
            response = await vod_pb2_grpc.VodServiceStub(self._channel).CreateVod(request)
        except grpc.aio.AioRpcError as exc:
            raise VodUnavailable(f"{self._target}: {exc.details() or exc.code().name}") from exc

        return VodRef(id=response.vod.id, url=response.vod.url, created=response.created)
