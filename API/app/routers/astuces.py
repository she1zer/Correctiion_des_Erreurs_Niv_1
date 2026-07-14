from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.astuce import Astuce
from app.models.user import User
from app.schemas.astuce import AstuceCreate, AstuceResponse, AstuceUpdate
from app.security import get_current_user, require_roles

router = APIRouter(prefix="/api/astuces", tags=["Astuces ISITEK"])

DEFAULT_ASTUCES = [
    {
        "emoji": "🔌", "title": "Où placer vos prises ?",
        "summary": "Installez-les à 30 cm du sol dans les pièces de vie, à 110 cm au-dessus du plan de travail en cuisine.",
        "detail": "Dans un salon ou une chambre, prévoyez une prise tous les 3 à 4 mètres le long des murs, à 30 cm du sol (norme NFC 15-100). En cuisine, placez les prises à 110 cm au-dessus du plan de travail.",
        "category": "Électricité", "icon_name": "outlet_rounded",
        "gradient_start": "#FFB300", "gradient_end": "#FF6F00", "accent_color": "#E65100", "ordre": 1,
    },
    {
        "emoji": "💡", "title": "Emplacement des interrupteurs",
        "summary": "Placez-les à 90 cm du sol, côté poignée de la porte, à l'entrée de chaque pièce.",
        "detail": "L'interrupteur se place du côté de la poignée de la porte. Hauteur standard : 90 cm du sol.",
        "category": "Électricité", "icon_name": "lightbulb_rounded",
        "gradient_start": "#FFD54F", "gradient_end": "#F9A825", "accent_color": "#F57F17", "ordre": 2,
    },
    {
        "emoji": "🚿", "title": "Électricité en salle de bain",
        "summary": "Respectez les volumes de sécurité : aucune prise à moins de 60 cm de la baignoire ou douche.",
        "detail": "La salle de bain est divisée en volumes (0, 1, 2). Aucune prise dans le volume 0.",
        "category": "Sécurité", "icon_name": "shower_rounded",
        "gradient_start": "#4FC3F7", "gradient_end": "#0277BD", "accent_color": "#01579B", "ordre": 3,
    },
    {
        "emoji": "🛡️", "title": "Disjoncteur différentiel",
        "summary": "Un différentiel 30 mA protège les personnes. Obligatoire sur toutes les prises.",
        "detail": "Chaque circuit de prises doit être protégé par un disjoncteur différentiel 30 mA.",
        "category": "Sécurité", "icon_name": "shield_rounded",
        "gradient_start": "#EF5350", "gradient_end": "#C62828", "accent_color": "#B71C1C", "ordre": 4,
    },
]


def seed_astuces(db: Session) -> None:
    if db.query(Astuce).first():
        return
    for data in DEFAULT_ASTUCES:
        db.add(Astuce(**data))
    db.commit()


@router.get("/", response_model=list[AstuceResponse])
def list_astuces(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_user),
):
    seed_astuces(db)
    return (
        db.query(Astuce)
        .filter(Astuce.is_active == True)
        .order_by(Astuce.ordre.asc(), Astuce.id.asc())
        .all()
    )


@router.get("/admin/all", response_model=list[AstuceResponse])
def list_all_astuces_admin(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    seed_astuces(db)
    return db.query(Astuce).order_by(Astuce.ordre.asc(), Astuce.id.asc()).all()


@router.post("/", response_model=AstuceResponse, status_code=201)
def create_astuce(
    data: AstuceCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    astuce = Astuce(**data.model_dump())
    db.add(astuce)
    db.commit()
    db.refresh(astuce)
    return astuce


@router.patch("/{astuce_id}", response_model=AstuceResponse)
def update_astuce(
    astuce_id: int,
    data: AstuceUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    astuce = db.query(Astuce).filter(Astuce.id == astuce_id).first()
    if not astuce:
        raise HTTPException(status_code=404, detail="Astuce introuvable")
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(astuce, k, v)
    astuce.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(astuce)
    return astuce


@router.delete("/{astuce_id}", status_code=204)
def delete_astuce(
    astuce_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    astuce = db.query(Astuce).filter(Astuce.id == astuce_id).first()
    if not astuce:
        raise HTTPException(status_code=404, detail="Astuce introuvable")
    db.delete(astuce)
    db.commit()
