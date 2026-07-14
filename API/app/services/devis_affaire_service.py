from datetime import date, datetime
from decimal import Decimal

from sqlalchemy.orm import Session

from app.models.affaire import Affaire
from app.models.devis_proforma import DevisProforma
from app.models.user import User
from app.schemas.affaire import AffaireCreate
from app.services.affaire_service import create_affaire


def generate_numero_affaire(db: Session) -> str:
    year = datetime.now().strftime("%y")
    prefix = f"{year}DA"
    existing = (
        db.query(Affaire)
        .filter(Affaire.numero_affaire.like(f"{prefix}%"))
        .order_by(Affaire.numero_affaire.desc())
        .first()
    )
    if existing:
        try:
            seq = int(existing.numero_affaire.replace(prefix, "")) + 1
        except ValueError:
            seq = db.query(Affaire).count() + 1
    else:
        seq = 1
    return f"{prefix}{seq:03d}"


def create_affaire_from_devis(
    db: Session,
    devis: DevisProforma,
    current_user: User,
    numero_affaire: str | None = None,
    domaine: str = "FOURNITURE",
    type_affaire: str = "FOURNITURE",
    creer_etapes_standard: bool = True,
) -> Affaire:
    if devis.affaire_id:
        existing = db.query(Affaire).filter(Affaire.id == devis.affaire_id).first()
        if existing:
            return existing

    numero = (numero_affaire or generate_numero_affaire(db)).upper()
    if db.query(Affaire).filter(Affaire.numero_affaire == numero).first():
        raise ValueError("Ce numéro d'affaire existe déjà")

    lignes = devis.get_lignes()
    if lignes:
        libelle = lignes[0].get("designation") or f"Devis {devis.numero_devis}"
        if len(lignes) > 1:
            libelle = f"{libelle} (+{len(lignes) - 1} réf.)"
    else:
        libelle = f"Affaire suite devis {devis.numero_devis}"

    data = AffaireCreate(
        numero_affaire=numero,
        responsable_nom=current_user.nom,
        responsable_prenom=current_user.prenom,
        responsable_role=current_user.poste or "Technicien ISITEK",
        date_ouverture=date.today(),
        client_nom=devis.client_nom or "Client",
        numero_commande=devis.client_da,
        libelle_affaire=libelle[:500],
        domaine=domaine,
        type_affaire=type_affaire,
        montant_affaire=Decimal(devis.total_ht_net),
        correspondant_nom=devis.contact,
        correspondant_email=devis.email_from,
        demande_id=devis.demande_id,
        devis_proforma_id=devis.id,
        creer_etapes_standard=creer_etapes_standard,
    )

    affaire = create_affaire(db, data)
    devis.affaire_id = affaire.id
    db.commit()
    db.refresh(affaire)
    return affaire
