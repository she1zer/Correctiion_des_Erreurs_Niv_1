from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.isi_chat import IsiChatConversation, IsiChatMessage
from app.models.user import User
from app.schemas.ai import (
    IsiChatRequest,
    IsiChatResponse,
    IsiConversationMessageResponse,
    IsiConversationResponse,
    IsiEmailAnalyzeRequest,
    IsiEmailAnalyzeResponse,
    IsiStatusResponse,
    OllamaChatRequest,
)
from app.config import settings
from app.security import require_roles
from app.services.easy_db_context_service import build_easy_db_context
from app.services.isi_ai_service import (
    analyze_email_with_isi,
    chat_isi,
    chat_ollama_raw,
    get_isi_model_label,
    get_isi_provider,
    isi_available,
    list_ollama_models,
    ollama_available,
)
from app.services.reference_extractor import extract_client_info, extract_references

router = APIRouter(prefix="/api/ai", tags=["Easy IA"])


def _conv_title_from_message(message: str) -> str:
    text = message.strip().replace("\n", " ")
    if len(text) <= 60:
        return text or "Conversation Easy"
    return text[:57] + "..."


@router.get("/status", response_model=IsiStatusResponse)
def isi_status(
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    provider = get_isi_provider()
    return IsiStatusResponse(
        available=isi_available(),
        provider=provider,
        model=get_isi_model_label(),
        base_url=(
            "https://generativelanguage.googleapis.com"
            if provider == "gemini"
            else settings.ollama_base_url if provider == "ollama" else "https://api.openai.com"
        ),
        installed_models=list_ollama_models() if provider == "ollama" else [],
        ollama_online=ollama_available(),
    )


@router.get("/conversations", response_model=list[IsiConversationResponse])
def list_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    convs = (
        db.query(IsiChatConversation)
        .filter(IsiChatConversation.user_id == current_user.id)
        .order_by(IsiChatConversation.updated_at.desc())
        .all()
    )
    result = []
    for c in convs:
        count = db.query(IsiChatMessage).filter(IsiChatMessage.conversation_id == c.id).count()
        result.append(
            IsiConversationResponse(
                id=c.id,
                title=c.title,
                created_at=c.created_at,
                updated_at=c.updated_at,
                message_count=count,
            )
        )
    return result


@router.post("/conversations", response_model=IsiConversationResponse, status_code=201)
def create_conversation(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    conv = IsiChatConversation(user_id=current_user.id, title="Nouvelle conversation")
    db.add(conv)
    db.commit()
    db.refresh(conv)
    return IsiConversationResponse(
        id=conv.id,
        title=conv.title,
        created_at=conv.created_at,
        updated_at=conv.updated_at,
        message_count=0,
    )


@router.get("/conversations/{conversation_id}/messages", response_model=list[IsiConversationMessageResponse])
def list_conversation_messages(
    conversation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    conv = db.query(IsiChatConversation).filter(IsiChatConversation.id == conversation_id).first()
    if not conv or conv.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Conversation introuvable")
    messages = (
        db.query(IsiChatMessage)
        .filter(IsiChatMessage.conversation_id == conversation_id)
        .order_by(IsiChatMessage.created_at.asc())
        .all()
    )
    return [
        IsiConversationMessageResponse(
            id=m.id,
            role=m.role,
            content=m.content,
            created_at=m.created_at,
        )
        for m in messages
    ]


@router.delete("/conversations/{conversation_id}", status_code=204)
def delete_conversation(
    conversation_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    conv = db.query(IsiChatConversation).filter(IsiChatConversation.id == conversation_id).first()
    if not conv or conv.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Conversation introuvable")
    db.delete(conv)
    db.commit()
    return Response(status_code=204)


@router.post("/chat", response_model=IsiChatResponse)
def isi_chat(
    data: IsiChatRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    if not isi_available():
        raise HTTPException(
            status_code=503,
            detail=(
                "Easy indisponible. Démarrez Ollama sur le PC : ollama serve"
            ),
        )

    conv: IsiChatConversation | None = None
    if data.conversation_id:
        conv = db.query(IsiChatConversation).filter(IsiChatConversation.id == data.conversation_id).first()
        if not conv or conv.user_id != current_user.id:
            raise HTTPException(status_code=404, detail="Conversation introuvable")
    else:
        conv = IsiChatConversation(
            user_id=current_user.id,
            title=_conv_title_from_message(data.message),
        )
        db.add(conv)
        db.flush()

    user_msg = IsiChatMessage(conversation_id=conv.id, role="user", content=data.message)
    db.add(user_msg)

    try:
        if data.history:
            history = [m.model_dump() for m in data.history]
        else:
            prior = (
                db.query(IsiChatMessage)
                .filter(IsiChatMessage.conversation_id == conv.id)
                .order_by(IsiChatMessage.created_at.asc())
                .all()
            )
            history = [{"role": m.role, "content": m.content} for m in prior]
        db_context, sources_found = build_easy_db_context(db, current_user, data.message)
        reply, model_used = chat_isi(history, data.message, db_context=db_context)
    except RuntimeError as e:
        db.rollback()
        raise HTTPException(status_code=502, detail=str(e)) from e

    assistant_msg = IsiChatMessage(conversation_id=conv.id, role="assistant", content=reply)
    db.add(assistant_msg)
    conv.updated_at = datetime.utcnow()
    if conv.title == "Nouvelle conversation" and not data.conversation_id:
        conv.title = _conv_title_from_message(data.message)
    db.commit()

    return IsiChatResponse(
        reply=reply,
        model=model_used,
        provider=get_isi_provider(),
        conversation_id=conv.id,
        sources_found=sources_found,
    )


@router.post("/ollama-chat", response_model=IsiChatResponse)
def ollama_chat(
    data: OllamaChatRequest,
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    if not ollama_available():
        raise HTTPException(
            status_code=503,
            detail="Ollama indisponible. Démarrez Ollama sur le PC : ollama serve",
        )

    history = [m.model_dump() for m in data.history]
    try:
        reply, model_used = chat_ollama_raw(history, data.message)
    except RuntimeError as e:
        raise HTTPException(status_code=502, detail=str(e)) from e

    return IsiChatResponse(
        reply=reply,
        model=model_used,
        provider="ollama",
        conversation_id=None,
        sources_found=0,
    )


@router.post("/analyze-email", response_model=IsiEmailAnalyzeResponse)
def isi_analyze_email(
    data: IsiEmailAnalyzeRequest,
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    text = f"{data.subject}\n{data.body}"
    refs = extract_references(text)
    client_info = extract_client_info(data.body, data.subject, data.from_address)

    result = IsiEmailAnalyzeResponse(
        references=refs,
        client_nom=client_info.get("client_nom"),
        contact=client_info.get("contact"),
        client_da=client_info.get("client_da"),
        used_isi=False,
    )

    if isi_available():
        isi_data = analyze_email_with_isi(data.subject, data.body, data.from_address)
        if isi_data:
            result.used_isi = True
            if isi_data.get("references"):
                merged = list(dict.fromkeys(refs + isi_data["references"]))
                result.references = merged
            result.client_nom = isi_data.get("client_nom") or result.client_nom
            result.contact = isi_data.get("contact") or result.contact
            result.client_da = isi_data.get("client_da") or result.client_da
            result.resume = isi_data.get("resume")

    return result
