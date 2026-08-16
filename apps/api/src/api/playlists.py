"""Playlists: the ordered queues a screen plays through.

A playlist is a catalogue object, not a media file — the m3u8 stays in the VOD
service. What lives here is *which* episodes, and *in what order*.
"""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from api.db import get_session
from api.models import Episode, Playlist, PlaylistItem, Show
from api.schemas import (
    PlaylistAddItem,
    PlaylistCreate,
    PlaylistDetail,
    PlaylistFromShow,
    PlaylistOut,
    PlaylistReorder,
    playlist_detail,
    playlist_out,
)

router = APIRouter(prefix="/playlists", tags=["playlists"])

DB = Annotated[AsyncSession, Depends(get_session)]


@router.get("", response_model=list[PlaylistOut])
async def list_playlists(session: DB) -> list[PlaylistOut]:
    rows = await session.scalars(select(Playlist).order_by(Playlist.id))
    return [playlist_out(row) for row in rows]


@router.post("", response_model=PlaylistDetail, status_code=201)
async def create_playlist(body: PlaylistCreate, session: DB) -> PlaylistDetail:
    playlist = Playlist(name=body.name.strip() or "untitled")
    session.add(playlist)
    await session.commit()
    await session.refresh(playlist)
    return playlist_detail(playlist)


@router.post("/from-show", response_model=PlaylistDetail, status_code=201)
async def create_from_show(body: PlaylistFromShow, session: DB) -> PlaylistDetail:
    """Build a queue out of a whole show, or one season of it, already in order."""
    query = select(Episode).join(Show).where(Show.key == body.show)
    if body.season is not None:
        query = query.where(Episode.season == body.season)
    if body.playable_only:
        query = query.where(Episode.vod_url.is_not(None))

    episodes = list(
        (await session.scalars(query.order_by(Episode.season, Episode.episode))).unique()
    )
    if not episodes:
        raise HTTPException(status_code=404, detail=f"no playable episodes for {body.show!r}")

    default = body.show if body.season is None else f"{body.show} S{body.season:02d}"
    playlist = Playlist(name=(body.name or default).strip())
    playlist.items = [
        PlaylistItem(episode_id=episode.id, position=index)
        for index, episode in enumerate(episodes)
    ]
    session.add(playlist)
    await session.commit()
    await session.refresh(playlist)
    return playlist_detail(playlist)


@router.get("/{playlist_id}", response_model=PlaylistDetail)
async def read_playlist(playlist_id: int, session: DB) -> PlaylistDetail:
    return playlist_detail(await _get(session, playlist_id))


@router.delete("/{playlist_id}", status_code=204)
async def delete_playlist(playlist_id: int, session: DB) -> None:
    await session.delete(await _get(session, playlist_id))
    await session.commit()


@router.post("/{playlist_id}/items", response_model=PlaylistDetail, status_code=201)
async def add_item(playlist_id: int, body: PlaylistAddItem, session: DB) -> PlaylistDetail:
    playlist = await _get(session, playlist_id)

    episode = await session.get(Episode, body.episode_id)
    if episode is None:
        raise HTTPException(status_code=404, detail=f"no episode {body.episode_id}")
    if any(item.episode_id == episode.id for item in playlist.items):
        raise HTTPException(status_code=409, detail="already in this playlist")

    playlist.items.append(PlaylistItem(episode_id=episode.id, position=len(playlist.items)))
    await session.commit()
    await session.refresh(playlist)
    return playlist_detail(playlist)


@router.delete("/{playlist_id}/items/{item_id}", response_model=PlaylistDetail)
async def remove_item(playlist_id: int, item_id: int, session: DB) -> PlaylistDetail:
    playlist = await _get(session, playlist_id)

    item = next((i for i in playlist.items if i.id == item_id), None)
    if item is None:
        raise HTTPException(status_code=404, detail=f"no item {item_id} in this playlist")

    playlist.items.remove(item)
    _renumber(playlist)
    await session.commit()
    await session.refresh(playlist)
    return playlist_detail(playlist)


@router.put("/{playlist_id}/order", response_model=PlaylistDetail)
async def reorder(playlist_id: int, body: PlaylistReorder, session: DB) -> PlaylistDetail:
    playlist = await _get(session, playlist_id)

    by_id = {item.id: item for item in playlist.items}
    if set(body.item_ids) != set(by_id):
        raise HTTPException(status_code=400, detail="item_ids must list every item exactly once")

    for position, item_id in enumerate(body.item_ids):
        by_id[item_id].position = position
    await session.commit()
    await session.refresh(playlist)
    return playlist_detail(playlist)


async def _get(session: AsyncSession, playlist_id: int) -> Playlist:
    playlist = await session.get(Playlist, playlist_id)
    if playlist is None:
        raise HTTPException(status_code=404, detail=f"no playlist {playlist_id}")
    return playlist


def _renumber(playlist: Playlist) -> None:
    """Keep positions dense — the display walks them by index."""
    for position, item in enumerate(playlist.items):
        item.position = position
