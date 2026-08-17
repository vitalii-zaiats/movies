"""How a token travels between the client and us.

Two ways in, because two very different clients have to work:

* `Authorization: Bearer …` — the TV, a script, curl. Explicit, no cookie jar.
* a cookie — the browser app, which gets one for free and keeps it across
  reloads. That's what makes a guest survive a refresh without any JavaScript
  deciding where to stash a token.

The header wins when both are present: if somebody bothered to send one, they
mean it.

Handing a *new* token back goes through `request.state`, not through the
`Response` a dependency was given. A route that mints a guest and then raises
`NotFound` would otherwise drop the token on the floor and mint another guest on
the next request; going through the middleware means the token rides out on
whatever response actually gets sent, error or not.
"""

from collections.abc import Awaitable, Callable

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

from api.settings import settings

STATE_KEY = "issued_token"
# For clients that can't see a Set-Cookie — the TV app reads this once and then
# sends it as a bearer token forever after.
TOKEN_HEADER = "X-Session-Token"


def read_token(request: Request) -> str | None:
    scheme, _, value = request.headers.get("authorization", "").partition(" ")
    if scheme.lower() == "bearer" and value.strip():
        return value.strip()
    return request.cookies.get(settings.session_cookie)


def issue_token(request: Request, token: str) -> None:
    """Mark this request as having created a session. The middleware ships it."""
    setattr(request.state, STATE_KEY, token)


def attach_token(response: Response, token: str) -> None:
    response.headers[TOKEN_HEADER] = token
    response.set_cookie(
        settings.session_cookie,
        token,
        max_age=settings.session_ttl_seconds,
        httponly=True,
        samesite="lax",
        secure=settings.session_cookie_secure,
        path="/",
    )


def clear_token(response: Response) -> None:
    response.delete_cookie(settings.session_cookie, path="/")


class SessionMiddleware(BaseHTTPMiddleware):
    async def dispatch(
        self, request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        response = await call_next(request)
        token = getattr(request.state, STATE_KEY, None)
        if token:
            attach_token(response, token)
        return response
