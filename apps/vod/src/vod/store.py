"""SQLite storage for VODs.

Deliberately no migration tool: this service owns one table with one required
column. But no implicit setup either — the schema is created by `vod-init`
before the service runs, and starting without it is an error, not a cue to
improvise. See `vod.schema`.
"""

import asyncio
import sqlite3
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path


class SchemaMissing(RuntimeError):
    """The database hasn't been prepared."""


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

    def check(self) -> None:
        """Refuse to run against storage nobody prepared.

        Called at startup so the failure says what to do, instead of the service
        coming up healthy on an empty database it made itself.
        """
        fix = f"run `vod-init --db {self.path}` first"
        if not self.path.exists():
            raise SchemaMissing(f"no database at {self.path} — {fix}")

        with self._connect() as connection:
            table = connection.execute(
                "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'vods'"
            ).fetchone()

        if table is None:
            raise SchemaMissing(f"{self.path} has no `vods` table — {fix}")

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
