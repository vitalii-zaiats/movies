"""Entry point: `uv run proxy`."""

import argparse

from aiohttp import web

from proxy.server import create_app


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="proxy", description="Async streaming proxy")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8001)
    parser.add_argument(
        "--allow-host",
        action="append",
        default=[],
        metavar="HOST",
        help="only proxy this host (repeatable; default: any)",
    )
    args = parser.parse_args(argv)

    web.run_app(create_app(frozenset(args.allow_host)), host=args.host, port=args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
