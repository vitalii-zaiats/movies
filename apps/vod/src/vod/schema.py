"""Preparing the database — deliberately not something the service does on boot.

A process that creates its own schema hides a deployment step and will happily
start against the wrong file, or an empty one, and look healthy. Preparing
storage is a separate action: by hand, from a script, from Ansible, or from the
one-shot `vod-init` container in compose.
"""

import argparse
import os
import sqlite3
from pathlib import Path

SCHEMA = """
CREATE TABLE IF NOT EXISTS vods (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    -- What the source is, and therefore how it's served: a playlist we relay
    -- and rewrite, or a resource we hand out in byte ranges. A torrent is the
    -- second kind with a different transport, not a third kind.
    kind           TEXT NOT NULL DEFAULT 'hls',
    playlist_url   TEXT NOT NULL UNIQUE,
    -- The playlist as it was when we could still fetch it. This is what makes
    -- the service a source of truth rather than a pass-through: a VOD's
    -- playlist never changes, so holding it is both safe and the whole point.
    playlist_cache TEXT,
    cached_at      TEXT,
    -- Carried, not interpreted. Poster, title, whatever the catalogue wants
    -- back later — none of it is this service's business.
    metadata       TEXT NOT NULL DEFAULT '{}',
    created_at     TEXT NOT NULL
);
"""

# Columns added after the first version. `vod-init` is idempotent and the only
# migration this service has: one table, and a list of what may be missing.
ADDED = {
    "kind": "TEXT NOT NULL DEFAULT 'hls'",
    "playlist_cache": "TEXT",
    "cached_at": "TEXT",
    "metadata": "TEXT NOT NULL DEFAULT '{}'",
}

DEFAULT_DB = Path(os.environ.get("VOD_DB", "data/vod.db"))


def initialise(path: Path) -> None:
    """Create the database and its one table, and catch it up. Safe to run again."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(path) as connection:
        connection.execute("PRAGMA journal_mode=WAL")
        connection.executescript(SCHEMA)

        # An older database keeps its rows and gains the columns. The alternative
        # is asking somebody to drop a table full of registered VODs, which is a
        # rude way to add a nullable field.
        present = {row[1] for row in connection.execute("PRAGMA table_info(vods)")}
        for column, definition in ADDED.items():
            if column not in present:
                connection.execute(f"ALTER TABLE vods ADD COLUMN {column} {definition}")

        # `title` and `poster` were columns before metadata was a thing; fold
        # whatever they hold into the blob, once.
        if {"title", "poster"} & present:
            connection.execute(
                """
                UPDATE vods
                   SET metadata = json_object('title', title, 'poster', poster)
                 WHERE metadata = '{}' AND (title IS NOT NULL OR poster IS NOT NULL)
                """
            )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="vod-init", description="Prepare the VOD database before the service runs"
    )
    parser.add_argument("--db", type=Path, default=DEFAULT_DB, help=f"default: {DEFAULT_DB}")
    args = parser.parse_args(argv)

    initialise(args.db)
    print(f"ready: {args.db}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
