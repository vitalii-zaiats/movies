# ashdi-finder

Finds every `<iframe>` in a page that points at `ashdi.vip`, opens each one and
reports the `.m3u8` streams its player is configured with.

**It does not know how to make an HTTP request.** You hand it something that
does. That keeps proxies, retries, timeouts and headers where they belong — in
the application — and makes the whole thing testable with a canned string.

```python
from ashdi_finder import resolve, aresolve

result = resolve("https://example.com/film/123", fetcher=my_fetcher)
result = await aresolve("https://example.com/film/123", fetcher=my_async_fetcher)

for stream in result.streams:
    print(stream.label, stream.url)
```

## The fetcher

Anything with this shape will do — it's a structural `Protocol`, so nothing
needs to subclass or import anything:

```python
class Fetcher(Protocol):
    def fetch(self, url: str, *, referer: str | None = None) -> Response: ...

class Response(Protocol):
    text: str
    url: str   # after redirects; relative iframe sources resolve against it
```

`httpkit.build_fetcher()` is the ready-made one (httpx underneath, with rotating
proxies and 429 backoff). It's an **optional** dependency, pulled in by
`ashdi-finder[cli]` — the package itself installs nothing but a parser, so a
requester built on raw sockets is a first-class option, not a workaround.

Whatever your fetcher raises is wrapped in `FetchError` with the original
exception chained. Only the first page raises; a player that fails to load lands
in its own `PlayerResult.error`.

## Sync and async

The parsing — `find_ashdi_iframes`, `extract_streams` — is pure and shared.
`resolve` and `aresolve` are thin sequencers over the same decisions in
`results.py`, so the two can differ in how they wait and in nothing else.

## CLI

```bash
uv run ashdi-finder https://ashdi.vip/vod/167527
uv run ashdi-finder <url> --no-follow            # list iframes, no extra requests
uv run ashdi-finder <url> --json --show-html
uv run ashdi-finder <url> --html-file page.html  # offline, from a saved page
uv run ashdi-finder <url> --proxy @proxies.txt   # or $PROXY_URL
```

Exit codes: `0` — found streams, `1` — nothing found, `2` — the first page failed.

## How it works

1. **Iframes** — checks `src`, `data-src`, `data-lazy-src`, `data-litespeed-src`
   and `data-url`, resolving relative and `//ashdi.vip/...` values against the
   page's final URL.
2. **Player** — fetches each iframe with the page as `Referer` and reads the
   `file` key out of `new Playerjs({...})`: a single URL, a comma-separated
   multi-quality list (`[720p]a.m3u8,[1080p]b.m3u8`), or a JSON playlist of
   seasons and episodes whose titles come through as labels. If no player config
   is found, the page is swept for `.m3u8` URLs.

Server-rendered HTML only — iframes injected later by JS won't show up.
