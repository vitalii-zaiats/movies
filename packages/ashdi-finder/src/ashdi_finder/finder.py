"""Parse a page's DOM and pull out iframes that point at ashdi.vip."""

from dataclasses import dataclass
from urllib.parse import urljoin, urlsplit

from bs4 import BeautifulSoup

ASHDI_HOST = "ashdi.vip"

# Lazy-loading players rarely keep the real URL in `src`.
URL_ATTRS = ("src", "data-src", "data-lazy-src", "data-litespeed-src", "data-url")


@dataclass(frozen=True, slots=True)
class IframeHit:
    """A single <iframe> whose URL resolves to ashdi.vip."""

    url: str
    attr: str
    html: str


def is_ashdi_url(url: str) -> bool:
    parts = urlsplit(url)
    if parts.scheme not in ("http", "https"):
        return False
    host = parts.hostname or ""
    return host == ASHDI_HOST or host.endswith(f".{ASHDI_HOST}")


def find_ashdi_iframes(html: str, base_url: str | None = None) -> list[IframeHit]:
    """Return every ashdi.vip iframe found in `html`, in document order.

    `base_url` resolves relative and protocol-relative (`//ashdi.vip/...`) srcs.
    """
    soup = BeautifulSoup(html, "lxml")
    hits: list[IframeHit] = []
    seen: set[str] = set()

    for iframe in soup.find_all("iframe"):
        for attr in URL_ATTRS:
            raw = iframe.get(attr)
            if not isinstance(raw, str) or not raw.strip():
                continue
            url = urljoin(base_url, raw.strip()) if base_url else raw.strip()
            if not is_ashdi_url(url) or url in seen:
                continue
            seen.add(url)
            hits.append(IframeHit(url=url, attr=attr, html=str(iframe)))

    return hits
