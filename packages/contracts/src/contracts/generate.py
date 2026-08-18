"""Regenerate the stubs from the .proto files.

    uv run --package contracts python -m contracts.generate

Generation runs with `src/` as the include root on purpose: that makes protoc
emit `from contracts import vod_pb2`, instead of the bare `import vod_pb2` that
only works when the file sits on sys.path.

Dart comes out of the same protoc — the one grpcio-tools ships — driven through
`protoc-gen-dart`, so there is no second compiler to install and no chance of
the two languages being generated from different versions of a contract:

    dart pub global activate protoc_plugin

Without that plugin the Dart step is skipped with a note rather than failing:
somebody regenerating the Python stubs shouldn't need a Dart toolchain.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parent  # src/
REPO = PACKAGE.parents[3]

# Where the Flutter package keeps its generated code. Committed there, like the
# Python stubs are committed here, so `flutter pub get` is the whole setup.
DART_OUT = REPO / "mobile" / "kino_api" / "lib" / "src" / "generated"

# Only the contract a phone actually speaks. `vod.proto` is service-to-service —
# the app reaches the VOD service over plain HTTP, for an `.m3u8` a player can
# read — so shipping it to Android would be shipping a stub for a call the app
# must never make.
DART_PROTOS = ("catalogue.proto",)


def protoc(*arguments: str, cwd: Path) -> int:
    command = [sys.executable, "-m", "grpc_tools.protoc", f"-I{ROOT}", *arguments]
    print(" ".join(command))
    return subprocess.run(command, cwd=cwd).returncode


def find_dart_plugin() -> Path | None:
    """`protoc-gen-dart`, wherever pub put it."""
    found = shutil.which("protoc-gen-dart")
    if found:
        return Path(found)
    candidate = Path(os.environ.get("PUB_CACHE", Path.home() / ".pub-cache")) / "bin" / "protoc-gen-dart"
    return candidate if candidate.is_file() else None


def main() -> int:
    protos = sorted(PACKAGE.glob("*.proto"))
    if not protos:
        print("no .proto files found", file=sys.stderr)
        return 1

    names = [str(p.relative_to(ROOT)) for p in protos]
    code = protoc(
        f"--python_out={ROOT}",
        f"--pyi_out={ROOT}",
        f"--grpc_python_out={ROOT}",
        *names,
        cwd=ROOT,
    )
    if code != 0:
        return code

    for proto in protos:
        print(f"  {proto.stem}_pb2.py, {proto.stem}_pb2_grpc.py")

    plugin = find_dart_plugin()
    if plugin is None:
        print("\nprotoc-gen-dart not found — skipping Dart.")
        print("  dart pub global activate protoc_plugin")
        return 0

    DART_OUT.mkdir(parents=True, exist_ok=True)
    code = protoc(
        f"--plugin=protoc-gen-dart={plugin}",
        f"--dart_out=grpc:{DART_OUT}",
        *[f"contracts/{name}" for name in DART_PROTOS],
        cwd=ROOT,
    )
    if code != 0:
        return code

    for name in DART_PROTOS:
        stem = Path(name).stem
        print(f"  {DART_OUT.relative_to(REPO)}/{stem}.pb.dart, {stem}.pbgrpc.dart")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
