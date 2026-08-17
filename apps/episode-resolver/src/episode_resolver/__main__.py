"""Crawl a show's episodes, then open each one and pull out its ashdi streams.

This is where `crawlers`, `ashdi-finder` and `httpkit` meet. Neither library
imports the others, and neither knows what a proxy is: the requester is built
here, once, and handed to both.
"""

import argparse
import asyncio
import contextlib
import json
import sys
from dataclasses import dataclass, field, replace
from pathlib import Path

from ashdi_finder import FetchError, aresolve, is_ashdi_url
from crawlers import Item, UnknownSource, acrawl, from_spec, get, names
from httpkit import build_async_fetcher, resolve_pool

DEFAULT_SOURCE = "simpsonsua"
DEFAULT_SINK = "jsonl:data/{key}-streams.jsonl"


@dataclass(slots=True)
class Track:
    """One way to hear this episode: a player, its dub, and what it plays."""

    player: str
    audio: str | None
    stream: str | None = None
    error: str | None = None

    def to_dict(self) -> dict[str, str | None]:
        row: dict[str, str | None] = {"player": self.player, "stream": self.stream}
        if self.audio:
            row["audio"] = self.audio
        if self.error:
            row["error"] = self.error
        return row


@dataclass(slots=True)
class Resolved:
    item: Item
    tracks: list[Track] = field(default_factory=list)
    error: str | None = None

    @property
    def streams(self) -> list[str]:
        return [track.stream for track in self.tracks if track.stream]

    def to_item(self) -> Item:
        """Same episode, now carrying every way there is to play it.

        `tracks` rather than one stream, because a page can offer the same
        episode in two voices — and picking one on the crawler's behalf is
        exactly the choice nobody downstream can undo.
        """
        extra = {
            **self.item.extra,
            "tracks": [track.to_dict() for track in self.tracks],
            "players": [track.player for track in self.tracks],
            "streams": self.streams,
        }
        if self.error:
            extra["error"] = self.error
        return replace(self.item, extra=extra)


