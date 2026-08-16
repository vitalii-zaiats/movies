"""Rewrite the URLs inside an .m3u8 so nested requests come back through us.

Without this the proxy is pointless for HLS: the player would read the master
playlist through the proxy, then go fetch the variants and segments straight
from the origin — which is exactly the request that CORS blocks.
"""

import re
from urllib.parse import quote, urljoin

URI_ATTR_RE = re.compile(r'URI="([^"]*)"')


def is_playlist(content_type: str | None, url: str) -> bool:
    if content_type and "mpegurl" in content_type.lower():
        return True
    return url.split("?", 1)[0].lower().endswith(".m3u8")


def proxied(url: str) -> str:
    """A relative link back to this proxy — works whatever host it's served on."""
    return f"/?url={quote(url, safe='')}"


def rewrite(text: str, base_url: str) -> str:
    """Point every URL in the playlist — lines and `URI="..."` attrs — at the proxy."""
    lines = []

    for line in text.splitlines():
        stripped = line.strip()

        if not stripped:
            lines.append(line)
        elif stripped.startswith("#"):
            # #EXT-X-KEY, #EXT-X-MAP, #EXT-X-MEDIA all hide a URL in an attribute.
            lines.append(
                URI_ATTR_RE.sub(
                    lambda m: f'URI="{proxied(urljoin(base_url, m.group(1)))}"', line
                )
            )
        else:
            lines.append(proxied(urljoin(base_url, stripped)))

    return "\n".join(lines) + "\n"
