"""The whole pipeline in one call: page -> ashdi iframes -> .m3u8 streams.

Shared by the CLI and the HTTP API so both behave identically.
"""

from dataclasses import dataclass, field

import httpx

from ashdi_finder.fetcher import fetch_html
from ashdi_finder.finder import find_ashdi_iframes, is_ashdi_url
from ashdi_finder.player import Stream, extract_streams


class FetchError(Exception):
    """The page itself could not be downloaded."""


@dataclass(slots=True)
class PlayerResult:
    """One ashdi player page: where we found it and what it plays."""

    url: str
    attr: str
    html: str = ""
    streams: list[Stream] = field(default_factory=list)
    error: str | None = None

    def to_dict(self, include_html: bool = False) -> dict:
        return {
            "url": self.url,
            "attr": self.attr,
            "error": self.error,
            "streams": [
                {"url": s.url, "label": s.label, "source": s.source} for s in self.streams
            ],
            **({"html": self.html} if include_html else {}),
        }


@dataclass(slots=True)
class ResolveResult:
    source_url: str
    final_url: str
    players: list[PlayerResult]

    @property
    def streams(self) -> list[Stream]:
        return [s for p in self.players for s in p.streams]

    def to_dict(self, include_html: bool = False) -> dict:
        return {
            "source_url": self.source_url,
            "final_url": self.final_url,
            "count": len(self.players),
            "stream_count": len(self.streams),
            "players": [p.to_dict(include_html) for p in self.players],
        }


def resolve(
    url: str,
    *,
    timeout: float = 20.0,
    follow: bool = True,
    html: str | None = None,
    proxy: str | None = None,
) -> ResolveResult:
    """Scan `url` for ashdi iframes and, unless `follow` is off, open each one.

    `follow=False` means "make no extra requests" — a URL that is already a
    player page still gets parsed, since its HTML is in hand either way.

    Pass `html` to skip the first download and parse an already-fetched page.
    Raises `FetchError` only for the initial page; a player that fails to load
    lands in that `PlayerResult.error` instead.
    """
    if html is None:
        try:
            html, final_url = fetch_html(url, timeout=timeout, proxy=proxy)
        except httpx.HTTPError as exc:
            raise FetchError(str(exc)) from exc
    else:
        final_url = url

    # An ashdi URL is already the player page — no iframe hunting needed.
    if is_ashdi_url(final_url):
        player = PlayerResult(url=final_url, attr="direct", streams=extract_streams(html))
        return ResolveResult(url, final_url, [player])

    players = [
        _open_player(hit, referer=final_url, timeout=timeout, follow=follow, proxy=proxy)
        for hit in find_ashdi_iframes(html, base_url=final_url)
    ]
    return ResolveResult(url, final_url, players)


def _open_player(
    hit, *, referer: str, timeout: float, follow: bool, proxy: str | None = None
) -> PlayerResult:
    result = PlayerResult(url=hit.url, attr=hit.attr, html=hit.html)
    if not follow:
        return result

    try:
        player_html, _ = fetch_html(hit.url, timeout=timeout, referer=referer, proxy=proxy)
    except httpx.HTTPError as exc:
        result.error = str(exc)
        return result

    result.streams = extract_streams(player_html)
    return result
