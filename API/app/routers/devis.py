from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import Response
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.devis_proforma import DevisProforma
from app.models.devis_share import DevisShare
from app.models.demande import Demande
from app.models.user import User
from app.schemas.devis import (
    CreateAffaireFromDevisRequest,
    DevisCreate,
    DevisRenderRequest,
    DevisResponse,
    DevisShareCreate,
    DevisShareResponse,
    DevisUpdate,
    EmailAnalyzeRequest,
    EmailAnalyzeResponse,
    EmailSummary,
    ProductSearchResponse,
    ProductSearchResult,
    ProduitLigne,
)
from app.schemas.affaire import AffaireResponse
from app.security import get_current_user, require_roles, user_has_permission
from app.services.devis_affaire_service import create_affaire_from_devis
from app.services.devis_calculator import compute_devis_totals, generate_numero_devis
from app.services.devis_excel_service import (
    build_devis_excel,
    build_devis_pdf,
    devis_model_to_render,
)
from app.services.devis_proforma_pdf import build_proforma_pdf
from app.services.email_service import EmailNotConfiguredError, fetch_email_by_id, fetch_recent_emails
from app.services.product_search_service import search_product_reference
from app.services.reference_extractor import extract_client_info, extract_references

router = APIRouter(prefix="/api/devis", tags=["Devis Proforma"])


def _user_display(user: User | None) -> str | None:
    if not user:
        return None
    return f"{user.prenom} {user.nom}".strip()


def _share_for_user(db: Session, devis_id: int, user_id: int) -> DevisShare | None:
    return (
        db.query(DevisShare)
        .filter(DevisShare.devis_id == devis_id, DevisShare.shared_with_id == user_id)
        .first()
    )


def _can_view_devis(db: Session, devis: DevisProforma, user: User) -> bool:
    if user.role == UserRole.admin:
        return True
    if devis.created_by_id == user.id:
        return True
    return _share_for_user(db, devis.id, user.id) is not None


def _can_edit_devis(db: Session, devis: DevisProforma, user: User) -> bool:
    if user.role == UserRole.admin:
        return True
    if devis.created_by_id == user.id:
        return True
    share = _share_for_user(db, devis.id, user.id)
    return share is not None and share.can_edit


def _require_view(db: Session, devis: DevisProforma, user: User) -> None:
    if not _can_view_devis(db, devis, user):
        raise HTTPException(status_code=403, detail="Accès refusé à ce devis")


def _require_edit(db: Session, devis: DevisProforma, user: User) -> None:
    if not _can_edit_devis(db, devis, user):
        raise HTTPException(status_code=403, detail="Modification non autorisée")


def _to_response(devis: DevisProforma, current_user: User, db: Session) -> DevisResponse:
    lignes_raw = devis.get_lignes()
    lignes = [ProduitLigne(**l) for l in lignes_raw]
    owner = db.query(User).filter(User.id == devis.created_by_id).first() if devis.created_by_id else None
    is_owner = devis.created_by_id == current_user.id
    share = None if is_owner or current_user.role == UserRole.admin else _share_for_user(db, devis.id, current_user.id)
    return DevisResponse(
        id=devis.id,
        numero_devis=devis.numero_devis,
        date_devis=devis.date_devis,
        contact=devis.contact,
        client_nom=devis.client_nom,
        client_numero_cc=devis.client_numero_cc,
        client_da=devis.client_da,
        affaire_suivie_par=devis.affaire_suivie_par,
        ref_demande=devis.ref_demande or devis.client_da,
        telephone=devis.telephone or devis.client_numero_cc,
        objet_demande=devis.objet_demande,
        remise_exceptionnelle_active=bool(devis.remise_exceptionnelle_active),
        remise_exceptionnelle_pct=float(devis.remise_exceptionnelle_pct or 10),
        acompte_pourcentage=devis.acompte_pourcentage,
        validite_offre=devis.validite_offre,
        delai_livraison=devis.delai_livraison,
        moyen_reglement=devis.moyen_reglement,
        libelle_cheque=devis.libelle_cheque,
        condition_reglement=getattr(devis, "condition_reglement", None) or "habituelles",
        lignes=lignes,
        total_ht_brut=devis.total_ht_brut,
        total_remise=devis.total_remise,
        total_ht_net=devis.total_ht_net,
        email_message_id=devis.email_message_id,
        email_subject=devis.email_subject,
        email_from=devis.email_from,
        demande_id=devis.demande_id,
        affaire_id=devis.affaire_id,
        created_by_id=devis.created_by_id,
        created_by_name=_user_display(owner),
        is_owner=is_owner,
        is_shared=share is not None,
        can_edit=_can_edit_devis(db, devis, current_user),
        created_at=devis.created_at,
    )


