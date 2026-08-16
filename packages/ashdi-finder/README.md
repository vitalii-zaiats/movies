# ashdi-finder

Takes a page URL, finds every `<iframe>` in the DOM that points at `ashdi.vip`,
opens each one and prints the `.m3u8` streams its player is configured with.

```bash
uv run ashdi-finder https://example.com/film/123
uv run ashdi-finder https://ashdi.vip/vod/167527      # player URL directly
uv run ashdi-finder <url> --no-follow                 # list iframes, no extra requests
uv run ashdi-finder <url> --json --show-html
uv run ashdi-finder <url> --html-file page.html       # offline, from a saved page
```

Exit codes: `0` — found streams, `1` — nothing found, `2` — the first page failed to load.

## How it works

1. **Iframes** — checks `src`, `data-src`, `data-lazy-src`, `data-litespeed-src`
   and `data-url` on every `<iframe>`, resolving relative and `//ashdi.vip/...`
   values against the page's final URL.
2. **Player** — fetches each iframe with the page as `Referer` and reads the
   `file` key out of `new Playerjs({...})`. That value can be a single URL, a
   comma-separated multi-quality list (`[720p]a.m3u8,[1080p]b.m3u8`), or a JSON
   playlist of seasons/episodes — season and episode titles come through as
   labels. If no player config is found, the page is swept for `.m3u8` URLs.

Server-rendered HTML only — iframes injected later by JS won't show up.
