# api

The catalogue: shows, episodes, posters, and a link to the VOD that plays each
one. It stores **no stream URLs** — a playlist belongs to
[`apps/vod`](../vod), and all the API keeps is `http://vod.localhost:8030/1`.

```bash
docker compose up -d                                  # postgres
uv run --directory apps/api alembic upgrade head      # schema
uv run vod                                            # the VOD service (gRPC :50051)
uv run api                                            # :8020
```

## Endpoints

| route                   | what you get                                            |
|-------------------------|----------------------------------------------------------|
| `GET /health`           | status plus row counts                                    |
| `GET /shows`            | every show                                                |
| `GET /shows/{key}`      | one show with its episodes                                |
| `GET /episodes`         | `?show=&season=&q=&playable=&limit=&offset=` — paginated  |
| `GET /episodes/{id}`    | one episode with its show                                 |

Each episode carries `vod_url` and a computed `playlist`
(`{vod_url}/index.m3u8`) — the only URL a player needs.

## Playlists

A playlist is a **catalogue object** — an ordered list of episodes, not a media
file. The m3u8 never leaves the VOD service; what lives here is which episodes
and in what order, which is exactly what a screen needs to auto-advance.

| route                                | what it does                                        |
|--------------------------------------|------------------------------------------------------|
| `GET /playlists`                     | all of them, with item counts                         |
| `POST /playlists`                    | `{name}` — an empty one                               |
| `POST /playlists/from-show`          | `{show, season?, name?}` — a whole show or one season |
| `GET /playlists/{id}`                | items in order, each with its episode and `playlist`  |
| `DELETE /playlists/{id}`             | drop it                                               |
| `POST /playlists/{id}/items`         | `{episode_id}` — append                               |
| `DELETE /playlists/{id}/items/{item}`| remove, then renumber                                 |
| `PUT /playlists/{id}/order`          | `{item_ids}` — must list every item exactly once      |

`from-show` skips episodes without a VOD by default (`playable_only`): a hole in
the queue would stall auto-next. Positions are dense and 0-based, rewritten on
every mutation, so the display can walk them by index.

## Layers

```
main.py / playlists.py   routes: request in, DTO out — no queries, no decisions
services.py              what the API does: rules, ordering, ingest, commits
repositories.py          every SQL query in the API, each written once
models.py                the schema
```

Services raise `NotFound` / `Conflict` / `Invalid` from `errors.py`; one handler
in `main.py` turns those into 404 / 409 / 400. That's why nothing below the
route layer imports FastAPI — a service can be called from a script or a test
without pretending to be a request.

## Getting data in

The API doesn't crawl and it doesn't seed. Whoever found a stream registers it
with the VOD service and then posts the episode here:

```
POST /ingest/episodes   {"items": [{show_key, title, season, episode, source_url, vod_id, …}]}
```

That's [`apps/seeder`](../seeder). Upserts on `source_url`, so re-sending is
safe.

## Talking to the VOD service

Read-only, over the gRPC contract in [`contracts`](../../packages/contracts).
`api.vod_client.VodClient` has `get` and no `create` — registering a VOD is the
crawler side's job, and leaving the method out is what keeps that true.

## Migrations

Alembic against Postgres, async engine, URL taken from `api.settings` so the
migration and the running app can't disagree.

```bash
cd apps/api
uv run alembic revision --autogenerate -m "what changed"
uv run alembic upgrade head
uv run alembic downgrade -1
```

Configure with `API_DATABASE_URL` (default
`postgresql+asyncpg://kino:kino@127.0.0.1:5432/kino`) and `API_VOD_GRPC_TARGET`.
