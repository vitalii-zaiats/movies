# api

The catalogue: shows, episodes, posters, and a link to the VOD that plays each
one — plus the people watching it. It stores **no stream URLs**: a playlist
belongs to [`apps/vod`](../vod), and all the API keeps is the id that points at
it.

```bash
docker compose up -d                                  # postgres
uv run --directory apps/api alembic upgrade head      # schema
uv run vod                                            # the VOD service (gRPC :50051)
uv run api                                            # :8020
```

## Everyone has an account

There is no signed-out state. A request with no token gets a **guest** — a real
row, with real history — and the token comes back on the response:

```
X-Session-Token: aw9PSGNtYuu7…
Set-Cookie: kino_session=…; HttpOnly; SameSite=Lax
```

The browser keeps the cookie and stops thinking about it. The TV reads the
header once and sends `Authorization: Bearer …` forever after; the header wins
when both are present.

Later, that guest **claims** the account: an email and a password are written
onto *the same row*, so everything watched, every playlist built and every
position saved is still there. Nothing is copied, nothing is merged, and there's
no "import your guest data" screen to get wrong.

```
POST /auth/claim   {"email": "…", "password": "…"}
```

Two orthogonal things describe a user:

| what          | column                | means                                     |
|---------------|-----------------------|-------------------------------------------|
| guest / member| `claimed_at` is null  | can they log back in from another device?  |
| role          | `role` — `user`/`admin`| what are they allowed to do?              |

A guest is a `user`. Making the first admin is a chicken-and-egg problem, so it
happens from a shell:

```bash
uv run --directory apps/api api-admin create you@example.com   # prompts for a password
uv run --directory apps/api api-admin grant you@example.com
uv run --directory apps/api api-admin list
```

The last admin can't be demoted — locking yourself out of your own stack is a
bad afternoon.

### Guests are minted on demand, not on every request

`GET /episodes` doesn't create anything; `GET /me/history` does. The split is
the `Viewer` / `CurrentUser` pair in `modules/accounts/deps.py` — public reads
personalise if a token is there and stay anonymous if it isn't, and only routes
that are *about* a person hand one out. Otherwise every crawler hitting the
catalogue would leave a user behind.

## Endpoints

### Catalogue

| route                   | what you get                                            |
|-------------------------|----------------------------------------------------------|
| `GET /health`           | status plus row counts                                    |
| `GET /shows`            | `?q=&series=&order=&limit=&offset=` — paginated, with counts |
| `GET /shows/{key}`      | one show with its episodes                                |
| `GET /episodes`         | `?show=&season=&q=&playable=&limit=&offset=` — paginated  |
| `GET /episodes/{id}`    | one episode with its show                                 |

Each episode carries `vod_url` and a computed `playlist`
(`{vod_url}/index.m3u8`) — the only URL a player needs.

A show in the list carries `episode_count` and `playable_count`, counted in one
grouped query. That's what lets a browse page draw eight thousand tiles without
a request per tile, and `series=` reads the same numbers as a shape: more than
one episode is a series, exactly one is a film. `order=` is `key` (default),
`added` or `title`.

### Auth

| route                          | what it does                                    |
|--------------------------------|--------------------------------------------------|
| `GET /auth/me`                 | who you are — minting a guest if you're nobody    |
| `PATCH /auth/me`               | `{display_name}`                                  |
| `POST /auth/guest`             | a *new* guest, even if you already have one       |
| `POST /auth/claim`             | `{email, password, display_name?}` — keeps the row|
| `POST /auth/login`             | `{email, password}` → a second session            |
| `POST /auth/logout`            | revokes this session                              |
| `POST /auth/device`            | a device with no keyboard asks to be signed in    |
| `GET /auth/device/{code}`      | what is being asked for, for the page saying yes  |
| `POST /auth/device/approve`    | `{code}` — the browser says yes, as itself        |
| `POST /auth/device/collect`    | `{secret}` — the device asking picks up a session |
| `GET /users`                   | admin: everyone, `?guests=`                       |
| `PATCH /users/{public_id}/role`| admin: `{role}`                                   |

`POST /auth/guest` is deliberately unconditional — that's what makes it usable
as "watch as someone else on the shared TV".

#### Signing in a television

Typing an email with a D-pad is the reason people give up, so the television
never asks for one. It calls `POST /auth/device`, shows what comes back as a QR
and a six-character code, and polls `collect`. A phone opens `/link?code=…`,
where somebody is already signed in, and approves it.

