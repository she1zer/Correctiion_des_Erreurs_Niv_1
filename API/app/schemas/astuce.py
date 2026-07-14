from datetime import datetime

from pydantic import BaseModel, Field


class AstuceBase(BaseModel):
    emoji: str = Field(default="💡", max_length=16)
    title: str = Field(min_length=3, max_length=200)
    summary: str = Field(min_length=5, max_length=500)
    detail: str = Field(min_length=5, max_length=5000)
    category: str = Field(min_length=2, max_length=80)
    icon_name: str = Field(default="lightbulb_rounded", max_length=80)
    gradient_start: str = Field(default="#FFD54F", max_length=10)
    gradient_end: str = Field(default="#F9A825", max_length=10)
    accent_color: str = Field(default="#F57F17", max_length=10)
    ordre: int = 0
    is_active: bool = True


class AstuceCreate(AstuceBase):
    pass


class AstuceUpdate(BaseModel):
    emoji: str | None = Field(default=None, max_length=16)
    title: str | None = Field(default=None, max_length=200)
    summary: str | None = Field(default=None, max_length=500)
    detail: str | None = Field(default=None, max_length=5000)
    category: str | None = Field(default=None, max_length=80)
    icon_name: str | None = Field(default=None, max_length=80)
    gradient_start: str | None = Field(default=None, max_length=10)
    gradient_end: str | None = Field(default=None, max_length=10)
    accent_color: str | None = Field(default=None, max_length=10)
    ordre: int | None = None
    is_active: bool | None = None


class AstuceResponse(AstuceBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
