from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
import os
import uuid
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.demande import Demande
from app.models.message import Message
from app.models.user import User
from app.schemas.demande import DemandeCreate, DemandeUpdate, DemandeResponse
from app.security import get_current_user, require_roles
from app.enums import UserRole
from app.services.demande_workflow import (
    build_resume,
    encode_skipped,
    next_status,
    parse_skipped,
    step_for_status,
)

router = APIRouter(prefix="/api/demandes", tags=["Demandes"])

@router.post("/upload")
def upload_demande_image(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user)
):
    try:
        os.makedirs("uploads", exist_ok=True)
        ext = file.filename.split(".")[-1]
        filename = f"{uuid.uuid4()}.{ext}"
        filepath = os.path.join("uploads", filename)
        
        with open(filepath, "wb") as buffer:
            buffer.write(file.file.read())
            
        return {"url": f"/uploads/{filename}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur d'upload : {e}")

@router.post("/", response_model=DemandeResponse, status_code=201)
def create_client_demande(
    data: DemandeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    demande = Demande(
        client_id=current_user.id,
        domaine=data.domaine,
        type_prestation=data.type_prestation,
        description=data.description,
        adresse=data.adresse,
        photos=data.photos,
        latitude=data.latitude,
        longitude=data.longitude,
        statut="recue"
    )
    db.add(demande)
    db.commit()
    db.refresh(demande)
    return demande

@router.get("/", response_model=list[DemandeResponse])
def get_client_demandes(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role == UserRole.client:
        return db.query(Demande).filter(Demande.client_id == current_user.id).order_by(Demande.created_at.desc()).all()
    # Admins or techniciens can view all demands
    return db.query(Demande).order_by(Demande.created_at.desc()).all()

@router.get("/{id}", response_model=DemandeResponse)
def get_demande_by_id(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    demande = db.query(Demande).filter(Demande.id == id).first()
    if not demande:
        raise HTTPException(status_code=404, detail="Demande introuvable")
    
    if current_user.role == UserRole.client and demande.client_id != current_user.id:
        raise HTTPException(status_code=403, detail="Accès non autorisé")
    
    return demande

@router.patch("/{id}", response_model=DemandeResponse)
def update_client_demande(
    id: int,
    data: DemandeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    demande = db.query(Demande).filter(Demande.id == id).first()
    if not demande:
        raise HTTPException(status_code=404, detail="Demande introuvable")
    
    # Check permissions
    if current_user.role == UserRole.client and demande.client_id != current_user.id:
        raise HTTPException(status_code=403, detail="Accès non autorisé")

    update_data = data.model_dump(exclude_unset=True)
    
    # Clients can only update rating/avis and statut for accept/refuse/payment
    if current_user.role == UserRole.client:
        allowed_keys = {"rating", "avis", "statut"}
        for key in list(update_data.keys()):
            if key not in allowed_keys:
                del update_data[key]

        if "statut" in update_data and update_data["statut"] not in (
            "reception_bc",
            "travaux_planifies",
            "reglement_cheque",
            "annule",
        ):
            raise HTTPException(status_code=400, detail="Action non autorisée sur ce statut")

        if "statut" in update_data and update_data["statut"] in ("travaux_planifies",):
            update_data["statut"] = "reception_bc"

        if "rating" in update_data:
            update_data["statut"] = "termine"

    for key, value in update_data.items():
        setattr(demande, key, value)

    db.commit()
    db.refresh(demande)
    return demande


@router.post("/{id}/avancer")
def avancer_demande(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin)),
):
    demande = db.query(Demande).filter(Demande.id == id).first()
    if not demande:
        raise HTTPException(status_code=404, detail="Demande introuvable")

    skipped = parse_skipped(demande.etapes_sautees)
    nxt = next_status(demande.statut, skipped)
    if not nxt:
        raise HTTPException(status_code=400, detail="Aucune étape suivante")

    demande.statut = nxt
    db.commit()
    db.refresh(demande)
    return demande


@router.post("/{id}/sauter-etape")
def sauter_etape_demande(
    id: int,
    data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin)),
):
    demande = db.query(Demande).filter(Demande.id == id).first()
    if not demande:
        raise HTTPException(status_code=404, detail="Demande introuvable")

    step = data.get("etape")
    if not step or not isinstance(step, int):
        raise HTTPException(status_code=400, detail="Numéro d'étape requis")

    skipped = parse_skipped(demande.etapes_sautees)
    skipped.add(step)
    demande.etapes_sautees = encode_skipped(skipped)

    if step_for_status(demande.statut) == step:
        nxt = next_status(demande.statut, skipped)
        if nxt:
            demande.statut = nxt

    db.commit()
    db.refresh(demande)
    return demande