The two halves are deliberately *not* the same string:

* the **code** is short because it is read off a screen, and knowing it only
  lets you approve;
* the **secret** never leaves the device that asked, and is the only thing that
  can collect the session.

So a code approved by the wrong person hands the session to the device that
asked for it and to nobody else. Requests live ten minutes, collect once, and
`collect` answers `{"status": "pending"}` until somebody agrees — a status
rather than a 404, because a device polling every two seconds should not have
to read errors to learn it is still waiting.

### Me: progress, history, activity

| route                            | what it does                                     |
|----------------------------------|---------------------------------------------------|
| `PUT /me/progress/{episode_id}`  | `{position_seconds, duration_seconds?, completed?}`|
| `GET /me/progress/{episode_id}`  | where to seek to — 404 means "start at zero"      |
| `DELETE /me/progress/{episode_id}`| forget this episode                              |
| `GET /me/history`                | recently watched, `?completed=`                   |
| `GET /me/continue`               | started, not finished, newest first               |
| `GET /me/activity`               | the event feed, `?type=`                          |

Progress is **state** and history is a **log**, in two tables, on purpose.
`watch_progress` is one row per user and episode, rewritten as the player
reports in — a heartbeat every ten seconds must not grow a history table.
`activity_events` is append-only: an episode started, an episode finished, a
playlist created. Past 95% an episode counts as finished, unless the player
says so explicitly, in which case it's believed.

`completed_at` is set once. Scrubbing back to the start doesn't undo having
watched the thing.

### Playlists

A playlist is a **catalogue object** — an ordered list of episodes, not a media
file. The m3u8 never leaves the VOD service; what lives here is which episodes
and in what order, which is exactly what a screen needs to auto-advance.

| route                                | what it does                                        |
|--------------------------------------|------------------------------------------------------|
| `GET /playlists`                     | `?scope=visible\|mine\|public` — yours plus published |
| `POST /playlists`                    | `{name}` — an empty one                               |
| `POST /playlists/from-show`          | `{show, season?, name?}` — a whole show or one season |
| `GET /playlists/{id}`                | items in order, each with its episode and `playlist`  |
| `PATCH /playlists/{id}`              | `{name?, visibility?}` — rename, publish, take down   |
| `DELETE /playlists/{id}`             | drop it                                               |
| `POST /playlists/{id}/items`         | `{episode_id}` — append                               |
| `DELETE /playlists/{id}/items/{item}`| remove, then renumber                                 |
| `PUT /playlists/{id}/order`          | `{item_ids}` — must list every item exactly once      |

Playlists have an owner, and somebody else's private one comes back as **404,
not 403** — a 403 would confirm the id exists. Ownership is a `WHERE` clause in
the repository, not a check each route has to remember.

`visibility` is `private` or `public`. **Public is an editorial act, not a
sharing one**: a public playlist is a collection the whole install sees, so only
an admin can publish. Taking one down again is the owner's call too — nobody
should need an admin to unshare their own list. Being able to *see* a public
playlist never means being able to edit it.

`from-show` skips episodes without a VOD by default (`playable_only`): a hole in
the queue would stall auto-next. Positions are dense and 0-based, rewritten on
every mutation, so the display can walk them by index.

## The home screen

The client used to work the front page out for itself: a request per show, read
each `total`, sort by size, biggest one into the hero. That's a guess dressed as
a layout, and it costs a round trip per show. `GET /home` replaces it with a
decision somebody made — an ordered list of sections, each pointing at a show or
a public playlist, each already filled in.

| route                       | what it does                                       |
|-----------------------------|-----------------------------------------------------|
| `GET /home`                 | the whole page, in one request. `?preview=` for admins |
| `GET /sections`             | admin: all of them, hidden included                 |
| `POST /sections`            | admin: `{kind, title, kicker?, link?, show_id?, playlist_id?, item_limit?, visible?}` |
| `PATCH /sections/{id}`      | admin: only the keys you send                       |
| `PUT /sections/order`       | admin: `{section_ids}` — every one, exactly once     |
| `DELETE /sections/{id}`     | admin                                               |

A section's `kind` is `hero`, `rail`, `grid` or `banner`. A `banner` carries
artwork and a link with no episodes under it — "the finale is on Friday";
everything else needs a show or a playlist, and never both.

