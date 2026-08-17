"""Taking an upload and turning it into a URL."""

from dataclasses import dataclass

from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from api.errors import Invalid, NotFound
from api.modules.media import storage
from api.modules.media.images import EXTENSIONS, NotAnImage, inspect
from api.modules.media.models import MediaFile
from api.modules.media.repository import MediaRepository
from api.settings import settings


@dataclass(slots=True)
class MediaService:
    session: AsyncSession

    @property
    def files(self) -> MediaRepository:
        return MediaRepository(self.session)

    async def store(
        self, data: bytes, *, original_name: str | None = None, uploaded_by_id: int | None = None
    ) -> MediaFile:
        """Identify, measure, write, record. Uploading twice is idempotent."""
        if not data:
            raise Invalid("empty upload")
        if len(data) > settings.max_upload_bytes:
            limit = settings.max_upload_bytes // (1024 * 1024)
            raise Invalid(f"too big — the limit is {limit} MiB")

        try:
            image = inspect(data)
        except NotAnImage as exc:
            raise Invalid(str(exc)) from exc

        digest = storage.digest_of(data)
        existing = await self.files.by_digest(digest)
        if existing is not None:
            # The row is already there, but the file may not be if the volume
            # was replaced under it. Writing is cheap and idempotent.
            storage.write(existing.filename, data)
            return existing

        extension = EXTENSIONS[image.content_type]
        storage.write(f"{digest}{extension}", data)

        record = MediaFile(
            digest=digest,
            extension=extension,
            content_type=image.content_type,
            size_bytes=len(data),
            width=image.width,
            height=image.height,
            original_name=(original_name or None) and original_name[:300],
        )
        record.uploaded_by_id = uploaded_by_id
        try:
            await self.files.add(record)
            await self.session.commit()
        except IntegrityError:
            # Two admins uploading the same file at once. The unique index is
            # the referee; whoever lost just reads the winner's row.
            await self.session.rollback()
            winner = await self.files.by_digest(digest)
            if winner is None:
                raise
            return winner
        return record

    async def get(self, media_id: int) -> MediaFile:
        record = await self.files.get(media_id)
        if record is None:
            raise NotFound(f"no media {media_id}")
        return record

    async def url(self, media_id: int) -> str:
        """Where a file is served from, for callers that only hold an id.

        Here rather than in a caller's DTO layer: how these URLs are built is
        this module's business, and it changes the day nginx or a CDN takes the
        serving over.
        """
        return storage.url_for((await self.get(media_id)).filename)

    async def page(self, *, limit: int = 50, offset: int = 0) -> tuple[list[MediaFile], int]:
        return await self.files.page(limit=limit, offset=offset)

    async def delete(self, media_id: int) -> None:
        """Drops the row and the file.

        Any artwork pointing at it is left with its stored URL, which will now
        404 — the frontend already treats a broken image as the normal case, and
        a cascade here would silently empty a home screen instead.
        """
        record = await self.get(media_id)
        name = record.filename
        await self.files.delete(record)
        await self.session.commit()
        storage.remove(name)