@router.post("/{id}/ajouter-etape")
def ajouter_etape_custom(
    id: int,
    data: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin)),
):
    import json

    demande = db.query(Demande).filter(Demande.id == id).first()
    if not demande:
        raise HTTPException(status_code=404, detail="Demande introuvable")

    label = data.get("label", "").strip()
    actor = data.get("actor", "Isitek").strip()
    after_step = data.get("after_step", 1)
    if not label:
        raise HTTPException(status_code=400, detail="Libellé requis")

    custom = []
    if demande.etapes_custom:
        try:
            custom = json.loads(demande.etapes_custom)
        except json.JSONDecodeError:
            custom = []

    custom.append({"label": label, "actor": actor, "after_step": after_step})
    demande.etapes_custom = json.dumps(custom, ensure_ascii=False)
    db.commit()
    db.refresh(demande)
    return demande


@router.post("/{id}/envoyer-resume-chat")
def envoyer_resume_chat(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin)),
):
    demande = db.query(Demande).filter(Demande.id == id).first()
    if not demande:
        raise HTTPException(status_code=404, detail="Demande introuvable")

    if step_for_status(demande.statut) < 3:
        raise HTTPException(status_code=400, detail="Résumé disponible à partir de l'étape 3")

    msg = Message(
        client_id=demande.client_id,
        sender_role="support",
        content=build_resume(demande),
    )
    db.add(msg)
    db.commit()
    return {"message": "Résumé envoyé au chat"}


@router.post("/{id}/generer-facture")
def generer_facture_chat(
    id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin)),
):
    demande = db.query(Demande).filter(Demande.id == id).first()
    if not demande:
        raise HTTPException(status_code=404, detail="Demande introuvable")

    if step_for_status(demande.statut) < 8:
        raise HTTPException(status_code=400, detail="Facture disponible à partir de l'étape Facturation")

    montant = demande.devis_montant or 0
    content = (
        f"🧾 Facture ISITEK — Demande #{demande.id}\n"
        f"• Client : demande {demande.type_prestation} ({demande.domaine})\n"
        f"• Montant TTC : {montant:,} FCFA\n"
        f"• Adresse : {demande.adresse}\n"
        f"La facture détaillée est disponible dans l'onglet Demandes."
    ).replace(",", " ")

    msg = Message(
        client_id=demande.client_id,
        sender_role="support",
        content=content,
    )
    db.add(msg)
    db.commit()
    return {"message": "Facture envoyée au chat"}


@router.get("/satisfactions/list")
def list_satisfactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin)),
):
    demandes = (
        db.query(Demande)
        .filter(Demande.rating.isnot(None))
        .order_by(Demande.created_at.desc())
        .all()
    )
    result = []
    for d in demandes:
        client = db.query(User).filter(User.id == d.client_id).first()
        result.append({
            "demande_id": d.id,
            "domaine": d.domaine,
            "type_prestation": d.type_prestation,
            "rating": d.rating,
            "avis": d.avis,
            "client_nom": f"{client.prenom} {client.nom}" if client else "Client",
            "client_email": client.email if client else "",
            "created_at": d.created_at,
        })
    return result
