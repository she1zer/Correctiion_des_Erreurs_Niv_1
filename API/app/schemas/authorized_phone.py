from datetime import datetime

from pydantic import BaseModel, Field


class AuthorizedPhoneCreate(BaseModel):
    telephone: str = Field(min_length=8, max_length=30)
    label: str | None = Field(default=None, max_length=120)


class AuthorizedPhoneUpdate(BaseModel):
    telephone: str | None = Field(default=None, min_length=8, max_length=30)
    label: str | None = None
    is_active: bool | None = None


class AuthorizedPhoneResponse(BaseModel):
    id: int
    telephone: str
    label: str | None = None
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True
