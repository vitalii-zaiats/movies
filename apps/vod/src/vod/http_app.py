"""The public face: `vod.localhost/1` and the playlist behind it.

A player only ever talks to this service. `GET /{id}/index.m3u8` answers with the
playlist itself — no redirect — having fetched it through apps/proxy on the
server side, and every link inside it points back here at `/{id}/media`.
"""

from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from urllib.parse import urlsplit

import httpx
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse

from vod.relay import PLAYLIST_HEADERS, Relay, is_playlist
from vod.store import VodStore


def create_app(store: VodStore, public_url: str, proxy_url: str) -> FastAPI:
    base = public_url.rstrip("/")
    relay = Relay(proxy_url)

    @asynccontextmanager
    async def lifespan(_: FastAPI) -> AsyncIterator[None]:
        yield
        await relay.aclose()

    app = FastAPI(title="vod", version="0.1.0", lifespan=lifespan)

    # The page playing this is served from somewhere else (:5173, a TV, a phone).
    app.add_middleware(
        CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"]
    )

    @app.get("/health")
    async def health() -> dict:
        return {"status": "ok", "vods": await store.count(), "proxy": proxy_url}

    @app.get("/{vod_id}")
    async def read(vod_id: int) -> dict:
        vod = await _get(vod_id)
        # No upstream URL in here on purpose — outside, a VOD is our URL only.
        return {
            "id": vod.id,
            "url": f"{base}/{vod.id}",
            "playlist": f"{base}/{vod.id}/index.m3u8",
            "title": vod.title,
            "poster": vod.poster,
            "created_at": vod.created_at,
        }

    @app.get("/{vod_id}/index.m3u8")
    async def playlist(vod_id: int) -> Response:
        vod = await _get(vod_id)
        status, body, content_type = await _fetch_playlist(vod.playlist_url)
        return Response(
            content=body, status_code=status, media_type=content_type, headers=PLAYLIST_HEADERS
        )

    @app.get("/{vod_id}/media")
    async def media(vod_id: int, u: str, request: Request) -> Response:
        """Variants and segments. `u` is only ever a link we wrote ourselves."""
        await _get(vod_id)

        if urlsplit(u).scheme not in ("http", "https"):
            raise HTTPException(status_code=400, detail="u must be an absolute http(s) URL")

        if is_playlist(u):
            status, body, content_type = await _fetch_playlist(u)
            return Response(
                content=body,
                status_code=status,
                media_type=content_type,
                headers=PLAYLIST_HEADERS,
            )

        try:
            upstream, chunks = await relay.open(u, request.headers.get("range"))
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=502, detail=f"upstream failed: {exc}") from exc

        async def body() -> AsyncIterator[bytes]:
            try:
                async for chunk in chunks:
                    yield chunk
            finally:
                await upstream.aclose()

        return StreamingResponse(
            body(), status_code=upstream.status_code, headers=Relay.headers_from(upstream)
        )

    async def _fetch_playlist(url: str) -> tuple[int, str, str]:
        try:
            return await relay.playlist(url)
        except httpx.HTTPError as exc:
            raise HTTPException(status_code=502, detail=f"upstream failed: {exc}") from exc

    async def _get(vod_id: int):
        vod = await store.get(vod_id)
        if vod is None:
            raise HTTPException(status_code=404, detail=f"no vod {vod_id}")
        return vod

    return app