Wiring a **private** playlist into the home screen is refused, because the home
screen is public and that would publish it by the back door. If one is made
private *afterwards*, its section is dropped from `/home` rather than drawn —
visibility can change under a section, and the front page is the wrong place to
find that out.

`visible: false` is a draft. Drafts appear in `GET /sections` and under
`GET /home?preview=true`, which is admin-only — a query parameter shouldn't be
enough to publish something.

### Banners, in five sizes

Artwork is one picture at one **placement**, attached to a show, a playlist or a
section. Different sizes of the same thing, not different things — which is why
placement is a column and not five columns.

| placement | recommended | what it is                                |
|-----------|-------------|--------------------------------------------|
| `hero`    | 1920×820    | the wide one at the top                    |
| `tile`    | 640×360     | a 16:9 rail tile                           |
| `poster`  | 600×900     | 2:3, for a grid                            |
| `square`  | 600×600     | for a phone rail                           |
| `logo`    | 800×320     | title treatment, sits *over* the hero      |

| route                       | what it does                                       |
|-----------------------------|-----------------------------------------------------|
| `GET /artwork/placements`   | the table above, as JSON — advisory, nothing is rejected |
| `GET /artwork`              | admin: `?subject_type=&subject_id=`                 |
| `PUT /artwork`              | admin: `{subject_type, subject_id, placement, url\|media_id}` |
| `DELETE /artwork/{id}`      | admin                                               |

