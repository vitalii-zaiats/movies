# vod

The VOD microservice, and **the source of truth for anything playable**. One row
is one playable thing:

```python
VOD(
    id=1,
    kind="hls",                    # a playlist we relay, or bytes we serve in ranges
    playlist_url="https://…/index.m3u8",
    playlist_cache="#EXTM3U…",     # what was served, kept
    metadata={"show_key": …, "kind": "film", "audio": "Стругачка", …},
)
```

Two of those are worth dwelling on:

- **`playlist_cache`** is why this is a source of truth rather than a hop. A
  VOD's playlist doesn't change, so the first fetch is kept and every later
  viewer is served from it — the day the origin rotates its URLs, what we
  already hold still plays.
- **`metadata`** is carried and never read. It exists so [`apps/api`](../api)
  can build its catalogue by walking this list instead of going and finding the
  same facts a second time. Whatever isn't put in it there is nothing else in
  the system to learn it from.

Two faces, one process:

- **gRPC** (`:50051`) — `vod.v1.VodService` from [`contracts`](../../packages/contracts).
  `CreateVod` is how whoever crawled a stream registers it; `ListVods(after_id)`
  is how the catalogue reads this list from wherever it left off.
- **HTTP** (`:8030`) — what a player talks to: `http://vod.localhost:8030/1`.

```bash
uv run vod-init       # prepare the database — once, before the service runs
uv run proxy          # required: playlists only go out through it
uv run vod            # grpc :50051, http :8030
uv run vod --db data/vod.db --public-url /vod
```

The service **will not create its own schema**. Started against a database
nobody prepared it exits with a message telling you to run `vod-init`, rather
than coming up healthy on an empty file it made itself. In compose that's a
one-shot `vod-init` service the `vod` service waits on; on a real host it's a
deploy step like any migration.

## HTTP

| route                | what it does                                              |
|----------------------|-----------------------------------------------------------|
| `GET /health`        | status and how many VODs are stored                        |
| `GET /{id}`          | id, our URLs, metadata — **never the upstream URL**        |
| `GET /{id}/index.m3u8` | 307 into [`apps/proxy`](../proxy)                        |

The playlist route always goes through the proxy, never straight to the origin.
That isn't only about hiding where the file comes from: ashdi answers with
`Access-Control-Allow-Origin: https://ashdi.vip`, so a browser can't read the
playlist from anywhere else, and the proxy rewrites the playlist so variants and
segments come back through us too. Point it elsewhere with `--proxy-url` or
`VOD_PROXY_URL`.

## Storage

SQLite, one table, created on startup:

```sql
vods(id INTEGER PK, playlist_url TEXT UNIQUE NOT NULL, title, poster, created_at)
```

No Alembic here on purpose — one required column doesn't need a migration tool.
The API's schema does, and that's where Alembic lives.

`CreateVod` is idempotent on `playlist_url`: re-seeding returns the existing id
with `created: false` instead of making a duplicate.
