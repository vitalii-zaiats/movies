"""simpsonsua.tv — read the sitemap and pull show / season / episode out of URLs.

The site has no listing to paginate; everything is in one sitemap.xml. Episode
URLs look like:

    /american-dad-sezon-1/2217-american-dad-1-sezon-7-seriya.html
     └── folder: <key>-sezon-<S>   └── file: <id>-<key>-<S>-sezon-<E>-seriya

so the key is `american-dad`, season 1, episode 7. Both halves carry the key,
but not always: some files drop it (`sezon-36/4150-36-sezon-10-11-seriya.html`),
some folders are themed collections rather than a show (`lgbt/`, `podoroz/`).
"""

import re
from xml.etree import ElementTree

from crawlers.models import Item
from crawlers.source import Source, register

SITEMAP = "https://simpsonsua.tv/sitemap.xml"
NS = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}

# Episodes with no key anywhere in the URL live under bare `sezon-NN/` folders or
# themed collections (`lgbt/`, `podoroz/`) — on this site those are the Simpsons.
DEFAULT_KEY = "simpsony"

EPISODE_RE = re.compile(
    r"""^
    (?P<id>\d+)-                            # numeric page id
    (?:(?P<key>[a-z][a-z0-9-]*?)-)?         # show key — must start with a letter,
                                            # optional because some files omit it
    (?P<season>\d+)-sezon-
    (?P<episode>\d+)(?:-(?P<last>\d+))?-    # single episode, or a double like 13-14
    seri?y[ai]                              # seriya / serya / seriyi — all in use
    \.html$""",
    re.VERBOSE,
)

# Folder form `<key>-sezon-<number>`; the key there is the canonical show slug.
FOLDER_RE = re.compile(r"^(?P<key>.+)-sezon-\d+$")


@register
class SimpsonsUA(Source):
    name = "simpsonsua"
    paginated = False

    def page_url(self, number: int) -> str:
        return SITEMAP

    def parse(self, xml: str) -> list[Item]:
        root = ElementTree.fromstring(xml)
        items = []

        for node in root.findall("sm:url", NS):
            url = (node.findtext("sm:loc", namespaces=NS) or "").strip()
            if not url:
                continue

            parsed = parse_episode_url(url)
            if parsed is None:
                continue  # blog post, season index, collection — not an episode

            lastmod = (node.findtext("sm:lastmod", namespaces=NS) or "").strip()
            if lastmod:
                parsed["lastmod"] = lastmod

            items.append(Item(title=_title(parsed), url=url, extra=parsed))

        return items


def parse_episode_url(url: str) -> dict | None:
    """`{key, season, episode, episode_end, id}` for an episode URL, else None."""
    path = url.split("//", 1)[-1].split("/", 1)[-1].strip("/")
    parts = path.split("/")
    name = parts[-1]
    folder = parts[-2] if len(parts) > 1 else ""

    match = EPISODE_RE.match(name)
    if match is None:
        return None

    # Prefer the folder's key: it's the canonical slug, while the filename
    # sometimes carries a transliterated variant (hotel-hazbin vs gotel-hazbn).
    folder_match = FOLDER_RE.match(folder)
    key = (folder_match["key"] if folder_match else None) or match["key"] or DEFAULT_KEY

    return {
        "key": key,
        "season": int(match["season"]),
        "episode": int(match["episode"]),
        "episode_end": int(match["last"]) if match["last"] else None,
        "id": int(match["id"]),
    }


def _title(parsed: dict) -> str:
    episode = f"{parsed['episode']:02d}"
    if parsed["episode_end"]:
        episode += f"-{parsed['episode_end']:02d}"
    label = f"S{parsed['season']:02d}E{episode}"
    return f"{parsed['key']} {label}" if parsed["key"] else label