`PUT` upserts, because there is only ever one hero for a show — the unique
constraint says so and the verb matches. Give **exactly one** of `url` (somebody
else's server) or `media_id` (an upload); when it's an upload the URL is
resolved once, at write time, so reads are a column rather than a join and a
branch.

On the home screen a section's own artwork **overrides** the artwork of what it
points at. That's what makes "use a different hero just for this rail" possible
without changing the show everywhere else uses it.

## Uploads

| route                | what it does                                              |
|----------------------|------------------------------------------------------------|
| `POST /media`        | admin: multipart `file` → a row and a URL                  |
| `GET /media`         | admin: the picker's list, newest first                     |
| `DELETE /media/{id}` | admin: drops the row and the file                          |
| `GET /media/{name}`  | the file, `immutable` for a year                           |

**Content-addressed**: a file's name is the SHA-256 of its bytes. Uploading the
same banner twice is the same row and the same URL, and every URL is immutable,
which is what lets it be cached forever.

The format is decided by **reading the bytes** — PNG, JPEG, GIF and WebP
headers, parsed in `media/images.py` — never by trusting the multipart content
type. A text file called `hero.png` is a 400. Width and height come out of the
same parse, so the admin panel can warn that a 400px image will look soft as a
hero. SVG is deliberately not accepted: it's a document that can carry script,
and these are served from the same origin as the app.

Bytes live on a volume (`API_MEDIA_ROOT`), the row lives in Postgres. Back them
up together or not at all.

## Layout

One folder per feature, each with the same five files. Adding a feature is
adding a folder and one line in `modules/__init__.py` — not editing four shared
files that everything else also imports.

```
main.py                  the app: middleware, routers, errors → status codes
settings.py              configuration, from the environment
errors.py                NotFound / Conflict / Invalid / Unauthorized / Forbidden

core/                    what every module stands on, and knows nothing about them
  database.py            engine and session
  models.py              Base, TimestampMixin, utcnow
  registry.py            every table in one import — this is Alembic's metadata
  repository.py          the session-and-a-table base
  schemas.py             ORMModel, Page
  security.py            session tokens (sha256) and passwords (scrypt)
  deps.py                DB

modules/
  accounts/              users, guests, claiming, roles, sessions
  catalogue/             shows and episodes
  media/                 uploaded files, content-addressed
  playlists/             ordered queues, owned, publishable
  activity/              progress and the event log
  curation/              the home screen: sections and artwork
    models.py            the tables
    schemas.py           the DTOs
    repository.py        every query, written once
    service.py           the rules — no FastAPI import anywhere below the router
    deps.py              the wiring
    router.py            request in, DTO out

clients/vod.py           read-only gRPC into apps/vod
cli.py                   `api-admin`
```

Services raise from `errors.py`; one handler in `main.py` turns those into
404 / 409 / 400 / 401 / 403. That's why nothing below the router layer imports
FastAPI — a service can be called from a script, the `api-admin` CLI or a test
without pretending to be a request.

### What a module may know about another

The dependency graph is a straight line, and three rules keep it one:

**A module's service is its public face; its repository is private.** Nothing
outside `catalogue/` constructs an `EpisodeRepository`. Playlists asks
`CatalogueService.show_episodes`, activity asks `CatalogueService.episode`, and
curation asks `PlaylistService.published` — which is also where the rule "only a
public playlist may be shown to everyone" lives, because what `public` means is
the playlists module's business, not the home screen's.

**Cross-module wiring happens in `deps.py` and nowhere else.** That's the
composition root: `CurationService` names a catalogue, a playlists and a media
service as constructor arguments, and `curation/deps.py` is the only file that
knows which concrete classes satisfy them. It reuses the neighbours' own
dependency functions, so everything lands on the one session FastAPI opened.

**Side effects get inverted; reads bound by a foreign key don't.**
`playlists/ports.py` declares an `ActivityRecorder` protocol — the port lives
with the *consumer* — and `ActivityService` satisfies it structurally. Nothing
in playlists imports activity; nothing in activity has heard of playlists. Event
names are plain strings (`playlists/events.py`), so a module names its own
events without a shared enum every feature has to come and edit.

Reads are the other half of that sentence, and deliberately not symmetric. A
DTO layer between activity and catalogue would be translation for its own sake:
`watch_progress.episode_id` is a foreign key with `ON DELETE CASCADE` in one
database, inside one transaction. A Python-level indirection cannot decouple
what the DDL couples — it can only make the code lie about the schema. So model
imports that mirror real foreign keys stay, and imports that exist purely for a
type annotation move under `if TYPE_CHECKING` (routers excepted — FastAPI
resolves those annotations at runtime to build the DI graph).

An anti-corruption layer belongs at a boundary you don't control: another team,
another service, another datastore. If a module ever becomes one of those, the
ACL goes at *that* seam — `clients/vod.py` is already the example, and it's the
only place in the API shaped that way.

Schema-level reuse is fine and is already the DTO answer: `HistoryEntry` embeds
`EpisodeWithShow`, and a home-screen section embeds `ShowOut` and `PlaylistOut`.
A published DTO is a contract; re-declaring the shape of a show in three modules
would only mean three places to change it.

Cross-module writes share one transaction. `ActivityService.record` appends to
the feed and deliberately does **not** commit: "the playlist was created but the
event wasn't" is not a state worth allowing.

## Getting data in

The API doesn't crawl and it doesn't seed. Whoever found a stream registers it
with the VOD service and then posts the episode here:

```
POST /ingest/episodes   {"items": [{show_key, title, season, episode, source_url, vod_id, …}]}
```

That's [`apps/seeder`](../seeder). Upserts on `source_url`, so re-sending is
safe.

Open by default, because that's what `docker compose run --rm seed` expects on a
LAN. Set `API_INGEST_TOKEN` and the endpoint takes exactly two keys: that value
in an `X-Api-Key` header, or an admin session.

## Talking to the VOD service

Read-only, over the gRPC contract in [`contracts`](../../packages/contracts).
`api.clients.vod.VodClient` has `get` and no `create` — registering a VOD is the
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

A new module means a new line in `core/registry.py`. A model class nobody
imported isn't in `Base.metadata`, and autogenerate reports that as "drop this
table" rather than as a mistake.

## The same catalogue over gRPC

There are two presentation layers and one set of decisions. `src/api/rpc/`
serves [`catalogue.v1`](../../packages/contracts/src/contracts/catalogue.proto)
— shows, episodes, the home screen, identity, progress and playlists — and
every method does what a route does: open a session, build the graph from
`core/services.py`, call one method on it, turn the answer into a message.

```bash
uv run api-grpc                       # :50061
grpcurl -plaintext 127.0.0.1:50061 list
grpcurl -plaintext 127.0.0.1:50061 catalogue.v1.Catalogue/Health
```

Reflection is on, which is what makes those two commands work at all — it's
this port's answer to the OpenAPI page the HTTP one gets for free.

What stays on HTTP: ingest, VOD sync, media upload and the section editor.
Those are one machine talking to another, or an admin with a file picker.

Identity travels as metadata rather than a cookie, because gRPC has none:

```
authorization: bearer <token>     inbound, every call
x-session-token: <token>          outbound, when this call created the session
```

A call that needs somebody and was given nobody mints a guest — the same rule
`CurrentUser` follows — and the new token rides back in the initial metadata, so
a client never has to know which RPC created it.

The same pairing is on this port as `Accounts.StartDeviceLink` and
`Accounts.CollectDeviceLink` — the television speaks gRPC like everything else.
Approval is not here: it happens in a browser, where somebody is already signed
in and can read what they are agreeing to.

Refusals become status codes in one place, `rpc/errors.py`, exactly as
`main.py` does it for HTTP:

| raised        | HTTP | gRPC                |
|---------------|------|---------------------|
| `NotFound`    | 404  | `NOT_FOUND`         |
| `Conflict`    | 409  | `ALREADY_EXISTS`    |
| `Invalid`     | 400  | `INVALID_ARGUMENT`  |
| `Unauthorized`| 401  | `UNAUTHENTICATED`   |
| `Forbidden`   | 403  | `PERMISSION_DENIED` |

### TLS

Unset, the port is plaintext — which is correct behind nginx, where the hop
from it is inside a compose network. Set both halves and it isn't:

```bash
API_GRPC_TLS_CERT=/certs/cert.pem API_GRPC_TLS_KEY=/certs/key.pem uv run api-grpc
# grpc on 127.0.0.1:50061 (tls)
```

Half a pair is refused rather than ignored: a typo that silently downgrades a
port to plaintext is the worst outcome available. `API_GRPC_TLS_CLIENT_CA`
turns on mutual TLS — the door then opens only for a device holding a
certificate signed by that CA, *on top of* the session token rather than
instead of it.

A self-signed certificate has to name every address a client will dial, or the
handshake fails on a name it never claimed:

```bash
openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
  -keyout key.pem -out cert.pem -subj "/CN=kino.local" \
  -addext "subjectAltName=DNS:kino.local,IP:192.168.0.10"
```

The client then has to trust it — see [`mobile/kino_api`](../../mobile/kino_api),
which takes the CA's bytes rather than asking Android to trust it everywhere.

The other way is to let nginx do it, which is one certificate for the whole
stack instead of one per service. gRPC paths are `/package.Service/Method`, so
a prefix is enough to tell them from the app's own routes:

```nginx
server {
    listen 443 ssl;
    http2 on;                       # gRPC is HTTP/2 and nothing else

    ssl_certificate     /etc/letsencrypt/live/kino/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/kino/privkey.pem;

    location /catalogue.v1. {
        grpc_pass grpc://api-grpc:50061;
    }

    location / {
        proxy_pass http://web:8080;
    }
}
```

## Configuration

All prefixed `API_`.

| variable                 | default                                             | what                                  |
|--------------------------|-----------------------------------------------------|----------------------------------------|
| `API_DATABASE_URL`       | `postgresql+asyncpg://kino:kino@127.0.0.1:5432/kino` |                                        |
| `API_VOD_GRPC_TARGET`    | `127.0.0.1:50051`                                    |                                        |
| `API_VOD_BASE`           | `/vod`                                               | where a browser reaches the VOD service |
| `API_GRPC_HOST`          | `127.0.0.1`                                          | the gRPC port — see above               |
| `API_GRPC_PORT`          | `50061`                                              |                                        |
| `API_GRPC_TLS_CERT`      | unset                                                | PEM; with the key, the port is TLS      |
| `API_GRPC_TLS_KEY`       | unset                                                | PEM                                     |
| `API_GRPC_TLS_CLIENT_CA` | unset                                                | set it and clients need a certificate too |
| `API_CORS_ORIGINS`       | `["*"]`                                              | wildcard = no cookies; name origins to allow them |
| `API_SESSION_TTL_DAYS`   | `365`                                                | a guest *is* their token — keep it long |
| `API_SESSION_COOKIE`     | `kino_session`                                       |                                        |
| `API_SESSION_COOKIE_SECURE` | `false`                                           | turn on behind real TLS                 |
| `API_INGEST_TOKEN`       | unset                                                | see above                               |
| `API_MEDIA_ROOT`         | `data/media`                                         | where uploaded bytes land — a volume    |
| `API_MEDIA_BASE`         | `/media`                                             | where a browser reaches them            |
| `API_MAX_UPLOAD_BYTES`   | `8388608`                                            | 8 MiB                                   |
