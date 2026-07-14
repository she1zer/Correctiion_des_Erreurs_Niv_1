from sqlalchemy.orm import Session, joinedload

from app.enums import ETAPES_AFFAIRE_STANDARD
from app.models.affaire import Affaire, AffaireAction
from app.schemas.affaire import AffaireActionCreate, AffaireCreate


def _create_standard_actions(affaire_id: int) -> list[AffaireAction]:
    actions = []
    for i, (libelle, champs) in enumerate(ETAPES_AFFAIRE_STANDARD, start=1):
        actions.append(
            AffaireAction(
                affaire_id=affaire_id,
                libelle=libelle,
                ordre=i,
                champs_actifs=champs,
            )
        )
    return actions


def create_affaire(db: Session, data: AffaireCreate) -> Affaire:
    affaire = Affaire(
        numero_affaire=data.numero_affaire.upper(),
        responsable_nom=data.responsable_nom,
        responsable_prenom=data.responsable_prenom,
        responsable_role=data.responsable_role,
        date_ouverture=data.date_ouverture,
        client_nom=data.client_nom,
        numero_commande=data.numero_commande,
        libelle_affaire=data.libelle_affaire,
        domaine=data.domaine,
        type_affaire=data.type_affaire,
        montant_affaire=data.montant_affaire,
        date_livraison_bc=data.date_livraison_bc,
        correspondant_nom=data.correspondant_nom,
        correspondant_telephone=data.correspondant_telephone,
        correspondant_email=data.correspondant_email,
        statut=data.statut,
        demande_id=data.demande_id,
        devis_proforma_id=data.devis_proforma_id,
    )
    db.add(affaire)
    db.flush()

    if data.actions:
        for action_data in data.actions:
            db.add(AffaireAction(affaire_id=affaire.id, **action_data.model_dump()))
    elif data.creer_etapes_standard:
        for action in _create_standard_actions(affaire.id):
            db.add(action)

    db.commit()
    db.refresh(affaire)
    return get_affaire(db, affaire.id)


def get_affaire(db: Session, affaire_id: int) -> Affaire | None:
    return (
        db.query(Affaire)
        .options(
            joinedload(Affaire.actions).joinedload(AffaireAction.responsable),
            joinedload(Affaire.actions).joinedload(AffaireAction.support),
            joinedload(Affaire.actions).joinedload(AffaireAction.banque),
        )
        .filter(Affaire.id == affaire_id)
        .first()
    )


def list_affaires(db: Session, skip: int = 0, limit: int = 100) -> list[Affaire]:
    return db.query(Affaire).order_by(Affaire.created_at.desc()).offset(skip).limit(limit).all()
