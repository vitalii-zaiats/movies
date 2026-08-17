"""Composing the home screen, and editing what it's made of.

`home()` is the read the whole front page is one request to. Everything else
here is the admin side that fills it.

Its neighbours arrive through the constructor, wired in `deps.py`, and only
ever as their **services** — never their repositories, never their schemas,
never their enums. Concretely that means the rules stay where they belong:
whether a playlist may be shown to everyone is answered by
`PlaylistService.published`, and where an uploaded file is served from is
answered by `MediaService.url`. This module asks; it doesn't reimplement.
"""

from __future__ import annotations

from collections.abc import Sequence
from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Any

from api.errors import Invalid, NotFound
from api.modules.curation.models import Artwork, Placement, Section, SectionKind
from api.modules.curation.repository import SUBJECTS, ArtworkRepository, SectionRepository

if TYPE_CHECKING:
    from sqlalchemy.ext.asyncio import AsyncSession

    from api.modules.catalogue.models import Episode
    from api.modules.catalogue.service import CatalogueService
    from api.modules.media.service import MediaService
    from api.modules.playlists.service import PlaylistService


@dataclass(slots=True)
class ResolvedSection:
    """A section with everything it needs to be drawn, and nothing else.

    Built rather than mapped: the artwork here is already merged (the section's
    own overriding the subject's) and the episodes are already cut to
    `item_limit`, so the DTO layer stays a translation and the template stays
    dumb.
    """

    section: Section
    episodes: list[Episode] = field(default_factory=list)
    artwork: dict[Placement, str] = field(default_factory=dict)


