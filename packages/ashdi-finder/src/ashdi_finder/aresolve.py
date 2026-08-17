"""The same pipeline, awaited.

The twin of `resolve`: identical decisions, taken from `results`, differing only
in how it waits. If you change one, the other almost certainly needs the same
edit — which is why every judgement call was pushed out of both.
"""

from ashdi_finder import results as core
from ashdi_finder.fetching import AsyncFetcher, FetchError, Response
from ashdi_finder.results import ResolveResult


async def aresolve(
    url: str,
    *,
    fetcher: AsyncFetcher,
    follow: bool = True,
    html: str | None = None,
) -> ResolveResult:
    if html is None:
        page = await afetch(fetcher, url)
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
            page = await afetch(fetcher, hit.url, referer=final_url)
        except FetchError as exc:
            players.append(core.failed(hit, exc))
            continue
        players.append(core.opened(hit, page.text))

    return ResolveResult(url, final_url, players)


async def afetch(fetcher: AsyncFetcher, url: str, referer: str | None = None) -> Response:
    try:
        return await fetcher.fetch(url, referer=referer)
    except FetchError:
        raise
    except Exception as exc:
        raise FetchError(f"{url}: {exc}") from exc
