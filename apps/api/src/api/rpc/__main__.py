"""Entry point: `uv run api-grpc`.

A process of its own rather than a thread beside uvicorn. The two layers share
a database and nothing else, so there is no reason for one to be able to take
the other down — and every reason for them to be restartable apart.
"""

import argparse

from api.rpc.server import run
from api.settings import settings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="api-grpc", description="Catalogue API over gRPC")
    parser.add_argument("--host", default=settings.grpc_host)
    parser.add_argument("--port", type=int, default=settings.grpc_port)
    args = parser.parse_args(argv)

    run(args.host, args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
