from pydantic import BaseModel, Field
from datetime import datetime


class ChatMessage(BaseModel):
    role: str = "user"
    content: str


class IsiChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=8000)
    history: list[ChatMessage] = Field(default_factory=list)
    conversation_id: int | None = None


class OllamaChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=8000)
    history: list[ChatMessage] = Field(default_factory=list)


class IsiConversationResponse(BaseModel):
    id: int
    title: str
    created_at: datetime
    updated_at: datetime
    message_count: int = 0

    class Config:
        from_attributes = True


class IsiConversationMessageResponse(BaseModel):
    id: int
    role: str
    content: str
    created_at: datetime

    class Config:
        from_attributes = True


class IsiChatResponse(BaseModel):
    reply: str
    model: str
    provider: str = "openai"
    conversation_id: int | None = None
    sources_found: int = 0


class IsiStatusResponse(BaseModel):
    available: bool
    provider: str = "none"
    model: str
    base_url: str = ""
    installed_models: list[str] = Field(default_factory=list)
    ollama_online: bool = False


class IsiEmailAnalyzeRequest(BaseModel):
    subject: str = ""
    body: str = Field(..., min_length=1)
    from_address: str = ""


class IsiEmailAnalyzeResponse(BaseModel):
    references: list[str] = Field(default_factory=list)
    client_nom: str | None = None
    contact: str | None = None
    client_da: str | None = None
    resume: str | None = None
    used_isi: bool = False
