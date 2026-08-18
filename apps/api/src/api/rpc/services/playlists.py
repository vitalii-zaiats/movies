"""Playlists: the queue a screen actually plays.

Every method takes `user` — a playlist belongs to somebody, and a caller with no
token becomes a guest rather than being turned away. Who may change what is the
service's rule, not this file's: it passes the user down and lets the refusal
come back as a status.
"""

import grpc
from contracts import catalogue_pb2 as pb
from contracts import catalogue_pb2_grpc as stubs

from api.modules.playlists.schemas import playlist_detail, playlist_out
from api.rpc import convert
from api.rpc.calls import call


class PlaylistsService(stubs.PlaylistsServicer):
    async def ListPlaylists(
        self, request: pb.ListPlaylistsRequest, context: grpc.aio.ServicerContext
    ) -> pb.ListPlaylistsResponse:
        async with call(context) as rpc:
            user = await rpc.user()
            rows = await rpc.services.playlists.all(
                user, scope=convert.PLAYLIST_SCOPES[request.scope]  # type: ignore[arg-type]
            )
            items = [convert.playlist(playlist_out(row, user)) for row in rows]
        return pb.ListPlaylistsResponse(items=items)

    async def GetPlaylist(
        self, request: pb.GetPlaylistRequest, context: grpc.aio.ServicerContext
    ) -> pb.PlaylistDetail:
        async with call(context) as rpc:
            user = await rpc.user()
            row = await rpc.services.playlists.get(request.id, user)
            return convert.playlist_detail(playlist_detail(row, user))

    async def CreatePlaylist(
        self, request: pb.CreatePlaylistRequest, context: grpc.aio.ServicerContext
    ) -> pb.PlaylistDetail:
        async with call(context) as rpc:
            user = await rpc.user()
            row = await rpc.services.playlists.create(request.name, user)
            return convert.playlist_detail(playlist_detail(row, user))

    async def CreateFromShow(
        self, request: pb.CreateFromShowRequest, context: grpc.aio.ServicerContext
    ) -> pb.PlaylistDetail:
        async with call(context) as rpc:
            user = await rpc.user()
            row = await rpc.services.playlists.from_show(
                user,
                show_key=request.show,
                season=request.season if request.HasField("season") else None,
                name=request.name if request.HasField("name") else None,
                playable_only=request.playable_only,
            )
            return convert.playlist_detail(playlist_detail(row, user))

    async def UpdatePlaylist(
        self, request: pb.UpdatePlaylistRequest, context: grpc.aio.ServicerContext
    ) -> pb.PlaylistDetail:
        """Rename, publish, or take it down. What isn't sent is left alone."""
        visibility = (
            convert.VISIBILITY_FROM.get(request.visibility)
            if request.HasField("visibility")
            else None
        )
        async with call(context) as rpc:
            user = await rpc.user()
            row = await rpc.services.playlists.update(
                request.id,
                user,
                name=request.name if request.HasField("name") else None,
                visibility=visibility,
            )
            return convert.playlist_detail(playlist_detail(row, user))

    async def DeletePlaylist(
        self, request: pb.DeletePlaylistRequest, context: grpc.aio.ServicerContext
    ) -> pb.DeletePlaylistResponse:
        async with call(context) as rpc:
            await rpc.services.playlists.delete(request.id, await rpc.user())
        return pb.DeletePlaylistResponse()

    async def AddItem(
        self, request: pb.AddItemRequest, context: grpc.aio.ServicerContext
    ) -> pb.PlaylistDetail:
        async with call(context) as rpc:
            user = await rpc.user()
            row = await rpc.services.playlists.add_item(
                request.playlist_id, request.episode_id, user
            )
            return convert.playlist_detail(playlist_detail(row, user))

    async def RemoveItem(
        self, request: pb.RemoveItemRequest, context: grpc.aio.ServicerContext
    ) -> pb.PlaylistDetail:
        async with call(context) as rpc:
            user = await rpc.user()
            row = await rpc.services.playlists.remove_item(
                request.playlist_id, request.item_id, user
            )
            return convert.playlist_detail(playlist_detail(row, user))

    async def Reorder(
        self, request: pb.ReorderRequest, context: grpc.aio.ServicerContext
    ) -> pb.PlaylistDetail:
        async with call(context) as rpc:
            user = await rpc.user()
            row = await rpc.services.playlists.reorder(
                request.playlist_id, list(request.item_ids), user
            )
            return convert.playlist_detail(playlist_detail(row, user))
