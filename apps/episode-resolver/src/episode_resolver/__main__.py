"""Crawl a show's episodes, then open each one and pull out its ashdi streams.

This is where `crawlers` and `ashdi-finder` meet. Neither package imports the
other — the composition lives here, in the app, so a source stays a source and
a stream resolver stays a stream resolver.
"""

import argparse
import contextlib
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field, replace

from ashdi_finder import FetchError, resolve
from crawlers import Item, UnknownSource, crawl, from_spec, get, names

DEFAULT_SOURCE = "simpsonsua"
DEFAULT_SINK = "jsonl:data/{key}-streams.jsonl"


@dataclass(slots=True)
class Resolved:
    item: Item
    players: list[str] = field(default_factory=list)
    streams: list[str] = field(default_factory=list)
    error: str | None = None

    def to_item(self) -> Item:
        """Same episode, now carrying what it plays."""
        extra = {
            **self.item.extra,
            "players": self.players,
            "streams": self.streams,
        }
        if self.error:
            extra["error"] = self.error
        return replace(self.item, extra=extra)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="resolve-episodes",
        description="Resolve ashdi streams for every episode of one show.",
    )
    parser.add_argument("key", help="show key from the crawled URLs, e.g. family-guy")
    parser.add_argument(
        "--source", default=DEFAULT_SOURCE, help=f"crawler source (default: {DEFAULT_SOURCE})"
    )
    parser.add_argument("--sink", help=f"where results go (default: {DEFAULT_SINK})")
    parser.add_argument("--limit", type=int, help="stop after this many episodes")
    parser.add_argument(
        "--workers", type=int, default=4, help="episodes fetched at once (default: 4)"
    )
    parser.add_argument(
        "--timeout", type=float, default=20.0, help="request timeout, seconds (default: 20)"
    )
    parser.add_argument(
        "--proxy",
        help="proxy URL, comma-separated list, or @file (default: $PROXY_URL)",
    )
    parser.add_argument("--keys", action="store_true", help="list keys the source offers and exit")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    try:
        source = get(args.source)
    except UnknownSource as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    episodes = _episodes(source, timeout=args.timeout, proxy=args.proxy)

    if args.keys:
        for key, count in sorted(_key_counts(episodes).items()):
            print(f"{key:24} {count}")
        return 0

    wanted = [i for i in episodes if i.extra.get("key") == args.key]
    if not wanted:
        print(
            f"error: no episodes with key {args.key!r} in {source.name} "
            f"— try --keys to see what's there",
            file=sys.stderr,
        )
        return 1

    wanted.sort(key=lambda i: (i.extra.get("season") or 0, i.extra.get("episode") or 0))
    if args.limit:
        wanted = wanted[: args.limit]

    sink = from_spec(args.sink or DEFAULT_SINK.format(key=args.key))
    found = failed = 0

    with contextlib.closing(sink), ThreadPoolExecutor(max_workers=args.workers) as pool:
        print(f"{len(wanted)} episodes of {args.key} from {source.name}", file=sys.stderr)

        for result in pool.map(lambda item: _resolve(item, args.timeout, args.proxy), wanted):
            sink.write([result.to_item()])
            if result.error:
                failed += 1
                print(f"  {result.item.title:24} failed: {result.error}", file=sys.stderr)
                continue

            found += len(result.streams)
            first = result.streams[0] if result.streams else "(no stream found)"
            print(f"  {result.item.title:24} {len(result.streams):>2}  {first}")

    print(f"\n{len(wanted)} episodes, {found} streams, {failed} failed", file=sys.stderr)
    return 0 if found else 1


def _episodes(source, timeout: float, proxy: str | None = None) -> list[Item]:
    """Everything the source lists — for a sitemap that's a single request."""
    return [
        item
        for page in crawl(source, timeout=timeout, delay=0, proxy=proxy)
        for item in page.items
    ]


def _key_counts(items: list[Item]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for item in items:
        key = item.extra.get("key")
        if key:
            counts[key] = counts.get(key, 0) + 1
    return counts


def _resolve(item: Item, timeout: float, proxy: str | None = None) -> Resolved:
    try:
        result = resolve(item.url, timeout=timeout, proxy=proxy)
    except FetchError as exc:
        return Resolved(item=item, error=str(exc))

    return Resolved(
        item=item,
        players=[p.url for p in result.players],
        streams=[s.url for s in result.streams],
    )


if __name__ == "__main__":
    raise SystemExit(main())