def _apply_devis_data(devis: DevisProforma, data: DevisCreate | DevisUpdate, lignes: list[ProduitLigne] | None = None) -> None:
    fields = data.model_dump(exclude_unset=True, exclude={"lignes", "numero_devis"})
    for key, value in fields.items():
        if hasattr(devis, key):
            setattr(devis, key, value)
    if getattr(data, "ref_demande", None) is not None:
        devis.client_da = data.ref_demande
    elif getattr(data, "client_da", None) is not None:
        devis.ref_demande = data.client_da
    if getattr(data, "telephone", None) is not None:
        devis.client_numero_cc = data.telephone
    elif getattr(data, "client_numero_cc", None) is not None:
        devis.telephone = data.client_numero_cc
    if lignes is not None:
        devis.set_lignes([l.model_dump() for l in lignes])
        brut, remise, net = compute_devis_totals(lignes)
        devis.total_ht_brut = brut
        devis.total_remise = remise
        devis.total_ht_net = net


def _require_can_create_devis(user: User) -> None:
    if user.role == UserRole.technicien and not user_has_permission(user, "can_create_devis"):
        raise HTTPException(
            status_code=403,
            detail="Vous n'avez pas l'autorisation de créer ou modifier des devis proforma",
        )


@router.get("/emails", response_model=list[EmailSummary])
def list_emails(
    limit: int = Query(20, ge=1, le=50),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    try:
        emails = fetch_recent_emails(limit=limit)
    except EmailNotConfiguredError:
        # IMAP non configuré — l'app utilise Gmail OAuth côté Flutter
        return []
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Erreur connexion email: {e}") from e

    return [
        EmailSummary(
            message_id=e["message_id"],
            subject=e["subject"],
            from_address=e["from_address"],
            from_name=e.get("from_name"),
            date=e["date"],
            preview=e["preview"],
            references=e.get("references", []),
        )
        for e in emails
    ]


@router.post("/emails/analyze", response_model=EmailAnalyzeResponse)
def analyze_email(
    data: EmailAnalyzeRequest,
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_can_create_devis(current_user)
    text = data.raw_text or ""
    subject = data.subject or ""
    from_address = data.from_address or ""

    if data.message_id:
        try:
            email_data = fetch_email_by_id(data.message_id)
        except EmailNotConfiguredError as e:
            raise HTTPException(status_code=503, detail=str(e)) from e
        except Exception as e:
            raise HTTPException(status_code=502, detail=f"Erreur email: {e}") from e
        if not email_data:
            raise HTTPException(status_code=404, detail="Email introuvable")
        text = email_data["body"]
        subject = email_data["subject"]
        from_address = email_data["from_address"]

    if not text.strip():
        raise HTTPException(status_code=400, detail="Contenu email vide")

    refs = extract_references(f"{subject}\n{text}")
    client_info = extract_client_info(text, subject, from_address)

    suggested: dict[str, str] = {}
    for ref in refs[:5]:
        search = search_product_reference(ref, max_results=1)
        if search.get("suggested_designation"):
            suggested[ref] = search["suggested_designation"]

    return EmailAnalyzeResponse(
        references=refs,
        client_nom=client_info.get("client_nom"),
        contact=client_info.get("contact"),
        client_da=client_info.get("client_da"),
        suggested_designations=suggested,
    )


@router.get("/search/{reference}", response_model=ProductSearchResponse)
def search_reference(
    reference: str,
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    data = search_product_reference(reference)
    return ProductSearchResponse(
        reference=data["reference"],
        search_url=data["search_url"],
        shopping_url=data.get("shopping_url", ""),
        suggested_designation=data.get("suggested_designation", ""),
        results=[ProductSearchResult(**r) for r in data["results"]],
    )


@router.get("/next-number")
def next_devis_number(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    count = db.query(DevisProforma).count()
    return {"numero_devis": generate_numero_devis(count)}


@router.get("/", response_model=list[DevisResponse])
def list_devis(
    q: str | None = Query(None, description="Recherche globale"),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    if current_user.role == UserRole.admin:
        query = db.query(DevisProforma)
    else:
        shared_ids = [
            s.devis_id
            for s in db.query(DevisShare).filter(DevisShare.shared_with_id == current_user.id).all()
        ]
        filters = [DevisProforma.created_by_id == current_user.id]
        if shared_ids:
            filters.append(DevisProforma.id.in_(shared_ids))
        query = db.query(DevisProforma).filter(or_(*filters))

    if q:
        search_filter = or_(
            DevisProforma.numero_devis.ilike(f"%{q}%"),
            DevisProforma.client_nom.ilike(f"%{q}%"),
            DevisProforma.contact.ilike(f"%{q}%"),
            DevisProforma.objet_demande.ilike(f"%{q}%"),
            DevisProforma.lignes_json.ilike(f"%{q}%"),
            DevisProforma.affaire_suivie_par.ilike(f"%{q}%"),
            DevisProforma.ref_demande.ilike(f"%{q}%"),
        )
        query = query.filter(search_filter)

    items = query.order_by(DevisProforma.created_at.desc()).all()
    return [_to_response(d, current_user, db) for d in items]


@router.post("/", response_model=DevisResponse, status_code=201)
def create_devis(
    data: DevisCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_can_create_devis(current_user)
    count = db.query(DevisProforma).count()
    numero = data.numero_devis or generate_numero_devis(count)

    if db.query(DevisProforma).filter(DevisProforma.numero_devis == numero).first():
        raise HTTPException(status_code=400, detail="Numéro de devis déjà utilisé")

    devis = DevisProforma(
        numero_devis=numero,
        created_by_id=current_user.id,
        email_message_id=data.email_message_id,
        email_subject=data.email_subject,
        email_from=data.email_from,
        demande_id=data.demande_id,
    )
    _apply_devis_data(devis, data, data.lignes)
    db.add(devis)

    if data.demande_id:
        demande = db.query(Demande).filter(Demande.id == data.demande_id).first()
        if demande:
            demande.devis_montant = devis.total_ht_net
            demande.statut = "devis_propose"

    db.commit()
    db.refresh(devis)
    return _to_response(devis, current_user, db)


@router.get("/{devis_id}", response_model=DevisResponse)
def get_devis(
    devis_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    devis = db.query(DevisProforma).filter(DevisProforma.id == devis_id).first()
    if not devis:
        raise HTTPException(status_code=404, detail="Devis introuvable")
    _require_view(db, devis, current_user)
    return _to_response(devis, current_user, db)


@router.patch("/{devis_id}", response_model=DevisResponse)
def update_devis(
    devis_id: int,
    data: DevisUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    devis = db.query(DevisProforma).filter(DevisProforma.id == devis_id).first()
    if not devis:
        raise HTTPException(status_code=404, detail="Devis introuvable")
    _require_edit(db, devis, current_user)
    _require_can_create_devis(current_user)

    lignes = data.lignes
    _apply_devis_data(devis, data, lignes)

    if data.demande_id:
        demande = db.query(Demande).filter(Demande.id == data.demande_id).first()
        if demande:
            demande.devis_montant = devis.total_ht_net
            demande.statut = "devis_propose"

    db.commit()
    db.refresh(devis)
    return _to_response(devis, current_user, db)


@router.delete("/{devis_id}", status_code=204)
def delete_devis(
    devis_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    devis = db.query(DevisProforma).filter(DevisProforma.id == devis_id).first()
    if not devis:
        raise HTTPException(status_code=404, detail="Devis introuvable")
    if current_user.role != UserRole.admin and devis.created_by_id != current_user.id:
        raise HTTPException(status_code=403, detail="Seul l'admin ou le créateur peut supprimer ce devis")
    if devis.affaire_id:
        raise HTTPException(status_code=400, detail="Impossible de supprimer un devis lié à une affaire")
    db.query(DevisShare).filter(DevisShare.devis_id == devis_id).delete()
    db.delete(devis)
    db.commit()
    return Response(status_code=204)


@router.get("/{devis_id}/shares", response_model=list[DevisShareResponse])
def list_devis_shares(
    devis_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    devis = db.query(DevisProforma).filter(DevisProforma.id == devis_id).first()
    if not devis:
        raise HTTPException(status_code=404, detail="Devis introuvable")
    if current_user.role != UserRole.admin and devis.created_by_id != current_user.id:
        raise HTTPException(status_code=403, detail="Seul le propriétaire peut voir les partages")
    shares = db.query(DevisShare).filter(DevisShare.devis_id == devis_id).all()
    result = []
    for s in shares:
        u = db.query(User).filter(User.id == s.shared_with_id).first()
        result.append(
            DevisShareResponse(
                id=s.id,
                devis_id=s.devis_id,
                shared_with_id=s.shared_with_id,
                shared_with_name=_user_display(u) or "",
                shared_with_email=u.email if u else "",
                can_edit=s.can_edit,
                created_at=s.created_at,
            )
        )
    return result


@router.post("/{devis_id}/share", response_model=DevisShareResponse, status_code=201)
def share_devis(
    devis_id: int,
    data: DevisShareCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    devis = db.query(DevisProforma).filter(DevisProforma.id == devis_id).first()
    if not devis:
        raise HTTPException(status_code=404, detail="Devis introuvable")
    if current_user.role != UserRole.admin and devis.created_by_id != current_user.id:
        raise HTTPException(status_code=403, detail="Seul le propriétaire peut partager ce devis")
    target = db.query(User).filter(User.id == data.user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")
    if target.role == UserRole.client:
        raise HTTPException(status_code=400, detail="Impossible de partager avec un client")
    if data.user_id == devis.created_by_id:
        raise HTTPException(status_code=400, detail="Le devis appartient déjà à cet utilisateur")
    existing = _share_for_user(db, devis_id, data.user_id)
    if existing:
        existing.can_edit = data.can_edit
        db.commit()
        db.refresh(existing)
        share = existing
    else:
        share = DevisShare(
            devis_id=devis_id,
            shared_by_id=current_user.id,
            shared_with_id=data.user_id,
            can_edit=data.can_edit,
        )
        db.add(share)
        db.commit()
        db.refresh(share)
    return DevisShareResponse(
        id=share.id,
        devis_id=share.devis_id,
        shared_with_id=share.shared_with_id,
        shared_with_name=_user_display(target) or "",
        shared_with_email=target.email,
        can_edit=share.can_edit,
        created_at=share.created_at,
    )


@router.delete("/{devis_id}/share/{user_id}", status_code=204)
def unshare_devis(
    devis_id: int,
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    devis = db.query(DevisProforma).filter(DevisProforma.id == devis_id).first()
    if not devis:
        raise HTTPException(status_code=404, detail="Devis introuvable")
    if current_user.role != UserRole.admin and devis.created_by_id != current_user.id:
        raise HTTPException(status_code=403, detail="Seul le propriétaire peut retirer un partage")
    share = _share_for_user(db, devis_id, user_id)
    if not share:
        raise HTTPException(status_code=404, detail="Partage introuvable")
    db.delete(share)
    db.commit()
    return Response(status_code=204)


@router.post("/{devis_id}/create-affaire", response_model=AffaireResponse, status_code=201)
def create_affaire_from_devis_endpoint(
    devis_id: int,
    data: CreateAffaireFromDevisRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    if current_user.role == UserRole.technicien and not user_has_permission(current_user, "can_create_affaire"):
        raise HTTPException(status_code=403, detail="Vous n'avez pas l'autorisation de créer des dossiers d'affaire")

    devis = db.query(DevisProforma).filter(DevisProforma.id == devis_id).first()
    if not devis:
        raise HTTPException(status_code=404, detail="Devis introuvable")

    try:
        affaire = create_affaire_from_devis(
            db,
            devis,
            current_user,
            numero_affaire=data.numero_affaire,
            domaine=data.domaine,
            type_affaire=data.type_affaire,
            creer_etapes_standard=data.creer_etapes_standard,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e)) from e

    from app.services.affaire_service import get_affaire
    return get_affaire(db, affaire.id)


@router.post("/render-excel")
def render_devis_excel(
    data: DevisRenderRequest,
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_can_create_devis(current_user)
    """Génère le devis au format Excel (modèle ISITEK az.jpeg)."""
    try:
        excel_bytes = build_devis_excel(data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur génération Excel: {e}") from e
    filename = f"ISITEK_Proforma_{data.numero_devis or 'draft'}.xlsx"
    return Response(
        content=excel_bytes,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.post("/render-pdf")
def render_devis_pdf(
    data: DevisRenderRequest,
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    _require_can_create_devis(current_user)
    """Génère le PDF via Excel (mise en page identique au modèle DEVIS EXCELL 2026)."""
    try:
        pdf_bytes = build_devis_pdf(data)
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e)) from e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur génération PDF: {e}") from e
    filename = f"ISITEK_Proforma_{data.numero_devis or 'draft'}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/{devis_id}/pdf")
def download_devis_pdf(
    devis_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    devis = db.query(DevisProforma).filter(DevisProforma.id == devis_id).first()
    if not devis:
        raise HTTPException(status_code=404, detail="Devis introuvable")
    _require_view(db, devis, current_user)

    try:
        pdf_bytes = build_devis_pdf(devis_model_to_render(devis))
    except RuntimeError:
        pdf_bytes = build_proforma_pdf(devis)
    filename = f"devis_{devis.numero_devis}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
