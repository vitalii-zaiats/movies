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
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    playlist_url TEXT NOT NULL UNIQUE,
    title        TEXT,
    poster       TEXT,
    created_at   TEXT NOT NULL
);
"""

DEFAULT_DB = Path(os.environ.get("VOD_DB", "data/vod.db"))


def initialise(path: Path) -> None:
    """Create the database and its one table. Safe to run again."""
    path.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(path) as connection:
        connection.execute("PRAGMA journal_mode=WAL")
        connection.executescript(SCHEMA)


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
