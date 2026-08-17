"""What kind of image is this, and how big?

Read out of the bytes, never out of the `Content-Type` the client sent. An
upload endpoint that believes the header is an upload endpoint that stores
whatever it's handed under a name that says `image/png`.

Four formats, parsed from their headers by hand. Pillow would do this too, and
would also pull a stack of C libraries into a slim image for the sake of eight
bytes of big-endian integer — not a trade worth making when the whole job is
recognising a magic number and reading a size out of a fixed offset.

SVG is deliberately absent. It's a document, not a bitmap: it can carry script,
and these files get served from the same origin as the app.
"""

import struct
from dataclasses import dataclass

# Content types we're willing to store, keyed by what the bytes actually say.
PNG = "image/png"
JPEG = "image/jpeg"
GIF = "image/gif"
WEBP = "image/webp"

EXTENSIONS = {PNG: ".png", JPEG: ".jpg", GIF: ".gif", WEBP: ".webp"}


@dataclass(frozen=True, slots=True)
class ImageInfo:
    content_type: str
    width: int | None
    height: int | None


class NotAnImage(ValueError):
    """The bytes aren't one of the formats we accept."""


def inspect(data: bytes) -> ImageInfo:
    """Identify and measure, or refuse."""
    for reader in (_png, _gif, _webp, _jpeg):
        info = reader(data)
        if info is not None:
            return info
    raise NotAnImage("not a PNG, JPEG, GIF or WebP")


def _png(data: bytes) -> ImageInfo | None:
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        return None
    # IHDR is required to be the first chunk, so the size is at a fixed offset.
    if len(data) < 24:
        return ImageInfo(PNG, None, None)
    width, height = struct.unpack(">II", data[16:24])
    return ImageInfo(PNG, width, height)


def _gif(data: bytes) -> ImageInfo | None:
    if not data.startswith((b"GIF87a", b"GIF89a")):
        return None
    if len(data) < 10:
        return ImageInfo(GIF, None, None)
    width, height = struct.unpack("<HH", data[6:10])
    return ImageInfo(GIF, width, height)


def _webp(data: bytes) -> ImageInfo | None:
    if not (data.startswith(b"RIFF") and data[8:12] == b"WEBP"):
        return None

    chunk = data[12:16]
    try:
        if chunk == b"VP8X":
            # Three-byte little-endian, and stored one less than the real size.
            width = int.from_bytes(data[24:27], "little") + 1
            height = int.from_bytes(data[27:30], "little") + 1
            return ImageInfo(WEBP, width, height)
        if chunk == b"VP8 ":
            # The 14 low bits of each field; the top two are the scale.
            width, height = struct.unpack("<HH", data[26:30])
            return ImageInfo(WEBP, width & 0x3FFF, height & 0x3FFF)
        if chunk == b"VP8L":
            bits = int.from_bytes(data[21:25], "little")
            return ImageInfo(WEBP, (bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1)
    except (struct.error, IndexError):
        pass
    return ImageInfo(WEBP, None, None)


def _jpeg(data: bytes) -> ImageInfo | None:
    if not data.startswith(b"\xff\xd8"):
        return None

    # JPEG keeps the size in a start-of-frame segment, which sits after a
    # variable number of other segments, so the only way there is to walk them.
    offset = 2
    end = len(data)
    while offset + 9 < end:
        if data[offset] != 0xFF:
            offset += 1
            continue

        marker = data[offset + 1]
        # Standalone markers carry no length; anything else does.
        if marker in (0xD8, 0xD9) or 0xD0 <= marker <= 0xD7:
            offset += 2
            continue
        if 0xC0 <= marker <= 0xCF and marker not in (0xC4, 0xC8, 0xCC):
            height, width = struct.unpack(">HH", data[offset + 5 : offset + 9])
            return ImageInfo(JPEG, width, height)

        length = struct.unpack(">H", data[offset + 2 : offset + 4])[0]
        if length < 2:
            break
        offset += 2 + length

    return ImageInfo(JPEG, None, None)
