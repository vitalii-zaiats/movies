"""Auth routes, and the admin's view of who exists.

`GET /auth/me` is the one a client calls first: it answers "who am I" and, if
the answer would have been nobody, quietly makes it somebody.
"""

from typing import Annotated

from fastapi import APIRouter, Query, Request, Response

from api.modules.accounts.deps import Accounts, Admin, CurrentUser
from api.modules.accounts.models import User
from api.modules.accounts.schemas import (
    ClaimRequest,
    DeviceApproval,
    DeviceCollect,
    DeviceLinkOut,
    DeviceLinkStatus,
    DeviceSession,
    Identity,
    LoginRequest,
    RenameRequest,
    RoleRequest,
    UserOut,
    UserPage,
)
from api.modules.accounts.service import Credential
from api.modules.accounts.transport import attach_token, clear_token, read_token

router = APIRouter(tags=["accounts"])


def _identity(credential: Credential) -> Identity:
    return Identity(token=credential.token, user=UserOut.model_validate(credential.user))


@router.get("/auth/me", response_model=UserOut)
async def me(user: CurrentUser) -> User:
    return user


@router.post("/auth/guest", response_model=Identity, status_code=201)
async def start_guest(request: Request, response: Response, accounts: Accounts) -> Identity:
    """A guest on demand, for a client that would rather not wait to be given one.

    Deliberately unconditional: calling it while already signed in starts a
    *second*, empty identity rather than handing back the first. That's what
    makes it usable as "watch as someone else on the shared TV".
    """
    credential = await accounts.guest(user_agent=request.headers.get("user-agent"))
    attach_token(response, credential.token)
    return _identity(credential)


@router.post("/auth/claim", response_model=Identity, status_code=201)
async def claim(
    body: ClaimRequest,
    request: Request,
    response: Response,
    user: CurrentUser,
    accounts: Accounts,
) -> Identity:
    """Keep the account, add the login.

    Everything watched as a guest stays where it is — this writes an email and a
    password onto that same row.
    """
    credential = await accounts.claim(
        user,
        email=str(body.email),
        password=body.password,
        display_name=body.display_name,
        user_agent=request.headers.get("user-agent"),
    )
    attach_token(response, credential.token)
    return _identity(credential)


@router.post("/auth/login", response_model=Identity)
async def login(
    body: LoginRequest, request: Request, response: Response, accounts: Accounts
) -> Identity:
    credential = await accounts.login(
        str(body.email), body.password, user_agent=request.headers.get("user-agent")
    )
    attach_token(response, credential.token)
    return _identity(credential)


@router.post("/auth/logout", status_code=204)
async def logout(request: Request, response: Response, accounts: Accounts) -> None:
    await accounts.logout(read_token(request))
    clear_token(response)


@router.patch("/auth/me", response_model=UserOut)
async def rename(body: RenameRequest, user: CurrentUser, accounts: Accounts) -> User:
    return await accounts.rename(user, body.display_name)


@router.get("/users", response_model=UserPage)
async def list_users(
    _: Admin,
    accounts: Accounts,
    guests: Annotated[bool | None, Query(description="only guests, or only claimed")] = None,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> UserPage:
    users, total = await accounts.all_users(limit=limit, offset=offset, guests=guests)
    return UserPage(
        total=total,
        limit=limit,
        offset=offset,
        items=[UserOut.model_validate(user) for user in users],
    )


@router.patch("/users/{public_id}/role", response_model=UserOut)
async def set_role(public_id: str, body: RoleRequest, _: Admin, accounts: Accounts) -> User:
    return await accounts.set_role(public_id, body.role)


# --- signing in a device with no keyboard ------------------------------------
#
# Typing an email and a password with a remote is miserable, so the television
# never asks for either. It shows a code, a phone opens that code in a browser
# and approves it as whoever is signed in there, and the television collects a
# session of its own.
#
# The two halves are deliberately not the same secret. The code is short because
# it is read off a screen; knowing it only lets somebody *approve*. The secret
# stays inside the television and is the only thing that can collect the
# session — so even a code approved by the wrong person hands the token to the
# device that asked for it, and to nothing else.


@router.post("/auth/device", response_model=DeviceLinkOut, status_code=201)
async def start_device_link(request: Request, accounts: Accounts) -> DeviceLinkOut:
    """Begin a pairing. Deliberately open: nobody is signed in yet."""
    link = await accounts.start_link(device_name=request.headers.get("user-agent"))
    return DeviceLinkOut.of(link)


@router.get("/auth/device/{code}", response_model=DeviceLinkStatus)
async def device_link_status(code: str, accounts: Accounts) -> DeviceLinkStatus:
    """What is being asked for, for the page that is about to say yes."""
    return DeviceLinkStatus.of(await accounts.link_for(code))


@router.post("/auth/device/approve", response_model=DeviceLinkStatus)
async def approve_device_link(
    body: DeviceApproval, user: CurrentUser, accounts: Accounts
) -> DeviceLinkStatus:
    """Say yes, as somebody. The only step in this dance that needs an identity,
    and it is the phone's."""
    return DeviceLinkStatus.of(await accounts.approve_link(body.code, user))


@router.post("/auth/device/collect", response_model=DeviceSession)
async def collect_device_link(
    body: DeviceCollect, request: Request, response: Response, accounts: Accounts
) -> DeviceSession:
    """The television asking whether it may come in yet."""
    credential = await accounts.collect_link(
        body.secret, user_agent=request.headers.get("user-agent")
    )
    if credential is None:
        return DeviceSession(status="pending")

    attach_token(response, credential.token)
    return DeviceSession(status="linked", identity=_identity(credential))
