"""Page → ashdi iframes → .m3u8 streams, synchronously.

Every decision lives in `results`; this module only sequences requests. It never
imports an HTTP library — the requester arrives as an argument, so it can be
httpx, a socket you drive yourself, or a canned response in a test.
"""

from ashdi_finder import results as core
from ashdi_finder.fetching import Fetcher, FetchError, Response
from ashdi_finder.results import ResolveResult


def resolve(
    url: str,
    *,
    fetcher: Fetcher,
    follow: bool = True,
    html: str | None = None,
) -> ResolveResult:
    """Scan `url` for ashdi iframes and, unless `follow` is off, open each one.

    `follow=False` means "make no extra requests". Pass `html` to skip the first
    request entirely and work from a page you already have.

    Raises `FetchError` only for the first page; a player that fails to load
    lands in its own `PlayerResult.error`.
    """
    if html is None:
        page = fetch(fetcher, url)
        html, final_url = page.text, page.url
    else:
        final_url = url

    if core.is_player_page(final_url):
        return core.direct(url, final_url, html)

    players = []
    for hit in core.hits_in(html, final_url):
        if not follow:
            players.append(core.unopened(hit))
            continue
        try:
            page = fetch(fetcher, hit.url, referer=final_url)
        except FetchError as exc:
            players.append(core.failed(hit, exc))
            continue
        players.append(core.opened(hit, page.text))

    return ResolveResult(url, final_url, players)


def fetch(fetcher: Fetcher, url: str, referer: str | None = None) -> Response:
    """Call the injected requester and normalise however it failed.

    Broad on purpose: we don't know what the caller's requester raises — httpx
    errors, socket errors, something of their own — and it isn't our business.
    """
    try:
        return fetcher.fetch(url, referer=referer)
    except FetchError:
        raise
    except Exception as exc:
        raise FetchError(f"{url}: {exc}") from exc
