"""The gRPC server: servicers in, one port out.

`api.main.create_app` is this file's opposite number. Both are short for the
same reason — the interesting things happen a layer down, and a transport that
starts growing decisions is a transport that has started lying about where they
live.
"""

import asyncio
import signal
from collections.abc import Sequence

import grpc
from contracts import catalogue_pb2 as pb
from contracts import catalogue_pb2_grpc as stubs
from grpc_reflection.v1alpha import reflection

from api.core.database import engine
from api.rpc.errors import Refusals
from api.rpc.services import (
    AccountsService,
    CatalogueService,
    PlaylistsService,
    WatchingService,
)
from api.settings import settings

# How long a shutdown waits for calls already in flight. Long enough for a
# progress report, short enough that a deploy isn't held up by a phone that
# wandered off mid-stream.
GRACE_SECONDS = 5.0


def build_server() -> grpc.aio.Server:
    server = grpc.aio.server(interceptors=[Refusals()])

    stubs.add_CatalogueServicer_to_server(CatalogueService(), server)
    stubs.add_AccountsServicer_to_server(AccountsService(), server)
    stubs.add_WatchingServicer_to_server(WatchingService(), server)
    stubs.add_PlaylistsServicer_to_server(PlaylistsService(), server)

    # Reflection, so the server can describe itself. That's what makes
    # `grpcurl -plaintext host:50061 list` work, and it's the gRPC equivalent of
    # the OpenAPI page the HTTP side gets for free.
    reflection.enable_server_reflection(_service_names(), server)
    return server


def _service_names() -> Sequence[str]:
    return (
        pb.DESCRIPTOR.services_by_name["Catalogue"].full_name,
        pb.DESCRIPTOR.services_by_name["Accounts"].full_name,
        pb.DESCRIPTOR.services_by_name["Watching"].full_name,
        pb.DESCRIPTOR.services_by_name["Playlists"].full_name,
        reflection.SERVICE_NAME,
    )


async def serve(host: str, port: int) -> None:
    server = build_server()
    server.add_insecure_port(f"{host}:{port}")

    await server.start()
    print(f"grpc on {host}:{port}", flush=True)

    stopping = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sign in (signal.SIGINT, signal.SIGTERM):
        # A container is stopped with SIGTERM, and a server that ignores it gets
        # killed ten seconds later with whatever it was doing half-done.
        loop.add_signal_handler(sign, stopping.set)

    await stopping.wait()
    await server.stop(GRACE_SECONDS)
    # The pool belongs to the process, and this is the end of it.
    await engine.dispose()


def run(host: str | None = None, port: int | None = None) -> None:
    asyncio.run(serve(host or settings.grpc_host, port or settings.grpc_port))
