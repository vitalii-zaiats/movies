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


class DeviceLinkOut(BaseModel):
    """What a television is told when it asks to be signed in.

    `verify_path` rather than a URL, like `vod_base` and `media_base`: the
    server has no idea what address this install is reached on, and the client
    that drew the QR does.
    """

    code: str
    secret: str
    verify_path: str
    expires_in: int


class DeviceLinkStatus(BaseModel):
    """What the phone is about to approve, before it approves it."""

    code: str
    device_name: str | None
    approved: bool
    expires_in: int


class DeviceApproval(BaseModel):
    code: str


class DeviceCollect(BaseModel):
    secret: str


class DeviceSession(BaseModel):
    """Not yet, or here you go.

    `pending` is the ordinary answer for as long as somebody is walking to their
    phone, so it is a status rather than an error — a television polling this
    should not have to read 404s to know it is still waiting.
    """

    status: str
    identity: Identity | None = None
