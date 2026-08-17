"""Wiring for activity."""

from typing import Annotated

from fastapi import Depends

from api.core.deps import DB
from api.modules.activity.service import ActivityService


def activity_service(session: DB) -> ActivityService:
    return ActivityService(session)


Activity = Annotated[ActivityService, Depends(activity_service)]
