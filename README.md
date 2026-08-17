# testing-shit

A uv workspace: one lockfile, one `.venv` at the root, every Python member
installed editable.

| path                                             | what it is                                                                        |
|--------------------------------------------------|-----------------------------------------------------------------------------------|
| [`packages/ashdi-finder`](packages/ashdi-finder) | library + CLI: finds ashdi.vip iframes on a page and resolves their `.m3u8` streams |
| [`packages/vod-packager`](packages/vod-packager) | library + CLI: cuts a video into HLS `.ts` segments on disk (needs `ffmpeg`)         |
| [`packages/contracts`](packages/contracts)       | gRPC contracts (`vod.v1`) and the stubs generated from them                          |
| [`packages/httpkit`](packages/httpkit)           | the shared HTTP client: rotating proxies, retries on 429                             |
| [`packages/crawlers`](packages/crawlers)         | listing-page crawlers: pluggable sources in, sinks (stdout / jsonl / sqlite) out      |
| [`apps/proxy`](apps/proxy)                       | async (aiohttp) streaming proxy — fetches a URL, streams it back with open CORS      |
| [`apps/episode-resolver`](apps/episode-resolver) | crawls a show's episodes, then resolves each one's ashdi streams                     |
| [`apps/seeder`](apps/seeder)                     | loads what was crawled into the VOD service and the catalogue                        |
| [`apps/api`](apps/api)                           | FastAPI catalogue: shows, episodes, users, progress, playlists (Postgres + Alembic)  |
| [`apps/vod`](apps/vod)                           | VOD microservice: owns playlists, gRPC inwards, `vod.localhost/1` outwards (SQLite)  |
| [`apps/hub`](apps/hub)                           | WebSocket pairing hub — display ↔ remote over a Redis bus                            |
| [`web`](web)                                     | Vue 3 + TS + SCSS PWA: player on the big screen, remote control on the phone         |
| [`frontend`](frontend)                           | Nuxt 4 + TS + SCSS catalogue to browse: shows, episodes, playlists, search            |

```bash
uv sync                                            # python side
uv run ashdi-finder https://ashdi.vip/vod/167527   # find streams on a page
uv run vod-pack ~/Downloads/video.mp4              # cut a file into .ts segments
uv run crawl kinoukr 3                             # look at 3 listing pages
uv run crawl kinoukr 5 --sink sqlite:data/items.db # crawl into storage
uv run resolve-episodes family-guy                 # episodes -> ashdi streams

docker compose up -d                               # postgres :5432, redis :6379
uv run --directory apps/api alembic upgrade head   # catalogue schema
uv run vod-init                                    # vod schema
uv run seed-catalogue data/family-guy-streams.jsonl  # fill both (services must be up)

uv run proxy                                       # proxy      → :8001
uv run hub                                         # socket     → :8010
uv run api                                         # catalogue  → :8020
uv run vod                                         # vod http   → :8030, grpc :50051
cd web && npm install && npm run dev               # PWA        → :5173
cd frontend && npm install && npm run dev          # catalogue  → :3000
```

## Catalogue and VOD

**[`apps/vod`](apps/vod) is the source of truth.** A row there is a playable
thing: the playlist, a copy of it as it was when it could still be fetched, and
a JSON blob of everything the crawl knew about what it plays. Nothing else in
the system holds all three, and nothing else needs to.

Writes go one way and stop there. [`apps/seeder`](apps/seeder) registers streams
with the VOD service — with the whole envelope: show key, film or series, season
and episode, year, genres, dub, IMDb id — and then asks the catalogue to go and
look. It never writes to the catalogue.

[`apps/api`](apps/api) **derives** its catalogue by reading that list. It walks
`ListVods(after_id=cursor)` from wherever it left off, builds shows and episodes
out of the envelopes, and keeps the cursor in a row of its own, so a catalogue
that was down for a day catches up by itself and one that was dropped can be
rebuilt from scratch:

```bash
docker compose run --rm seed data/<source>-streams.jsonl   # register + "go look"
docker compose exec api api-admin sync-vods --since 0      # read the list again
```

Its gRPC client has no `CreateVod` at all — that's what keeps the direction from
being merely a comment. The catalogue stores a **link** to the VOD
(`http://vod.localhost:8030/1`), never an upstream stream URL. They talk over
`vod.v1` from [`packages/contracts`](packages/contracts); neither imports the
other, and they don't share a database.

One episode can have several VODs: some sources publish the same episode in two
dubs, which are two files and therefore two playable things. The catalogue keeps
one episode row with a track per dub, and the player offers the choice.

The VOD service hands out playlists only through [`apps/proxy`](apps/proxy):
`GET /1/index.m3u8` redirects into it, so the origin URL stays inside and the
playlist comes back rewritten (variants and segments routed through us), which
is also the only way a browser can read it at all.

## Casting

[`web`](web) is one PWA in two roles. Opened at `/` it's the **display**: it
takes a room code from [`apps/hub`](apps/hub) and shows it as a QR. The phone
scans it, lands on `/r/<code>`, and becomes the **remote**. Everything between
them goes through Redis pub/sub, so the two ends don't have to be on the same
hub process.

Open the display on the LAN address Vite prints, not `localhost` — the QR
encodes whatever origin the display is on, and the phone has to be able to reach
it.

Streams themselves still need [`apps/proxy`](apps/proxy) in the middle: ashdi
answers with `Access-Control-Allow-Origin: https://ashdi.vip`, so hls.js can't
read a playlist from any other origin.

## Proxies

Everything that scrapes goes through [`httpkit`](packages/httpkit), so a
rotating residential gateway is one setting for the whole repo:

```bash
export PROXY_URL='http://user:pass@gate.provider.com:7000'
uv run resolve-episodes family-guy         # picks it up, no flag needed
uv run crawl kinoukr 5 --proxy @proxies.txt  # or per command, list or file
```

429s are retried with backoff on the next proxy in the pool, and keep-alive is
disabled while proxying so each request gets a fresh exit IP.

## Docker

Every service has a Dockerfile, built **from the repo root** so uv can see the
workspace:

```bash
docker build -f apps/api/Dockerfile -t kino-api .
docker build -f web/Dockerfile      -t kino-web .
```

The image doesn't carry the monorepo. `uv sync --package <name>` installs that
service's dependency closure and nothing else — `kino-hub` has aiohttp and redis
in it, no FastAPI, no SQLAlchemy, no crawlers — and only the resulting venv is
copied into a clean `python:3.13-slim` stage. No uv, no sources, no lockfile,
no sibling services. Images land between 240 and 420 MB; `kino-web` is 94 MB.

Two details worth knowing if you edit them:

- The venv is built at `/app/.venv`, the same path it runs from. A venv's
  console scripts hard-code their own absolute path in a shebang, so building at
  `/src` and copying elsewhere produces `exec: no such file or directory`.
- `apps/api` copies `alembic.ini` and `migrations/` in as data: they live
  outside the package, so the wheel doesn't contain them.
  `docker run --entrypoint alembic kino-api upgrade head` works.

`kino-episode-resolver` is a job image: it takes arguments, runs, and exits.

```bash
docker run --rm -v "$PWD/data:/data" kino-episode-resolver family-guy --limit 5
```

`kino-web` is node + nginx: nginx serves the built bundle and fronts `/api` and
`/ws`, so in production everything is one origin and the CORS question never
comes up. It expects `api` and `hub` to be resolvable — service names on a
compose network.

## Layout

`packages/` holds libraries, `apps/` holds deployables — the root `members` globs
both, so a new one needs no registration. Depend on a sibling with
`[tool.uv.sources] <name> = { workspace = true }`.
