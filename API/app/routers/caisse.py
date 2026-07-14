import re
from datetime import datetime
from decimal import Decimal, InvalidOperation

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_, cast, String
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.enums import UserRole
from app.models.caisse import FicheControleCaisse, LivreCaisseHebdo, LigneLivreCaisse
from app.models.user import User
from app.schemas.caisse import (
    CaisseSearchControleHit,
    CaisseSearchLivreHit,
    CaisseSearchResponse,
    FicheControleCaisseCreate,
    FicheControleCaisseResponse,
    FicheControleCaisseUpdate,
    FicheControlePageResponse,
    LivreCaisseHebdoCreate,
    LivreCaisseHebdoResponse,
    LivreCaisseHebdoUpdate,
    LigneLivreCaisseSchema,
)
from app.security import require_roles, user_has_permission

router = APIRouter(prefix="/api/caisse", tags=["Caisse"])


def _has_caisse_any(user: User) -> bool:
    return user_has_permission(user, "can_access_caisse") or user_has_permission(user, "can_caisse_controle") or user_has_permission(user, "can_caisse_livre")


def _require_caisse(user: User) -> None:
    if user.role == UserRole.admin or _has_caisse_any(user):
        return
    raise HTTPException(status_code=403, detail="Accès module Caisse non autorisé")


def _require_controle(user: User) -> None:
    if user.role == UserRole.admin:
        return
    if user_has_permission(user, "can_access_caisse") or user_has_permission(user, "can_caisse_controle"):
        return
    raise HTTPException(status_code=403, detail="Accès fiche contrôle caisse non autorisé")


def _require_livre(user: User) -> None:
    if user.role == UserRole.admin:
        return
    if user_has_permission(user, "can_access_caisse") or user_has_permission(user, "can_caisse_livre"):
        return
    raise HTTPException(status_code=403, detail="Accès livre de caisse non autorisé")


def _assign_page_slot(db: Session, sections_par_page: int) -> tuple[int, int]:
    if sections_par_page == 1:
        max_page = db.query(func.max(FicheControleCaisse.page_id)).scalar() or 0
        return int(max_page) + 1, 1

    pages_with_slot2 = {
        r[0]
        for r in db.query(FicheControleCaisse.page_id)
        .filter(FicheControleCaisse.slot == 2, FicheControleCaisse.page_id.isnot(None))
        .distinct()
        .all()
    }
    open_fiche = (
        db.query(FicheControleCaisse)
        .filter(
            FicheControleCaisse.slot == 1,
            FicheControleCaisse.sections_par_page == 2,
            FicheControleCaisse.page_id.isnot(None),
        )
        .order_by(FicheControleCaisse.created_at.desc())
        .all()
    )
    for f in open_fiche:
        if f.page_id not in pages_with_slot2:
            return f.page_id, 2

    max_page = db.query(func.max(FicheControleCaisse.page_id)).scalar() or 0
    return int(max_page) + 1, 1


def _infer_annee(data: dict) -> int | None:
    if data.get("annee"):
        return data["annee"]
    for key in ("date_debut", "periode_debut", "montant_caisse_date"):
        d = data.get(key)
        if d:
            return d.year if hasattr(d, "year") else None
    return datetime.utcnow().year


def _parse_amount_query(q: str) -> Decimal | None:
    cleaned = q.strip().replace(" ", "").replace(",", ".")
    cleaned = re.sub(r"[^\d.\-]", "", cleaned)
    if not cleaned or cleaned in (".", "-", "-."):
        return None
    try:
        return Decimal(cleaned)
    except InvalidOperation:
        return None


