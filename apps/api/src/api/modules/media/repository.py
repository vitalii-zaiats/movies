"""Every query about uploaded files."""

from sqlalchemy import func, select

from api.core.repository import Repository
from api.modules.media.models import MediaFile


class MediaRepository(Repository[MediaFile]):
    model = MediaFile

    async def by_digest(self, digest: str) -> MediaFile | None:
        return await self.session.scalar(select(MediaFile).where(MediaFile.digest == digest))

    async def page(self, *, limit: int = 50, offset: int = 0) -> tuple[list[MediaFile], int]:
        query = select(MediaFile)
        total = await self.session.scalar(select(func.count()).select_from(query.subquery()))
        rows = await self.session.scalars(
            query.order_by(MediaFile.id.desc()).limit(limit).offset(offset)
        )
        return list(rows.unique()), total or 0
