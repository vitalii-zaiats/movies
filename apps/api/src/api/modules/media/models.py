"""The uploads table.

One row per distinct set of bytes. `digest` is both the primary way in and the
name on disk, which is what makes re-uploading the same file a no-op instead of
a second copy.
"""

from sqlalchemy import ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from api.core.models import Base, TimestampMixin
from api.modules.accounts.models import User


class MediaFile(Base, TimestampMixin):
    __tablename__ = "media_files"

    id: Mapped[int] = mapped_column(primary_key=True)

    # SHA-256, hex. The file on disk is `{digest}{extension}`.
    digest: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    extension: Mapped[str] = mapped_column(String(8))
    content_type: Mapped[str] = mapped_column(String(60))
    size_bytes: Mapped[int] = mapped_column(Integer)

    # Read out of the bytes at upload time, so the admin panel can say "this is
    # 400px wide, it will look soft as a hero".
    width: Mapped[int | None] = mapped_column(Integer, nullable=True)
    height: Mapped[int | None] = mapped_column(Integer, nullable=True)

    # What the admin called it on their disk. Kept for the picker, never used
    # as a path — the name on disk is the digest.
    original_name: Mapped[str | None] = mapped_column(String(300), nullable=True)

    # Who uploaded it. Null once that account is gone; the file itself stays,
    # because a banner shouldn't vanish from the home screen when an admin does.
    uploaded_by_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    uploaded_by: Mapped[User | None] = relationship(lazy="joined")

    @property
    def filename(self) -> str:
        return f"{self.digest}{self.extension}"
