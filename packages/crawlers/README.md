# crawlers

Listing-page crawlers. **Sources** say where the pages are and how to read them,
**sinks** say where the items go, and the engine walks one into the other using
a **fetcher** you provide.

```
source (a site)  ->  engine  ->  sink (stdout / jsonl / sqlite / your own)
                       ^
                    fetcher (yours; httpkit has a ready one)
```

The package depends on no HTTP library. `crawl` and `acrawl` take anything with
`fetch(url, *, referer=None) -> Response` — see `crawlers.fetching`. That's why
proxies and retries appear nowhere in here: they're the caller's business.

```python
from crawlers import acrawl, crawl, get

for page in crawl(get("kinoukr"), pages=3, fetcher=my_fetcher):
    print(page.number, len(page.items))

async for page in acrawl(get("simpsonsua"), fetcher=my_async_fetcher):
    ...
```

## Adding a source

Drop a module into `src/crawlers/sources/`. Nothing else changes — the registry
imports everything in that folder, so `@register` is all the wiring there is.

```python
from crawlers.models import Item
from crawlers.source import Source, register

@register
class MySite(Source):
    name = "mysite"

    def page_url(self, number: int) -> str:
        return f"https://mysite.tv/page/{number}/"

    def parse(self, html: str) -> list[Item]:
        return [Item(title=..., url=..., poster=...)]
```

Site-specific fields that don't fit `title/url/poster` go in `Item.extra` — they
land flat in the sink output.

A source that isn't paginated — one sitemap, one feed — sets `paginated = False`
and returns the same URL from `page_url`. The engine then reads it once and
ignores any page count it was given.

Registered today: `kinoukr` (listing pages) and `simpsonsua` (sitemap.xml, with
show key / season / episode parsed out of the URLs).

## Sinks

| spec            | what it does                                                  |
|-----------------|---------------------------------------------------------------|
| `stdout`        | prints items as they arrive (the CLI default)                  |
| `jsonl:<path>`  | appends one JSON object per line, skipping URLs already there  |
| `sqlite:<path>` | one row per URL in an `items` table, with `first_seen`         |
| `memory`        | keeps them in a list, for in-process use                       |

Both stored sinks are idempotent on URL — jsonl reads the file's URLs first,
sqlite uses `url` as the primary key with `ON CONFLICT DO NOTHING` — so
re-running a crawl adds only what's new. A bare path works too when the
extension is unambiguous (`.jsonl`, `.db`, `.sqlite`, `.sqlite3`).

The sqlite table:

```sql
items(url PRIMARY KEY, source, title, poster, extra JSON, first_seen)
```

`first_seen` is written on insert only, so it keeps the moment an item first
appeared rather than the last time it was crawled.

Your own sink just needs `write(items)` (returning how many were new) and
`close()`.

## Entry points

The CLI is one of them — for looking at a source by hand:

```bash
uv run crawl --list             # registered sources
uv run crawl kinoukr 3          # 3 pages to stdout
uv run crawl kinoukr 5 --sink jsonl:data/kinoukr.jsonl
uv run crawl kinoukr 2 --json
```

The others are `run` / `arun`, which drain a crawl and return `Stats` for an app
that wants the numbers rather than the pages, and `crawl` / `acrawl`, the raw
generators — [`apps/episode-resolver`](../../apps/episode-resolver) uses the
async one.

The CLI needs a working requester, so it pulls `httpkit` through the optional
`crawlers[cli]` extra and imports it lazily. The library itself installs only a
parser.
