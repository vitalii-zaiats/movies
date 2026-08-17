"""What every repository has in common: a session and a table.

Repositories exist so that "how do we find X" has one greppable answer. This
base only saves the boilerplate — the interesting queries are still written out
by hand in each module, because a generic `filter(**kwargs)` is how a data layer
stops being readable.
"""

from typing import Any, ClassVar

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession


class Repository[ModelT]:
    model: ClassVar[Any]

    def __init__(self, session: AsyncSession) -> None:
        self.session = session

    async def get(self, row_id: int) -> ModelT | None:
        return await self.session.get(self.model, row_id)

    async def add(self, row: ModelT) -> ModelT:
        """Flush, don't commit. Committing is the service's decision."""
        self.session.add(row)
        await self.session.flush()
        return row

    async def delete(self, row: ModelT) -> None:
        await self.session.delete(row)

    async def count(self) -> int:
        return await self.session.scalar(select(func.count()).select_from(self.model)) or 0
