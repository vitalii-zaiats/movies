"""Pull .m3u8 stream URLs out of an ashdi.vip player page.

The page hands its config to Playerjs:

    player = new Playerjs({ id:"videoplayer167527", file:'https://.../index.m3u8', ... })

`file` is either a single URL, a comma-separated multi-quality list
(`[720p]url,[1080p]url`), or a JSON playlist of seasons/episodes for serials.
"""

import json
import re
from dataclasses import dataclass

M3U8_RE = re.compile(r"https?://[^\s'\"\\<>()]+\.m3u8[^\s'\"\\<>()]*")
PLAYERJS_FILE_RE = re.compile(
    r"""new\s+Playerjs\s*\(\s*\{.*?\bfile\s*:\s*(?P<q>['"])(?P<value>.*?)(?<!\\)(?P=q)""",
    re.DOTALL,
)
QUALITY_RE = re.compile(r"\[(?P<label>[^\]]+)\]\s*(?P<url>[^,]+)")
ESCAPE_RE = re.compile(r"\\u([0-9a-fA-F]{4})|\\(.)", re.DOTALL)
SHORT_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "b": "\b", "f": "\f"}


@dataclass(frozen=True, slots=True)
class Stream:
    """One playable stream URL, with whatever label the page gave it."""

    url: str
    label: str | None = None
    source: str = "playerjs"


def extract_streams(html: str) -> list[Stream]:
    """Return every .m3u8 stream on a player page, in document order."""
    config = _playerjs_file(html)
    streams = _parse_file_value(config, label=None) if config is not None else []

    # Nothing structured? Fall back to sweeping the whole page for m3u8 URLs.
    if not streams:
        streams = [Stream(url=u, source="page-scan") for u in M3U8_RE.findall(html)]

    return _dedupe(streams)


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


def _parse_file_value(value: str, label: str | None) -> list[Stream]:
    value = value.strip()
    if not value:
        return []

    if value.startswith(("[{", "{")):
        try:
            return _walk_playlist(json.loads(value), prefix=label)
        except json.JSONDecodeError:
            pass  # not a playlist after all — treat it as a plain URL list

    return [
        Stream(url=url, label=_join(label, quality))
        for quality, url in _split_qualities(value)
        if ".m3u8" in url
    ]


def _walk_playlist(node: object, prefix: str | None) -> list[Stream]:
    """Recurse a Playerjs playlist, keeping the season/episode titles as labels."""
    if isinstance(node, list):
        return [s for item in node for s in _walk_playlist(item, prefix)]

    if not isinstance(node, dict):
        return []

    title = node.get("title") or node.get("comment")
    label = _join(prefix, title if isinstance(title, str) else None)

    if isinstance(node.get("folder"), list):
        return _walk_playlist(node["folder"], prefix=label)

    file_value = node.get("file")
    if isinstance(file_value, str):
        return _parse_file_value(file_value, label=label)

    return []


def _split_qualities(value: str) -> list[tuple[str | None, str]]:
    """`[720p]a.m3u8,[1080p]b.m3u8` -> [("720p", "a.m3u8"), ("1080p", "b.m3u8")]."""
    tagged = [(m.group("label").strip(), m.group("url").strip()) for m in QUALITY_RE.finditer(value)]
    if tagged:
        return list(tagged)
    return [(None, part.strip()) for part in value.split(",") if part.strip()]


def _join(*parts: str | None) -> str | None:
    kept = [p.strip() for p in parts if p and p.strip()]
    return " / ".join(kept) or None


def _dedupe(streams: list[Stream]) -> list[Stream]:
    seen: set[str] = set()
    out: list[Stream] = []
    for stream in streams:
        if stream.url in seen:
            continue
        seen.add(stream.url)
        out.append(stream)
    return out