@dataclass(slots=True)
class CurationService:
    session: AsyncSession
    catalogue: CatalogueService
    playlists: PlaylistService
    media: MediaService

    @property
    def sections(self) -> SectionRepository:
        return SectionRepository(self.session)

    @property
    def artwork(self) -> ArtworkRepository:
        return ArtworkRepository(self.session)

    # --- the read everything else exists for --------------------------------

    async def home(self, *, preview: bool = False) -> list[ResolvedSection]:
        """The whole front page: ordered sections, each already filled in.

        `preview` is the admin's view — it includes sections marked invisible so
        they can be checked before being published.
        """
        sections = await self.sections.ordered(visible_only=not preview)

        # A section pointing at a playlist that has since been made private is
        # dropped rather than drawn. Wiring one up already refuses (see
        # `_check_source`), but visibility can change afterwards, and the home
        # screen is the wrong place to find that out.
        sections = [
            section
            for section in sections
            if section.playlist is None or section.playlist.is_public
        ]

        art = await self._artwork_for(sections)
        return [
            ResolvedSection(
                section=section,
                episodes=await self._episodes_for(section),
                artwork=art.get(section.id, {}),
            )
            for section in sections
        ]

    # --- sections -----------------------------------------------------------

    async def all_sections(self) -> list[Section]:
        return await self.sections.ordered()

    async def section(self, section_id: int) -> Section:
        section = await self.sections.get(section_id)
        if section is None:
            raise NotFound(f"no section {section_id}")
        return section

    async def create_section(
        self,
        *,
        kind: SectionKind,
        title: str,
        kicker: str | None = None,
        link: str | None = None,
        show_id: int | None = None,
        playlist_id: int | None = None,
        item_limit: int = 14,
        visible: bool = True,
    ) -> Section:
        await self._check_source(kind, show_id, playlist_id)
        section = await self.sections.add(
            Section(
                kind=kind,
                title=title.strip() or "untitled",
                kicker=(kicker or "").strip() or None,
                link=(link or "").strip() or None,
                show_id=show_id,
                playlist_id=playlist_id,
                item_limit=item_limit,
                visible=visible,
                position=await self.sections.next_position(),
            )
        )
        await self.session.commit()
        return await self._reloaded(section.id)

    async def update_section(self, section_id: int, changes: dict[str, Any]) -> Section:
        """Only the keys the caller actually sent — see `SectionUpdate`."""
        section = await self.section(section_id)

        await self._check_source(
            changes.get("kind", section.kind),
            changes.get("show_id", section.show_id),
            changes.get("playlist_id", section.playlist_id),
        )

        for key, value in changes.items():
            setattr(section, key, value)
        await self.session.commit()
        return await self._reloaded(section.id)

    async def delete_section(self, section_id: int) -> None:
        await self.sections.delete(await self.section(section_id))
        await self.session.commit()

    async def reorder_sections(self, section_ids: Sequence[int]) -> list[Section]:
        sections = await self.sections.ordered()
        by_id = {section.id: section for section in sections}
        if set(section_ids) != set(by_id):
            raise Invalid("section_ids must list every section exactly once")

        for position, section_id in enumerate(section_ids):
            by_id[section_id].position = position
        await self.session.commit()
        return await self.sections.ordered()

    # --- artwork ------------------------------------------------------------

    async def set_artwork(
        self,
        *,
        subject_type: str,
        subject_id: int,
        placement: Placement,
        url: str | None = None,
        media_id: int | None = None,
    ) -> Artwork:
        """Upsert one picture at one placement.

        Either an uploaded file or a link, never both and never neither. When
        it's an upload, the URL is resolved once, here — so every read is a
        column rather than a join and a branch.
        """
        if subject_type not in SUBJECTS:
            raise Invalid(f"subject_type must be one of {', '.join(SUBJECTS)}")
        if (url is None) == (media_id is None):
            raise Invalid("give exactly one of url or media_id")

        await self._check_subject(subject_type, subject_id)
        resolved = url if media_id is None else await self.media.url(media_id)

        existing = await self.artwork.at_placement(subject_type, subject_id, placement)
        if existing is not None:
            existing.url = resolved or ""
            existing.media_id = media_id
            await self.session.commit()
            return existing

        row = await self.artwork.add(
            Artwork(
                placement=placement,
                url=resolved or "",
                media_id=media_id,
                **{f"{subject_type}_id": subject_id},
            )
        )
        await self.session.commit()
        return row

    async def artwork_for(self, subject_type: str, subject_id: int) -> list[Artwork]:
        if subject_type not in SUBJECTS:
            raise Invalid(f"subject_type must be one of {', '.join(SUBJECTS)}")
        return await self.artwork.for_subject(subject_type, subject_id)

    async def delete_artwork(self, artwork_id: int) -> None:
        row = await self.artwork.get(artwork_id)
        if row is None:
            raise NotFound(f"no artwork {artwork_id}")
        await self.artwork.delete(row)
        await self.session.commit()

    # --- internals ----------------------------------------------------------

    async def _reloaded(self, section_id: int) -> Section:
        """Re-read so `show` / `playlist` / `artwork` are loaded on the way out."""
        self.session.expire_all()
        return await self.section(section_id)

    async def _check_source(
        self, kind: SectionKind, show_id: int | None, playlist_id: int | None
    ) -> None:
        if show_id is not None and playlist_id is not None:
            raise Invalid("a section points at a show or a playlist, not both")
        if kind is not SectionKind.banner and show_id is None and playlist_id is None:
            raise Invalid(f"a {kind.value} section needs a show or a playlist")

        if show_id is not None:
            await self.catalogue.show_by_id(show_id)
        if playlist_id is not None:
            # Raises if it isn't public — the home screen is, so anything on it
            # has to be. That rule is the playlists module's to state.
            await self.playlists.published(playlist_id)

    async def _check_subject(self, subject_type: str, subject_id: int) -> None:
        """Refuse to attach a picture to a row that isn't there."""
        match subject_type:
            case "show":
                await self.catalogue.show_by_id(subject_id)
            case "playlist":
                await self.playlists.published(subject_id)
            case _:
                await self.section(subject_id)

    async def _episodes_for(self, section: Section) -> list[Episode]:
        if section.kind is SectionKind.banner:
            return []
        if section.playlist is not None:
            return [item.episode for item in section.playlist.items][: section.item_limit]
        if section.show is not None:
            episodes = await self.catalogue.show_episodes(section.show.key, playable_only=True)
            return episodes[: section.item_limit]
        return []

    async def _artwork_for(self, sections: list[Section]) -> dict[int, dict[Placement, str]]:
        """One query for every picture on the page, then merged per section.

        The section's own artwork wins over the artwork of what it points at —
        that's what makes "use a different hero just for this rail" possible
        without touching the show everywhere else uses it.
        """
        rows = await self.artwork.for_home(
            show_ids=[s.show_id for s in sections if s.show_id],
            playlist_ids=[s.playlist_id for s in sections if s.playlist_id],
            section_ids=[s.id for s in sections],
        )

        by_show: dict[int, dict[Placement, str]] = {}
        by_playlist: dict[int, dict[Placement, str]] = {}
        by_section: dict[int, dict[Placement, str]] = {}
        for row in rows:
            if row.show_id is not None:
                by_show.setdefault(row.show_id, {})[row.placement] = row.url
            elif row.playlist_id is not None:
                by_playlist.setdefault(row.playlist_id, {})[row.placement] = row.url
            elif row.section_id is not None:
                by_section.setdefault(row.section_id, {})[row.placement] = row.url

        merged: dict[int, dict[Placement, str]] = {}
        for section in sections:
            if section.show_id:
                subject = by_show.get(section.show_id, {})
            elif section.playlist_id:
                subject = by_playlist.get(section.playlist_id, {})
            else:
                subject = {}
            merged[section.id] = {**subject, **by_section.get(section.id, {})}
        return merged
