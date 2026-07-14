from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.authorized_phone import AuthorizedEmployeePhone
from app.models.user import User
from app.schemas.authorized_phone import (
    AuthorizedPhoneCreate,
    AuthorizedPhoneResponse,
    AuthorizedPhoneUpdate,
)
from app.security import require_roles
from app.services.phone_utils import phones_match

router = APIRouter(prefix="/api/authorized-phones", tags=["Téléphones employés"])


def _duplicate_exists(db: Session, telephone: str, exclude_id: int | None = None) -> bool:
    rows = db.query(AuthorizedEmployeePhone).all()
    for row in rows:
        if exclude_id and row.id == exclude_id:
            continue
        if phones_match(row.telephone, telephone):
            return True
    return False


@router.get("/", response_model=list[AuthorizedPhoneResponse])
def list_authorized_phones(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    return (
        db.query(AuthorizedEmployeePhone)
        .order_by(AuthorizedEmployeePhone.created_at.desc())
        .all()
    )


@router.post("/", response_model=AuthorizedPhoneResponse, status_code=201)
def create_authorized_phone(
    data: AuthorizedPhoneCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin)),
):
    if _duplicate_exists(db, data.telephone):
        raise HTTPException(status_code=400, detail="Ce numéro est déjà enregistré")
    row = AuthorizedEmployeePhone(
        telephone=data.telephone.strip(),
        label=data.label,
        created_by_id=current_user.id,
    )
    db.add(row)
    db.commit()
    db.refresh(row)
    return row


@router.patch("/{phone_id}", response_model=AuthorizedPhoneResponse)
def update_authorized_phone(
    phone_id: int,
    data: AuthorizedPhoneUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    row = db.query(AuthorizedEmployeePhone).filter(AuthorizedEmployeePhone.id == phone_id).first()
    if not row:
        raise HTTPException(status_code=404, detail="Numéro introuvable")
    if data.telephone and _duplicate_exists(db, data.telephone, exclude_id=phone_id):
        raise HTTPException(status_code=400, detail="Ce numéro est déjà enregistré")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(row, key, value)
    db.commit()
    db.refresh(row)
    return row


@router.delete("/{phone_id}", status_code=204)
def delete_authorized_phone(
    phone_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    row = db.query(AuthorizedEmployeePhone).filter(AuthorizedEmployeePhone.id == phone_id).first()
    if not row:
        raise HTTPException(status_code=404, detail="Numéro introuvable")
    db.delete(row)
    db.commit()
