# @testing-shit/web

Vue 3 + TypeScript + SCSS, installable as a PWA. One app, three faces:

- `/` — **display**: the big screen. Shows a pairing QR when idle, plays HLS
  when told to, and moves to the next episode on its own.
- `/r/:code` — **remote**: what the QR opens on your phone. Picks a playlist,
  drives transport, shows progress.
- `/dashboard` — **playlists**: build them from a show or a season, reorder,
  add and remove episodes.

```bash
docker compose up -d      # redis + postgres
uv run proxy              # :8001 — playlists are only served through it
uv run vod                # :8030 + grpc :50051
uv run api                # :8020 — catalogue and playlists
uv run hub                # :8010 — pairing socket
npm run dev               # :5173 — this app
```

## Playing

The remote sends `play(playlistId, index)`; the display fetches that playlist
from the API and keeps the queue itself. That's deliberate — the screen goes on
playing, and goes on advancing, even if the phone walks out of the room. On
`ended` it loads the next item; at the end of the queue it stops.

Safari plays HLS natively; everywhere else the display loads **hls.js**, which
is why it's a dynamic import — a 178 kB (gzipped) chunk the phone never fetches.
A fatal playback error stops rather than skipping: with a broken gateway,
auto-next would race through a 442-item queue in seconds.

State (`position`, `duration`, `playing`, `index`, `title`) flows back once a
second while playing and on every change, so the remote's slider and buttons
follow the screen rather than guessing.

Open the display on the **LAN address** Vite prints (`http://192.168.x.x:5173`),
not `localhost` — the QR encodes `location.origin`, and a phone can't reach your
localhost.

`npm run build` type-checks with `vue-tsc` and emits `dist/` plus a service
worker. `npm run preview` serves the built output.

## How it talks

`src/lib/protocol.ts` mirrors `apps/hub/src/hub/protocol.py`; change one, change
the other. `src/lib/useHub.ts` holds the socket: it reconnects with backoff (a
screen may sit on a TV for days) but gives up permanently when the hub says the
code is unknown, because retrying can't fix that.

Vite proxies `/ws` to the hub, so the browser stays on a single origin and the
socket needs no CORS and no absolute URL.

## Installing it

Service workers and the install prompt need a secure context. `localhost` counts
as one; **`http://192.168.x.x:5173` does not** — over plain LAN HTTP the phone
will run the app fine but won't offer to install it and won't register the SW.

You have Tailscale running, so the least painful fix is serving over its
certificate (`tailscale serve`), or any HTTPS tunnel. That's a deployment
question, not a code one — the manifest and SW are already in the build.
