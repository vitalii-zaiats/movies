"""Every query about sections and artwork."""

from collections.abc import Sequence
from typing import Final

from sqlalchemy import or_, select
from sqlalchemy.orm import InstrumentedAttribute

from api.core.repository import Repository
from api.modules.curation.models import Artwork, Placement, Section

# Which column holds the subject, per subject name. One mapping, used by every
# read and write, so "what can artwork be attached to" has a single answer.
SUBJECTS: Final[dict[str, InstrumentedAttribute[int | None]]] = {
    "show": Artwork.show_id,
    "playlist": Artwork.playlist_id,
    "section": Artwork.section_id,
}


class SectionRepository(Repository[Section]):
    model = Section

    async def ordered(self, *, visible_only: bool = False) -> list[Section]:
        query = select(Section)
        if visible_only:
            query = query.where(Section.visible.is_(True))
        rows = await self.session.scalars(query.order_by(Section.position, Section.id))
        return list(rows.unique())

    async def next_position(self) -> int:
        """Append to the end. Reordering is a separate, explicit act."""
        rows = await self.session.scalars(
            select(Section.position).order_by(Section.position.desc()).limit(1)
        )
        last = rows.first()
        return 0 if last is None else last + 1


class ArtworkRepository(Repository[Artwork]):
    model = Artwork

    async def for_subject(self, subject_type: str, subject_id: int) -> list[Artwork]:
        column = SUBJECTS[subject_type]
        rows = await self.session.scalars(
            select(Artwork).where(column == subject_id).order_by(Artwork.placement)
        )
        return list(rows.unique())

    async def at_placement(
        self, subject_type: str, subject_id: int, placement: Placement
    ) -> Artwork | None:
        """The row a `PUT` overwrites — the unique constraint made concrete."""
        column = SUBJECTS[subject_type]
        return await self.session.scalar(
            select(Artwork).where(column == subject_id, Artwork.placement == placement)
        )

    async def for_home(
        self, *, show_ids: Sequence[int], playlist_ids: Sequence[int], section_ids: Sequence[int]
    ) -> list[Artwork]:
        """Everything the home screen might draw, in one query.

        The alternative is a lazy load per section per placement, which is how a
        page with a dozen rails turns into fifty round trips.
        """
        clauses = []
        if show_ids:
            clauses.append(Artwork.show_id.in_(show_ids))
        if playlist_ids:
            clauses.append(Artwork.playlist_id.in_(playlist_ids))
        if section_ids:
            clauses.append(Artwork.section_id.in_(section_ids))
        if not clauses:
            return []

        rows = await self.session.scalars(select(Artwork).where(or_(*clauses)))
        return list(rows.unique())
