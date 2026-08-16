"""What a crawl produces. Sources fill these in, sinks consume them."""

from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class Item:
    title: str
    url: str
    poster: str | None = None
    source: str = ""
    # Anything a particular site offers that others don't (kind, rating, year...).
    extra: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        data = {
            "source": self.source,
            "title": self.title,
            "url": self.url,
            "poster": self.poster,
        }
        return {**data, **self.extra} if self.extra else data


@dataclass(slots=True)
class Page:
    source: str
    number: int
    url: str
    items: list[Item]
    error: str | None = None

    def to_dict(self) -> dict:
        return {
            "source": self.source,
            "page": self.number,
            "url": self.url,
            "error": self.error,
            "items": [i.to_dict() for i in self.items],
        }
