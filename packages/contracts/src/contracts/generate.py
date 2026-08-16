"""Regenerate the stubs from the .proto files.

    uv run --package contracts python -m contracts.generate

Generation runs with `src/` as the include root on purpose: that makes protoc
emit `from contracts import vod_pb2`, instead of the bare `import vod_pb2` that
only works when the file sits on sys.path.
"""

import subprocess
import sys
from pathlib import Path

PACKAGE = Path(__file__).resolve().parent
ROOT = PACKAGE.parent  # src/


def main() -> int:
    protos = sorted(PACKAGE.glob("*.proto"))
    if not protos:
        print("no .proto files found", file=sys.stderr)
        return 1

    command = [
        sys.executable,
        "-m",
        "grpc_tools.protoc",
        f"-I{ROOT}",
        f"--python_out={ROOT}",
        f"--pyi_out={ROOT}",
        f"--grpc_python_out={ROOT}",
        *[str(p.relative_to(ROOT)) for p in protos],
    ]
    print(" ".join(command))
    result = subprocess.run(command, cwd=ROOT)
    if result.returncode == 0:
        for proto in protos:
            print(f"  {proto.stem}_pb2.py, {proto.stem}_pb2_grpc.py")
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
