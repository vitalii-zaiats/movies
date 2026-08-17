"""Reading what the resolver wrote."""

import json
from collections.abc import Iterator
from pathlib import Path
from typing import NotRequired, TypedDict, cast


class ResolvedRecord(TypedDict):
    """One line of `resolve-episodes` output, as far as seeding cares.

    Everything but the source URL is optional: the file is written by whichever
    source ran, and a record for an episode nothing was found for carries little.
    """

    url: str
    title: NotRequired[str]
    key: NotRequired[str]
    season: NotRequired[int]
    episode: NotRequired[int]
    episode_end: NotRequired[int | None]
    poster: NotRequired[str | None]
    streams: NotRequired[list[str]]
    players: NotRequired[list[str]]
    error: NotRequired[str]


def read(path: Path) -> Iterator[ResolvedRecord]:
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                yield cast(ResolvedRecord, json.loads(line))


def single_stream(record: ResolvedRecord) -> str | None:
    """The one playlist to register, if there's exactly one.

    Zero means nothing was found; more than one is a choice nobody has made yet,
    and guessing here would put the wrong stream in the catalogue.
    """
    streams = record.get("streams") or []
    return streams[0] if len(streams) == 1 else None
