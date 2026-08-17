"""Resolve streams for a whole crawl, from the file the crawl already wrote.

`resolve-episodes` walks a source live, one show at a time. This one starts from
`crawl <source> --details` output — eight thousand titles that already carry the
player URLs their pages linked to — and turns each into what `seed-catalogue`
eats: a record with exactly one stream.

    crawl kinoukr --details -> jsonl -> resolve-crawl -> jsonl -> seed-catalogue

A film's player is one file and becomes one record. A serial's player is a
playlist, and each of its leaves becomes a record of its own — which is how the
1 101 series in this catalogue stop being one nameless episode each and get
their real seasons back.

Where a serial carries several dubs, the same episode appears once per dub and
only one may survive: the catalogue keeps one row per (show, season, episode),
by constraint. The first in playlist order wins, which is the order the site put
them in.
"""

import argparse
import asyncio
import json
import sys
from collections.abc import Iterator
from pathlib import Path
from typing import Any

from ashdi_finder import FetchError, aresolve
from httpkit import build_async_fetcher, resolve_pool

DEFAULT_OUT = Path("data/kinoukr-streams.jsonl")


def read(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def key_of(url: str) -> str:
    """The show key `seed-crawled` used, so this lands on the same rows."""
    name = url.rstrip("/").rsplit("/", 1)[-1]
    return name.removesuffix(".html") or url


def player_of(record: dict[str, Any]) -> str | None:
    """The first ashdi player on the page. Tortuga is somebody else's format."""
    return next((url for url in record.get("players") or [] if "ashdi.vip/" in url), None)


# This app's own working notes. Everything else the crawl wrote is a fact about
# the film, and travels with the stream so the seeder can hand both over at once.
NOTES = frozenset({"players", "trailer", "streams", "error", "source"})


def facts(record: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in record.items() if key not in NOTES}


def film_record(record: dict[str, Any], stream: str) -> dict[str, Any]:
    return {
        **facts(record),
        "url": record["url"],
        "key": key_of(record["url"]),
        "title": record.get("title") or record["url"],
        "season": 1,
        "episode": 1,
        "poster": record.get("poster"),
        "streams": [stream],
    }


def episode_records(record: dict[str, Any], episodes: list[Any]) -> Iterator[dict[str, Any]]:
    """One record per (season, episode), first dub wins."""
    seen: set[tuple[int, int]] = set()

    for episode in episodes:
        season, number = episode.season or 1, episode.episode
        if number is None or (season, number) in seen or not episode.url:
            continue
        seen.add((season, number))

        yield {
            **facts(record),
            # A page holds a whole serial, so the episode needs a URL of its own
            # to be idempotent on — the fragment is ours, and the site ignores it.
            "url": f"{record['url']}#s{season:02d}e{number:02d}",
            "key": key_of(record["url"]),
            "title": episode.title or f"S{season:02d}E{number:02d}",
            "season": season,
            "episode": number,
            "episode_end": episode.episode_end,
            "poster": episode.poster or record.get("poster"),
            "streams": [episode.url],
        }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="resolve-crawl",
        description="Resolve ashdi streams for every title in a crawl file",
    )
    parser.add_argument("path", type=Path, help="output of `crawl <source> --details`")
    parser.add_argument("-o", "--out", type=Path, default=DEFAULT_OUT, help=f"default: {DEFAULT_OUT}")
    parser.add_argument("--workers", type=int, default=8, help="players open at once (default: 8)")
    parser.add_argument("--delay", type=float, default=0.2, help="pause per worker (default: 0.2)")
    parser.add_argument("--limit", type=int, help="stop after this many titles")
    parser.add_argument(
        "--serials", action="store_true", help="also open /serial/ players, one record per episode"
    )
    parser.add_argument("--timeout", type=float, default=25.0)
    parser.add_argument("--proxy", help="proxy URL, list, or @file (default: $PROXY_URL)")
    return parser


async def run(args: argparse.Namespace) -> int:
    records = read(args.path)
    wanted = [
        (record, player)
        for record in records
        if (player := player_of(record))
        and (args.serials or "/serial/" not in player)
    ]
    if args.limit:
        wanted = wanted[: args.limit]

    print(f"{len(wanted):,} of {len(records):,} titles have an ashdi player", file=sys.stderr)

    gate = asyncio.Semaphore(max(1, args.workers))
    fetcher = build_async_fetcher(proxy=resolve_pool(args.proxy), timeout=args.timeout)
    out: list[dict[str, Any]] = []
    failed = empty = 0

    async def one(record: dict[str, Any], player: str) -> list[dict[str, Any]]:
        nonlocal failed, empty
        async with gate:
            if args.delay:
                await asyncio.sleep(args.delay)
            try:
                result = await aresolve(player, fetcher=fetcher)
            except (FetchError, Exception) as exc:  # the requester's, or a parse
                failed += 1
                print(f"  {record['url']}  failed: {exc}", file=sys.stderr)
                return []

        if result.episodes:
            return list(episode_records(record, result.episodes))

        streams = [stream.url for stream in result.streams]
        if not streams:
            empty += 1
            return []
        # One file is what a film is; anything else here is a quality ladder, and
        # the first rung is the one the packager should be given.
        return [film_record(record, streams[0])]

    tasks = [asyncio.create_task(one(record, player)) for record, player in wanted]
    done = 0
    for task in tasks:
        out.extend(await task)
        done += 1
        if done % 250 == 0:
            print(f"  {done:,}/{len(tasks):,} players opened, {len(out):,} records", file=sys.stderr)

    await fetcher.aclose()

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(
        "\n".join(json.dumps(record, ensure_ascii=False) for record in out) + "\n",
        encoding="utf-8",
    )

    print(
        f"\n{len(out):,} records written to {args.out}\n"
        f"{failed:,} players failed, {empty:,} played nothing"
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if not args.path.is_file():
        print(f"error: no such file: {args.path}", file=sys.stderr)
        return 2

    return asyncio.run(run(args))


if __name__ == "__main__":
    raise SystemExit(main())
