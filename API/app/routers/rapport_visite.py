import os
import shutil
from datetime import datetime

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.rapport_visite import RapportVisite
from app.models.user import User
from app.schemas.rapport_visite import (
    EtatLieuxLigne,
    RapportPhotoItem,
    RapportVisiteCreate,
    RapportVisiteResponse,
    RapportVisiteUpdate,
)
from app.security import require_roles, user_has_permission

router = APIRouter(prefix="/api/rapport-visite", tags=["Rapports de visite"])

UPLOAD_ROOT = "uploads/rapports"


def _require_can_create_rapport(user: User) -> None:
    if user.role == UserRole.technicien and not user_has_permission(user, "can_create_rapport"):
        raise HTTPException(
            status_code=403,
            detail="Vous n'avez pas l'autorisation de gérer les rapports de visite",
        )


def _can_view(rapport: RapportVisite, user: User) -> bool:
    if user.role == UserRole.admin:
        return True
    return rapport.created_by_id == user.id


def _can_edit(rapport: RapportVisite, user: User) -> bool:
    if user.role == UserRole.admin:
        return True
    if rapport.created_by_id != user.id:
        return False
    return user_has_permission(user, "can_create_rapport")


def _user_display(db: Session, user_id: int | None) -> str | None:
    if not user_id:
        return None
    u = db.query(User).filter(User.id == user_id).first()
    if not u:
        return None
    return f"{u.prenom} {u.nom}".strip()


def _generate_numero(db: Session) -> str:
    year = datetime.utcnow().year
    prefix = f"RVT-{year}-"
    count = db.query(RapportVisite).filter(RapportVisite.numero_rapport.startswith(prefix)).count()
    return f"{prefix}{count + 1:04d}"


def _to_response(db: Session, rapport: RapportVisite) -> RapportVisiteResponse:
    lignes_raw = rapport.get_lignes()
    lignes = [EtatLieuxLigne(**l) for l in lignes_raw]
    photos_raw = rapport.get_photos()
    photos = [RapportPhotoItem(**p) for p in photos_raw]
    return RapportVisiteResponse(
        id=rapport.id,
        numero_rapport=rapport.numero_rapport,
        date_visite=rapport.date_visite,
        client=rapport.client,
        correspondant_technique=rapport.correspondant_technique,
        type_prestation=rapport.type_prestation,
        type_batiment=rapport.type_batiment,
        note_nb=rapport.note_nb or "",
        nom_intervenant=rapport.nom_intervenant or "",
        lignes=lignes,
        photos=photos,
        created_by_id=rapport.created_by_id,
        created_by_name=_user_display(db, rapport.created_by_id),
        created_at=rapport.created_at,
        updated_at=rapport.updated_at,
    )


def _photo_abs_path(rel_path: str) -> str:
    return os.path.join("uploads", rel_path.replace("\\", "/"))


def _delete_photo_files(photos: list[dict]) -> None:
    for p in photos:
        path = p.get("path")
        if not path:
            continue
        full = path if os.path.isabs(path) else _photo_abs_path(path)
        if os.path.isfile(full):
            try:
                os.remove(full)
            except OSError:
                pass


