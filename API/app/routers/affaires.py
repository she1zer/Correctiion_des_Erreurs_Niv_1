from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.affaire import Affaire, AffaireAction
from app.models.banque import Banque
from app.models.user import User
from app.schemas.affaire import (
    AffaireActionCreate,
    AffaireActionResponse,
    AffaireActionUpdate,
    AffaireCreate,
    AffaireListItem,
    AffaireResponse,
    AffaireUpdate,
    BanqueCreate,
    BanqueResponse,
)
from app.security import require_roles, get_current_user, user_has_permission
from app.services.affaire_service import create_affaire, get_affaire, list_affaires

router = APIRouter(prefix="/api/affaires", tags=["Affaires"])


@router.get("/", response_model=list[AffaireListItem])
def get_affaires(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role == UserRole.client:
        return db.query(Affaire).filter(Affaire.correspondant_email == current_user.email).order_by(Affaire.created_at.desc()).all()
    return list_affaires(db, skip, limit)


@router.get("/next-number")
def next_affaire_number(
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    from app.services.devis_affaire_service import generate_numero_affaire
    return {"numero_affaire": generate_numero_affaire(db)}


@router.post("/", response_model=AffaireResponse, status_code=201)
def post_affaire(
    data: AffaireCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role == UserRole.client:
        raise HTTPException(status_code=403, detail="Accès non autorisé")
    if current_user.role == UserRole.technicien and not user_has_permission(current_user, "can_create_affaire"):
        raise HTTPException(status_code=403, detail="Vous n'avez pas l'autorisation de créer des dossiers d'affaire")
    existing = db.query(Affaire).filter(Affaire.numero_affaire == data.numero_affaire.upper()).first()
    if existing:
        raise HTTPException(status_code=400, detail="Ce numéro d'affaire existe déjà")
    return create_affaire(db, data)


@router.get("/{affaire_id}")
def get_affaire_detail(
    affaire_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    affaire = get_affaire(db, affaire_id)
    if not affaire:
        raise HTTPException(status_code=404, detail="Affaire introuvable")
    if current_user.role == UserRole.client:
        if affaire.correspondant_email != current_user.email:
            raise HTTPException(status_code=403, detail="Accès non autorisé à cette affaire")
        # Filter out skipped actions for client
        actions_filtered = [a for a in affaire.actions if not a.est_saute]
        return {
            "id": affaire.id,
            "numero_affaire": affaire.numero_affaire,
            "responsable_nom": affaire.responsable_nom,
            "responsable_prenom": affaire.responsable_prenom,
            "responsable_role": affaire.responsable_role,
            "date_ouverture": affaire.date_ouverture,
            "client_nom": affaire.client_nom,
            "numero_commande": affaire.numero_commande,
            "libelle_affaire": affaire.libelle_affaire,
            "domaine": affaire.domaine,
            "type_affaire": affaire.type_affaire,
            "montant_affaire": affaire.montant_affaire,
            "date_livraison_bc": affaire.date_livraison_bc,
            "correspondant_nom": affaire.correspondant_nom,
            "correspondant_telephone": affaire.correspondant_telephone,
            "correspondant_email": affaire.correspondant_email,
            "statut": affaire.statut,
            "demande_id": affaire.demande_id,
            "satisfaction_etoiles": affaire.satisfaction_etoiles,
            "satisfaction_commentaire": affaire.satisfaction_commentaire,
            "created_at": affaire.created_at,
            "updated_at": affaire.updated_at,
            "actions": actions_filtered
        }
    return affaire


@router.patch("/{affaire_id}", response_model=AffaireResponse)
def patch_affaire(
    affaire_id: int,
    data: AffaireUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    affaire = get_affaire(db, affaire_id)
    if not affaire:
        raise HTTPException(status_code=404, detail="Affaire introuvable")
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(affaire, key, value)
    db.commit()
    return get_affaire(db, affaire_id)


@router.delete("/{affaire_id}", status_code=204)
def delete_affaire(
    affaire_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    affaire = db.query(Affaire).get(affaire_id)
    if not affaire:
        raise HTTPException(status_code=404, detail="Affaire introuvable")
    db.delete(affaire)
    db.commit()


@router.post("/{affaire_id}/actions", response_model=AffaireActionResponse, status_code=201)
def add_action(
    affaire_id: int,
    data: AffaireActionCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    affaire = db.query(Affaire).get(affaire_id)
    if not affaire:
        raise HTTPException(status_code=404, detail="Affaire introuvable")
    action = AffaireAction(affaire_id=affaire_id, **data.model_dump())
    db.add(action)
    db.commit()
    db.refresh(action)
    return action


@router.delete("/actions/{action_id}", status_code=204)
def delete_action(
    action_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    action = db.query(AffaireAction).get(action_id)
    if not action:
        raise HTTPException(status_code=404, detail="Action introuvable")
    db.delete(action)
    db.commit()


@router.patch("/actions/{action_id}", response_model=AffaireActionResponse)
def update_action(
    action_id: int,
    data: AffaireActionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    action = db.query(AffaireAction).get(action_id)
    if not action:
        raise HTTPException(status_code=404, detail="Action introuvable")
    update = data.model_dump(exclude_unset=True)
    if "statut" in update and update["statut"].value in ("non_entame", "annule", "bloque"):
        if not update.get("commentaire") and not action.commentaire:
            raise HTTPException(
                status_code=400,
                detail="Commentaire/justification obligatoire pour ce statut",
            )
    for key, value in update.items():
        setattr(action, key, value)
    if data.statut is not None and data.statut.value == "termine":
        action.termine = True
    db.commit()
    db.refresh(action)
    return action


@router.get("/banques/list", response_model=list[BanqueResponse])
def list_banques(db: Session = Depends(get_db)):
    return db.query(Banque).order_by(Banque.nom).all()


@router.post("/banques", response_model=BanqueResponse, status_code=201)
def create_banque(
    data: BanqueCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    banque = Banque(nom=data.nom)
    db.add(banque)
    db.commit()
    db.refresh(banque)
    return banque


from pydantic import BaseModel

class SatisfactionSubmit(BaseModel):
    etoiles: int
    commentaire: str | None = None


@router.post("/{affaire_id}/envoyer-resume-chat")
def envoyer_resume_chat(
    affaire_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    affaire = db.query(Affaire).filter(Affaire.id == affaire_id).first()
    if not affaire:
        raise HTTPException(status_code=404, detail="Affaire introuvable")
    
    # Find client by email
    client = db.query(User).filter(User.email == affaire.correspondant_email).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable pour cette affaire (email non associé)")
    
    # Create message
    montant_formatted = f"{affaire.montant_affaire:,.0f}".replace(",", " ") if affaire.montant_affaire else "—"
    content = (
        f"📢 *[Résumé de votre demande]*\n\n"
        f"• **Projet :** {affaire.libelle_affaire}\n"
        f"• **Numéro d'affaire :** {affaire.numero_affaire}\n"
        f"• **Domaine :** {affaire.domaine}\n"
        f"• **Montant :** {montant_formatted} FCFA\n"
        f"• **Responsable :** {affaire.responsable_prenom} {affaire.responsable_nom}"
    )
    from app.models.message import Message
    msg = Message(
        client_id=client.id,
        sender_role="support",
        content=content
    )
    db.add(msg)
    db.commit()
    return {"status": "success", "message": "Résumé envoyé dans le chat."}


@router.post("/{affaire_id}/envoyer-facture-chat")
def envoyer_facture_chat(
    affaire_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    affaire = db.query(Affaire).filter(Affaire.id == affaire_id).first()
    if not affaire:
        raise HTTPException(status_code=404, detail="Affaire introuvable")
    
    if not affaire.demande_id:
        # Let's try to link it dynamically if there's a demande for this client
        from app.models.demande import Demande
        client_user = db.query(User).filter(User.email == affaire.correspondant_email).first()
        if client_user:
            dem = db.query(Demande).filter(Demande.client_id == client_user.id).order_by(Demande.created_at.desc()).first()
            if dem:
                affaire.demande_id = dem.id
                db.commit()
        if not affaire.demande_id:
            raise HTTPException(status_code=400, detail="Cette affaire n'est pas liée à une demande client (facture impossible à générer)")
            
    # Find client by email
    client = db.query(User).filter(User.email == affaire.correspondant_email).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable pour cette affaire")
        
    content = (
        f"📄 *[Facture Disponible]*\n\n"
        f"Votre facture pour le projet **{affaire.libelle_affaire}** (Affaire {affaire.numero_affaire}) est disponible.\n"
        f"Vous pouvez la télécharger en cliquant sur le lien ci-dessous :\n"
        f"🔗 /api/rapports/facture-excel/{affaire.demande_id}"
    )
    from app.models.message import Message
    msg = Message(
        client_id=client.id,
        sender_role="support",
        content=content
    )
    db.add(msg)
    db.commit()
    return {"status": "success", "message": "Facture envoyée dans le chat."}


@router.post("/{affaire_id}/satisfaction")
def submit_satisfaction(
    affaire_id: int,
    data: SatisfactionSubmit,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    affaire = db.query(Affaire).filter(Affaire.id == affaire_id).first()
    if not affaire:
        raise HTTPException(status_code=404, detail="Affaire introuvable")
        
    if current_user.role == UserRole.client and affaire.correspondant_email != current_user.email:
        raise HTTPException(status_code=403, detail="Non autorisé")
        
    affaire.satisfaction_etoiles = data.etoiles
    affaire.satisfaction_commentaire = data.commentaire
    db.commit()
    return {"status": "success"}


@router.get("/satisfactions/list")
def list_satisfactions(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin)),
):
    # Return all affairs with feedback
    affaires_list = db.query(Affaire).filter(Affaire.satisfaction_etoiles.isnot(None)).order_by(Affaire.updated_at.desc()).all()
    return [
        {
            "id": a.id,
            "numero_affaire": a.numero_affaire,
            "libelle_affaire": a.libelle_affaire,
            "client_nom": a.client_nom,
            "correspondant_nom": a.correspondant_nom,
            "correspondant_email": a.correspondant_email,
            "satisfaction_etoiles": a.satisfaction_etoiles,
            "satisfaction_commentaire": a.satisfaction_commentaire,
            "updated_at": a.updated_at.isoformat()
        }
        for a in affaires_list
    ]
