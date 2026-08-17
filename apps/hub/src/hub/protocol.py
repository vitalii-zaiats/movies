"""Room codes and the shape of what travels over the wire.

The TypeScript mirror of this lives in `web/src/lib/protocol.ts` — keep the two
in step.
"""

import secrets
from typing import Any, Literal, TypedDict

# No 0/O/1/I: the code gets read off a screen and typed by hand often enough.
ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
CODE_LENGTH = 6

# A room outlives brief disconnects but not a closed tab left overnight.
ROOM_TTL = 3600

Role = Literal["display", "remote"]

ROOM_KEY = "hub:room:{code}"
ROOM_CHANNEL = "hub:room:{code}:bus"

# What clients exchange. The hub reads `type` and nothing else, so this stays an
# open object on purpose — the display and the remote own the rest of it.
Body = dict[str, Any]


class Envelope(TypedDict):
    """One message on a room's bus."""

    room: str
    # Who sent it, so it isn't delivered back to them. None for hub-generated news.
    sender: str | None
    body: Body


class Counts(TypedDict):
    displays: int
    remotes: int


def new_code() -> str:
    return "".join(secrets.choice(ALPHABET) for _ in range(CODE_LENGTH))


def normalise_code(value: str) -> str:
    return value.strip().upper()


def is_code(value: str) -> bool:
    value = normalise_code(value)
    return len(value) == CODE_LENGTH and all(char in ALPHABET for char in value)