@router.get("/", response_model=list[RapportVisiteResponse])
def list_rapports_visite(
    q: str | None = Query(None, max_length=120),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    query = db.query(RapportVisite)
    if current_user.role != UserRole.admin:
        query = query.filter(RapportVisite.created_by_id == current_user.id)

    if q and q.strip():
        term = f"%{q.strip()}%"
        query = query.filter(
            or_(
                RapportVisite.client.ilike(term),
                RapportVisite.correspondant_technique.ilike(term),
                RapportVisite.type_prestation.ilike(term),
                RapportVisite.type_batiment.ilike(term),
                RapportVisite.nom_intervenant.ilike(term),
                RapportVisite.numero_rapport.ilike(term),
                RapportVisite.note_nb.ilike(term),
                RapportVisite.lignes_json.ilike(term),
            )
        )

    items = query.order_by(RapportVisite.date_visite.desc()).limit(200).all()
    return [_to_response(db, r) for r in items]


@router.get("/{rapport_id}", response_model=RapportVisiteResponse)
def get_rapport_visite(
    rapport_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    rapport = db.query(RapportVisite).filter(RapportVisite.id == rapport_id).first()
    if not rapport:
        raise HTTPException(status_code=404, detail="Rapport introuvable")
    if not _can_view(rapport, current_user):
        raise HTTPException(status_code=403, detail="Accès refusé")
    return _to_response(db, rapport)


@router.post("/", response_model=RapportVisiteResponse, status_code=201)
def create_rapport_visite(
    data: RapportVisiteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_can_create_rapport(current_user)
    rapport = RapportVisite(
        numero_rapport=_generate_numero(db),
        date_visite=data.date_visite,
        client=data.client.strip(),
        correspondant_technique=data.correspondant_technique.strip(),
        type_prestation=data.type_prestation.strip(),
        type_batiment=data.type_batiment.strip(),
        note_nb=data.note_nb,
        nom_intervenant=data.nom_intervenant.strip(),
        created_by_id=current_user.id,
    )
    rapport.set_lignes([l.model_dump() for l in data.lignes])
    rapport.set_photos([])
    db.add(rapport)
    db.commit()
    db.refresh(rapport)
    os.makedirs(f"{UPLOAD_ROOT}/{rapport.id}", exist_ok=True)
    return _to_response(db, rapport)


@router.patch("/{rapport_id}", response_model=RapportVisiteResponse)
def update_rapport_visite(
    rapport_id: int,
    data: RapportVisiteUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    rapport = db.query(RapportVisite).filter(RapportVisite.id == rapport_id).first()
    if not rapport:
        raise HTTPException(status_code=404, detail="Rapport introuvable")
    if not _can_edit(rapport, current_user):
        raise HTTPException(status_code=403, detail="Modification non autorisée")

    payload = data.model_dump(exclude_unset=True)
    if "lignes" in payload:
        lignes_data = payload.pop("lignes")
        if lignes_data is not None:
            rapport.set_lignes(lignes_data)
    if "photos" in payload:
        photos_data = payload.pop("photos")
        if photos_data is not None:
            old_paths = {p.get("path") for p in rapport.get_photos()}
            new_photos = photos_data
            new_paths = {p["path"] for p in new_photos}
            for path in old_paths - new_paths:
                if path:
                    full = _photo_abs_path(path)
                    if os.path.isfile(full):
                        try:
                            os.remove(full)
                        except OSError:
                            pass
            rapport.set_photos(new_photos)

    for key, value in payload.items():
        if hasattr(rapport, key) and value is not None:
            setattr(rapport, key, value)

    rapport.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(rapport)
    return _to_response(db, rapport)


@router.post("/{rapport_id}/photos", response_model=RapportVisiteResponse)
async def upload_rapport_photo(
    rapport_id: int,
    file: UploadFile = File(...),
    legende: str = Form(default=""),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    rapport = db.query(RapportVisite).filter(RapportVisite.id == rapport_id).first()
    if not rapport:
        raise HTTPException(status_code=404, detail="Rapport introuvable")
    if not _can_edit(rapport, current_user):
        raise HTTPException(status_code=403, detail="Modification non autorisée")

    os.makedirs(f"{UPLOAD_ROOT}/{rapport.id}", exist_ok=True)
    photos = rapport.get_photos()

    if file.filename:
        ext = os.path.splitext(file.filename)[1].lower() or ".jpg"
        safe_name = f"{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{len(photos)}{ext}"
        rel_path = f"rapports/{rapport.id}/{safe_name}"
        dest = os.path.join("uploads", rel_path)
        with open(dest, "wb") as out:
            shutil.copyfileobj(file.file, out)
        photos.append({"path": rel_path, "legende": legende})

    rapport.set_photos(photos)
    rapport.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(rapport)
    return _to_response(db, rapport)


@router.delete("/{rapport_id}", status_code=204)
def delete_rapport_visite(
    rapport_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    rapport = db.query(RapportVisite).filter(RapportVisite.id == rapport_id).first()
    if not rapport:
        raise HTTPException(status_code=404, detail="Rapport introuvable")
    if not _can_edit(rapport, current_user):
        raise HTTPException(status_code=403, detail="Suppression non autorisée")

    _delete_photo_files(rapport.get_photos())
    folder = f"{UPLOAD_ROOT}/{rapport.id}"
    if os.path.isdir(folder):
        shutil.rmtree(folder, ignore_errors=True)

    db.delete(rapport)
    db.commit()
