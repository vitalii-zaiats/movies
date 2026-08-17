"""The three ways a route can ask who's calling.

    Viewer       whoever they are, or nobody. Never creates anything.
    CurrentUser  somebody, guaranteed — mints a guest if it has to.
    Admin        somebody with the role, or a refusal.

The split matters. `CurrentUser` writes a row, so it belongs on routes that are
*about* a person: progress, history, playlists. Putting it on `GET /episodes`
would hand every crawler and every uncached page load its own user.
"""

from typing import Annotated

from fastapi import Depends, Request

from api.core.deps import DB
from api.errors import Forbidden, Unauthorized
from api.modules.accounts.models import User
from api.modules.accounts.service import AccountService
from api.modules.accounts.transport import issue_token, read_token


def account_service(session: DB) -> AccountService:
    return AccountService(session)


Accounts = Annotated[AccountService, Depends(account_service)]


async def viewer(request: Request, accounts: Accounts) -> User | None:
    """Personalise if we can, stay anonymous if we can't."""
    return await accounts.identify(read_token(request))


Viewer = Annotated[User | None, Depends(viewer)]


async def current_user(request: Request, accounts: Accounts) -> User:
    """Everyone who asks gets an identity, even before they ask for one."""
    user = await accounts.identify(read_token(request))
    if user is not None:
        return user

    credential = await accounts.guest(user_agent=request.headers.get("user-agent"))
    issue_token(request, credential.token)
    return credential.user


CurrentUser = Annotated[User, Depends(current_user)]


async def admin(user: Viewer) -> User:
    """Deliberately built on `Viewer`: a stranger poking an admin route should
    get a 401, not a brand new guest row plus a 403."""
    if user is None:
        raise Unauthorized("this needs an account")
    if not user.is_admin:
        raise Forbidden("admins only")
    return user


Admin = Annotated[User, Depends(admin)]
