"""Who's calling, and how they stop being nobody.

Every method that creates a session returns the token in the message *and* in
the `x-session-token` metadata. Twice on purpose: the field is for the call that
was about signing in, the metadata is for every other call, where a guest gets
minted as a side effect and the client shouldn't have to know which RPC did it.
"""

import grpc
from contracts import catalogue_pb2 as pb
from contracts import catalogue_pb2_grpc as stubs

from api.modules.accounts.schemas import UserOut
from api.modules.accounts.service import Credential
from api.rpc import convert
from api.rpc.calls import call, user_agent


async def _identity(rpc, credential: Credential) -> pb.Identity:  # type: ignore[no-untyped-def]
    """A new session: hand the token back both ways."""
    await rpc.issue(credential.token)
    return convert.identity(credential.token, UserOut.model_validate(credential.user))


class AccountsService(stubs.AccountsServicer):
    async def WhoAmI(
        self, request: pb.WhoAmIRequest, context: grpc.aio.ServicerContext
    ) -> pb.Identity:
        """The first call a client makes.

        A caller with a token gets themselves back and an empty `token` field —
        they already have theirs, and echoing it would tempt somebody into
        storing it twice. A caller with none becomes a guest, and that one does
        come with a token.
        """
        async with call(context) as rpc:
            known = await rpc.viewer()
            if known is not None:
                return pb.Identity(token="", user=convert.user(UserOut.model_validate(known)))

            credential = await rpc.services.accounts.guest(user_agent=user_agent(context))
            return await _identity(rpc, credential)

    async def StartGuest(
        self, request: pb.StartGuestRequest, context: grpc.aio.ServicerContext
    ) -> pb.Identity:
        """A *new* guest, unconditionally — even for a caller who already is one.

        That's what makes it "watch as someone else on the shared TV" rather
        than a slower `WhoAmI`.
        """
        async with call(context) as rpc:
            credential = await rpc.services.accounts.guest(user_agent=user_agent(context))
            return await _identity(rpc, credential)

    async def Claim(
        self, request: pb.ClaimRequest, context: grpc.aio.ServicerContext
    ) -> pb.Identity:
        """Keep the account, add the login.

        Everything watched as a guest stays where it is: an email and a password
        are written onto that same row, and the session it comes back with is a
        new one for the same person.
        """
        async with call(context) as rpc:
            credential = await rpc.services.accounts.claim(
                await rpc.user(),
                email=request.email,
                password=request.password,
                display_name=request.display_name if request.HasField("display_name") else None,
                user_agent=user_agent(context),
            )
            return await _identity(rpc, credential)

    async def Login(
        self, request: pb.LoginRequest, context: grpc.aio.ServicerContext
    ) -> pb.Identity:
        async with call(context) as rpc:
            credential = await rpc.services.accounts.login(
                request.email, request.password, user_agent=user_agent(context)
            )
            return await _identity(rpc, credential)

    async def Logout(
        self, request: pb.LogoutRequest, context: grpc.aio.ServicerContext
    ) -> pb.LogoutResponse:
        async with call(context) as rpc:
            await rpc.services.accounts.logout(rpc.token)
        return pb.LogoutResponse()

    async def Rename(
        self, request: pb.RenameRequest, context: grpc.aio.ServicerContext
    ) -> pb.User:
        async with call(context) as rpc:
            user = await rpc.services.accounts.rename(await rpc.user(), request.display_name)
            return convert.user(UserOut.model_validate(user))