def _apply_lignes_livre(livre: LivreCaisseHebdo, lignes_data: list[LigneLivreCaisseSchema]):
    livre.lignes.clear()
    running = livre.montant_caisse_valeur or Decimal("0")
    for ligne in lignes_data:
        entree = ligne.entree or Decimal("0")
        sortie = ligne.sortie or Decimal("0")
        if ligne.solde is not None:
            solde = ligne.solde
            running = solde
        elif entree or sortie:
            running = running + entree - sortie
            solde = running
        else:
            solde = ligne.solde
        livre.lignes.append(
            LigneLivreCaisse(
                numero=ligne.numero,
                date_operation=ligne.date_operation,
                numero_piece=ligne.numero_piece or "",
                nom_prenoms=ligne.nom_prenoms or "",
                detail_operation=ligne.detail_operation or "",
                entree=ligne.entree,
                sortie=ligne.sortie,
                solde=solde,
                signature_beneficiaire=ligne.signature_beneficiaire or "",
            )
        )


# ── Fiche contrôle caisse ─────────────────────────────────────────────────────

@router.get("/controle/", response_model=list[FicheControleCaisseResponse])
def list_fiches_controle(
    q: str | None = Query(None, max_length=120),
    annee: int | None = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_controle(current_user)
    query = db.query(FicheControleCaisse)
    if annee:
        query = query.filter(FicheControleCaisse.annee == annee)
    if q and q.strip():
        term = f"%{q.strip()}%"
        amount = _parse_amount_query(q)
        filters = [
            FicheControleCaisse.observations.ilike(term),
            FicheControleCaisse.sig_rep_operations.ilike(term),
            FicheControleCaisse.sig_comptable.ilike(term),
            FicheControleCaisse.sig_direction.ilike(term),
            cast(FicheControleCaisse.semaine, String).ilike(term),
            cast(FicheControleCaisse.annee, String).ilike(term),
        ]
        if amount is not None:
            filters.extend([
                FicheControleCaisse.solde_theorique == amount,
                FicheControleCaisse.solde_reel == amount,
                FicheControleCaisse.ecart_avt == amount,
                FicheControleCaisse.ecart_apt == amount,
            ])
        query = query.filter(or_(*filters))
    return query.order_by(FicheControleCaisse.created_at.desc()).limit(200).all()


@router.post("/controle/", response_model=FicheControleCaisseResponse, status_code=201)
def create_fiche_controle(
    data: FicheControleCaisseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_controle(current_user)
    payload = data.model_dump()
    sections = payload.get("sections_par_page") or 2
    page_id, slot = _assign_page_slot(db, sections)
    payload["page_id"] = page_id
    payload["slot"] = slot
    payload["sections_par_page"] = sections
    if payload.get("ecart_avt") is None and payload.get("solde_theorique") is not None and payload.get("solde_reel") is not None:
        payload["ecart_avt"] = payload["solde_reel"] - payload["solde_theorique"]
    payload["annee"] = _infer_annee(payload)
    payload["created_by_id"] = current_user.id
    fiche = FicheControleCaisse(**payload)
    db.add(fiche)
    db.commit()
    db.refresh(fiche)
    return fiche


@router.get("/controle/page/{page_id}", response_model=FicheControlePageResponse)
def get_fiche_controle_page(
    page_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_controle(current_user)
    fiches = (
        db.query(FicheControleCaisse)
        .filter(FicheControleCaisse.page_id == page_id)
        .order_by(FicheControleCaisse.slot.asc())
        .all()
    )
    if not fiches:
        raise HTTPException(status_code=404, detail="Page introuvable")
    f1 = next((f for f in fiches if f.slot == 1), None)
    f2 = next((f for f in fiches if f.slot == 2), None)
    sections = f1.sections_par_page if f1 else (f2.sections_par_page if f2 else 2)
    return FicheControlePageResponse(
        page_id=page_id,
        sections_par_page=sections,
        fiche_slot_1=f1,
        fiche_slot_2=f2,
    )


@router.get("/controle/{fiche_id}", response_model=FicheControleCaisseResponse)
def get_fiche_controle(
    fiche_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_controle(current_user)
    fiche = db.query(FicheControleCaisse).filter(FicheControleCaisse.id == fiche_id).first()
    if not fiche:
        raise HTTPException(status_code=404, detail="Fiche introuvable")
    return fiche


@router.patch("/controle/{fiche_id}", response_model=FicheControleCaisseResponse)
def update_fiche_controle(
    fiche_id: int,
    data: FicheControleCaisseUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_controle(current_user)
    fiche = db.query(FicheControleCaisse).filter(FicheControleCaisse.id == fiche_id).first()
    if not fiche:
        raise HTTPException(status_code=404, detail="Fiche introuvable")
    payload = data.model_dump(exclude_unset=True)
    if "date_debut" in payload and "annee" not in payload:
        payload["annee"] = _infer_annee({**payload, "annee": fiche.annee})
    for k, v in payload.items():
        setattr(fiche, k, v)
    if "ecart_avt" not in payload and fiche.solde_theorique is not None and fiche.solde_reel is not None:
        fiche.ecart_avt = fiche.solde_reel - fiche.solde_theorique
    fiche.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(fiche)
    return fiche


@router.delete("/controle/{fiche_id}", status_code=204)
def delete_fiche_controle(
    fiche_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_controle(current_user)
    fiche = db.query(FicheControleCaisse).filter(FicheControleCaisse.id == fiche_id).first()
    if not fiche:
        raise HTTPException(status_code=404, detail="Fiche introuvable")
    db.delete(fiche)
    db.commit()


# ── Livre caisse hebdomadaire ─────────────────────────────────────────────────

@router.get("/livre/", response_model=list[LivreCaisseHebdoResponse])
def list_livres_caisse(
    q: str | None = Query(None, max_length=120),
    annee: int | None = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_livre(current_user)
    query = db.query(LivreCaisseHebdo).options(joinedload(LivreCaisseHebdo.lignes))
    if annee:
        query = query.filter(LivreCaisseHebdo.annee == annee)
    if q and q.strip():
        term = f"%{q.strip()}%"
        amount = _parse_amount_query(q)
        subq = db.query(LigneLivreCaisse.livre_id).filter(
            or_(
                LigneLivreCaisse.nom_prenoms.ilike(term),
                LigneLivreCaisse.detail_operation.ilike(term),
                LigneLivreCaisse.numero_piece.ilike(term),
            )
        )
        if amount is not None:
            subq = subq.union(
                db.query(LigneLivreCaisse.livre_id).filter(
                    or_(
                        LigneLivreCaisse.solde == amount,
                        LigneLivreCaisse.entree == amount,
                        LigneLivreCaisse.sortie == amount,
                    )
                )
            )
        ids = [r[0] for r in subq.distinct().all()]
        filters = [
            cast(LivreCaisseHebdo.annee, String).ilike(term),
            cast(LivreCaisseHebdo.semaine, String).ilike(term),
        ]
        if ids:
            filters.append(LivreCaisseHebdo.id.in_(ids))
        query = query.filter(or_(*filters))
    livres = query.order_by(LivreCaisseHebdo.created_at.desc()).limit(200).all()
    return livres


@router.post("/livre/", response_model=LivreCaisseHebdoResponse, status_code=201)
def create_livre_caisse(
    data: LivreCaisseHebdoCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_livre(current_user)
    payload = data.model_dump(exclude={"lignes"})
    payload["annee"] = _infer_annee(payload)
    payload["created_by_id"] = current_user.id
    livre = LivreCaisseHebdo(**payload)
    if data.lignes:
        _apply_lignes_livre(livre, data.lignes)
    db.add(livre)
    db.commit()
    db.refresh(livre)
    return livre


@router.get("/livre/{livre_id}", response_model=LivreCaisseHebdoResponse)
def get_livre_caisse(
    livre_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_livre(current_user)
    livre = (
        db.query(LivreCaisseHebdo)
        .options(joinedload(LivreCaisseHebdo.lignes))
        .filter(LivreCaisseHebdo.id == livre_id)
        .first()
    )
    if not livre:
        raise HTTPException(status_code=404, detail="Livre introuvable")
    return livre


@router.patch("/livre/{livre_id}", response_model=LivreCaisseHebdoResponse)
def update_livre_caisse(
    livre_id: int,
    data: LivreCaisseHebdoUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_livre(current_user)
    livre = (
        db.query(LivreCaisseHebdo)
        .options(joinedload(LivreCaisseHebdo.lignes))
        .filter(LivreCaisseHebdo.id == livre_id)
        .first()
    )
    if not livre:
        raise HTTPException(status_code=404, detail="Livre introuvable")
    payload = data.model_dump(exclude_unset=True)
    lignes_data = payload.pop("lignes", None)
    if "periode_debut" in payload and "annee" not in payload:
        payload["annee"] = _infer_annee({**payload, "annee": livre.annee})
    for k, v in payload.items():
        setattr(livre, k, v)
    if lignes_data is not None:
        _apply_lignes_livre(livre, [LigneLivreCaisseSchema(**l) for l in lignes_data])
    livre.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(livre)
    return livre


@router.delete("/livre/{livre_id}", status_code=204)
def delete_livre_caisse(
    livre_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_livre(current_user)
    livre = db.query(LivreCaisseHebdo).filter(LivreCaisseHebdo.id == livre_id).first()
    if not livre:
        raise HTTPException(status_code=404, detail="Livre introuvable")
    db.delete(livre)
    db.commit()


# ── Recherche globale caisse ──────────────────────────────────────────────────

@router.get("/search", response_model=CaisseSearchResponse)
def search_caisse(
    q: str = Query(..., min_length=1, max_length=120),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_caisse(current_user)
    term = q.strip()
    like = f"%{term}%"
    amount = _parse_amount_query(term)
    year = None
    if term.isdigit() and len(term) == 4:
        year = int(term)

    fiches_q = db.query(FicheControleCaisse)
    if year:
        fiches_q = fiches_q.filter(FicheControleCaisse.annee == year)
    else:
        filters = [
            FicheControleCaisse.observations.ilike(like),
            cast(FicheControleCaisse.annee, String).ilike(like),
        ]
        if amount is not None:
            filters.extend([
                FicheControleCaisse.solde_theorique == amount,
                FicheControleCaisse.solde_reel == amount,
                FicheControleCaisse.ecart_avt == amount,
                FicheControleCaisse.ecart_apt == amount,
            ])
        fiches_q = fiches_q.filter(or_(*filters))
    fiches = fiches_q.order_by(FicheControleCaisse.date_debut.desc()).limit(50).all()

    lignes_q = db.query(LigneLivreCaisse).join(LivreCaisseHebdo)
    if year:
        lignes_q = lignes_q.filter(LivreCaisseHebdo.annee == year)
    else:
        filters = [
            LigneLivreCaisse.nom_prenoms.ilike(like),
            LigneLivreCaisse.detail_operation.ilike(like),
            LigneLivreCaisse.numero_piece.ilike(like),
            cast(LivreCaisseHebdo.annee, String).ilike(like),
        ]
        if amount is not None:
            filters.extend([
                LigneLivreCaisse.solde == amount,
                LigneLivreCaisse.entree == amount,
                LigneLivreCaisse.sortie == amount,
            ])
        lignes_q = lignes_q.filter(or_(*filters))
    lignes = lignes_q.limit(80).all()

    return CaisseSearchResponse(
        fiches_controle=[
            CaisseSearchControleHit(
                id=f.id,
                annee=f.annee,
                semaine=f.semaine,
                date_debut=f.date_debut,
                date_fin=f.date_fin,
                solde_theorique=f.solde_theorique,
                solde_reel=f.solde_reel,
                ecart_avt=f.ecart_avt,
                ecart_apt=f.ecart_apt,
            )
            for f in fiches
        ],
        livre_lignes=[
            CaisseSearchLivreHit(
                livre_id=l.livre_id,
                ligne_id=l.id,
                annee=l.livre.annee,
                semaine=l.livre.semaine,
                nom_prenoms=l.nom_prenoms,
                detail_operation=l.detail_operation,
                solde=l.solde,
                entree=l.entree,
                sortie=l.sortie,
                date_operation=l.date_operation,
                numero_piece=l.numero_piece,
            )
            for l in lignes
        ],
    )
