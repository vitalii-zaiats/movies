"""SQLite storage for VODs.

Deliberately no migration tool: this service owns one table with one required
column. But no implicit setup either — the schema is created by `vod-init`
before the service runs, and starting without it is an error, not a cue to
improvise. See `vod.schema`.
"""

import asyncio
import json
import sqlite3
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any


class SchemaMissing(RuntimeError):
    """The database hasn't been prepared."""


@dataclass(frozen=True, slots=True)
class Vod:
    """One playable thing, as this service knows it.

    `playlist_url` is the only field that has to be true. `metadata` is carried
    for whoever registered it — a poster, a title, whatever the catalogue would
    otherwise have to go and find again — and this service never reads it.
    """

    id: int
    kind: str
    playlist_url: str
    created_at: str
    # What was served last time it could be fetched. A VOD's playlist doesn't
    # change, so this is a copy rather than a cache with a staleness problem.
    playlist_cache: str | None = None
    cached_at: str | None = None
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def title(self) -> str | None:
        """Kept as a property because the whole repo already asks for it."""
        value = self.metadata.get("title")
        return value if isinstance(value, str) else None

    @property
    def poster(self) -> str | None:
        value = self.metadata.get("poster")
        return value if isinstance(value, str) else None


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
        self,
        playlist_url: str,
        metadata: dict[str, Any] | None = None,
        kind: str = "hls",
    ) -> tuple[Vod, bool]:
        """Register a source. Returns `(vod, created)` — idempotent on the URL."""
        return await asyncio.to_thread(self._create, playlist_url, metadata or {}, kind)

    async def keep_playlist(self, vod_id: int, body: str) -> None:
        """Remember what was served, so the next viewer doesn't depend on upstream."""
        await asyncio.to_thread(self._keep_playlist, vod_id, body)

    async def get(self, vod_id: int) -> Vod | None:
        return await asyncio.to_thread(self._get, vod_id)

    # Not `list`: inside a class body that name would shadow the builtin and
    # break every `list[...]` annotation below it.
    async def page(self, limit: int = 50, after_id: int = 0) -> list[Vod]:
        return await asyncio.to_thread(self._page, limit, after_id)

    async def count(self) -> int:
        return await asyncio.to_thread(self._count)

    def _create(
        self, playlist_url: str, metadata: dict[str, Any], kind: str
    ) -> tuple[Vod, bool]:
        """Insert, or teach the existing row what the registrar now knows.

        Two statements rather than one clever upsert: `ON CONFLICT DO UPDATE`
        reports the same `rowcount` for both, and then "did this exist already"
        — the question the whole idempotent seed rests on — can't be answered.
        """
        now = datetime.now(UTC).isoformat(timespec="seconds")
        blob = json.dumps(metadata, ensure_ascii=False)

        with self._connect() as connection:
            row = connection.execute(
                "SELECT * FROM vods WHERE playlist_url = ?", (playlist_url,)
            ).fetchone()

            if row is None:
                connection.execute(
                    """
                    INSERT INTO vods (kind, playlist_url, metadata, created_at)
                    VALUES (?, ?, ?, ?)
                    """,
                    (kind, playlist_url, blob, now),
                )
                created = True
            else:
                created = False
                # An empty blob is somebody who knows less; leave what's there.
                if metadata:
                    connection.execute(
                        "UPDATE vods SET metadata = ? WHERE id = ?", (blob, row["id"])
                    )

            fresh = connection.execute(
                "SELECT * FROM vods WHERE playlist_url = ?", (playlist_url,)
            ).fetchone()

        return _row(fresh), created

    def _keep_playlist(self, vod_id: int, body: str) -> None:
        now = datetime.now(UTC).isoformat(timespec="seconds")
        with self._connect() as connection:
            connection.execute(
                "UPDATE vods SET playlist_cache = ?, cached_at = ? WHERE id = ?",
                (body, now, vod_id),
            )

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
        kind=row["kind"] or "hls",
        playlist_url=row["playlist_url"],
        created_at=row["created_at"],
        playlist_cache=row["playlist_cache"],
        cached_at=row["cached_at"],
        metadata=_metadata(row["metadata"]),
    )


def _metadata(raw: str | None) -> dict[str, Any]:
    """Whatever was handed in, or nothing. A bad blob is not worth a 500."""
    try:
        value = json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        return {}
    return value if isinstance(value, dict) else {}
