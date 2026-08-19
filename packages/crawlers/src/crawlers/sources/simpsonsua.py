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
from typing import Any, NotRequired, TypedDict
from urllib.parse import urljoin
from xml.etree import ElementTree

from bs4 import BeautifulSoup

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

# An episode page offers its players as tabs, and the tab says which dub it is:
#
#     <h2>ОБЕРІТЬ ОЗВУЧКУ</h2>
#     <ul class="movie-tabs">
#       <li><a class="tablinks" onclick="openTab(event, 'Player1')">Стругачка</a>
#       <li><a class="tablinks" onclick="openTab(event, 'Player3')">Колодій</a>
#     <div id="Player1"><iframe src="https://ashdi.vip/vod/277500">
#     <div id="Player3"><iframe src="https://ashdi.vip/vod/273658">
#
# Two tabs can mean two different things, and only the label tells them apart:
# named studios are dubs of the same episode, while "ПЛЕЄР 1 / ПЛЕЄР 2" is one
# dub mirrored on two hosts. A number is not a name, so it isn't kept as one.
TAB_TARGET_RE = re.compile(r"openTab\(\s*event\s*,\s*'([^']+)'")
GENERIC_TAB_RE = re.compile(r"^\s*(плеєр|player|дзеркало|mirror)\s*\d*\s*$", re.IGNORECASE)


class EpisodeUrl(TypedDict):
    """What an episode URL tells us on its own, before any page is fetched."""

    key: str
    season: int
    episode: int
    # Set when the episode aired as a pair, e.g. `13-14`.
    episode_end: int | None
    id: int
    # Only present when the sitemap entry carried one.
    lastmod: NotRequired[str]


class Track(TypedDict):
    """One player on an episode page, and whose voice it carries."""

    player: str
    # None when the tab was called "ПЛЕЄР 2" — a mirror, not a dub.
    audio: str | None


@register
class SimpsonsUA(Source):
    name = "simpsonsua"
    # Everything this site publishes is dubbed into Ukrainian.
    language = "uk"
    paginated = False
    # The sitemap gives the numbering; only the page itself gives the dubs.
    item_pages = True

    def page_url(self, number: int) -> str:
        return SITEMAP

    def parse_item(self, html: str, url: str) -> Item | None:
        """The episode's own page: which players it has, and in whose voice.

        The sitemap already said what episode this is, so nothing here repeats
        it — the engine merges this over the listing item, and what it adds is
        the one thing a URL can't carry.
        """
        tracks = tracks_on(html, url)
        if not tracks:
            return None

        soup = BeautifulSoup(html, "lxml")
        heading = soup.select_one(".poster h2")
        extra: dict[str, Any] = {"tracks": tracks}
        if heading and (name := heading.get_text(strip=True)):
            extra["episode_title"] = name

        return Item(title=extra.get("episode_title", ""), url=url, extra=extra)

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


def tracks_on(html: str, base_url: str) -> list[Track]:
    """Every player the page offers, in tab order, with its dub if it has one."""
    soup = BeautifulSoup(html, "lxml")
    found: list[Track] = []

    for tab in soup.select("ul.movie-tabs a.tablinks"):
        target = TAB_TARGET_RE.search(str(tab.get("onclick") or ""))
        if target is None:
            continue

        box = soup.select_one(f"#{target[1]}")
        frame = box.select_one("iframe[src]") if box else None
        if frame is None:
            continue

        label = tab.get_text(strip=True)
        found.append(
            Track(
                player=urljoin(base_url, str(frame["src"])),
                audio=None if GENERIC_TAB_RE.match(label) else label or None,
            )
        )

    # A page with no tabs still has a player; it just has nothing to say about it.
    if not found:
        found = [
            Track(player=urljoin(base_url, str(frame["src"])), audio=None)
            for frame in soup.select(".fullnews iframe[src], #dle-content iframe[src]")
        ]

    return found


def parse_episode_url(url: str) -> EpisodeUrl | None:
    """Everything an episode URL encodes, or None when it isn't one."""
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

    return EpisodeUrl(
        key=key,
        season=int(match["season"]),
        episode=int(match["episode"]),
        episode_end=int(match["last"]) if match["last"] else None,
        id=int(match["id"]),
    )


def _title(parsed: EpisodeUrl) -> str:
    episode = f"{parsed['episode']:02d}"
    if parsed["episode_end"]:
        episode += f"-{parsed['episode_end']:02d}"
    label = f"S{parsed['season']:02d}E{episode}"
    return f"{parsed['key']} {label}" if parsed["key"] else label
