from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.user import User
from app.schemas.user import UserBrief, UserResponse, UserUpdate
from app.security import get_current_user, require_roles, hash_password

router = APIRouter(prefix="/api/users", tags=["Utilisateurs"])


@router.get("/techniciens", response_model=list[UserBrief])
def list_techniciens(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    return (
        db.query(User)
        .filter(User.role.in_([UserRole.technicien, UserRole.admin]), User.is_active.is_(True))
        .order_by(User.nom)
        .all()
    )


@router.get("/", response_model=list[UserResponse])
def list_users(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    return db.query(User).order_by(User.created_at.desc()).all()


@router.patch("/me", response_model=UserResponse)
def update_profile(
    data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    update_data = data.model_dump(exclude_unset=True)
    update_data.pop("role", None)
    update_data.pop("is_active", None)
    update_data.pop("poste", None)
    update_data.pop("can_create_affaire", None)
    update_data.pop("can_create_devis", None)
    update_data.pop("can_create_rapport", None)
    update_data.pop("can_manage_actions_internes", None)
    
    if "password" in update_data and update_data["password"]:
        current_user.hashed_password = hash_password(update_data["password"])
        update_data.pop("password")
        
    for key, value in update_data.items():
        setattr(current_user, key, value)
        
    db.commit()
    db.refresh(current_user)
    return current_user


@router.patch("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: int,
    data: UserUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    user = db.query(User).get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")
    
    update_data = data.model_dump(exclude_unset=True)
    if "password" in update_data and update_data["password"]:
        user.hashed_password = hash_password(update_data["password"])
        update_data.pop("password")
        
    for key, value in update_data.items():
        setattr(user, key, value)
        
    db.commit()
    db.refresh(user)
    return user


def effective_permissions(user: User) -> dict:
    if user.role == UserRole.admin:
        return {
            "can_create_affaire": True,
            "can_create_devis": True,
            "can_create_rapport": True,
            "can_manage_actions_internes": True,
            "can_access_caisse": True,
            "can_caisse_controle": True,
            "can_caisse_livre": True,
        }
    return {
        "can_create_affaire": bool(user.can_create_affaire),
        "can_create_devis": bool(user.can_create_devis),
        "can_create_rapport": bool(user.can_create_rapport),
        "can_manage_actions_internes": bool(user.can_manage_actions_internes),
        "can_access_caisse": bool(user.can_access_caisse),
        "can_caisse_controle": bool(user.can_caisse_controle),
        "can_caisse_livre": bool(user.can_caisse_livre),
    }


@router.get("/me/permissions")
def my_permissions(current_user: User = Depends(get_current_user)):
    return effective_permissions(current_user)


@router.delete("/{user_id}", status_code=204)
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin)),
):
    if user_id == current_user.id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas supprimer votre propre compte")
    user = db.query(User).get(user_id)
    if not user:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")
    db.delete(user)
    db.commit()
