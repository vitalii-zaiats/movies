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

## Seeding

```bash
uv run api-seed data/family-guy-streams.jsonl
```

Takes the output of `resolve-episodes`, keeps records with **exactly one**
stream (zero means nothing was found, more than one is a choice nobody has made
yet), registers each playlist with the VOD service over gRPC, and stores the
metadata with the id it gets back.

Both halves are idempotent — VODs are keyed by playlist URL, episodes by source
URL — so re-running it updates instead of duplicating.

## Talking to the VOD service

Only over the gRPC contract in [`contracts`](../../packages/contracts): no
cross-service imports, no shared database. `api.vod_client.VodClient` is the
whole surface.

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
