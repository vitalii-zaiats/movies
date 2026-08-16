"""One entry point among several: look at a source's pages from the terminal.

`crawlers.engine.run` is the other one — that's what apps call.
"""

import argparse
import contextlib
import json
import sys

from crawlers import source as sources
from crawlers.engine import crawl
from crawlers.sinks import from_spec


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="crawl",
        description="Read listing pages from a registered source.",
    )
    parser.add_argument("source", nargs="?", help="source name (see --list)")
    parser.add_argument(
        "pages", type=int, nargs="?", default=1, help="how many pages to read (default: 1)"
    )
    parser.add_argument("--start", type=int, default=1, help="first page number (default: 1)")
    parser.add_argument(
        "--sink",
        help="where items go: stdout (default), memory, jsonl:<path>",
    )
    parser.add_argument(
        "--delay", type=float, default=0.5, help="pause between pages, seconds (default: 0.5)"
    )
    parser.add_argument(
        "--timeout", type=float, default=20.0, help="request timeout, seconds (default: 20)"
    )
    parser.add_argument(
        "--proxy",
        help="proxy URL, comma-separated list, or @file (default: $PROXY_URL)",
    )
    parser.add_argument("--json", action="store_true", help="print the crawl as JSON")
    parser.add_argument("--list", action="store_true", help="list registered sources and exit")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if args.list:
        for name in sources.names():
            print(name)
        return 0

    try:
        source = sources.get(args.source) if args.source else _only_source()
    except sources.UnknownSource as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    if args.pages < 1 or args.start < 1:
        print("error: pages and --start must be >= 1", file=sys.stderr)
        return 2

    # Printing is itself a sink, so JSON output just swaps it for an in-memory one.
    sink = from_spec(args.sink or ("memory" if args.json else "stdout"))
    found = 0

    with contextlib.closing(sink):
        pages = []
        for page in crawl(
            source,
            args.pages,
            args.start,
            timeout=args.timeout,
            delay=args.delay,
            proxy=args.proxy,
        ):
            pages.append(page)
            if page.error:
                print(f"page {page.number}  failed: {page.error}", file=sys.stderr)
                continue

            if not args.json:
                print(f"page {page.number}  ({len(page.items)} items)  {page.url}")
            sink.write(page.items)
            found += len(page.items)
            if not args.json:
                print()

        if args.json:
            print(
                json.dumps(
                    {"source": source.name, "count": found, "pages": [p.to_dict() for p in pages]},
                    ensure_ascii=False,
                    indent=2,
                )
            )

    return 0 if found else 1


def _only_source():
    """No name given: fine while there's exactly one source, ambiguous after that."""
    names = sources.names()
    if len(names) == 1:
        return sources.get(names[0])
    raise sources.UnknownSource(f"pick a source: {', '.join(names)}")


if __name__ == "__main__":
    raise SystemExit(main())
