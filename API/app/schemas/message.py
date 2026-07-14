from datetime import datetime
from pydantic import BaseModel

class MessageBase(BaseModel):
    content: str

class MessageCreate(BaseModel):
    content: str
    client_id: int | None = None  # Specifiable by admin to send message to a client

class MessageResponse(MessageBase):
    id: int
    client_id: int
    sender_role: str  # 'client' or 'support'
    created_at: datetime

    class Config:
        from_attributes = True
