"""What a crawl produces. Sources fill these in, sinks consume them."""

from collections.abc import Mapping
from dataclasses import dataclass, field
from typing import Any, TypedDict, cast


class ItemPayload(TypedDict):
    """The flat JSON shape sinks store.

    Source-specific fields ride along *beside* these rather than nested under a
    key of their own, because that's what the sinks and the seeder read.
    """

    source: str
    title: str
    url: str
    poster: str | None


class PagePayload(TypedDict):
    source: str
    page: int
    url: str
    error: str | None
    items: list[ItemPayload]


@dataclass(frozen=True, slots=True)
class Item:
    title: str
    url: str
    poster: str | None = None
    source: str = ""
    # Anything a particular site offers that others don't (kind, rating, year...).
    # Open by nature — each source decides — so it stays a mapping.
    extra: Mapping[str, Any] = field(default_factory=dict)

    def to_dict(self) -> ItemPayload:
        payload = ItemPayload(
            source=self.source, title=self.title, url=self.url, poster=self.poster
        )
        if not self.extra:
            return payload
        # The extras are merged flat; the cast says so out loud.
        return cast(ItemPayload, {**payload, **self.extra})


@dataclass(slots=True)
class Page:
    source: str
    number: int
    url: str
    items: list[Item]
    error: str | None = None

    def to_dict(self) -> PagePayload:
        return PagePayload(
            source=self.source,
            page=self.number,
            url=self.url,
            error=self.error,
            items=[item.to_dict() for item in self.items],
        )
