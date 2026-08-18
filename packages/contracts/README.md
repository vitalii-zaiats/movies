# contracts

The gRPC contracts the services talk over, plus the stubs generated from them.
Both sides depend on this package, so neither service imports the other.

```
src/contracts/
├── vod.proto              the contracts — edit these
├── catalogue.proto
├── vod_pb2.py             generated
├── vod_pb2.pyi            generated
├── vod_pb2_grpc.py        generated
├── catalogue_pb2.py       …and the same three for the catalogue
└── generate.py            emits Python here and Dart into mobile/kino_api
```

Regenerate after editing a `.proto`:

```bash
uv run --package contracts python -m contracts.generate
```

That writes both languages from one protoc — the Python stubs here, and the Dart
ones into [`mobile/kino_api`](../../mobile/kino_api), so a service and its phone
client can't be built from different versions of the same file. Dart needs
`dart pub global activate protoc_plugin` once; without it that half is skipped
with a note rather than failing, because regenerating the Python stubs shouldn't
require a Dart toolchain.

The generated files are committed on purpose — installing the workspace
shouldn't need `protoc`. Generation uses `src/` as the include root so protoc
writes `from contracts import vod_pb2` rather than a bare `import vod_pb2`,
which only resolves when the file happens to be on `sys.path`.

## vod.v1

`VodService` — `CreateVod`, `GetVod`, `ListVods`. A VOD is one playable thing:
`playlist_url` (an `index.m3u8`) is the only required field, `url` is where we
serve it (`http://vod.localhost/1`), and `metadata` (title, poster) is optional
— null until the API knows better.

`CreateVod` is idempotent on `playlist_url` and reports `created: false` when
the playlist was already registered, so a seed can be re-run safely.

## catalogue.v1

What a phone talks to: `Catalogue` (shows, episodes, the home screen, and
`StreamShows` for the whole list at once), `Accounts`, `Watching` and
`Playlists`. Served by [`apps/api`](../../apps/api) beside its HTTP routes and
over the same services — see `api/rpc/`.

Only this one is generated for Dart. `vod.proto` is service-to-service: the app
reaches the VOD service over plain HTTP for an `.m3u8` a player can read, so
shipping it a stub would be shipping a call it must never make.
