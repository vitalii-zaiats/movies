"""What the catalogue does, said without HTTP and without SQL.

Routes translate requests; repositories translate storage; this is the layer in
between that actually decides things. Nothing here imports FastAPI, so any of it
can be called from a script or a test.
"""

import json
from collections.abc import Sequence
from dataclasses import dataclass
from typing import Any, Protocol

from sqlalchemy.ext.asyncio import AsyncSession

from api.errors import NotFound
from sqlalchemy import select

from api.modules.catalogue.models import Episode, EpisodeTrack, Show, SyncCursor
from api.modules.catalogue.repository import EpisodeRepository, ShowRepository
from api.modules.catalogue.schemas import (
    IngestEpisode,
    IngestReport,
    IngestShow,
    ShowReport,
    SyncReport,
)

# The one list this catalogue follows, and the name its cursor is filed under.
VOD_CURSOR = "vod"


class VodSource(Protocol):
    """What the sync needs from the VOD service: a walk, and nothing else.

    A protocol rather than the client itself, so this layer can be driven from a
    test, a script, or a different transport without knowing about gRPC.
    """

    async def page(self, after_id: int = 0, limit: int = 200) -> Sequence[Any]: ...


@dataclass(slots=True)
class CatalogueService:
    session: AsyncSession

    @property
    def shows(self) -> ShowRepository:
        return ShowRepository(self.session)

    @property
    def episodes(self) -> EpisodeRepository:
        return EpisodeRepository(self.session)

    async def counts(self) -> tuple[int, int]:
        return await self.shows.count(), await self.episodes.count()

    async def all_shows(self) -> list[Show]:
        return await self.shows.all()

    async def show_page(
        self,
        *,
        title_like: str | None,
        series: bool | None,
        order: str,
        limit: int,
        offset: int,
        kind: str | None = None,
        language: str | None = None,
    ) -> tuple[list[tuple[Show, int, int]], int]:
        return await self.shows.page(
            title_like=title_like,
            series=series,
            kind=kind,
            language=language,
            order=order,
            limit=limit,
            offset=offset,
        )

    async def show(self, key: str) -> Show:
        show = await self.shows.by_key(key)
        if show is None:
            raise NotFound(f"no show {key!r}")
        return show

    async def episode_page(
        self,
        *,
        show: str | None,
        season: int | None,
        title_like: str | None,
        playable: bool | None,
        limit: int,
        offset: int,
    ) -> tuple[list[Episode], int]:
        return await self.episodes.page(
            show=show,
            season=season,
            title_like=title_like,
            playable=playable,
            limit=limit,
            offset=offset,
        )

    async def episode(self, episode_id: int) -> Episode:
        episode = await self.episodes.get(episode_id)
        if episode is None:
            raise NotFound(f"no episode {episode_id}")
        return episode

    async def show_by_id(self, show_id: int) -> Show:
        """By row id, for whoever is holding a foreign key rather than a key."""
        show = await self.shows.get(show_id)
        if show is None:
            raise NotFound(f"no show {show_id}")
        return show

    async def show_episodes(
        self, show_key: str, *, season: int | None = None, playable_only: bool = True
    ) -> list[Episode]:
        """A show's episodes in order, for whoever is building a queue.

        Here rather than in the caller because it's the catalogue's business
        what "in order" and "playable" mean. Other modules get this; they don't
        get `EpisodeRepository` — a module's service is its public face and its
        repository is its own affair.
        """
        show = await self.show(show_key)
        return await self.episodes.for_show(
            show.id, season=season, playable_only=playable_only
        )

    async def set_poster(self, key: str, url: str | None) -> Show:
        """Put a picture on a show, or take it off.

        A curator's act, not a crawl's: `describe` only ever fills gaps, because
        a re-crawl must not undo a choice somebody made deliberately. This one
        overwrites, because that is the whole point of making the choice.
        """
        show = await self.show(key)
        show.poster = url
        await self.session.commit()
        return show

    async def sync_vods(
        self, vods: VodSource, batch: int = 200, since: int | None = None
    ) -> SyncReport:
        """Read the VOD service from where we left off and build rows from it.

        The direction is the point. Nothing pushes episodes here any more: the
        VOD service owns playable things, it was told everything the crawl knew
        while the crawl still knew it, and this walks that list at its own pace.
        A catalogue that was down for a day catches up by itself.

        A VOD without the facts to place it — no show, no episode number — is
        counted and stepped over, not retried forever: the cursor moves past it,
        because looking again would only find the same silence.

        The walk only ever goes forward, so a VOD that was re-registered with
        better metadata is not seen again by an ordinary run. `since` is the way
        back: rewind to 0 and the whole list is read afresh, which is what to do
        after teaching the registrar something new.
        """
        start = await self.cursor() if since is None else max(0, since)
        report = SyncReport(created=0, updated=0, skipped=0, cursor=start)

        while True:
            page = await vods.page(after_id=report.cursor, limit=batch)
            if not page:
                break

            for vod in page:
                filed = _from_vod(vod)
                if filed is None:
                    report.skipped += 1
                else:
                    episode, details = filed
                    outcome = await self.ingest([episode])
                    report.created += outcome.created
                    report.updated += outcome.updated
                    # The show is described in the same breath: the envelope
                    # carries both halves, and splitting them across two passes
                    # was only ever an accident of how this used to be pushed.
                    if details is not None:
                        await self.describe([details])
                report.cursor = max(report.cursor, int(vod.id))

            await self._remember(report.cursor)

        return report

    async def cursor(self, name: str = VOD_CURSOR) -> int:
        row = await self.session.get(SyncCursor, name)
        return row.position if row else 0

    async def _remember(self, position: int, name: str = VOD_CURSOR) -> None:
        row = await self.session.get(SyncCursor, name)
        if row is None:
            self.session.add(SyncCursor(name=name, position=position))
        else:
            row.position = position
        await self.session.commit()

    async def describe(self, items: Sequence[IngestShow]) -> ShowReport:
        """Fill in what a crawl knows about shows that already exist.

        Episodes create a show; this only describes one, so a key nobody has
        seeded is counted and skipped rather than conjured into a row with a
        synopsis and no episodes.
        """
        updated = unknown = 0

        for item in items:
            show = await self.shows.by_key(item.key)
            if show is None:
                unknown += 1
                continue

            # Only what was actually sent: two sources can each fill their half,
            # and a later crawl that knows less must not erase what one knew.
            for field, value in item.model_dump(exclude={"key"}, exclude_none=True).items():
                setattr(show, field, value)
            updated += 1

        await self.session.commit()
        return ShowReport(updated=updated, unknown=unknown)

    async def ingest(self, items: Sequence[IngestEpisode]) -> IngestReport:
        """Take a batch of episodes from whoever crawled them.

        The API stores a VOD *id* it was told about; it never creates one. That
        direction is deliberate — registering a playlist is the crawler's job,
        and this service only ever reads the VOD service.
        """
        report = IngestReport(shows=0, created=0, updated=0)
        known: dict[str, Show] = {}

        for item in items:
            show = known.get(item.show_key)
            if show is None:
                show = await self.shows.by_key(item.show_key)
                if show is None:
                    show = await self.shows.create(
                        item.show_key,
                        item.show_title or _pretty(item.show_key),
                        item.show_poster,
                    )
                    report.shows += 1
                elif item.show_poster and not show.poster:
                    # A show seeded before its artwork was crawled gets it now.
                    # Only when there's nothing there: whatever a curator or an
                    # earlier, better source put on the row outranks a re-seed.
                    show.poster = item.show_poster
                known[item.show_key] = show

            # By URL first, because that is what a re-seed of the same page is
            # idempotent on. Then by number: the same episode can arrive under a
            # second URL — a themed collection beside the season folder — and it
            # is the same episode, which is what the unique key on (show,
            # season, episode) has always said. Without this the second copy
            # takes the whole sync down with an integrity error.
            episode = await self.episodes.by_source_url(item.source_url) or (
                await self.episodes.by_number(show.id, item.season, item.episode)
            )
            if episode is None:
                # Built complete before it's added: `title`, `season` and
                # `episode` are NOT NULL, so a half-filled row can't survive the
                # flush that `add` does.
                episode = await self.episodes.add(
                    Episode(show_id=show.id, source_url=item.source_url, **_numbers(item))
                )
                report.created += 1
            else:
                for field, value in _numbers(item).items():
                    # A sender that says nothing about the VOD is saying it
                    # doesn't know, not that there isn't one. Overwriting here
                    # is how a metadata pass silently unplayed a whole
                    # catalogue that a stream pass had just filled in.
                    if field == "vod_id" and value is None:
                        continue
                    setattr(episode, field, value)
                report.updated += 1

            if item.vod_id is not None:
                await self._track(episode, item.vod_id, item.audio, item.language)

        await self.session.commit()
        return report

    async def _track(
        self, episode: Episode, vod_id: int, audio: str | None, language: str | None = None
    ) -> None:
        """Remember that this VOD is one way to hear this episode.

        A second dub is a second row, not a replacement: the episode keeps the
        first one it was given as its default, because something has to play
        when nobody has expressed a preference.
        """
        existing = await self.session.scalar(
            select(EpisodeTrack).where(EpisodeTrack.vod_id == vod_id)
        )

        # A voice, not a URL. These sources hand out playlist links that rotate:
        # resolve the same episode twice and the same dub comes back under a new
        # address, which registers as a new VOD. Keyed on the id alone, every
        # re-seed would hang another "Стругачка" on the episode until the player
        # offered the same voice four times, three of them dead.
        #
        # So a named voice that is already here keeps its row and points at the
        # newer stream. An unnamed one can't be matched this way — two nameless
        # streams may be two different things — and stays keyed on the id.
        if existing is None and audio:
            existing = await self.session.scalar(
                select(EpisodeTrack).where(
                    EpisodeTrack.episode_id == episode.id, EpisodeTrack.audio == audio
                )
            )
            if existing is not None:
                # The episode's default follows the track it was pointing at.
                if episode.vod_id == existing.vod_id:
                    episode.vod_id = vod_id
                existing.vod_id = vod_id

        if existing is None:
            self.session.add(
                EpisodeTrack(
                    episode_id=episode.id, vod_id=vod_id, audio=audio, language=language
                )
            )
        else:
            # Only ever fills in: a re-seed that has learned the language should
            # add it, and one that has forgotten it should not erase it.
            if audio and existing.audio != audio:
                existing.audio = audio
            if language and existing.language != language:
                existing.language = language

        if episode.vod_id is None:
            episode.vod_id = vod_id


