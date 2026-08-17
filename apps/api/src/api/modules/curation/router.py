"""The home screen, and the admin routes that decide what's on it.

`GET /home` is open and takes no identity at all — it's the same page for
everyone, which is what makes it cacheable. Everything that changes it is
admin-only.
"""

from typing import Annotated

from fastapi import APIRouter, Query

from api.errors import Forbidden
from api.modules.accounts.deps import Admin, Viewer
from api.modules.curation.deps import Curation
from api.modules.curation.models import RECOMMENDED, Artwork, Section
from api.modules.curation.schemas import (
    ArtworkOut,
    ArtworkUpsert,
    HomeOut,
    HomeSection,
    PlacementInfo,
    SectionCreate,
    SectionOut,
    SectionReorder,
    SectionUpdate,
)
from api.modules.curation.service import ResolvedSection

router = APIRouter(tags=["curation"])


def _home_section(resolved: ResolvedSection) -> HomeSection:
    section = resolved.section
    return HomeSection(
        id=section.id,
        kind=section.kind,
        title=section.title,
        kicker=section.kicker,
        link=section.link,
        show=section.show,  # type: ignore[arg-type]
        playlist=section.playlist,  # type: ignore[arg-type]
        artwork=resolved.artwork,
        items=resolved.episodes,  # type: ignore[arg-type]
    )


@router.get("/home", response_model=HomeOut)
async def home(
    curation: Curation,
    user: Viewer,
    preview: Annotated[bool, Query(description="admins: include hidden sections")] = False,
) -> HomeOut:
    """One request for the whole front page.

    The client used to build this itself — a probe per show, sorted by episode
    count, biggest one into the hero. This is the same screen, decided by a
    person instead of guessed at, in one round trip.

    Open, and `Viewer` rather than `CurrentUser`: the page is the same for
    everyone, so it needn't mint a guest to be read. The identity is here only
    to decide whether `preview` is allowed — a draft section is unpublished, and
    a query parameter shouldn't be enough to publish it.
    """
    if preview and not (user is not None and user.is_admin):
        raise Forbidden("preview is for admins")

    sections = await curation.home(preview=preview)
    return HomeOut(sections=[_home_section(section) for section in sections])


@router.get("/sections", response_model=list[SectionOut])
async def list_sections(_: Admin, curation: Curation) -> list[Section]:
    """Everything, hidden ones included — this is the editing view."""
    return await curation.all_sections()


@router.post("/sections", response_model=SectionOut, status_code=201)
async def create_section(body: SectionCreate, _: Admin, curation: Curation) -> Section:
    return await curation.create_section(**body.model_dump())


@router.put("/sections/order", response_model=list[SectionOut])
async def reorder_sections(
    body: SectionReorder, _: Admin, curation: Curation
) -> list[Section]:
    return await curation.reorder_sections(body.section_ids)


@router.patch("/sections/{section_id}", response_model=SectionOut)
async def update_section(
    section_id: int, body: SectionUpdate, _: Admin, curation: Curation
) -> Section:
    # `exclude_unset` is the whole point: sending `{"visible": false}` must not
    # also blank out the kicker that wasn't mentioned.
    return await curation.update_section(section_id, body.model_dump(exclude_unset=True))


@router.delete("/sections/{section_id}", status_code=204)
async def delete_section(section_id: int, _: Admin, curation: Curation) -> None:
    await curation.delete_section(section_id)


@router.get("/artwork/placements", response_model=list[PlacementInfo])
async def placements() -> list[PlacementInfo]:
    """The sizes to upload. Advisory — nothing is rejected for being off."""
    return [
        PlacementInfo(
            placement=placement,
            width=width,
            height=height,
            ratio=f"{width} / {height}",
        )
        for placement, (width, height) in RECOMMENDED.items()
    ]


@router.get("/artwork", response_model=list[ArtworkOut])
async def list_artwork(
    _: Admin,
    curation: Curation,
    subject_type: Annotated[str, Query(pattern="^(show|playlist|section)$")],
    subject_id: int,
) -> list[Artwork]:
    return await curation.artwork_for(subject_type, subject_id)


@router.put("/artwork", response_model=ArtworkOut)
async def set_artwork(body: ArtworkUpsert, _: Admin, curation: Curation) -> Artwork:
    """One picture at one placement, replacing whatever was there.

    Upsert rather than POST-then-PATCH because there is only ever one hero for
    a show — the unique constraint says so, and this is the shape that matches.
    """
    return await curation.set_artwork(
        subject_type=body.subject_type,
        subject_id=body.subject_id,
        placement=body.placement,
        url=body.url,
        media_id=body.media_id,
    )


@router.delete("/artwork/{artwork_id}", status_code=204)
async def delete_artwork(artwork_id: int, _: Admin, curation: Curation) -> None:
    await curation.delete_artwork(artwork_id)
