"""Load resolved episodes into the catalogue.

Reads the jsonl that `resolve-episodes` writes, registers each playlist with the
VOD service over gRPC, and stores the metadata plus the link it gets back.

Only records with exactly one stream are taken: zero means nothing was found,
and more than one means a choice nobody has made yet.
"""

import argparse
import asyncio
import json
import sys
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path

from sqlalchemy import select

from api.db import Session, engine
from api.models import Episode, Show
from api.vod_client import VodClient, VodUnavailable


@dataclass
class Report:
    read: int = 0
    skipped: int = 0
    vods_created: int = 0
    shows: int = 0
    episodes_created: int = 0
    episodes_updated: int = 0


def records(path: Path) -> Iterator[dict]:
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                yield json.loads(line)


async def seed(path: Path, limit: int | None = None) -> Report:
    report = Report()

    async with VodClient() as vod, Session() as session:
        shows: dict[str, Show] = {}

        for record in records(path):
            report.read += 1
            streams = record.get("streams") or []
            if len(streams) != 1:
                report.skipped += 1
                continue

            key = record.get("key") or "unknown"
            show = shows.get(key) or await _show(session, key)
            if key not in shows:
                shows[key] = show
                report.shows += 1

            ref = await vod.create(streams[0], title=record.get("title"))
            report.vods_created += int(ref.created)

            created = await _episode(session, show, record, ref.id, ref.url)
            report.episodes_created += int(created)
            report.episodes_updated += int(not created)

            if limit and report.episodes_created + report.episodes_updated >= limit:
                break

        await session.commit()

    return report


async def _show(session, key: str) -> Show:
    show = await session.scalar(select(Show).where(Show.key == key))
    if show is None:
        show = Show(key=key, title=key.replace("-", " ").title())
        session.add(show)
        await session.flush()
    return show


async def _episode(session, show: Show, record: dict, vod_id: int, vod_url: str) -> bool:
    """Upsert on the source URL. Returns True when the row is new."""
    source_url = record["url"]
    episode = await session.scalar(select(Episode).where(Episode.source_url == source_url))
    created = episode is None

    if episode is None:
        episode = Episode(show_id=show.id, source_url=source_url)
        session.add(episode)

    episode.season = int(record.get("season") or 0)
    episode.episode = int(record.get("episode") or 0)
    episode.episode_end = record.get("episode_end")
    episode.title = record.get("title") or source_url
    episode.poster = record.get("poster")  # null for now — the crawler has none
    episode.vod_id = vod_id
    episode.vod_url = vod_url
    await session.flush()
    return created


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="api-seed", description="Seed the catalogue and the VOD service from a jsonl"
    )
    parser.add_argument("path", type=Path, help="output of `resolve-episodes`")
    parser.add_argument("--limit", type=int, help="stop after this many episodes")
    args = parser.parse_args(argv)

    if not args.path.is_file():
        print(f"error: no such file: {args.path}", file=sys.stderr)
        return 2

    try:
        report = asyncio.run(_run(args.path, args.limit))
    except VodUnavailable as exc:
        print(f"error: vod service unreachable ({exc}) — is `uv run vod` up?", file=sys.stderr)
        return 2

    print(
        f"read {report.read}, skipped {report.skipped} (not exactly one stream)\n"
        f"shows {report.shows}, vods registered {report.vods_created}\n"
        f"episodes: {report.episodes_created} new, {report.episodes_updated} updated"
    )
    return 0


async def _run(path: Path, limit: int | None) -> Report:
    try:
        return await seed(path, limit)
    finally:
        await engine.dispose()


if __name__ == "__main__":
    raise SystemExit(main())
