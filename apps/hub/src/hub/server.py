"""The socket itself: pair a display with remotes, relay what they say.

The hub understands exactly three things — who is in a room, and the two
envelopes `command` (remote → display) and `state` (display → remote). What a
command *means* is the app's business, not the hub's.
"""

import json
import logging
import uuid
from collections.abc import AsyncIterator
from dataclasses import dataclass, field

from aiohttp import WSMsgType, web
from redis.asyncio import Redis

from hub.broker import Broker
from hub.protocol import Role, is_code, normalise_code

log = logging.getLogger(__name__)

HEARTBEAT = 30.0
MAX_MESSAGE = 64 * 1024
RELAYED = frozenset({"command", "state"})


# eq=False keeps identity hashing: members live in sets, and two connections are
# never "the same" just because their fields match.
@dataclass(slots=True, eq=False)
class Member:
    id: str
    role: Role
    code: str
    socket: web.WebSocketResponse


@dataclass
class Rooms:
    """Members connected to *this* process, grouped by room."""

    broker: Broker
    members: dict[str, set[Member]] = field(default_factory=dict)

    async def add(self, member: Member) -> None:
        local = self.members.setdefault(member.code, set())
        if not local:
            await self.broker.subscribe(member.code, self._deliver)
        local.add(member)

    async def remove(self, member: Member) -> None:
        local = self.members.get(member.code, set())
        local.discard(member)
        if not local:
            self.members.pop(member.code, None)
            await self.broker.unsubscribe(member.code)

    async def _deliver(self, message: dict) -> None:
        """A message came back off the bus — hand it to everyone but the sender."""
        code = message.get("room", "")
        sender = message.get("sender")

        for member in list(self.members.get(code, ())):
            if member.id == sender or member.socket.closed:
                continue
            try:
                await member.socket.send_json(message["body"])
            except ConnectionError:
                pass  # the socket is going away; its own handler will clean up

    def counts(self, code: str) -> dict[str, int]:
        local = self.members.get(code, ())
        return {
            "displays": sum(1 for m in local if m.role == "display"),
            "remotes": sum(1 for m in local if m.role == "remote"),
        }


def create_app(redis_url: str = "redis://127.0.0.1:6379/0") -> web.Application:
    app = web.Application()
    app["redis_url"] = redis_url
    app.cleanup_ctx.append(_services)
    app.add_routes([web.get("/health", health), web.get("/ws", websocket)])
    return app


async def _services(app: web.Application) -> AsyncIterator[None]:
    redis = Redis.from_url(app["redis_url"], decode_responses=True)
    broker = Broker(redis)
    app["broker"] = broker
    app["rooms"] = Rooms(broker)
    try:
        yield
    finally:
        await broker.close()
        await redis.aclose()


async def health(request: web.Request) -> web.Response:
    try:
        await request.app["broker"].ping()
    except Exception as exc:  # noqa: BLE001 — the point is to report any failure
        return web.json_response({"status": "degraded", "redis": str(exc)}, status=503)
    return web.json_response({"status": "ok"})


async def websocket(request: web.Request) -> web.WebSocketResponse:
    socket = web.WebSocketResponse(heartbeat=HEARTBEAT, max_msg_size=MAX_MESSAGE)
    await socket.prepare(request)

    broker: Broker = request.app["broker"]
    rooms: Rooms = request.app["rooms"]

    role: Role = "remote" if request.query.get("role") == "remote" else "display"
    member = await _join(socket, broker, rooms, role, request.query.get("code", ""))
    if member is None:
        return socket

    await _announce(broker, rooms, member.code)

    try:
        async for message in socket:
            if message.type is not WSMsgType.TEXT:
                continue
            await _relay(broker, member, message.data)
    finally:
        await rooms.remove(member)
        if member.role == "display":
            await broker.drop(member.code)  # the screen left; the code dies with it
        await _announce(broker, rooms, member.code)

    return socket


async def _join(
    socket: web.WebSocketResponse, broker: Broker, rooms: Rooms, role: Role, raw_code: str
) -> Member | None:
    if role == "display":
        # A display may ask for the code it used last time; it gets it back
        # unless someone else holds it, in which case a fresh one is issued.
        wanted = normalise_code(raw_code)
        code = wanted if is_code(wanted) and await broker.claim_room(wanted) else None
        code = code or await broker.create_room()
    else:
        code = normalise_code(raw_code)
        if not is_code(code) or not await broker.room_exists(code):
            await socket.send_json({"type": "error", "message": "unknown or expired code"})
            await socket.close()
            return None

    member = Member(id=uuid.uuid4().hex, role=role, code=code, socket=socket)
    await rooms.add(member)
    await broker.touch(code)
    await socket.send_json({"type": "welcome", "role": role, "code": code, "id": member.id})
    return member


async def _relay(broker: Broker, member: Member, raw: str) -> None:
    try:
        body = json.loads(raw)
    except json.JSONDecodeError:
        return
    if not isinstance(body, dict) or body.get("type") not in RELAYED:
        return

    body["from"] = member.role
    await broker.touch(member.code)
    await broker.publish(member.code, {"room": member.code, "sender": member.id, "body": body})


async def _announce(broker: Broker, rooms: Rooms, code: str) -> None:
    """Tell the room who's in it. Counts are local — one hub, one truth."""
    await broker.publish(
        code, {"room": code, "sender": None, "body": {"type": "peers", **rooms.counts(code)}}
    )
