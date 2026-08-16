# episode-resolver

Crawls a show's episode list with [`crawlers`](../../packages/crawlers), then
opens every episode page with [`ashdi-finder`](../../packages/ashdi-finder) and
stores the `.m3u8` streams it plays.

The two packages don't know about each other — this app is the only thing that
imports both. Adding a source or a stream host stays a change in one package.

```bash
uv run resolve-episodes family-guy --keys      # which shows the source has
uv run resolve-episodes family-guy             # all of them
uv run resolve-episodes family-guy --limit 5   # a taste
uv run resolve-episodes simpsony --workers 8 --sink jsonl:data/simpsony.jsonl
```

```
family-guy S23E20         1  https://ashdi.vip/video16/2/serials/family_guy_s23e20_.../index.m3u8
```

## Details

- Episodes come from `--source` (default `simpsonsua`) filtered by the show key
  the source parsed out of the URL, then sorted by season and episode.
- Pages are fetched `--workers` at a time (4 by default). The episode list
  itself is one request — the source's sitemap.
- Output goes to the crawler sinks, default `jsonl:data/<key>-streams.jsonl`.
  Each record is the episode item with `players` and `streams` added to it, so
  the season/episode fields ride along.
- An episode that fails to load is written with an `error` field and reported on
  stderr; the run keeps going. Exit `1` if nothing at all resolved.
- Hundreds of episode pages in a row is what gets you rate-limited. Point
  `--proxy` (or `$PROXY_URL`) at a rotating residential gateway and 429s are
  retried on a fresh exit IP — see [`httpkit`](../../packages/httpkit). Lowering
  `--workers` helps too.

Note that `sqlite:` sinks key on URL and skip rows they already have, so
re-resolving into an existing database won't refresh it — use a jsonl sink or a
fresh file for that.
