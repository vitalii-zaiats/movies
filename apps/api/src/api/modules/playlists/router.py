"""Playlist routes.

Every one of them takes `CurrentUser`: a playlist belongs to somebody, and a
caller without a token becomes a guest rather than being turned away. Ordering
decisions live in `PlaylistService`; this file only turns requests into calls
and models into DTOs.
"""

from typing import Annotated

from fastapi import APIRouter, Query

from api.modules.accounts.deps import CurrentUser
from api.modules.playlists.deps import Playlists
from api.modules.playlists.schemas import (
    PlaylistAddItem,
    PlaylistCreate,
    PlaylistDetail,
    PlaylistFromShow,
    PlaylistOut,
    PlaylistReorder,
    PlaylistUpdate,
    playlist_detail,
    playlist_out,
)
from api.modules.playlists.service import Scope

router = APIRouter(prefix="/playlists", tags=["playlists"])


@router.get("", response_model=list[PlaylistOut])
async def list_playlists(
    user: CurrentUser,
    playlists: Playlists,
    scope: Annotated[
        Scope, Query(description="yours plus public, only yours, or only public")
    ] = "visible",
) -> list[PlaylistOut]:
    """Yours plus whatever's published. An admin asking for everything gets it."""
    return [playlist_out(playlist, user) for playlist in await playlists.all(user, scope=scope)]


@router.post("", response_model=PlaylistDetail, status_code=201)
async def create_playlist(
    body: PlaylistCreate, user: CurrentUser, playlists: Playlists
) -> PlaylistDetail:
    return playlist_detail(await playlists.create(body.name, user), user)


@router.post("/from-show", response_model=PlaylistDetail, status_code=201)
async def create_from_show(
    body: PlaylistFromShow, user: CurrentUser, playlists: Playlists
) -> PlaylistDetail:
    playlist = await playlists.from_show(
        user,
        show_key=body.show,
        season=body.season,
        name=body.name,
        playable_only=body.playable_only,
    )
    return playlist_detail(playlist, user)


@router.get("/{playlist_id}", response_model=PlaylistDetail)
async def read_playlist(
    playlist_id: int, user: CurrentUser, playlists: Playlists
) -> PlaylistDetail:
    return playlist_detail(await playlists.get(playlist_id, user), user)


@router.patch("/{playlist_id}", response_model=PlaylistDetail)
async def update_playlist(
    playlist_id: int, body: PlaylistUpdate, user: CurrentUser, playlists: Playlists
) -> PlaylistDetail:
    """Rename, publish, or unpublish. Publishing is an admin's call."""
    playlist = await playlists.update(
        playlist_id, user, name=body.name, visibility=body.visibility
    )
    return playlist_detail(playlist, user)


@router.delete("/{playlist_id}", status_code=204)
async def delete_playlist(playlist_id: int, user: CurrentUser, playlists: Playlists) -> None:
    await playlists.delete(playlist_id, user)


@router.post("/{playlist_id}/items", response_model=PlaylistDetail, status_code=201)
async def add_item(
    playlist_id: int, body: PlaylistAddItem, user: CurrentUser, playlists: Playlists
) -> PlaylistDetail:
    return playlist_detail(await playlists.add_item(playlist_id, body.episode_id, user), user)


@router.delete("/{playlist_id}/items/{item_id}", response_model=PlaylistDetail)
async def remove_item(
    playlist_id: int, item_id: int, user: CurrentUser, playlists: Playlists
) -> PlaylistDetail:
    return playlist_detail(await playlists.remove_item(playlist_id, item_id, user), user)


@router.put("/{playlist_id}/order", response_model=PlaylistDetail)
async def reorder(
    playlist_id: int, body: PlaylistReorder, user: CurrentUser, playlists: Playlists
) -> PlaylistDetail:
    return playlist_detail(await playlists.reorder(playlist_id, body.item_ids, user), user)
