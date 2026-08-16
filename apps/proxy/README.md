# proxy

An async (aiohttp) server that does one thing: fetch a URL and stream it back
with `Access-Control-Allow-Origin: *`. No UI, no API, no other routes.

```bash
uv run proxy                              # 127.0.0.1:8001
uv run proxy --port 9000
uv run proxy --allow-host ashdi.vip       # refuse everything else
```

```
GET /?url=<absolute http(s) URL>
```

Also answers `HEAD` (same route, no body) and `OPTIONS` (CORS preflight).
`400` on a missing/bad `url`, `403` when an allowlist is set and the host isn't
on it, `502` when the origin fails. Every other status comes from the origin.

## What it does on the way through

- **Streams** in 64 KB chunks — never buffers a segment in memory.
- **Forwards `Range`/`If-Range`**, returns `Content-Range`/`Accept-Ranges`, so
  seeking and byte-range segments work; `206` passes through untouched.
- **Sets `Referer`/`Origin` to the target's own origin**, because HLS hosts
  routinely reject requests refered from somewhere else.
- **Rewrites `.m3u8` bodies** so nested URLs — variant playlists, segments and
  `URI="..."` attributes in `#EXT-X-KEY` / `#EXT-X-MAP` / `#EXT-X-MEDIA` — point
  back at the proxy. Without this the player reads the master playlist through
  the proxy and then fetches everything else directly, which is the exact
  request CORS blocks. Rewritten links are relative (`/?url=...`), so the proxy
  doesn't care what host it's reached on.

## Careful

With no `--allow-host` this is an open proxy: it will fetch anything the machine
can reach, private addresses included. It binds to `127.0.0.1` for that reason.
Don't expose it without an allowlist.
