"""Entry point: `uv run hub`."""

import argparse
import logging
import os

from aiohttp import web

from hub.server import create_app

DEFAULT_REDIS = os.environ.get("REDIS_URL", "redis://127.0.0.1:6379/0")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="hub", description="Pairing / relay WebSocket hub")
    parser.add_argument("--host", default="0.0.0.0")  # noqa: S104 — phones need to reach it
    parser.add_argument("--port", type=int, default=8010)
    parser.add_argument("--redis", default=DEFAULT_REDIS, help=f"default: {DEFAULT_REDIS}")
    args = parser.parse_args(argv)

    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    web.run_app(create_app(args.redis), host=args.host, port=args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
