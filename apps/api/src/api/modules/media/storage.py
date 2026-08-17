"""Bytes on disk.

Separated from the service so that "where do files live" is one small thing to
replace the day this wants S3 instead of a volume. Nothing above this module
builds a path.
"""

import hashlib
import re
from pathlib import Path

from api.settings import settings

# A stored name is a hex digest and an extension we chose ourselves. Anything
# else never touches the filesystem — this is the check that makes `../..`
# impossible rather than merely unlikely.
STORED_NAME = re.compile(r"^[0-9a-f]{64}\.(png|jpg|gif|webp)$")


def digest_of(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def root() -> Path:
    path = Path(settings.media_root)
    path.mkdir(parents=True, exist_ok=True)
    return path


def write(name: str, data: bytes) -> Path:
    """Idempotent: the name is derived from the bytes, so a rewrite is a no-op."""
    path = root() / name
    if not path.exists():
        # Write beside and rename, so a half-written file is never visible under
        # a name that promises those exact bytes.
        staging = path.with_suffix(path.suffix + ".part")
        staging.write_bytes(data)
        staging.replace(path)
    return path


def locate(name: str) -> Path | None:
    """Resolve a stored name to a file, or nothing. Never raises on bad input."""
    if not STORED_NAME.match(name):
        return None
    path = root() / name
    return path if path.is_file() else None


def remove(name: str) -> None:
    path = locate(name)
    if path is not None:
        path.unlink(missing_ok=True)


def url_for(name: str) -> str:
    return f"{settings.media_base.rstrip('/')}/{name}"
