"""Pull .m3u8 stream URLs out of an ashdi.vip player page.

The page hands its config to Playerjs:

    player = new Playerjs({ id:"videoplayer167527", file:'https://.../index.m3u8', ... })

`file` is either a single URL, a comma-separated multi-quality list
(`[720p]url,[1080p]url`), or — on a `/serial/` page — a JSON playlist nested
dub → season → episode:

    [{"title":"Postmodern","folder":[
        {"title":"Сезон 1","folder":[
            {"title":"Серія 1","file":"https://.../index.m3u8","id":"268988",
             "poster":"https://.../screen.jpg"}, ...

That nesting is a habit rather than a contract — a serial with one dub drops the
outer folder, a mini-series has no seasons — so the walk keeps every folder title
it passed and reads the numbers off the titles instead of off the depth.
"""

import json
import re
from dataclasses import dataclass, field

M3U8_RE = re.compile(r"https?://[^\s'\"\\<>()]+\.m3u8[^\s'\"\\<>()]*")
PLAYERJS_FILE_RE = re.compile(
    r"""new\s+Playerjs\s*\(\s*\{.*?\bfile\s*:\s*(?P<q>['"])(?P<value>.*?)(?<!\\)(?P=q)""",
    re.DOTALL,
)
QUALITY_RE = re.compile(r"\[(?P<label>[^\]]+)\]\s*(?P<url>[^,]+)")
ESCAPE_RE = re.compile(r"\\u([0-9a-fA-F]{4})|\\(.)", re.DOTALL)
SHORT_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "b": "\b", "f": "\f"}

SEASON_RE = re.compile(r"сезон\s*(\d+)|(\d+)\s*(?:-й\s*)?сезон", re.IGNORECASE)
EPISODE_RE = re.compile(
    r"(?:сер[ії]я|епізод)\s*(\d+)(?:\s*[-–—]\s*(\d+))?|(\d+)\s*(?:сер[ії]я|епізод)",
    re.IGNORECASE,
)
# The last resort when a title carries no numbers: `.../foo.s01e02.1080p_268989/...`
FILE_NAME_RE = re.compile(r"[._/-]s(\d{1,2})e(\d{1,3})", re.IGNORECASE)


@dataclass(frozen=True, slots=True)
class Stream:
    """One playable stream URL, with whatever label the page gave it."""

    url: str
    label: str | None = None
    source: str = "playerjs"


@dataclass(frozen=True, slots=True)
class Subtitle:
    """One .vtt track an episode ships with, labelled in the player's words."""

    url: str
    label: str | None = None


@dataclass(frozen=True, slots=True)
class Episode:
    """One leaf of a serial's playlist: where it sits, and what it plays.

    `season` and `episode` are what the titles said — None when they said
    nothing, which is honest about a playlist that named its folders freely.
    """

    title: str = ""
    season: int | None = None
    episode: int | None = None
    # A pair aired as one file: "Серія 12-13".
    episode_end: int | None = None
    # The folder above the seasons — a dub studio ("Postmodern") or "Субтитри".
    dub: str | None = None
    streams: list[Stream] = field(default_factory=list)
    subtitles: list[Subtitle] = field(default_factory=list)
    poster: str | None = None
    video_id: str | None = None
    # Every folder title above this leaf, outermost first, numbers and all.
    folders: tuple[str, ...] = ()

    @property
    def url(self) -> str | None:
        """What to play when nobody asked for a particular quality."""
        return self.streams[0].url if self.streams else None


def extract_streams(html: str) -> list[Stream]:
    """Return every .m3u8 stream on a player page, in document order."""
    config = _playerjs_file(html)
    streams = _config_streams(config) if config is not None else []

    # Nothing structured? Fall back to sweeping the whole page for m3u8 URLs.
    if not streams:
        streams = [Stream(url=u, source="page-scan") for u in M3U8_RE.findall(html)]

    return _dedupe(streams)


def extract_episodes(html: str) -> list[Episode]:
    """Every episode a serial player lists, in playlist order.

    Empty for a film — a `/vod/` page plays one file and has no playlist to walk.
    """
    config = _playerjs_file(html)
    return _playlist(config) if config is not None else []


def _config_streams(config: str) -> list[Stream]:
    """A film's own file value, or every stream the episodes add up to."""
    episodes = _playlist(config)
    if episodes:
        return [stream for episode in episodes for stream in episode.streams]
    return _files(config, label=None)


def _playerjs_file(html: str) -> str | None:
    match = PLAYERJS_FILE_RE.search(html)
    if not match:
        return None
    return _unescape(match.group("value"))


