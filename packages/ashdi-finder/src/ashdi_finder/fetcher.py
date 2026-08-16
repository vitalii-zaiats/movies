"""Download a page as a normal browser would."""

from httpkit import ProxyPool, build_client, resolve_pool

USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36"
)

HEADERS = {
    "User-Agent": USER_AGENT,
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "uk-UA,uk;q=0.9,en;q=0.8",
}


def fetch_html(
    url: str,
    timeout: float = 20.0,
    referer: str | None = None,
    proxy: ProxyPool | str | None = None,
) -> tuple[str, str]:
    """Return `(html, final_url)` after following redirects.

    `proxy` takes a pool, a spec string, or nothing — then `PROXY_URL` applies.
    """
    headers = dict(HEADERS)
    if referer:
        headers["Referer"] = referer

    pool = proxy if isinstance(proxy, ProxyPool) else resolve_pool(proxy)
    with build_client(headers=headers, timeout=timeout, proxy=pool) as client:
        response = client.get(url)
        response.raise_for_status()
        return response.text, str(response.url)
