"""Runs both faces of the service in one process: gRPC for us, HTTP for players."""

import argparse
import asyncio
import logging
import os
import sys
from pathlib import Path

import grpc
import uvicorn
from contracts import vod_pb2_grpc

from vod.grpc_service import VodService
from vod.http_app import create_app
from vod.store import SchemaMissing, VodStore

DEFAULT_DB = Path(os.environ.get("VOD_DB", "data/vod.db"))
DEFAULT_PUBLIC_URL = os.environ.get("VOD_PUBLIC_URL", "http://vod.localhost:8030")
DEFAULT_PROXY_URL = os.environ.get("VOD_PROXY_URL", "http://127.0.0.1:8001")

log = logging.getLogger("vod")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="vod", description="VOD microservice")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--http-port", type=int, default=8030)
    parser.add_argument("--grpc-port", type=int, default=50051)
    parser.add_argument("--db", type=Path, default=DEFAULT_DB, help=f"default: {DEFAULT_DB}")
    parser.add_argument(
        "--public-url",
        default=DEFAULT_PUBLIC_URL,
        help=f"what we tell others our URLs look like (default: {DEFAULT_PUBLIC_URL})",
    )
    parser.add_argument(
        "--proxy-url",
        default=DEFAULT_PROXY_URL,
        help=f"apps/proxy — every playlist goes through it (default: {DEFAULT_PROXY_URL})",
    )
    return parser


async def serve(args: argparse.Namespace) -> None:
    store = VodStore(args.db)
    store.check()  # storage is prepared before we run, never by us

    grpc_server = grpc.aio.server()
    vod_pb2_grpc.add_VodServiceServicer_to_server(
        VodService(store, args.public_url), grpc_server
    )
    grpc_server.add_insecure_port(f"{args.host}:{args.grpc_port}")
    await grpc_server.start()
    log.info("grpc on %s:%s", args.host, args.grpc_port)

    http = uvicorn.Server(
        uvicorn.Config(
            create_app(store, args.public_url, args.proxy_url),
            host=args.host,
            port=args.http_port,
            log_level="info",
        )
    )
    try:
        await http.serve()
    finally:
        await grpc_server.stop(grace=5)


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")

    try:
        asyncio.run(serve(args))
    except SchemaMissing as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
