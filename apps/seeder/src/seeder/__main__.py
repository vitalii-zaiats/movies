"""Load crawled episodes into the VOD service and the catalogue.

The direction matters: whoever crawled a stream registers it with the VOD
service and then tells the API the id it got back. The API never writes to the
VOD service — it only reads it.

    resolve-episodes  ->  jsonl  ->  seed-catalogue  ->  vod (gRPC)
                                                     ->  api (HTTP)
"""

import argparse
import asyncio
import os
import sys
from pathlib import Path

from seeder.catalogue import EMPTY, CatalogueUnavailable, CatalogueWriter, IngestEpisode
from seeder.records import ResolvedRecord, read, single_stream
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
    return parser


def episode_of(record: ResolvedRecord, vod_id: int) -> IngestEpisode:
    source_url = record["url"]
    return IngestEpisode(
        show_key=record.get("key") or "unknown",
        title=record.get("title") or source_url,
        season=int(record.get("season") or 0),
        episode=int(record.get("episode") or 0),
        episode_end=record.get("episode_end"),
        poster=record.get("poster"),
        source_url=source_url,
        vod_id=vod_id,
    )


async def seed(args: argparse.Namespace) -> int:
    read_count = skipped = registered = 0
    report = EMPTY
    batch: list[IngestEpisode] = []

    async with VodWriter(args.vod) as vod, CatalogueWriter(args.api) as catalogue:
        for record in read(args.path):
            read_count += 1

            playlist_url = single_stream(record)
            if playlist_url is None:
                skipped += 1
                continue

            ref = await vod.register(playlist_url, title=record.get("title"))
            registered += int(ref.created)
            batch.append(episode_of(record, ref.id))

            if len(batch) >= args.batch:
                report += await catalogue.ingest(batch)
                batch.clear()

            if args.limit and read_count >= args.limit:
                break

        report += await catalogue.ingest(batch)

    print(
        f"read {read_count}, skipped {skipped} (not exactly one stream)\n"
        f"vods registered {registered}\n"
        f"shows {report.shows}, episodes: {report.created} new, {report.updated} updated"
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
