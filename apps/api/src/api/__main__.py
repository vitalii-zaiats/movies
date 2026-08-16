"""Entry point: `uv run api`."""

import argparse

import uvicorn

from api.settings import settings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="api", description="Catalogue API")
    parser.add_argument("--host", default=settings.host)
    parser.add_argument("--port", type=int, default=settings.port)
    parser.add_argument("--reload", action="store_true")
    args = parser.parse_args(argv)

    uvicorn.run("api.main:app", host=args.host, port=args.port, reload=args.reload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
