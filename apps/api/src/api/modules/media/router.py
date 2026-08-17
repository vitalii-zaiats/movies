"""Uploading files, and serving them back.

Writes are admin-only; the read is open, because these are the images on the
home screen and every visitor needs them.
"""

from typing import Annotated

from fastapi import APIRouter, File, Query, UploadFile
from fastapi.responses import FileResponse, Response

from api.errors import Invalid, NotFound
from api.modules.accounts.deps import Admin
from api.modules.media import storage
from api.modules.media.deps import Media
from api.modules.media.models import MediaFile
from api.modules.media.schemas import MediaOut, MediaPage
from api.settings import settings

router = APIRouter(prefix="/media", tags=["media"])


@router.post("", response_model=MediaOut, status_code=201)
async def upload(admin: Admin, media: Media, file: Annotated[UploadFile, File()]) -> MediaFile:
    """Take an image and give back a URL.

    The format is decided by reading the bytes, not by trusting the multipart
    content type. Re-uploading the same file returns the same row — the name is
    the digest, so there's nothing to duplicate.
    """
    data = await file.read()
    if len(data) > settings.max_upload_bytes:
        # Checked here as well as in the service so a huge body is refused
        # before it's hashed.
        limit = settings.max_upload_bytes // (1024 * 1024)
        raise Invalid(f"too big — the limit is {limit} MiB")
    return await media.store(data, original_name=file.filename, uploaded_by_id=admin.id)


@router.get("", response_model=MediaPage)
async def list_media(
    _: Admin,
    media: Media,
    limit: Annotated[int, Query(ge=1, le=200)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
) -> MediaPage:
    """The picker's backing list — newest first."""
    files, total = await media.page(limit=limit, offset=offset)
    return MediaPage(
        total=total,
        limit=limit,
        offset=offset,
        items=[MediaOut.model_validate(file) for file in files],
    )


@router.delete("/{media_id}", status_code=204)
async def delete_media(media_id: int, _: Admin, media: Media) -> None:
    await media.delete(media_id)


@router.get("/{name}", include_in_schema=False)
async def serve(name: str) -> Response:
    """The file itself.

    Shares a path shape with `DELETE /media/{media_id}` and can't collide with
    it: a stored name is 64 hex characters and an extension, which no integer
    id will ever match. Short URLs win here — these end up in every `<img>` on
    the home screen.

    Immutable for a year: the name is the hash of the content, so these bytes
    can never become different bytes. In the deployed stack nginx should take
    this route over — it's here so the API is complete on its own.
    """
    path = storage.locate(name)
    if path is None:
        raise NotFound("no such file")
    return FileResponse(path, headers={"Cache-Control": "public, max-age=31536000, immutable"})