def _unescape(value: str) -> str:
    """Undo JS string escaping (`\\/`, `\\"`, `\\u0421`) without touching UTF-8 text."""

    def replace(match: re.Match[str]) -> str:
        code, char = match.groups()
        if code is not None:
            return chr(int(code, 16))
        return SHORT_ESCAPES.get(char, char)

    return ESCAPE_RE.sub(replace, value)


def _playlist(value: str) -> list[Episode]:
    """The playlist a serial's `file` holds. Empty when it's a plain URL list."""
    value = value.strip()
    if not value.startswith(("[{", "{")):
        return []

    try:
        return _walk_playlist(json.loads(value), folders=())
    except json.JSONDecodeError:
        return []  # not a playlist after all — the caller reads it as URLs


def _walk_playlist(node: object, folders: tuple[str, ...]) -> list[Episode]:
    """Recurse a Playerjs playlist, remembering the folders a leaf sits under."""
    if isinstance(node, list):
        return [episode for item in node for episode in _walk_playlist(item, folders)]

    if not isinstance(node, dict):
        return []

    title = node.get("title") or node.get("comment")
    title = title.strip() if isinstance(title, str) else ""

    if isinstance(node.get("folder"), list):
        return _walk_playlist(node["folder"], folders + ((title,) if title else ()))

    file_value = node.get("file")
    if not isinstance(file_value, str):
        return []

    return [_episode(node, title, folders, file_value)]


def _episode(
    node: dict[str, object], title: str, folders: tuple[str, ...], file_value: str
) -> Episode:
    season, dub = _season_and_dub(folders)
    episode, episode_end = _episode_numbers(title)

    if season is None or episode is None:
        # Titles are the uploader's words; the file name is the fallback that
        # doesn't depend on them.
        from_name = FILE_NAME_RE.search(file_value)
        if from_name:
            season = season if season is not None else int(from_name[1])
            episode = episode if episode is not None else int(from_name[2])

    return Episode(
        title=title,
        season=season,
        episode=episode,
        episode_end=episode_end,
        dub=dub,
        # The label stays the whole path — "Postmodern / Сезон 1 / Серія 1" —
        # so a flattened stream still says where it came from.
        streams=_files(file_value, label=_join(*folders, title)),
        subtitles=_subtitles(node.get("subtitle")),
        poster=_text(node.get("poster")),
        video_id=_text(node.get("id")) or _text(node.get("vid")),
        folders=folders,
    )


def _season_and_dub(folders: tuple[str, ...]) -> tuple[int | None, str | None]:
    """Which folder was the season, and which one named the voices."""
    season = None
    dub = None

    for folder in folders:
        number = _season_number(folder)
        if number is not None:
            season = number
        elif dub is None:
            dub = folder

    return season, dub


def _season_number(title: str) -> int | None:
    match = SEASON_RE.search(title)
    return int(match[1] or match[2]) if match else None


def _episode_numbers(title: str) -> tuple[int | None, int | None]:
    match = EPISODE_RE.search(title)
    if not match:
        return None, None
    return int(match[1] or match[3]), int(match[2]) if match[2] else None


def _files(value: str, label: str | None) -> list[Stream]:
    """One leaf's `file`: a URL, or several with a quality tag each."""
    return [
        Stream(url=url, label=_join(label, quality))
        for quality, url in _split_qualities(value)
        if ".m3u8" in url
    ]


def _subtitles(value: object) -> list[Subtitle]:
    """`subtitle` is labelled the same way the qualities are: `[Українські]a.vtt,...`"""
    if not isinstance(value, str) or not value.strip():
        return []
    return [Subtitle(url=url, label=label) for label, url in _split_qualities(value)]


def _split_qualities(value: str) -> list[tuple[str | None, str]]:
    """`[720p]a.m3u8,[1080p]b.m3u8` -> [("720p", "a.m3u8"), ("1080p", "b.m3u8")]."""
    tagged = [(m.group("label").strip(), m.group("url").strip()) for m in QUALITY_RE.finditer(value)]
    if tagged:
        return list(tagged)
    return [(None, part.strip()) for part in value.split(",") if part.strip()]


def _join(*parts: str | None) -> str | None:
    kept = [p.strip() for p in parts if p and p.strip()]
    return " / ".join(kept) or None


def _text(value: object) -> str | None:
    return value.strip() or None if isinstance(value, str) else None


def _dedupe(streams: list[Stream]) -> list[Stream]:
    seen: set[str] = set()
    out: list[Stream] = []
    for stream in streams:
        if stream.url in seen:
            continue
        seen.add(stream.url)
        out.append(stream)
    return out
