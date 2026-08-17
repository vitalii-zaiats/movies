# frontend

The catalogue, to browse. Nuxt 4 + TypeScript + SCSS, no server rendering: it
builds to static files the same way [`web`](../web) does, and the browser is the
only thing that ever talks to [`apps/api`](../apps/api).

```bash
cd frontend && npm install
npm run dev                                # → :3000, against `uv run api`
NUXT_PUBLIC_USE_MOCKS=true npm run dev     # → the same app on fixtures, no backend
npm run generate                           # static output in .output/public
```

This is not [`web`](../web). That one is the casting pair — a display on the TV
and a remote in your pocket, talking over [`apps/hub`](../apps/hub). This one is
the catalogue: what was crawled, what plays, and what's queued up.

## Where the data comes from

Everything reads the catalogue through one interface, `CatalogueClient`, and one
composable picks who implements it:

| file                                | what it is                                                     |
|-------------------------------------|----------------------------------------------------------------|
| `app/lib/catalogue/client.ts`       | the interface, and the error every implementation throws       |
| `app/lib/catalogue/mock.ts`         | fixtures, with the server's ordering, paging and 404s copied   |
| `app/lib/catalogue/http.ts`         | `apps/api`, over `/api` on this same origin                    |
| `app/lib/catalogue/fixtures.ts`     | the stand-in catalogue itself                                  |
| `app/composables/useCatalogue.ts`   | picks one, from `NUXT_PUBLIC_USE_MOCKS`                        |

The fixtures are shaped after what the crawlers actually produce rather than
after what would flatter the UI: posters are mostly missing, some episodes never
got a stream, one show's episode "titles" are only the codes the source page had
(which is what `data/simpsonsua.jsonl` looks like), and films arrive as shows
with exactly one episode. `app/types/catalogue.ts` mirrors
`apps/api/src/api/schemas.py` field for field, snake_case included — when the
server moves a field, that file is what has to change and the compiler finds the
rest.

Nitro proxies `/api` and `/vod` in dev to `:8020` and `:8030`, the same prefixes
nginx serves in the image, so a playlist URL behaves identically either way.

## The design, and where it had to give

The look is the Modernist system from the Claude design project: square corners,
2px dividers, Archivo, one red accent. `app/assets/styles/_tokens.scss` carries
its tokens verbatim and every component reads them as custom properties, so
retuning is one file.

The mock-up it was drawn from is a streaming service, and a streaming service
knows things this catalogue doesn't: ratings, genres, cast, runtimes, synopses,
"97% match". None of that is crawled, so none of it is invented here. What took
its place is what the catalogue does know:

| the design                | here                                              |
|---------------------------|---------------------------------------------------|
| match percentage badge    | the episode code — `S02E13`, or `S02E13-14`       |
| ★ rating                  | whether a stream exists at all                    |
| genres, cast, director    | the source URL, the VOD id, when it was added     |
| synopsis                  | how much of the show is here and how much plays   |

Where the tile has no artwork — which is most of the time — it draws a figure
derived from the show key, so the same show is the same colour everywhere.

## What the backend grew

Both of the things this app used to work around are on the server now, which is
what made eight thousand titles survivable:

- **`GET /shows` pages, counts and filters.** Every row carries `episode_count`
  and `playable_count`, so a tile's subtitle costs nothing; `series=` splits
  films from series; `order=added|title|key`. The home page is five requests
  instead of one per show, and `/shows` is a filter box over the whole
  catalogue rather than a list held in the browser.
- **posters on shows.** The ingest carries `show_poster`, so a tile has artwork
  without opening the show.

What it still hasn't got is a genre or a year — the crawl knows both, the
catalogue stores neither. That's why the editorial playlists (*Best of 2026*,
*Best comedies*) are built by `apps/seeder` over the crawl's jsonl and pushed in
as ordinary public playlists, rather than being a query the server could answer.

## Layout

```
app/
  assets/styles/     tokens, reset, type, one file per system component, utilities
  components/        tiles, rails, the hero, the dialog, the player
  composables/       useCatalogue
  lib/catalogue/     the client seam and the fixtures behind it
  pages/             /, /shows, /shows/[key], /search, /playlists, /watch/[id]
  types/             the API's DTOs
  utils/             episode codes, dates, generated artwork (auto-imported)
```
