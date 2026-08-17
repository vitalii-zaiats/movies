"""The one dependency every module needs: a session for this request.

Identity lives in `modules/accounts/deps.py`, not here — this file has to stay
importable by the accounts module itself.
"""

from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from api.core.database import get_session

DB = Annotated[AsyncSession, Depends(get_session)]
