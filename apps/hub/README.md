# hub

WebSocket pairing hub. A **display** opens a socket and gets a room code; a
**remote** joins that code (normally by scanning the QR the display shows) and
the two exchange messages.

Every message goes out to Redis pub/sub and comes back through a subscription —
even when both sockets are on the same process. That's what lets you run several
hubs behind one address without the display and the phone having to land on the
same one.

```bash
docker compose up -d              # redis
uv run hub                        # 0.0.0.0:8010
uv run hub --port 9000 --redis redis://elsewhere:6379/0
```

## Protocol

Connect to `GET /ws?role=display` or `GET /ws?role=remote&code=ABC123`.

The server answers with `{"type":"welcome","role":…,"code":…,"id":…}`, or with
`{"type":"error"}` and a close when the code is unknown or expired.

It relays exactly two envelopes and looks inside neither:

```jsonc
{"type": "command", "name": "background", "args": {"color": "#22d3ee"}}  // remote → display
{"type": "state",   "state": {"background": "#22d3ee"}}                  // display → remote
```

A `from` field (`display` / `remote`) is stamped on by the server, and senders
never receive their own message back. Anything else is dropped, so adding
`play(vod_id)` later is a change in the app, not here.

`{"type":"peers","displays":N,"remotes":N}` arrives whenever someone joins or
leaves. `GET /health` reports Redis reachability.

## Rooms

Codes are 6 characters from an alphabet with no `0/O/1/I` — they get read off a
screen and typed by hand. A room lives in Redis for an hour, refreshed on every
message, and is deleted the moment its display disconnects: the code belongs to
the screen, so a closed tab can't leave a joinable room behind.
