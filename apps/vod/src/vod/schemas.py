"""What the HTTP face hands out.

Pydantic rather than TypedDict here: FastAPI turns these into the OpenAPI schema,
so `/docs` describes the real shape instead of a bare object.
"""

from pydantic import BaseModel

from vod.store import Vod


class HealthOut(BaseModel):
    status: str
    vods: int
    proxy: str


class VodOut(BaseModel):
    id: int
    url: str
    playlist: str
    title: str | None
    poster: str | None
    created_at: str

    @classmethod
    def of(cls, vod: Vod, base: str) -> "VodOut":
        """Deliberately without `playlist_url`: outside, a VOD is our URL only."""
        return cls(
            id=vod.id,
            url=f"{base}/{vod.id}",
            playlist=f"{base}/{vod.id}/index.m3u8",
            title=vod.title,
            poster=vod.poster,
            created_at=vod.created_at,
        )
