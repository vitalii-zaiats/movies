"""Tokens and passwords.

Two different problems, deliberately solved two different ways:

*Session tokens* are 256 bits of `secrets` output. Nobody guesses those, so the
lookup hash only needs to be one-way, not slow — SHA-256 is right, and it lets
the token column carry a unique index that a single `SELECT` can hit.

*Passwords* are whatever a person typed, so the hash has to be expensive on
purpose. `hashlib.scrypt` is memory-hard and it's in the standard library, which
is worth more here than shaving a few milliseconds off with a third-party
argon2 build that has to be compiled into every image.
"""

import hashlib
import hmac
import secrets

# ~16 MiB and ~100 ms on the kind of box this runs on. The parameters travel
# inside the stored string, so raising them later doesn't invalidate old hashes.
_N = 2**14
_R = 8
_P = 1
_DKLEN = 32
_SCHEME = "scrypt"


def new_token() -> str:
    """A raw session token. Handed to the client once and never stored as-is."""
    return secrets.token_urlsafe(32)


def token_digest(token: str) -> str:
    """What actually goes in the database, so a table leak isn't a login."""
    return hashlib.sha256(token.encode()).hexdigest()


def hash_password(password: str) -> str:
    salt = secrets.token_bytes(16)
    derived = hashlib.scrypt(
        password.encode(), salt=salt, n=_N, r=_R, p=_P, dklen=_DKLEN, maxmem=64 * 1024 * 1024
    )
    return f"{_SCHEME}${_N}${_R}${_P}${salt.hex()}${derived.hex()}"


def verify_password(password: str, encoded: str | None) -> bool:
    """False for a wrong password and false for an account that has none.

    A guest has `password_hash = None`; treating that as "no password matches"
    rather than "any password matches" is the whole reason this takes an
    optional.
    """
    if not encoded:
        return False

    try:
        scheme, n, r, p, salt, expected = encoded.split("$")
        if scheme != _SCHEME:
            return False
        derived = hashlib.scrypt(
            password.encode(),
            salt=bytes.fromhex(salt),
            n=int(n),
            r=int(r),
            p=int(p),
            dklen=len(expected) // 2,
            maxmem=64 * 1024 * 1024,
        )
    except (ValueError, TypeError):
        return False

    return hmac.compare_digest(derived.hex(), expected)
