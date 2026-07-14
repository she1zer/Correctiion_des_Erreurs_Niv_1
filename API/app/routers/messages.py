from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database import get_db
from app.models.message import Message
from app.models.user import User
from app.schemas.message import MessageCreate, MessageResponse
from app.security import get_current_user, require_roles
from app.enums import UserRole

router = APIRouter(prefix="/api/messages", tags=["Messages"])

@router.post("/", response_model=MessageResponse, status_code=201)
def post_message(
    data: MessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role == UserRole.client:
        # Client sends message to support
        message = Message(
            client_id=current_user.id,
            sender_role="client",
            content=data.content
        )
    else:
        # Admin or technicien sends reply to client
        if not data.client_id:
            raise HTTPException(status_code=400, detail="client_id obligatoire pour le support")
        
        # Verify client exists
        client = db.query(User).filter(User.id == data.client_id).first()
        if not client:
            raise HTTPException(status_code=404, detail="Client introuvable")
            
        message = Message(
            client_id=data.client_id,
            sender_role="support",
            content=data.content
        )
        
    db.add(message)
    db.commit()
    db.refresh(message)
    return message

@router.get("/", response_model=list[MessageResponse])
def get_messages(
    client_id: int | None = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role == UserRole.client:
        return db.query(Message).filter(Message.client_id == current_user.id).order_by(Message.created_at.asc()).all()
    else:
        # Admin / support must specify a client_id to get their chat history
        if not client_id:
            raise HTTPException(status_code=400, detail="client_id obligatoire pour le support")
        return db.query(Message).filter(Message.client_id == client_id).order_by(Message.created_at.asc()).all()

@router.get("/conversations")
def get_conversations(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    # Fetch distinct clients who have sent or received messages
    subquery = db.query(Message.client_id).distinct().subquery()
    clients = db.query(User).filter(User.id.in_(subquery)).all()
    
    conversations = []
    for client in clients:
        # Get last message
        last_msg = db.query(Message).filter(Message.client_id == client.id).order_by(Message.created_at.desc()).first()
        conversations.append({
            "client_id": client.id,
            "email": client.email,
            "nom": client.nom,
            "prenom": client.prenom,
            "telephone": client.telephone,
            "poste": client.poste,
            "role": client.role.value if hasattr(client.role, 'value') else client.role,
            "last_message": last_msg.content if last_msg else "",
            "last_message_date": last_msg.created_at.isoformat() if last_msg else None
        })
        
    # Sort conversations by last message date desc
    conversations.sort(key=lambda x: x["last_message_date"] or "", reverse=True)
    return conversations


@router.delete("/conversations/{client_id}", status_code=204)
def delete_conversation(
    client_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    client = db.query(User).filter(User.id == client_id).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")
    db.query(Message).filter(Message.client_id == client_id).delete()
    db.commit()
