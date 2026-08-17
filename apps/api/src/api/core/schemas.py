"""Shapes shared by every module's DTOs."""

from pydantic import BaseModel, ConfigDict


class ORMModel(BaseModel):
    """A DTO read straight off a SQLAlchemy row."""

    model_config = ConfigDict(from_attributes=True)


class Page(BaseModel):
    """The envelope every listing uses, so paging looks the same everywhere."""

    total: int
    limit: int
    offset: int
