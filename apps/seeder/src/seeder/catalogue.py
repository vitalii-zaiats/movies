"""Handing episodes to the catalogue API.

Over HTTP, not over its database: the API owns its schema, and this app is a
client like any other. The payload is duplicated here as a TypedDict rather than
imported from the API package — the contract between the two is the endpoint,
not a shared module.
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
    episode_end: NotRequired[int | None]
    poster: NotRequired[str | None]
    vod_id: NotRequired[int | None]


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
