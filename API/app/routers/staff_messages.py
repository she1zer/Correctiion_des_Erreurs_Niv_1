from datetime import datetime

from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from fastapi import APIRouter, Depends, HTTPException, Query

from app.database import get_db
from app.enums import UserRole
from app.models.staff_message import StaffMessage
from app.models.user import User
from app.security import get_current_user, require_roles, require_staff

router = APIRouter(prefix="/api/staff-messages", tags=["Messages internes"])


class StaffMessageCreate(BaseModel):
    content: str = Field(min_length=1)
    technicien_id: int | None = None


class StaffMessageResponse(BaseModel):
    id: int
    technicien_id: int
    sender_id: int
    sender_role: str
    content: str
    created_at: datetime
    sender_nom: str | None = None
    sender_prenom: str | None = None

    class Config:
        from_attributes = True


class StaffConversationSummary(BaseModel):
    technicien_id: int
    technicien_nom: str
    technicien_prenom: str
    poste: str | None = None
    last_message: str
    last_message_date: datetime | None = None
    unread_count: int = 0


def _serialize_message(msg: StaffMessage, db: Session) -> dict:
    sender = db.query(User).get(msg.sender_id)
    return {
        "id": msg.id,
        "technicien_id": msg.technicien_id,
        "sender_id": msg.sender_id,
        "sender_role": msg.sender_role,
        "content": msg.content,
        "created_at": msg.created_at,
        "sender_nom": sender.nom if sender else None,
        "sender_prenom": sender.prenom if sender else None,
    }


@router.post("/", response_model=StaffMessageResponse, status_code=201)
def send_staff_message(
    data: StaffMessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff()),
):
    if current_user.role == UserRole.technicien:
        technicien_id = current_user.id
        sender_role = "technicien"
    else:
        if not data.technicien_id:
            raise HTTPException(status_code=400, detail="technicien_id obligatoire pour l'admin")
        technicien = db.query(User).filter(User.id == data.technicien_id, User.role == UserRole.technicien).first()
        if not technicien:
            raise HTTPException(status_code=404, detail="Technicien introuvable")
        technicien_id = technicien.id
        sender_role = "admin"

    message = StaffMessage(
        technicien_id=technicien_id,
        sender_id=current_user.id,
        sender_role=sender_role,
        content=data.content.strip(),
    )
    db.add(message)
    db.commit()
    db.refresh(message)
    return _serialize_message(message, db)


@router.get("/")
def get_staff_messages(
    technicien_id: int | None = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff()),
):
    if current_user.role == UserRole.technicien:
        tid = current_user.id
    else:
        if not technicien_id:
            raise HTTPException(status_code=400, detail="technicien_id obligatoire pour l'admin")
        tid = technicien_id

    messages = (
        db.query(StaffMessage)
        .filter(StaffMessage.technicien_id == tid)
        .order_by(StaffMessage.created_at.asc())
        .all()
    )
    return [_serialize_message(m, db) for m in messages]


@router.get("/conversations", response_model=list[StaffConversationSummary])
def list_staff_conversations(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    techniciens = db.query(User).filter(User.role == UserRole.technicien, User.is_active.is_(True)).all()
    conversations = []

    for tech in techniciens:
        last_msg = (
            db.query(StaffMessage)
            .filter(StaffMessage.technicien_id == tech.id)
            .order_by(StaffMessage.created_at.desc())
            .first()
        )
        if last_msg:
            conversations.append(
                StaffConversationSummary(
                    technicien_id=tech.id,
                    technicien_nom=tech.nom,
                    technicien_prenom=tech.prenom,
                    poste=tech.poste,
                    last_message=last_msg.content,
                    last_message_date=last_msg.created_at,
                )
            )
        else:
            conversations.append(
                StaffConversationSummary(
                    technicien_id=tech.id,
                    technicien_nom=tech.nom,
                    technicien_prenom=tech.prenom,
                    poste=tech.poste,
                    last_message="Aucun message",
                    last_message_date=None,
                )
            )

    conversations.sort(key=lambda x: x.last_message_date or datetime.min, reverse=True)
    return conversations
