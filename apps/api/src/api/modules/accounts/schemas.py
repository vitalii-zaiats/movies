"""What the accounts module hands out.

`id` never appears here — the outside world knows a user by `public_id`.
"""

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from api.core.schemas import ORMModel, Page
from api.modules.accounts.models import Role


class UserOut(ORMModel):
    public_id: str
    display_name: str
    email: str | None
    role: Role
    is_guest: bool
    created_at: datetime
    last_seen_at: datetime


class Identity(BaseModel):
    """A user together with the token that proves it.

    Returned once, at the moment a session is created. Every later response
    carries the user alone — the token is the client's to keep.
    """

    token: str
    user: UserOut


class ClaimRequest(BaseModel):
    """Turn the guest you already are into an account you can log back into."""

    email: EmailStr
    password: str = Field(min_length=8, max_length=200)
    display_name: str | None = Field(default=None, max_length=80)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=200)


class RenameRequest(BaseModel):
    display_name: str = Field(min_length=1, max_length=80)


class RoleRequest(BaseModel):
    role: Role


class UserPage(Page):
    items: list[UserOut]