def _from_vod(vod: Any) -> tuple[IngestEpisode, IngestShow | None] | None:
    """One registered VOD, read as an episode and a description of its show.

    The facts come out of the JSON the registrar carried; this parses them back
    and refuses to guess. A stream nobody said where to file is not an episode
    of anything — better counted and stepped over than filed under "unknown".
    """
    blob = _carried(vod)
    show_key = blob.get("show_key")
    source_url = blob.get("source_url")
    if not show_key or not source_url:
        return None

    title = str(blob.get("title") or source_url)
    poster = blob.get("poster")

    episode = IngestEpisode(
        show_key=str(show_key),
        show_title=title,
        show_poster=poster,
        title=title,
        season=_int(blob.get("season")) or 1,
        episode=_int(blob.get("episode")) or 1,
        episode_end=_int(blob.get("episode_end")),
        poster=poster,
        source_url=str(source_url),
        vod_id=int(vod.id),
        audio=blob.get("audio"),
        language=blob.get("audio_language"),
    )

    # Everything else is about the title rather than the stream. Absent keys stay
    # absent: `describe` only fills gaps, so a thin envelope can't erase a fat one.
    details = IngestShow(
        key=str(show_key),
        original_title=blob.get("original_title"),
        kind=blob.get("kind"),
        year=_int(blob.get("year")),
        year_end=_int(blob.get("year_end")),
        # `audio` is deliberately not copied here: for kinoukr it describes the
        # title (one dub, stated on the page), but where a source offers several
        # it describes *this stream* — and that belongs on the track.
        quality=blob.get("quality"),
        description=blob.get("description"),
        duration=blob.get("duration"),
        age_rating=blob.get("age"),
        genres=_strings(blob.get("genres")),
        countries=_strings(blob.get("countries")),
        directors=_strings(blob.get("directors")),
        starring=_strings(blob.get("cast")),
        imdb_id=blob.get("imdb_id"),
        imdb_rating=_float(blob.get("imdb")),
        imdb_votes=_int(blob.get("imdb_votes")),
    )
    told = details.model_dump(exclude={"key"}, exclude_none=True)
    return episode, (details if told else None)


def _carried(vod: Any) -> dict[str, Any]:
    """The registrar's JSON, plus the two fields the contract names outright."""
    try:
        blob = json.loads(vod.metadata.json) if vod.metadata.json else {}
    except json.JSONDecodeError:
        blob = {}
    if not isinstance(blob, dict):
        blob = {}

    for field in ("title", "poster"):
        if vod.metadata.HasField(field) and not blob.get(field):
            blob[field] = getattr(vod.metadata, field)
    return blob


def _int(value: Any) -> int | None:
    try:
        return int(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def _float(value: Any) -> float | None:
    try:
        return float(value) if value is not None else None
    except (TypeError, ValueError):
        return None


def _strings(value: Any) -> list[str] | None:
    """A list of names, or nothing. One string is a list of one, not a mistake."""
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        kept = [str(item) for item in value if item]
        return kept or None
    return None


def _numbers(item: IngestEpisode) -> dict[str, object]:
    """The half of an episode that a re-seed is allowed to overwrite."""
    return {
        "season": item.season,
        "episode": item.episode,
        "episode_end": item.episode_end,
        "title": item.title,
        "poster": item.poster,
        "vod_id": item.vod_id,
    }


def _pretty(key: str) -> str:
    return key.replace("-", " ").title()
