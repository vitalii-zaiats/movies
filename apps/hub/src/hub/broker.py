"""Redis side of the hub: room registry plus a pub/sub bus per room.

Everything a client sends goes to Redis and comes back through a subscription,
even when both ends happen to be on the same process. That way two hub
instances behind a load balancer behave exactly like one.
"""

import asyncio
import json
import logging
from collections.abc import Awaitable, Callable
from typing import cast

from redis.asyncio import Redis

from hub.protocol import ROOM_CHANNEL, ROOM_KEY, ROOM_TTL, Envelope, new_code

log = logging.getLogger(__name__)

Handler = Callable[[Envelope], Awaitable[None]]


class Broker:
    def __init__(self, redis: Redis) -> None:
        self._redis = redis
        self._readers: dict[str, asyncio.Task] = {}

    async def ping(self) -> bool:
        return bool(await self._redis.ping())

    async def create_room(self) -> str:
        """Reserve an unused code."""
        for _ in range(10):
            code = new_code()
            if await self._redis.set(ROOM_KEY.format(code=code), "1", ex=ROOM_TTL, nx=True):
                return code
        raise RuntimeError("could not allocate a free room code")

    async def claim_room(self, code: str) -> bool:
        """Take this exact code if nobody holds it.

        Lets a display keep the code it had before a reload, so a phone that
        remembered it doesn't have to rescan. `NX` settles the race if two
        screens ask for the same one.
        """
        return bool(await self._redis.set(ROOM_KEY.format(code=code), "1", ex=ROOM_TTL, nx=True))

    async def room_exists(self, code: str) -> bool:
        return bool(await self._redis.exists(ROOM_KEY.format(code=code)))

    async def touch(self, code: str) -> None:
        await self._redis.expire(ROOM_KEY.format(code=code), ROOM_TTL)

    async def drop(self, code: str) -> None:
        await self._redis.delete(ROOM_KEY.format(code=code))

    async def publish(self, code: str, message: Envelope) -> None:
        await self._redis.publish(ROOM_CHANNEL.format(code=code), json.dumps(message))

    async def subscribe(self, code: str, handler: Handler) -> None:
        """Start relaying a room's messages into `handler` (once per process)."""
        if code in self._readers:
            return

        pubsub = self._redis.pubsub()
        await pubsub.subscribe(ROOM_CHANNEL.format(code=code))
        self._readers[code] = asyncio.create_task(
            self._read(code, pubsub, handler), name=f"room-{code}"
        )

    async def unsubscribe(self, code: str) -> None:
        task = self._readers.pop(code, None)
        if task:
            task.cancel()

    async def _read(self, code: str, pubsub, handler: Handler) -> None:
        try:
            async for raw in pubsub.listen():
                if raw.get("type") != "message":
                    continue
                try:
                    await handler(cast(Envelope, json.loads(raw["data"])))
                except Exception:  # one bad message must not kill the room
                    log.exception("room %s: handler failed", code)
        except asyncio.CancelledError:
            raise
        finally:
            await pubsub.aclose()

    async def close(self) -> None:
        for task in self._readers.values():
            task.cancel()
        self._readers.clear()
