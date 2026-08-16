"""One route: `GET /?url=<absolute url>` — fetch it upstream, stream it back.

Exists because HLS hosts pin CORS to their own origin, so a browser on another
origin can't read their playlists. Everything here serves that one job.
"""

import asyncio
import ssl
from collections.abc import AsyncIterator
from urllib.parse import SplitResult, urlsplit

import certifi
from aiohttp import ClientError, ClientSession, ClientTimeout, TCPConnector, web

from proxy.playlist import is_playlist, rewrite

CHUNK = 64 * 1024
TIMEOUT = ClientTimeout(total=None, sock_connect=15, sock_read=60)

USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
)

# From the client to the origin: what a media player actually needs.
FORWARD = ("range", "if-range", "accept")

# From the origin back to the client. Deliberately no content-encoding —
# the client library already decoded the body for us.
RETURN = (
    "content-type",
    "accept-ranges",
    "content-range",
    "cache-control",
    "etag",
    "last-modified",
)

CORS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "*",
    "Access-Control-Expose-Headers": "*",
    "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
}


def create_app(allow_hosts: frozenset[str] = frozenset()) -> web.Application:
    app = web.Application()
    app["allow_hosts"] = allow_hosts
    app.cleanup_ctx.append(_session)
    # web.get() registers HEAD on the same handler — asking for it again is an error.
    app.add_routes([web.get("/", handle), web.options("/", preflight)])
    return app


async def _session(app: web.Application) -> AsyncIterator[None]:
    """One connection pool for the process lifetime.

    Verify against certifi rather than the stdlib default: on this machine the
    system bundle rejects hosts (self-signed cert in chain) that certifi accepts,
    which is also why httpx-based members here work out of the box.
    """
    context = ssl.create_default_context(cafile=certifi.where())
    async with ClientSession(timeout=TIMEOUT, connector=TCPConnector(ssl=context)) as session:
        app["session"] = session
        yield


async def preflight(_: web.Request) -> web.Response:
    return web.Response(status=204, headers=CORS)


async def handle(request: web.Request) -> web.StreamResponse:
    target = request.query.get("url", "").strip()
    if not target:
        raise web.HTTPBadRequest(text="missing ?url=", headers=CORS)

    parts = urlsplit(target)
    if parts.scheme not in ("http", "https") or not parts.hostname:
        raise web.HTTPBadRequest(text="url must be an absolute http(s) URL", headers=CORS)

    allow_hosts = request.app["allow_hosts"]
    if allow_hosts and parts.hostname not in allow_hosts:
        raise web.HTTPForbidden(text=f"host not allowed: {parts.hostname}", headers=CORS)

    session: ClientSession = request.app["session"]
    try:
        async with session.request(
            request.method, target, headers=_upstream_headers(request, parts)
        ) as upstream:
            content_type = upstream.headers.get("content-type")

            if request.method != "HEAD" and is_playlist(content_type, str(upstream.url)):
                return _playlist_response(upstream, await upstream.text())

            return await _stream_response(request, upstream)
    except (ClientError, asyncio.TimeoutError) as exc:
        raise web.HTTPBadGateway(text=f"upstream failed: {exc}", headers=CORS) from exc


def _upstream_headers(request: web.Request, parts: SplitResult) -> dict[str, str]:
    headers = {
        "User-Agent": USER_AGENT,
        # Look like a page on the origin itself — hosts that serve HLS commonly
        # reject requests whose Referer is somewhere else.
        "Referer": f"{parts.scheme}://{parts.netloc}/",
        "Origin": f"{parts.scheme}://{parts.netloc}",
    }
    for name in FORWARD:
        value = request.headers.get(name)
        if value:
            headers[name] = value
    return headers


def _playlist_response(upstream, text: str) -> web.Response:
    """Playlists are small, so they're read whole and rewritten in one go."""
    body = rewrite(text, str(upstream.url)).encode()
    headers = {
        **CORS,
        "Content-Type": upstream.headers.get("content-type", "application/vnd.apple.mpegurl"),
        "Cache-Control": "no-store",
    }
    return web.Response(status=upstream.status, body=body, headers=headers)


async def _stream_response(request: web.Request, upstream) -> web.StreamResponse:
    """Segments and everything else: pipe through without buffering."""
    headers = {**CORS, **{k: v for k in RETURN if (v := upstream.headers.get(k))}}

    # Only trustworthy when the body wasn't decompressed on the way in.
    if "content-encoding" not in upstream.headers:
        length = upstream.headers.get("content-length")
        if length:
            headers["Content-Length"] = length

    response = web.StreamResponse(status=upstream.status, headers=headers)
    await response.prepare(request)

    if request.method == "HEAD":
        await response.write_eof()
        return response

    try:
        async for chunk in upstream.content.iter_chunked(CHUNK):
            await response.write(chunk)
        await response.write_eof()
    except (ConnectionResetError, asyncio.CancelledError):
        pass  # player seeked away or closed the tab

    return response
