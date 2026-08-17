"""Filling the catalogue from what a listing crawler wrote.

`seed-catalogue` seeds episodes that already have a stream: it registers each
with the VOD service and hands the id over. This entry point seeds the *titles* —
everything `crawl kinoukr --details` found — before any stream is resolved, so
the catalogue has something to show while playback is still being sorted out.
Nothing here talks to the VOD service; every episode lands without a `vod_id`
and picks one up on a later pass.

    crawl kinoukr --details  ->  jsonl  ->  seed-crawled  ->  api (HTTP)

A crawled title isn't an episode of anything — it's a film, or the front page of
a series whose playlist nobody has opened yet. The catalogue knows shows and
episodes and nothing else, so each title becomes a show of its own holding one
episode. Resolving a serial later adds its real episodes beside that one.
"""

import argparse
import asyncio
import json
import os
import re
import sys
from collections.abc import Iterator
from pathlib import Path
from typing import NotRequired, TypedDict, cast

from seeder.catalogue import (
    EMPTY,
    CatalogueUnavailable,
    CatalogueWriter,
    IngestEpisode,
    IngestShow,
)

DEFAULT_API = os.environ.get("CATALOGUE_URL", "http://127.0.0.1:8020")
DEFAULT_BATCH = 200

SLUG_RE = re.compile(r"/([^/]+)\.html$")


class CrawledItem(TypedDict):
    """One line of a crawl, as far as seeding cares.

    The crawler's own fields are `source`, `title`, `url` and `poster`; a source
    that reads item pages adds its own beside them, and only the title matters
    here. Everything but the URL is optional — an item whose page failed to load
    still carries the card it came from.
    """

    url: str
    title: NotRequired[str]
    poster: NotRequired[str | None]
    kind: NotRequired[str]
    year: NotRequired[int]
    error: NotRequired[str]
    # What the page said about the title itself. All optional, all only as good
    # as the source — see `show_of`.
    original_title: NotRequired[str]
    description: NotRequired[str]
    duration: NotRequired[str]
    age: NotRequired[str]
    genres: NotRequired[list[str]]
    countries: NotRequired[list[str]]
    directors: NotRequired[list[str]]
    cast: NotRequired[list[str]]
    imdb: NotRequired[float]
    imdb_votes: NotRequired[int]
    imdb_id: NotRequired[str]


def read(path: Path) -> Iterator[CrawledItem]:
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                yield cast(CrawledItem, json.loads(line))


def key_of(url: str) -> str:
    """The site's own page slug — `9105-pasazhyr`.

    The numeric half is kept on purpose: 312 of kinoukr's 8 744 titles share a
    slug without it, and merging two different films into one show is a worse
    outcome than a key with a number in it.
    """
    match = SLUG_RE.search(url)
    return match[1] if match else url.rstrip("/").rsplit("/", 1)[-1] or url


def episode_of(item: CrawledItem) -> IngestEpisode:
    """A crawled title, as the single episode of a show of its own."""
    title = item.get("title") or item["url"]
    poster = item.get("poster")
    return IngestEpisode(
        show_key=key_of(item["url"]),
        show_title=title,
        # The same picture on both rows: for a film they are the same thing, and
        # a browse list of shows with no artwork is the one thing worth avoiding.
        show_poster=poster,
        title=title,
        season=1,
        episode=1,
        poster=poster,
        source_url=item["url"],
    )


def show_of(item: CrawledItem) -> IngestShow:
    """The title as the crawl described it — none of which the catalogue knew.

    Renamed in two places on the way over: the crawler calls an age limit `age`
    and a cast `cast`, and neither reads well as a column.
    """
    show: IngestShow = {"key": key_of(item["url"])}

    for source, target in (
        ("original_title", "original_title"),
        ("year", "year"),
        ("description", "description"),
        ("duration", "duration"),
        ("age", "age_rating"),
        ("genres", "genres"),
        ("countries", "countries"),
        ("directors", "directors"),
        ("cast", "starring"),
        ("imdb_id", "imdb_id"),
        ("imdb", "imdb_rating"),
        ("imdb_votes", "imdb_votes"),
    ):
        value = item.get(source)
        if value is not None:
            show[target] = value  # type: ignore[literal-required]

    return show


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="seed-crawled",
        description="Fill the catalogue with crawled titles, before any stream is resolved",
    )
    parser.add_argument("path", type=Path, help="output of `crawl <source> --details`")
    parser.add_argument("--api", default=DEFAULT_API, help=f"default: {DEFAULT_API}")
    parser.add_argument(
        "--batch",
        type=int,
        default=DEFAULT_BATCH,
        help=f"titles per POST (default: {DEFAULT_BATCH})",
    )
    parser.add_argument("--limit", type=int, help="stop after this many titles")
    return parser


async def seed(args: argparse.Namespace) -> int:
    read_count = described = unknown = 0
    report = EMPTY
    batch: list[IngestEpisode] = []
    details: list[IngestShow] = []

    async with CatalogueWriter(args.api) as catalogue:
        for item in read(args.path):
            read_count += 1
            batch.append(episode_of(item))
            details.append(show_of(item))

            if len(batch) >= args.batch:
                report += await catalogue.ingest(batch)
                batch.clear()
                # Episodes first, always: the row has to exist before there is
                # anything to describe.
                filled, missing = await catalogue.describe(details)
                described += filled
                unknown += missing
                details.clear()
                print(f"  {read_count} titles sent", file=sys.stderr)

            if args.limit and read_count >= args.limit:
                break

        report += await catalogue.ingest(batch)
        filled, missing = await catalogue.describe(details)
        described += filled
        unknown += missing

    print(
        f"read {read_count}\n"
        f"shows {report.shows}, episodes: {report.created} new, {report.updated} updated\n"
        f"described {described}, unknown {unknown}"
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if not args.path.is_file():
        print(f"error: no such file: {args.path}", file=sys.stderr)
        return 2

    try:
        return asyncio.run(seed(args))
    except CatalogueUnavailable as exc:
        print(f"error: catalogue api unreachable ({exc}) — is it up?", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
