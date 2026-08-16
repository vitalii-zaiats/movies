# contracts

The gRPC contracts the services talk over, plus the stubs generated from them.
Both sides depend on this package, so neither service imports the other.

```
src/contracts/
├── vod.proto        the contract — edit this
├── vod_pb2.py       generated
├── vod_pb2.pyi      generated
└── vod_pb2_grpc.py  generated
```

Regenerate after editing a `.proto`:

```bash
uv run --package contracts python -m contracts.generate
```

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
