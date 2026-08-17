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
    # One entry per way to hear this episode. A page can offer the same episode
    # in two voices, and which one somebody wants is not the crawler's call.
    tracks: NotRequired[list[dict[str, str | None]]]
    error: NotRequired[str]


def read(path: Path) -> Iterator[ResolvedRecord]:
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line:
                yield cast(ResolvedRecord, json.loads(line))


def playable(record: ResolvedRecord) -> list[tuple[str, str | None]]:
    """Every stream worth registering, as `(url, dub)`.

    A record that named its tracks gets one entry per voice — they are different
    things to play, and choosing between them belongs to whoever is watching.
    An older record has a flat list of streams and nothing to say about them; a
    single one is registered nameless, and several unlabelled ones are left
    alone, because picking between identical-looking URLs is a guess.
    """
    tracks = record.get("tracks") or []
    if tracks:
        return [
            (str(track["stream"]), track.get("audio"))
            for track in tracks
            if track.get("stream")
        ]

    streams = record.get("streams") or []
    return [(streams[0], None)] if len(streams) == 1 else []
