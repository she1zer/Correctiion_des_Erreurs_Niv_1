from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.user import User
from app.schemas.action import (
    ActionDisponible,
    ActionPriseCreate,
    ActionPriseResponse,
    ActionPriseUpdate,
)
from app.security import get_current_user, require_roles
from app.services import technicien_service as svc

router = APIRouter(prefix="/api/technicien", tags=["Technicien"])


@router.get("/actions-disponibles", response_model=list[ActionDisponible])
def actions_disponibles(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.technicien, UserRole.admin)),
):
    return svc.get_actions_disponibles(db, current_user)


@router.get("/actions-affaires", response_model=list[ActionDisponible])
def actions_affaires(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.technicien, UserRole.admin)),
):
    return svc.get_actions_affaires(db, current_user)


@router.get("/actions-internes", response_model=list[ActionDisponible])
def actions_internes(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.technicien, UserRole.admin)),
):
    return svc.get_actions_internes(db, current_user)


@router.post("/prendre-action", response_model=ActionPriseResponse, status_code=201)
def prendre_action(
    data: ActionPriseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.technicien, UserRole.admin)),
):
    return svc.prendre_action(db, current_user, data)


@router.get("/mes-actions", response_model=list[ActionPriseResponse])
def mes_actions(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.technicien, UserRole.admin)),
):
    return svc.get_mes_prises(db, current_user)


@router.get("/support-tasks", response_model=list[ActionPriseResponse])
def support_tasks(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.technicien, UserRole.admin)),
):
    return svc.get_support_tasks(db, current_user)


@router.patch("/prises/{prise_id}", response_model=ActionPriseResponse)
def update_prise(
    prise_id: int,
    data: ActionPriseUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.technicien, UserRole.admin)),
):
    return svc.update_prise(db, current_user, prise_id, data)
