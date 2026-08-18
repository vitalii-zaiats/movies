# kino_api

The catalogue as a Flutter package: [`catalogue.v1`](../../packages/contracts/src/contracts/catalogue.proto)
over gRPC, plus the two things a generated stub can't do for you.

```dart
final kino = KinoClient(
  host: '10.0.2.2',                            // the emulator's word for "this Mac"
  mediaBase: Uri.parse('http://10.0.2.2'),     // where nginx is
);

await kino.whoAmI();                           // become somebody
final page = await kino.shows(limit: 30, order: ShowOrder.SHOW_ORDER_NEWEST);
final detail = await kino.show(page.items.first.show.key);
final url = kino.streamUrl(detail.episodes.first);   // hand this to a player
```

## The two things

**The token.** Identity is metadata here, not a cookie: every call carries
`authorization: bearer …`, and any call may hand a *new* token back in
`x-session-token`, because the server mints a guest for whoever asks for
something personal without one. Both halves are handled inside the client, so no
screen has to know identity exists — and the token is kept in shared preferences,
which is what makes this phone the same person after a restart.

Pass your own [`TokenStore`] to change where it lives; `MemoryTokenStore` is
what the tests use.

**The URLs.** A playlist arrives as `/vod/7455/index.m3u8` — a path, because the
server has no idea what address the phone reached it on. `streamUrl`,
`trackUrl`, `posterUrl` and `resolve` are where that becomes something a player
or an `Image` can open, against `mediaBase`.

## What's on it

| what                    | calls                                                       |
|-------------------------|--------------------------------------------------------------|
| identity                | `whoAmI`, `startGuest`, `claim`, `login`, `logout`, `rename` |
| browsing                | `shows`, `allShows`, `show`, `episodes`, `episode`, `home`   |
| watching                | `report`, `progress`, `forget`, `history`, `continueWatching`|
| playlists               | `lists`, `list`, `createList`, `listFromShow`, `updateList`, `deleteList`, `addToList`, `removeFromList`, `reorderList` |

`allShows` is a server stream — the whole catalogue as it arrives, for a client
that wants to search offline rather than page through eight thousand titles
fifty at a time.

`progress` answers `null` rather than throwing when an episode has never been
watched: the server says `NOT_FOUND`, and "start at the beginning" is an answer.
Everything else throws `GrpcError`, whose `code` is the refusal — `NOT_FOUND`,
`PERMISSION_DENIED`, `UNAUTHENTICATED`.

## TLS

```dart
KinoClient(host: 'kino.example.com', port: 443, secure: true);       // real certificate
```

For a stack on the LAN with a certificate it signed itself, trust that one
authority and nothing else changes:

```dart
final ca = await rootBundle.load('assets/kino-ca.pem');
KinoClient(
  host: '192.168.0.10',
  secure: true,
  trustedRoots: ca.buffer.asUint8List(),
  authority: 'kino.local',   // the name on the certificate, not the address dialled
);
```

That's narrower than teaching Android to trust the CA system-wide, and it needs
no network security config. The certificate has to name every address a client
dials — see the openssl line in [`apps/api`](../../apps/api/README.md#tls).

## Generated code

`lib/src/generated/` is committed, so `flutter pub get` is the whole setup.
Regenerate both languages from one protoc — that's what keeps the Python service
and this from being built from different versions of the same file:

```bash
dart pub global activate protoc_plugin        # once
uv run --package contracts python -m contracts.generate
```

Two names in the contract are not the obvious ones. `PageInfo` and
`PlaylistVisibility` avoid colliding with `Page` and `Visibility` from
`material.dart`, which a generated client would otherwise hit on its first
screen. Ids are 32-bit for a related reason: 64-bit ones arrive as `Int64` from
`fixnum` and cost a conversion at every call site, for headroom seven thousand
shows will never need.
