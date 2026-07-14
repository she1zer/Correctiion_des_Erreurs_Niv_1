from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.enums import UserRole
from app.models.action_interne import ActionInterne
from app.models.user import User
from app.schemas.action import ActionInterneCreate, ActionInterneResponse, ActionInterneUpdate
from app.security import require_roles

router = APIRouter(prefix="/api/actions-internes", tags=["Actions internes"])


@router.get("/", response_model=list[ActionInterneResponse])
def list_actions(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    return (
        db.query(ActionInterne)
        .options(
            joinedload(ActionInterne.responsable),
            joinedload(ActionInterne.support),
        )
        .order_by(ActionInterne.created_at.desc())
        .all()
    )


@router.post("/", response_model=ActionInterneResponse, status_code=201)
def create_action(
    data: ActionInterneCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    action = ActionInterne(**data.model_dump())
    db.add(action)
    db.commit()
    db.refresh(action)
    return (
        db.query(ActionInterne)
        .options(
            joinedload(ActionInterne.responsable),
            joinedload(ActionInterne.support),
        )
        .filter(ActionInterne.id == action.id)
        .first()
    )


@router.get("/{action_id}", response_model=ActionInterneResponse)
def get_action(
    action_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    action = (
        db.query(ActionInterne)
        .options(
            joinedload(ActionInterne.responsable),
            joinedload(ActionInterne.support),
        )
        .filter(ActionInterne.id == action_id)
        .first()
    )
    if not action:
        raise HTTPException(status_code=404, detail="Action interne introuvable")
    return action


@router.patch("/{action_id}", response_model=ActionInterneResponse)
def update_action(
    action_id: int,
    data: ActionInterneUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    action = db.query(ActionInterne).get(action_id)
    if not action:
        raise HTTPException(status_code=404, detail="Action interne introuvable")
    update = data.model_dump(exclude_unset=True)
    if "statut" in update and update["statut"].value in ("non_entame", "annule", "bloque"):
        if not update.get("commentaire") and not action.commentaire:
            raise HTTPException(
                status_code=400,
                detail="Commentaire/justification obligatoire pour ce statut",
            )
    for key, value in update.items():
        setattr(action, key, value)
    db.commit()
    return get_action(action_id, db)


@router.delete("/{action_id}", status_code=204)
def delete_action(
    action_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    action = db.query(ActionInterne).get(action_id)
    if not action:
        raise HTTPException(status_code=404, detail="Action interne introuvable")
    db.delete(action)
    db.commit()
