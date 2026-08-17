"""Walks a source's pages and hands every item to a sink."""

import time
from collections.abc import Iterator
from dataclasses import dataclass, replace
from typing import TypedDict

import httpx

from crawlers.http import client
from crawlers.models import Page
from crawlers.sinks import Sink
from crawlers.source import Source


class StatsPayload(TypedDict):
    source: str
    pages: int
    failed: int
    found: int
    stored: int


@dataclass(slots=True)
class Stats:
    source: str
    pages: int = 0
    failed: int = 0
    found: int = 0
    stored: int = 0

    def to_dict(self) -> StatsPayload:
        return StatsPayload(
            source=self.source,
            pages=self.pages,
            failed=self.failed,
            found=self.found,
            stored=self.stored,
        )


def crawl(
    source: Source,
    pages: int = 1,
    start: int = 1,
    *,
    timeout: float = 20.0,
    delay: float = 0.5,
    proxy: str | None = None,
) -> Iterator[Page]:
    """Yield `pages` listing pages, one request at a time.

    A page that fails to load is yielded with `error` set rather than raising,
    so one bad page doesn't end the run. Storing is the caller's job — see `run`.
    """
    if not source.paginated:
        pages, start = 1, 1  # one document, asking for more would just refetch it

    with client(timeout=timeout, proxy=proxy) as http:
        for offset in range(pages):
            number = start + offset
            url = source.page_url(number)

            if offset and delay:
                time.sleep(delay)  # don't hammer the site

            try:
                response = http.get(url)
                response.raise_for_status()
            except httpx.HTTPError as exc:
                yield Page(source=source.name, number=number, url=url, items=[], error=str(exc))
                continue

            items = [replace(item, source=source.name) for item in source.parse(response.text)]
            yield Page(source=source.name, number=number, url=url, items=items)


def run(
    source: Source,
    pages: int = 1,
    start: int = 1,
    *,
    sink: Sink,
    timeout: float = 20.0,
    delay: float = 0.5,
    proxy: str | None = None,
) -> Stats:
    """Same crawl, but drained to completion and summarised. What apps call."""
    stats = Stats(source=source.name)

    for page in crawl(source, pages, start, timeout=timeout, delay=delay, proxy=proxy):
        stats.pages += 1
        if page.error:
            stats.failed += 1
            continue
        stats.found += len(page.items)
        stats.stored += sink.write(page.items)

    return stats
