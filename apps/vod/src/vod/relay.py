"""Fetching upstream media — always through apps/proxy, always server-side.

The browser talks to vod and to nothing else. vod talks to the proxy. The proxy
talks to the origin. Nobody downstream ever sees an upstream URL.

The proxy rewrites playlists to its own relative form (`/?url=<encoded>`). Those
links can't be handed to a player as they are: the player resolves them against
the URL *it* asked for, which is ours, not the proxy's. So every one of them is
rewritten again to point back at this service.
"""

import re
from collections.abc import AsyncIterator
from urllib.parse import quote, urlsplit

import httpx

# What apps/proxy leaves behind in a playlist, on lines and in URI="..." attrs.
PROXY_LINK_RE = re.compile(r"/\?url=([^\s\"'<>]+)")

PLAYLIST_HEADERS = {"Cache-Control": "no-store"}
PASS_THROUGH = ("content-type", "content-length", "content-range", "accept-ranges")


def is_playlist(url: str) -> bool:
    return urlsplit(url).path.lower().endswith(".m3u8")


class Relay:
    def __init__(self, proxy_url: str, timeout: float = 30.0) -> None:
        self._proxy = proxy_url.rstrip("/")
        self._client = httpx.AsyncClient(timeout=timeout, follow_redirects=True)

    async def aclose(self) -> None:
        await self._client.aclose()

    def _through(self, url: str) -> str:
        return f"{self._proxy}/?url={quote(url, safe='')}"

    async def playlist(self, vod_id: int, upstream: str) -> tuple[int, str, str]:
        """Return `(status, body, content_type)` with links pointing back at us."""
        response = await self._client.get(self._through(upstream))
        body = PROXY_LINK_RE.sub(
            lambda match: f"/{vod_id}/media?u={match.group(1)}", response.text
        )
        content_type = response.headers.get("content-type", "application/vnd.apple.mpegurl")
        return response.status_code, body, content_type

    async def open(
        self, upstream: str, range_header: str | None
    ) -> tuple[httpx.Response, AsyncIterator[bytes]]:
        """Start a streamed fetch. The caller must close the response."""
        request = self._client.build_request(
            "GET",
            self._through(upstream),
            headers={"Range": range_header} if range_header else None,
        )
        response = await self._client.send(request, stream=True)
        return response, response.aiter_bytes(64 * 1024)

    @staticmethod
    def headers_from(response: httpx.Response) -> dict[str, str]:
        return {
            name: value
            for name in PASS_THROUGH
            if (value := response.headers.get(name)) is not None
        }
