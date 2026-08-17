"""What this package needs from whoever does the talking — and nothing more.

These are structural protocols, so this module imports no HTTP library and holds
no opinion about proxies, retries, timeouts or headers. Whoever calls us decides
all of that; `httpkit.build_fetcher()` happens to satisfy the shape without
either side importing the other.
"""

from typing import Protocol


class Response(Protocol):
    @property
    def text(self) -> str: ...

    @property
    def url(self) -> str:
        """Where the page came from *after* redirects.

        Relative iframe sources resolve against this, so it can't be the URL we
        asked for.
        """


class Fetcher(Protocol):
    def fetch(self, url: str, *, referer: str | None = None) -> Response: ...


class AsyncFetcher(Protocol):
    async def fetch(self, url: str, *, referer: str | None = None) -> Response: ...


class FetchError(Exception):
    """A page could not be fetched. The requester's own error is chained onto it."""
