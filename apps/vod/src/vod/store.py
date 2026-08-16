"""SQLite storage for VODs.

Deliberately no migration tool here: this service owns one table with one
required column, and `CREATE TABLE IF NOT EXISTS` at startup is the whole story.
The API is the one with a schema worth versioning.
"""

import asyncio
import sqlite3
from dataclasses import dataclass
from datetime import UTC, datetime
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


@dataclass(frozen=True, slots=True)
class Vod:
    id: int
    playlist_url: str
    title: str | None
    poster: str | None
    created_at: str


class VodStore:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.path.parent.mkdir(parents=True, exist_ok=True)
        with self._connect() as connection:
            connection.execute("PRAGMA journal_mode=WAL")
            connection.executescript(SCHEMA)

    def _connect(self) -> sqlite3.Connection:
        connection = sqlite3.connect(self.path, timeout=10)
        connection.row_factory = sqlite3.Row
        return connection

    async def create(
        self, playlist_url: str, title: str | None = None, poster: str | None = None
    ) -> tuple[Vod, bool]:
        """Register a playlist. Returns `(vod, created)` — idempotent on the URL."""
        return await asyncio.to_thread(self._create, playlist_url, title, poster)

    async def get(self, vod_id: int) -> Vod | None:
        return await asyncio.to_thread(self._get, vod_id)

    # Not `list`: inside a class body that name would shadow the builtin and
    # break every `list[...]` annotation below it.
    async def page(self, limit: int = 50, after_id: int = 0) -> list[Vod]:
        return await asyncio.to_thread(self._page, limit, after_id)

    async def count(self) -> int:
        return await asyncio.to_thread(self._count)

    def _create(
        self, playlist_url: str, title: str | None, poster: str | None
    ) -> tuple[Vod, bool]:
        now = datetime.now(UTC).isoformat(timespec="seconds")
        with self._connect() as connection:
            cursor = connection.execute(
                """
                INSERT INTO vods (playlist_url, title, poster, created_at)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(playlist_url) DO NOTHING
                """,
                (playlist_url, title, poster, now),
            )
            created = bool(cursor.rowcount)
            row = connection.execute(
                "SELECT * FROM vods WHERE playlist_url = ?", (playlist_url,)
            ).fetchone()
        return _row(row), created

    def _get(self, vod_id: int) -> Vod | None:
        with self._connect() as connection:
            row = connection.execute("SELECT * FROM vods WHERE id = ?", (vod_id,)).fetchone()
        return _row(row) if row else None

    def _page(self, limit: int, after_id: int) -> list[Vod]:
        with self._connect() as connection:
            rows = connection.execute(
                "SELECT * FROM vods WHERE id > ? ORDER BY id LIMIT ?",
                (after_id, max(1, min(limit, 500))),
            ).fetchall()
        return [_row(row) for row in rows]

    def _count(self) -> int:
        with self._connect() as connection:
            return int(connection.execute("SELECT count(*) FROM vods").fetchone()[0])


def _row(row: sqlite3.Row) -> Vod:
    return Vod(
        id=row["id"],
        playlist_url=row["playlist_url"],
        title=row["title"],
        poster=row["poster"],
        created_at=row["created_at"],
    )
