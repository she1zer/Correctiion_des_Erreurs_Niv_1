from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator

from app.enums import StatutAction, StatutAffaire
from app.schemas.user import UserBrief


class BanqueCreate(BaseModel):
    nom: str


class BanqueResponse(BaseModel):
    id: int
    nom: str

    class Config:
        from_attributes = True


class AffaireActionBase(BaseModel):
    libelle: str
    ordre: int = 0
    champs_actifs: list[str] | None = None
    responsable_id: int | None = None
    support_id: int | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    date_action: date | None = None
    ref: str | None = None
    agence: str | None = None
    mode: str | None = None
    fournisseur: str | None = None
    observations: str | None = None
    banque_id: int | None = None
    statut: StatutAction = StatutAction.non_entame
    commentaire: str | None = None
    termine: bool = False
    est_saute: bool = False
    pourcentage_acompte: int | None = None
    garantie_mois: int | None = None


class AffaireActionCreate(AffaireActionBase):
    pass


class AffaireActionUpdate(BaseModel):
    libelle: str | None = None
    ordre: int | None = None
    champs_actifs: list[str] | None = None
    responsable_id: int | None = None
    support_id: int | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    date_action: date | None = None
    ref: str | None = None
    agence: str | None = None
    mode: str | None = None
    fournisseur: str | None = None
    observations: str | None = None
    banque_id: int | None = None
    statut: StatutAction | None = None
    commentaire: str | None = None
    termine: bool | None = None
    est_saute: bool | None = None
    pourcentage_acompte: int | None = None
    garantie_mois: int | None = None


class AffaireActionResponse(AffaireActionBase):
    id: int
    affaire_id: int
    responsable: UserBrief | None = None
    support: UserBrief | None = None
    banque: BanqueResponse | None = None

    class Config:
        from_attributes = True


class AffaireBase(BaseModel):
    numero_affaire: str = Field(..., pattern=r"^\d{2}DA\d{3}$", examples=["26DA069"])
    responsable_nom: str
    responsable_prenom: str
    responsable_role: str
    date_ouverture: date
    client_nom: str
    numero_commande: str | None = None
    libelle_affaire: str
    domaine: str
    type_affaire: str | None = None
    montant_affaire: Decimal | None = None
    date_livraison_bc: date | None = None
    correspondant_nom: str | None = None
    correspondant_telephone: str | None = None
    correspondant_email: str | None = None
    statut: StatutAffaire = StatutAffaire.non_entame
    demande_id: int | None = None
    devis_proforma_id: int | None = None
    satisfaction_etoiles: int | None = None
    satisfaction_commentaire: str | None = None


class AffaireCreate(AffaireBase):
    creer_etapes_standard: bool = False
    actions: list[AffaireActionCreate] | None = None


class AffaireUpdate(BaseModel):
    responsable_nom: str | None = None
    responsable_prenom: str | None = None
    responsable_role: str | None = None
    date_ouverture: date | None = None
    client_nom: str | None = None
    numero_commande: str | None = None
    libelle_affaire: str | None = None
    domaine: str | None = None
    type_affaire: str | None = None
    montant_affaire: Decimal | None = None
    date_livraison_bc: date | None = None
    correspondant_nom: str | None = None
    correspondant_telephone: str | None = None
    correspondant_email: str | None = None
    statut: StatutAffaire | None = None
    demande_id: int | None = None
    satisfaction_etoiles: int | None = None
    satisfaction_commentaire: str | None = None


class AffaireResponse(AffaireBase):
    id: int
    created_at: datetime
    updated_at: datetime
    actions: list[AffaireActionResponse] = []

    class Config:
        from_attributes = True


class AffaireListItem(BaseModel):
    id: int
    numero_affaire: str
    client_nom: str
    libelle_affaire: str
    domaine: str
    statut: StatutAffaire
    date_ouverture: date
    montant_affaire: Decimal | None = None

    class Config:
        from_attributes = True
