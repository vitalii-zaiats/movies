"""Register crawled streams with the VOD service, then tell the catalogue to look.

There is one write, and it goes to one place. Whoever crawled a stream registers
it with the VOD service together with everything they knew while they had it —
which show, which episode, where it came from. That service owns playable things
and is the source of truth for them.

    resolve-episodes -> jsonl -> seed-catalogue -> vod (gRPC CreateVod)
                                               -> api (POST /sync/vods, "go look")

The catalogue is not written to. It reads the VOD service from wherever it left
off and builds its own rows, so the two can be seeded, resynced or rebuilt
independently — and a catalogue that was down for a day catches up by itself
rather than needing the seed run again.
"""

import argparse
import asyncio
import json
import os
import sys
from collections.abc import Mapping
from pathlib import Path
from typing import Any

from seeder.catalogue import CatalogueUnavailable, CatalogueWriter
from seeder.records import ResolvedRecord, playable, read
from seeder.vod import VodUnavailable, VodWriter

DEFAULT_API = os.environ.get("CATALOGUE_URL", "http://127.0.0.1:8020")
DEFAULT_VOD = os.environ.get("VOD_GRPC_TARGET", "127.0.0.1:50051")
DEFAULT_BATCH = 100


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="seed-catalogue",
        description="Register crawled streams with the VOD service and fill the catalogue",
    )
    parser.add_argument("path", type=Path, help="output of `resolve-episodes`")
    parser.add_argument("--api", default=DEFAULT_API, help=f"default: {DEFAULT_API}")
    parser.add_argument("--vod", default=DEFAULT_VOD, help=f"default: {DEFAULT_VOD}")
    parser.add_argument(
        "--batch", type=int, default=DEFAULT_BATCH, help=f"episodes per POST (default: {DEFAULT_BATCH})"
    )
    parser.add_argument("--limit", type=int, help="stop after this many episodes")
    parser.add_argument(
        "--facts",
        type=Path,
        default=None,
        help="the crawl file, when the stream file was written without its facts",
    )
    return parser


# What the catalogue is allowed to learn about a title, and nothing more —
# `streams` and `players` are this app's working notes, not facts about a film.
CARRIED = (
    "kind",
    "original_title",
    "year",
    "year_end",
    "description",
    "duration",
    "age",
    "quality",
    "audio",
    "genres",
    "countries",
    "directors",
    "cast",
    "imdb",
    "imdb_votes",
    "imdb_id",
)


def carried(record: ResolvedRecord, facts: Mapping[str, Any] | None = None) -> dict[str, Any]:
    """Everything the catalogue will need when it comes looking for this VOD.

    This is the only moment the two halves of the story are in the same place:
    the stream, and everything the crawl knew about the thing it plays. What
    isn't put in here the catalogue will never learn, because nothing else in
    the system will ever tell it — it reads this service and no other.
    """
    known = dict(facts or {})
    envelope: dict[str, Any] = {
        "show_key": record.get("key") or "unknown",
        "title": record.get("title") or record["url"],
        "season": record.get("season"),
        "episode": record.get("episode"),
        "episode_end": record.get("episode_end"),
        "poster": record.get("poster") or known.get("poster"),
        "source_url": record["url"],
    }
    envelope.update({key: known[key] for key in CARRIED if known.get(key) is not None})
    return {key: value for key, value in envelope.items() if value is not None}


def facts_by_url(path: Path | None) -> dict[str, dict[str, Any]]:
    """The crawl's own file, indexed by page URL.

    Only needed for stream files written before the resolver started carrying
    the facts along with them. A newer file has both halves already.
    """
    if path is None:
        return {}
    return {
        record["url"]: record
        for record in (json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip())
    }


async def seed(args: argparse.Namespace) -> int:
    read_count = skipped = registered = 0
    known = facts_by_url(args.facts)

    async with VodWriter(args.vod) as vod, CatalogueWriter(args.api) as catalogue:
        for record in read(args.path):
            read_count += 1

            tracks = playable(record)
            if not tracks:
                skipped += 1
                continue

            facts = carried(record, known.get(record["url"], record))
            for playlist_url, dub in tracks:
                # One VOD per voice. They play different bytes, so they are
                # different playable things — and the dub travels with them,
                # because the catalogue has no other way to learn it.
                ref = await vod.register(
                    playlist_url,
                    title=record.get("title"),
                    facts={**facts, "audio": dub} if dub else facts,
                )
                registered += int(ref.created)

            if args.limit and read_count >= args.limit:
                break

        # One write, one direction. Then the catalogue is told there is
        # something new to come and read — it pulls, at its own pace, from the
        # service that owns playable things.
        report = await catalogue.sync()

    print(
        f"read {read_count}, skipped {skipped} (nothing playable)\n"
        f"vods registered {registered}\n"
        f"catalogue synced: {report.created} new, {report.updated} updated, "
        f"now at vod {report.cursor}"
    )
    return 0


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    if not args.path.is_file():
        print(f"error: no such file: {args.path}", file=sys.stderr)
        return 2

    try:
        return asyncio.run(seed(args))
    except VodUnavailable as exc:
        print(f"error: vod service unreachable ({exc}) — is it up?", file=sys.stderr)
        return 2
    except CatalogueUnavailable as exc:
        print(f"error: catalogue api unreachable ({exc}) — is it up?", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
