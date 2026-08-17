# seeder

Takes what the crawlers found and loads it into the two services:

```
resolve-episodes  ->  jsonl  ->  seed-catalogue  ->  vod  (gRPC CreateVod)
                                                 ->  api  (POST /ingest/episodes)
```

```bash
uv run seed-catalogue data/family-guy-streams.jsonl
uv run seed-catalogue data/simpsonsua.jsonl --api http://127.0.0.1:8020 --vod 127.0.0.1:50051
```

## Titles before streams

`seed-catalogue` needs a resolved stream per episode. A listing crawl has none
yet — it has eight thousand titles and no playlists — so there is a second door:

```
crawl kinoukr --details  ->  jsonl  ->  seed-crawled      ->  api  (titles)
                                    ->  seed-collections  ->  api  (playlists)
```

```bash
uv run seed-crawled data/kinoukr_all.jsonl
uv run seed-collections data/kinoukr_all.jsonl --email admin@example.com
```

`seed-crawled` posts what a crawled page knows — title, full-size poster — with
no `vod_id` at all, so the catalogue can be browsed while playback is still
being resolved. A crawled title isn't an episode of anything, so each becomes a
show of its own holding one episode; resolving a serial later adds its real
episodes beside that one.

`seed-collections` builds the editorial lists — *Best of 2026*, *Best comedies* —
and publishes them. The rules run over the jsonl rather than over the database,
because genres, years and IMDB scores are things the crawl knows and the
catalogue never stored. Publishing is an admin act, so it signs in first:

```bash
uv run --directory apps/api api-admin create you@example.com   # the first admin
uv run seed-collections data/kinoukr_all.jsonl --email you@example.com --replace
```

## Why it lives here and not in the API

Whoever crawled a stream is the one who knows it exists, so registering it with
the VOD service belongs on this side of the fence. The API only ever **reads**
that service — its gRPC client has no `CreateVod` at all, which is what keeps
the rule true rather than merely written down.

Episodes reach the catalogue over HTTP, not through its database. The API owns
its schema; this app is a client like any other, and the payload is duplicated
here as a small TypedDict because the contract between them is the endpoint, not
a shared module.

## Details

- Only records with **exactly one** stream are taken. Zero means nothing was
  found; more than one is a choice nobody has made yet, and guessing would put
  the wrong stream in the catalogue.
- Both writes are idempotent — VODs are keyed by playlist URL, episodes by
  source URL — so re-running updates instead of duplicating.
- Episodes are posted in batches (`--batch`, 100 by default) rather than one
  request each.
- `CATALOGUE_URL` and `VOD_GRPC_TARGET` work instead of the flags.
