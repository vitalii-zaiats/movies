"""The same walk, awaited.

Twin of `engine`: identical decisions — page numbers, what a page means, when to
give up on one — differing only in how it waits.
"""

import asyncio
from collections.abc import AsyncIterator

from crawlers.fetching import AsyncFetcher
from crawlers.models import Page, Stats
from crawlers.sinks import Sink
from crawlers.source import Source, page_numbers


async def acrawl(
    source: Source,
    pages: int = 1,
    start: int = 1,
    *,
    fetcher: AsyncFetcher,
    delay: float = 0.5,
) -> AsyncIterator[Page]:
    for index, number in enumerate(page_numbers(source, pages, start)):
        url = source.page_url(number)

        if index and delay:
            await asyncio.sleep(delay)

        try:
            page = await fetcher.fetch(url)
        except Exception as exc:  # whatever the injected requester raises
            yield Page.broken(source.name, number, url, str(exc))
            continue

        yield Page.of(source.name, number, url, source.parse(page.text))


async def arun(
    source: Source,
    pages: int = 1,
    start: int = 1,
    *,
    sink: Sink,
    fetcher: AsyncFetcher,
    delay: float = 0.5,
) -> Stats:
    stats = Stats(source=source.name)

    async for page in acrawl(source, pages, start, fetcher=fetcher, delay=delay):
        stats.pages += 1
        if page.error:
            stats.failed += 1
            continue
        stats.found += len(page.items)
        stats.stored += sink.write(page.items)

    return stats
