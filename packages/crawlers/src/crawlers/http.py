"""One place that decides what our requests look like on the wire."""

import httpx
from httpkit import ProxyPool, build_client, resolve_pool

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "uk-UA,uk;q=0.9,en;q=0.8",
}


def client(timeout: float = 20.0, proxy: ProxyPool | str | None = None) -> httpx.Client:
    """`proxy` takes a pool, a spec string, or nothing — then `PROXY_URL` applies."""
    pool = proxy if isinstance(proxy, ProxyPool) else resolve_pool(proxy)
    return build_client(headers=HEADERS, timeout=timeout, proxy=pool)
