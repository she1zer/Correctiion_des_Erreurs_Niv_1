from datetime import datetime

from pydantic import BaseModel, Field


class UserFeedbackCreate(BaseModel):
    type: str = Field(default="bug", pattern="^(bug|improvement|other)$")
    title: str = Field(min_length=3, max_length=200)
    description: str = Field(min_length=5, max_length=5000)


class UserFeedbackUpdate(BaseModel):
    status: str | None = Field(default=None, pattern="^(pending|in_progress|resolved|rejected)$")
    admin_response: str | None = None


class UserFeedbackResponse(BaseModel):
    id: int
    user_id: int
    type: str
    title: str
    description: str
    status: str
    admin_response: str | None = None
    created_at: datetime
    updated_at: datetime
    user_nom: str | None = None
    user_prenom: str | None = None
    user_email: str | None = None
    user_role: str | None = None

    class Config:
        from_attributes = True
