"""What a servicer method gets: a session, the services, and who's calling.

The HTTP layer answers "who's calling" from a cookie or a bearer header, and
hands a freshly minted guest back through a middleware. gRPC has no cookies and
no middleware, so both halves live here:

    in    `authorization: Bearer <token>` metadata, or `x-session-token`
    out   `x-session-token` in the *initial* metadata, whenever this call was
          the one that created the session

That's the whole protocol. A client keeps whatever comes back and sends it
afterwards; a client that keeps nothing is a new guest every time, which is
wasteful but not broken.

The three ways to ask are the same three the routes have, and they mean the same
things — `viewer` never creates anything, `user` always ends up with somebody,
`admin` refuses rather than minting.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from dataclasses import dataclass, field

import grpc

from api.core.database import Session
from api.core.services import Services, build
from api.errors import Forbidden, Unauthorized
from api.modules.accounts.models import User

# Lowercase on purpose: gRPC normalises metadata keys, and a client sending
# `X-Session-Token` would find it here under this name anyway.
TOKEN_METADATA = "x-session-token"


def read_token(context: grpc.aio.ServicerContext) -> str | None:
    """The bearer token, or the bare one, or nothing at all."""
    metadata = dict(context.invocation_metadata() or ())

    scheme, _, value = str(metadata.get("authorization", "")).partition(" ")
    if scheme.lower() == "bearer" and value.strip():
        return value.strip()

    # For clients whose transport already spends `authorization` on something
    # else — a proxy in front of us, say. Same token, plainer envelope.
    bare = str(metadata.get(TOKEN_METADATA, "")).strip()
    return bare or None


def user_agent(context: grpc.aio.ServicerContext) -> str | None:
    """Whatever the client called itself. Recorded on the session, nothing more."""
    metadata = dict(context.invocation_metadata() or ())
    agent = metadata.get("user-agent")
    return str(agent) if agent else None


@dataclass(slots=True)
class Call:
    """One RPC's worth of context."""

    services: Services
    context: grpc.aio.ServicerContext
    # Initial metadata may only be sent once, and only before the first
    # response. Two `user()` calls in one method is a reasonable thing to write,
    # so the second one must not blow up.
    _issued: bool = field(default=False, init=False)

    @property
    def token(self) -> str | None:
        return read_token(self.context)

    async def viewer(self) -> User | None:
        """Personalise if we can, stay anonymous if we can't."""
        return await self.services.accounts.identify(self.token)

    async def user(self) -> User:
        """Everyone who asks gets an identity, even before they ask for one."""
        found = await self.services.accounts.identify(self.token)
        if found is not None:
            return found

        credential = await self.services.accounts.guest(user_agent=user_agent(self.context))
        await self.issue(credential.token)
        return credential.user

    async def admin(self) -> User:
        """Built on `viewer`: a stranger poking an admin method should be turned
        away, not given a brand new guest row and *then* turned away."""
        found = await self.viewer()
        if found is None:
            raise Unauthorized("this needs an account")
        if not found.is_admin:
            raise Forbidden("admins only")
        return found

    async def issue(self, token: str) -> None:
        """Hand a newly created session back to whoever caused it."""
        if self._issued:
            return
        self._issued = True
        await self.context.send_initial_metadata(((TOKEN_METADATA, token),))


@asynccontextmanager
async def call(context: grpc.aio.ServicerContext) -> AsyncIterator[Call]:
    """A session for this RPC, closed when it returns.

    One per call, not one per connection: a session is a unit of work, and a
    phone that holds a channel open for an hour must not hold a transaction open
    for one.
    """
    async with Session() as session:
        yield Call(build(session), context)
