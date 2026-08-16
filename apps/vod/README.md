# vod

The VOD microservice. It owns playable things: one row, one `index.m3u8`.
Everything else — title, poster — is metadata it will happily hold and is null
until someone fills it in. The rich metadata lives in [`apps/api`](../api).

Two faces, one process:

- **gRPC** (`:50051`) — `vod.v1.VodService` from [`contracts`](../../packages/contracts).
  This is how the API registers playlists and gets back an id.
- **HTTP** (`:8030`) — what a player talks to: `http://vod.localhost:8030/1`.

```bash
uv run proxy          # required: playlists only go out through it
uv run vod            # grpc :50051, http :8030
uv run vod --db data/vod.db --public-url http://vod.localhost:8030
```

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
