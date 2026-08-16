"""An httpx.Client that rotates proxies and backs off when told to slow down."""

import random
import threading
import time
from collections.abc import Mapping

import httpx

from httpkit.proxies import ProxyPool

# Worth another go on a different exit IP.
RETRY_STATUS = frozenset({408, 425, 429, 500, 502, 503, 504})

DEFAULT_RETRIES = 3
DEFAULT_BACKOFF = 1.0
MAX_BACKOFF = 30.0


class RetryingTransport(httpx.BaseTransport):
    """Picks the next proxy per request and retries the statuses worth retrying.

    Living at the transport layer means every caller — every source, every
    resolver — gets this without changing a single call site.
    """

    def __init__(
        self,
        transports: list[httpx.BaseTransport],
        retries: int = DEFAULT_RETRIES,
        backoff: float = DEFAULT_BACKOFF,
    ) -> None:
        self._transports = transports
        self._retries = retries
        self._backoff = backoff
        self._index = 0
        self._lock = threading.Lock()

    def _next(self) -> httpx.BaseTransport:
        if len(self._transports) == 1:
            return self._transports[0]
        with self._lock:
            transport = self._transports[self._index % len(self._transports)]
            self._index += 1
        return transport

    def handle_request(self, request: httpx.Request) -> httpx.Response:
        for attempt in range(self._retries + 1):
            last = attempt == self._retries

            try:
                response = self._next().handle_request(request)
            except httpx.TransportError:
                if last:
                    raise
                time.sleep(self._delay(attempt))
                continue

            if response.status_code in RETRY_STATUS and not last:
                delay = _retry_after(response) or self._delay(attempt)
                response.close()
                time.sleep(delay)
                continue

            return response

        raise httpx.TransportError("retries exhausted")  # pragma: no cover

    def _delay(self, attempt: int) -> float:
        """Exponential, with jitter so parallel workers don't retry in lockstep."""
        return min(self._backoff * 2**attempt, MAX_BACKOFF) * random.uniform(0.7, 1.3)

    def close(self) -> None:
        for transport in self._transports:
            transport.close()


def build_client(
    *,
    headers: Mapping[str, str] | None = None,
    timeout: float = 20.0,
    proxy: ProxyPool | None = None,
    retries: int = DEFAULT_RETRIES,
    backoff: float = DEFAULT_BACKOFF,
    follow_redirects: bool = True,
) -> httpx.Client:
    """A client that goes through `proxy` (if given) and retries 429s."""
    limits = httpx.Limits(
        # No keep-alive when proxying: a rotating gateway hands out a new exit IP
        # per connection, so reusing one would pin us to the address we just
        # got rate-limited on.
        max_keepalive_connections=0 if proxy else 20,
        max_connections=20,
    )

    if proxy:
        transports: list[httpx.BaseTransport] = [
            httpx.HTTPTransport(proxy=url, limits=limits) for url in proxy.urls
        ]
    else:
        transports = [httpx.HTTPTransport(limits=limits)]

    return httpx.Client(
        headers=dict(headers or {}),
        timeout=timeout,
        follow_redirects=follow_redirects,
        transport=RetryingTransport(transports, retries=retries, backoff=backoff),
    )


def _retry_after(response: httpx.Response) -> float | None:
    """Honour `Retry-After: <seconds>`; HTTP-date form falls back to our backoff."""
    value = response.headers.get("retry-after")
    if not value:
        return None
    try:
        return min(float(value), MAX_BACKOFF)
    except ValueError:
        return None
