from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.point_traitement import FichePointTraitement, LignePointTraitement
from app.models.user import User
from app.schemas.point_traitement import (
    FichePointTraitementCreate,
    FichePointTraitementListItem,
    FichePointTraitementResponse,
    FichePointTraitementUpdate,
)
from app.security import get_current_user, require_roles

router = APIRouter(prefix="/api/point-traitement", tags=["Point Traitement Demandes"])


def _count_filled_lignes(fiche: FichePointTraitement) -> int:
    count = 0
    for l in fiche.lignes:
        if any([l.client, l.ref_demande, l.resume_demande, l.ref_devis, l.montant_ht, l.statut]):
            count += 1
    return count


def _total_montant(fiche: FichePointTraitement) -> Decimal:
    total = Decimal("0")
    for l in fiche.lignes:
        if l.montant_ht is not None:
            total += l.montant_ht
    return total


def _to_list_item(fiche: FichePointTraitement) -> FichePointTraitementListItem:
    return FichePointTraitementListItem(
        id=fiche.id,
        semaine=fiche.semaine,
        date_debut=fiche.date_debut,
        date_fin=fiche.date_fin,
        responsable=fiche.responsable,
        created_at=fiche.created_at,
        nb_lignes_remplies=_count_filled_lignes(fiche),
        total_montant_ht=_total_montant(fiche) if _count_filled_lignes(fiche) > 0 else None,
    )


def _apply_lignes(fiche: FichePointTraitement, lignes_data):
    fiche.lignes.clear()
    for ligne in lignes_data:
        fiche.lignes.append(
            LignePointTraitement(
                numero=ligne.numero,
                date_demande=ligne.date_demande,
                client=ligne.client or "",
                ref_demande=ligne.ref_demande or "",
                resume_demande=ligne.resume_demande or "",
                ref_devis=ligne.ref_devis or "",
                montant_ht=ligne.montant_ht,
                statut=ligne.statut or "",
            )
        )


@router.get("/", response_model=list[FichePointTraitementListItem])
def list_fiches(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    fiches = db.query(FichePointTraitement).order_by(FichePointTraitement.created_at.desc()).all()
    return [_to_list_item(f) for f in fiches]


@router.post("/", response_model=FichePointTraitementResponse, status_code=201)
def create_fiche(
    data: FichePointTraitementCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    fiche = FichePointTraitement(
        semaine=data.semaine,
        date_debut=data.date_debut,
        date_fin=data.date_fin,
        responsable=data.responsable,
        signature_base64=data.signature_base64,
        created_by_id=current_user.id,
    )
    if data.lignes:
        _apply_lignes(fiche, data.lignes)
    else:
        for i in range(1, 11):
            fiche.lignes.append(LignePointTraitement(numero=i))
    db.add(fiche)
    db.commit()
    db.refresh(fiche)
    return fiche


@router.get("/{fiche_id}", response_model=FichePointTraitementResponse)
def get_fiche(
    fiche_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    fiche = db.query(FichePointTraitement).filter(FichePointTraitement.id == fiche_id).first()
    if not fiche:
        raise HTTPException(status_code=404, detail="Fiche introuvable")
    return fiche


@router.patch("/{fiche_id}", response_model=FichePointTraitementResponse)
def update_fiche(
    fiche_id: int,
    data: FichePointTraitementUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    fiche = db.query(FichePointTraitement).filter(FichePointTraitement.id == fiche_id).first()
    if not fiche:
        raise HTTPException(status_code=404, detail="Fiche introuvable")

    if data.semaine is not None:
        fiche.semaine = data.semaine
    if data.date_debut is not None:
        fiche.date_debut = data.date_debut
    if data.date_fin is not None:
        fiche.date_fin = data.date_fin
    if data.responsable is not None:
        fiche.responsable = data.responsable
    if data.signature_base64 is not None:
        fiche.signature_base64 = data.signature_base64
    if data.lignes is not None:
        _apply_lignes(fiche, data.lignes)

    db.commit()
    db.refresh(fiche)
    return fiche


@router.delete("/{fiche_id}", status_code=204)
def delete_fiche(
    fiche_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    fiche = db.query(FichePointTraitement).filter(FichePointTraitement.id == fiche_id).first()
    if not fiche:
        raise HTTPException(status_code=404, detail="Fiche introuvable")
    db.delete(fiche)
    db.commit()
