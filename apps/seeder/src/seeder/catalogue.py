"""Talking to the catalogue API.

Over HTTP, not over its database: the API owns its schema, and this app is a
client like any other. The payloads are duplicated here as TypedDicts rather
than imported from the API package — the contract between the two is the
endpoint, not a shared module.

Note what this no longer does: push episodes. The catalogue pulls those from the
VOD service itself; all this asks for is that it goes and looks now.
"""

from collections.abc import Sequence
from dataclasses import dataclass
from typing import NotRequired, TypedDict

import httpx


class IngestEpisode(TypedDict):
    show_key: str
    title: str
    season: int
    episode: int
    source_url: str
    show_title: NotRequired[str | None]
    show_poster: NotRequired[str | None]
    episode_end: NotRequired[int | None]
    poster: NotRequired[str | None]
    vod_id: NotRequired[int | None]


class IngestShow(TypedDict, total=False):
    """What a crawl knows about a title itself, as `POST /ingest/shows` takes it.

    Every field but the key is optional and only what's sent is written, so a
    pass that knows the year and nothing else doesn't erase a synopsis.
    """

    key: str
    original_title: str | None
    year: int | None
    description: str | None
    duration: str | None
    age_rating: str | None
    genres: list[str] | None
    countries: list[str] | None
    directors: list[str] | None
    starring: list[str] | None
    imdb_id: str | None
    imdb_rating: float | None
    imdb_votes: int | None


@dataclass(frozen=True, slots=True)
class IngestReport:
    shows: int
    created: int
    updated: int

    def __add__(self, other: "IngestReport") -> "IngestReport":
        return IngestReport(
            shows=self.shows + other.shows,
            created=self.created + other.created,
            updated=self.updated + other.updated,
        )


EMPTY = IngestReport(shows=0, created=0, updated=0)


@dataclass(frozen=True, slots=True)
class SyncReport:
    """What one pull from the VOD service came to."""

    created: int
    updated: int
    skipped: int
    cursor: int


class CatalogueUnavailable(RuntimeError):
    """The API didn't answer, or refused the batch."""


class CatalogueWriter:
    def __init__(self, base_url: str, timeout: float = 60.0) -> None:
        self._base = base_url.rstrip("/")
        self._client = httpx.AsyncClient(timeout=timeout)

    async def __aenter__(self) -> "CatalogueWriter":
        return self

    async def __aexit__(self, *_: object) -> None:
        await self._client.aclose()

    async def ingest(self, items: Sequence[IngestEpisode]) -> IngestReport:
        if not items:
            return EMPTY

        try:
            response = await self._client.post(
                f"{self._base}/ingest/episodes", json={"items": list(items)}
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise CatalogueUnavailable(f"{self._base}: {exc}") from exc

        body = response.json()
        return IngestReport(
            shows=body["shows"], created=body["created"], updated=body["updated"]
        )

    async def sync(self) -> SyncReport:
        """Ask the catalogue to read the VOD service from where it left off."""
        try:
            response = await self._client.post(f"{self._base}/sync/vods", json={})
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise CatalogueUnavailable(f"{self._base}: {exc}") from exc

        body = response.json()
        return SyncReport(
            created=body["created"],
            updated=body["updated"],
            skipped=body["skipped"],
            cursor=body["cursor"],
        )

    async def describe(self, items: Sequence[IngestShow]) -> tuple[int, int]:
        """Fill in the titles themselves. Returns (updated, unknown)."""
        if not items:
            return 0, 0

        try:
            response = await self._client.post(
                f"{self._base}/ingest/shows", json={"items": list(items)}
            )
            response.raise_for_status()
        except httpx.HTTPError as exc:
            raise CatalogueUnavailable(f"{self._base}: {exc}") from exc

        body = response.json()
        return body["updated"], body["unknown"]
