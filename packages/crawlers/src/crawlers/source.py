"""The one interface a site has to implement, plus the registry that finds it.

Adding a site means dropping a module into `crawlers/sources/` with a class that
subclasses `Source` and carries `@register`. Nothing else has to be touched —
the package imports everything in that folder on startup.
"""

from abc import ABC, abstractmethod
from typing import ClassVar

from crawlers.models import Item

REGISTRY: dict[str, type["Source"]] = {}


class UnknownSource(LookupError):
    """Asked for a source that isn't registered. Plain LookupError, so that
    printing it doesn't wrap the message in quotes the way KeyError does."""


class Source(ABC):
    """A listing on one site — paginated, or a single document like a sitemap."""

    name: ClassVar[str]

    # False means there is exactly one document to read; the engine then ignores
    # the page count instead of fetching the same URL over and over.
    paginated: ClassVar[bool] = True

    @abstractmethod
    def page_url(self, number: int) -> str:
        """Absolute URL of listing page `number` (1-based)."""

    @abstractmethod
    def parse(self, html: str) -> list[Item]:
        """Items on one listing page, in document order."""


def register(cls: type[Source]) -> type[Source]:
    if not getattr(cls, "name", None):
        raise ValueError(f"{cls.__name__} needs a `name`")
    if cls.name in REGISTRY and REGISTRY[cls.name] is not cls:
        raise ValueError(f"two sources claim the name {cls.name!r}")
    REGISTRY[cls.name] = cls
    return cls


def get(name: str) -> Source:
    _load()
    if name not in REGISTRY:
        raise UnknownSource(f"unknown source {name!r} — have: {', '.join(names())}")
    return REGISTRY[name]()


def names() -> list[str]:
    _load()
    return sorted(REGISTRY)


def _load() -> None:
    """Import every module under `crawlers.sources` so decorators run."""
    import importlib
    import pkgutil

    import crawlers.sources as package

    for module in pkgutil.iter_modules(package.__path__):
        importlib.import_module(f"{package.__name__}.{module.name}")
