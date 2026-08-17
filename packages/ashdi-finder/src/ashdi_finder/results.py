"""The core: what a resolve produces, and every decision that needs no I/O.

Both orchestrators — sync `resolve` and async `aresolve` — are built out of these
pieces, so the two can only differ in how they wait, never in what they decide.
"""

from dataclasses import dataclass, field
from typing import NotRequired, TypedDict

from ashdi_finder.finder import IframeHit, find_ashdi_iframes, is_ashdi_url
from ashdi_finder.player import Episode, Stream, extract_episodes, extract_streams


class StreamPayload(TypedDict):
    url: str
    label: str | None
    source: str


class SubtitlePayload(TypedDict):
    url: str
    label: str | None


class EpisodePayload(TypedDict):
    """One playlist entry. `url` is its first stream — the rest, if a leaf had
    several qualities, are in the player's own `streams`."""

    title: str
    season: int | None
    episode: int | None
    episode_end: int | None
    dub: str | None
    url: str | None
    poster: str | None
    video_id: str | None
    subtitles: list[SubtitlePayload]


class PlayerPayload(TypedDict):
    url: str
    attr: str
    error: str | None
    streams: list[StreamPayload]
    # A serial's playlist, empty for a film.
    episodes: list[EpisodePayload]
    # Only when the caller asked for the matched markup.
    html: NotRequired[str]


class ResolvePayload(TypedDict):
    source_url: str
    final_url: str
    count: int
    stream_count: int
    episode_count: int
    players: list[PlayerPayload]


@dataclass(slots=True)
class PlayerResult:
    """One ashdi player page: where we found it and what it plays."""

    url: str
    attr: str
    html: str = ""
    streams: list[Stream] = field(default_factory=list)
    episodes: list[Episode] = field(default_factory=list)
    error: str | None = None

    def to_dict(self, include_html: bool = False) -> PlayerPayload:
        payload = PlayerPayload(
            url=self.url,
            attr=self.attr,
            error=self.error,
            streams=[
                StreamPayload(url=s.url, label=s.label, source=s.source) for s in self.streams
            ],
            episodes=[
                EpisodePayload(
                    title=e.title,
                    season=e.season,
                    episode=e.episode,
                    episode_end=e.episode_end,
                    dub=e.dub,
                    url=e.url,
                    poster=e.poster,
                    video_id=e.video_id,
                    subtitles=[
                        SubtitlePayload(url=s.url, label=s.label) for s in e.subtitles
                    ],
                )
                for e in self.episodes
            ],
        )
        if include_html:
            payload["html"] = self.html
        return payload


@dataclass(slots=True)
class ResolveResult:
    source_url: str
    final_url: str
    players: list[PlayerResult]

    @property
    def streams(self) -> list[Stream]:
        return [s for p in self.players for s in p.streams]

    @property
    def episodes(self) -> list[Episode]:
        """Every episode across the players — empty unless one played a serial."""
        return [e for p in self.players for e in p.episodes]

    def to_dict(self, include_html: bool = False) -> ResolvePayload:
        return ResolvePayload(
            source_url=self.source_url,
            final_url=self.final_url,
            count=len(self.players),
            stream_count=len(self.streams),
            episode_count=len(self.episodes),
            players=[p.to_dict(include_html) for p in self.players],
        )


def is_player_page(url: str) -> bool:
    """An ashdi URL is already the player page — no iframe hunting needed."""
    return is_ashdi_url(url)


def direct(source_url: str, final_url: str, html: str) -> ResolveResult:
    """Result for a URL that was itself a player page.

    Parsed even when following is switched off: its HTML is already in hand, so
    reading it costs no request.
    """
    player = PlayerResult(
        url=final_url,
        attr="direct",
        streams=extract_streams(html),
        episodes=extract_episodes(html),
    )
    return ResolveResult(source_url, final_url, [player])


def hits_in(html: str, final_url: str) -> list[IframeHit]:
    return find_ashdi_iframes(html, base_url=final_url)


def unopened(hit: IframeHit) -> PlayerResult:
    """The iframe we found, without having opened it."""
    return PlayerResult(url=hit.url, attr=hit.attr, html=hit.html)


def opened(hit: IframeHit, player_html: str) -> PlayerResult:
    result = unopened(hit)
    result.streams = extract_streams(player_html)
    # A `/serial/` player: the same streams, with their seasons kept.
    result.episodes = extract_episodes(player_html)
    return result


def failed(hit: IframeHit, error: Exception) -> PlayerResult:
    result = unopened(hit)
    result.error = str(error)
    return result