async def retry(path: Path, sink_spec: str | None, args: argparse.Namespace) -> int:
    """Open the players that didn't answer last time, and only those.

    A 502 from the player host says nothing about the episode — the iframe URL
    is still right, it just wasn't served that minute. So the first pass keeps
    the URL and this one comes back for it, leaving everything that already
    resolved untouched.
    """
    records = [
        json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()
    ]
    pending = [
        record
        for record in records
        if any(not track.get("stream") for track in record.get("tracks") or [])
    ]
    print(f"{len(pending)} of {len(records)} records have a player that didn't open", file=sys.stderr)
    if not pending:
        return 0

    gate = asyncio.Semaphore(max(1, args.workers))
    fixed = 0

    async with build_async_fetcher(
        proxy=resolve_pool(args.proxy), timeout=args.timeout
    ) as fetcher:

        async def one(record: dict) -> None:
            nonlocal fixed
            for track in record.get("tracks") or []:
                if track.get("stream"):
                    continue
                async with gate:
                    try:
                        result = await aresolve(str(track["player"]), fetcher=fetcher)
                    except FetchError as exc:
                        track["error"] = str(exc)
                        continue
                if result.streams:
                    track["stream"] = result.streams[0].url
                    track.pop("error", None)
                    fixed += 1

        await asyncio.gather(*(one(record) for record in pending))

    for record in records:
        record["streams"] = [
            track["stream"] for track in record.get("tracks") or [] if track.get("stream")
        ]

    out = Path(sink_spec.removeprefix("jsonl:")) if sink_spec else path
    out.write_text(
        "\n".join(json.dumps(record, ensure_ascii=False) for record in records) + "\n",
        encoding="utf-8",
    )
    print(f"{fixed} more streams; written to {out}")
    return 0


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
    parser.add_argument(
        "--retry",
        type=Path,
        default=None,
        help="re-open only the players that failed in this file, and rewrite it",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        return asyncio.run(run(args))
    except UnknownSource as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


async def run(args: argparse.Namespace) -> int:
    # Coming back for the players that didn't answer needs none of the rest:
    # no crawl, no source, just the file and the URLs it already holds.
    if args.retry is not None:
        if not args.retry.is_file():
            print(f"error: no such file: {args.retry}", file=sys.stderr)
            return 2
        return await retry(args.retry, args.sink, args)

    source = get(args.source)

    # One requester for both halves of the job, built where the proxy is known.
    async with build_async_fetcher(
        proxy=resolve_pool(args.proxy), timeout=args.timeout
    ) as fetcher:
        episodes = [
            item async for page in acrawl(source, fetcher=fetcher, delay=0) for item in page.items
        ]

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
        gate = asyncio.Semaphore(max(1, args.workers))

        with contextlib.closing(sink):
            print(f"{len(wanted)} episodes of {args.key} from {source.name}", file=sys.stderr)

            async def one(item: Item) -> Resolved:
                async with gate:
                    return await _resolve(source, item, fetcher)

            # Tasks start now, bounded by the gate; awaiting them in submission
            # order keeps the output readable while everything runs at once.
            tasks = [asyncio.create_task(one(item)) for item in wanted]
            for task in tasks:
                result = await task
                sink.write([result.to_item()])

                if result.error:
                    failed += 1
                    print(
                        f"  {result.item.title:24} failed: {result.error}", file=sys.stderr
                    )
                    continue

                found += len(result.streams)
                first = result.streams[0] if result.streams else "(no stream found)"
                print(f"  {result.item.title:24} {len(result.streams):>2}  {first}")

        print(f"\n{len(wanted)} episodes, {found} streams, {failed} failed", file=sys.stderr)
        return 0 if found else 1


def _key_counts(items: list[Item]) -> dict[str, int]:
    """Dynamic keys by nature — a mapping, not a record."""
    counts: dict[str, int] = {}
    for item in items:
        key = item.extra.get("key")
        if key:
            counts[key] = counts.get(key, 0) + 1
    return counts


async def _resolve(source, item: Item, fetcher) -> Resolved:
    """Every player this episode has, opened one at a time.

    The episode page is read here rather than during the crawl: a crawl with
    `details` on would open all three thousand pages before the `--key` filter
    ever ran, and this job only ever wants one show. It costs the same request
    either way — the page has to be opened to find a player at all.

    What the page adds is which tab was which dub, so each voice keeps its name.
    Without that the streams come back nameless, which is true to what is known.
    """
    listed: list[Track] = []

    if source.item_pages:
        try:
            page = await fetcher.fetch(item.url)
            described = source.parse_item(page.text, item.url)
        except Exception as exc:  # the requester's, or a page the parser choked on
            return Resolved(item=item, error=str(exc))

        listed = [
            Track(player=str(track["player"]), audio=track.get("audio"))
            for track in (described.extra.get("tracks") if described else []) or []
            if is_ashdi_url(str(track.get("player") or ""))
        ]

    if not listed:
        try:
            result = await aresolve(item.url, fetcher=fetcher)
        except FetchError as exc:
            return Resolved(item=item, error=str(exc))
        return Resolved(
            item=item,
            tracks=[
                Track(player=player.url, audio=None, stream=stream.url)
                for player in result.players
                for stream in player.streams
            ],
        )

    for track in listed:
        try:
            result = await aresolve(track.player, fetcher=fetcher)
        except FetchError as exc:
            # ashdi answers 502 often enough that treating it as "no such
            # stream" would quietly lose episodes. The iframe URL is what was
            # actually learned here, so it's kept with the reason it didn't
            # open — `--retry` comes back for exactly these.
            track.error = str(exc)
            continue
        streams = result.streams
        track.stream = streams[0].url if streams else None
        if track.stream is None:
            track.error = "player opened but offered no stream"

    return Resolved(item=item, tracks=listed)


if __name__ == "__main__":
    raise SystemExit(main())
