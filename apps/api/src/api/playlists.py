"""Playlist routes.

A playlist is a catalogue object — an ordered list of episodes, not a media
file. Every decision about ordering lives in `PlaylistService`; this file only
turns requests into calls and models into DTOs.
"""

from fastapi import APIRouter

from api.deps import Playlists
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


@router.get("", response_model=list[PlaylistOut])
async def list_playlists(playlists: Playlists) -> list[PlaylistOut]:
    return [playlist_out(playlist) for playlist in await playlists.all()]


@router.post("", response_model=PlaylistDetail, status_code=201)
async def create_playlist(body: PlaylistCreate, playlists: Playlists) -> PlaylistDetail:
    return playlist_detail(await playlists.create(body.name))


@router.post("/from-show", response_model=PlaylistDetail, status_code=201)
async def create_from_show(body: PlaylistFromShow, playlists: Playlists) -> PlaylistDetail:
    playlist = await playlists.from_show(
        show_key=body.show,
        season=body.season,
        name=body.name,
        playable_only=body.playable_only,
    )
    return playlist_detail(playlist)


@router.get("/{playlist_id}", response_model=PlaylistDetail)
async def read_playlist(playlist_id: int, playlists: Playlists) -> PlaylistDetail:
    return playlist_detail(await playlists.get(playlist_id))


@router.delete("/{playlist_id}", status_code=204)
async def delete_playlist(playlist_id: int, playlists: Playlists) -> None:
    await playlists.delete(playlist_id)


@router.post("/{playlist_id}/items", response_model=PlaylistDetail, status_code=201)
async def add_item(
    playlist_id: int, body: PlaylistAddItem, playlists: Playlists
) -> PlaylistDetail:
    return playlist_detail(await playlists.add_item(playlist_id, body.episode_id))


@router.delete("/{playlist_id}/items/{item_id}", response_model=PlaylistDetail)
async def remove_item(playlist_id: int, item_id: int, playlists: Playlists) -> PlaylistDetail:
    return playlist_detail(await playlists.remove_item(playlist_id, item_id))


@router.put("/{playlist_id}/order", response_model=PlaylistDetail)
async def reorder(
    playlist_id: int, body: PlaylistReorder, playlists: Playlists
) -> PlaylistDetail:
    return playlist_detail(await playlists.reorder(playlist_id, body.item_ids))
