"""Room codes and the shape of what travels over the wire.

The TypeScript mirror of this lives in `web/src/lib/protocol.ts` — keep the two
in step.
"""

import secrets
from typing import Literal

# No 0/O/1/I: the code gets read off a screen and typed by hand often enough.
ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
CODE_LENGTH = 6

# A room outlives brief disconnects but not a closed tab left overnight.
ROOM_TTL = 3600

Role = Literal["display", "remote"]

ROOM_KEY = "hub:room:{code}"
ROOM_CHANNEL = "hub:room:{code}:bus"


def new_code() -> str:
    return "".join(secrets.choice(ALPHABET) for _ in range(CODE_LENGTH))


def normalise_code(value: str) -> str:
    return value.strip().upper()


def is_code(value: str) -> bool:
    value = normalise_code(value)
    return len(value) == CODE_LENGTH and all(char in ALPHABET for char in value)
