"""Every query about users and their sessions."""

from datetime import datetime

from sqlalchemy import delete, func, select

from api.core.repository import Repository
from api.modules.accounts.models import AuthSession, Role, User


class UserRepository(Repository[User]):
    model = User

    async def by_public_id(self, public_id: str) -> User | None:
        return await self.session.scalar(select(User).where(User.public_id == public_id))

    async def by_email(self, email: str) -> User | None:
        """Case-folded, because nobody remembers how they typed their email."""
        return await self.session.scalar(select(User).where(User.email == email.strip().lower()))

    async def page(
        self,
        *,
        limit: int = 50,
        offset: int = 0,
        role: Role | None = None,
        guests: bool | None = None,
    ) -> tuple[list[User], int]:
        query = select(User)
        if role is not None:
            query = query.where(User.role == role)
        if guests is not None:
            query = query.where(
                User.claimed_at.is_(None) if guests else User.claimed_at.is_not(None)
            )

        total = await self.session.scalar(select(func.count()).select_from(query.subquery()))
        rows = await self.session.scalars(
            query.order_by(User.created_at.desc()).limit(limit).offset(offset)
        )
        return list(rows), total or 0

    async def count_admins(self) -> int:
        return (
            await self.session.scalar(
                select(func.count()).select_from(User).where(User.role == Role.admin)
            )
            or 0
        )


class SessionRepository(Repository[AuthSession]):
    model = AuthSession

    async def by_digest(self, digest: str) -> AuthSession | None:
        return await self.session.scalar(
            select(AuthSession).where(AuthSession.token_hash == digest)
        )

    async def revoke_all(self, user_id: int) -> None:
        await self.session.execute(delete(AuthSession).where(AuthSession.user_id == user_id))

    async def purge_expired(self, before: datetime) -> int:
        """Housekeeping. Nothing calls this on a request path — it's for a job."""
        result = await self.session.execute(
            delete(AuthSession).where(AuthSession.expires_at < before)
        )
        return result.rowcount or 0
