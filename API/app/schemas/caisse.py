from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class FicheControleCaisseBase(BaseModel):
    semaine: int | None = None
    annee: int | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    solde_theorique: Decimal | None = None
    solde_reel: Decimal | None = None
    ecart_avt: Decimal | None = None
    observations: str = ""
    ecart_apt: Decimal | None = None
    sig_rep_operations: str = ""
    sig_comptable: str = ""
    sig_direction: str = ""
    sections_par_page: int = Field(default=2, ge=1, le=2)


class FicheControleCaisseCreate(FicheControleCaisseBase):
    pass


class FicheControleCaisseUpdate(BaseModel):
    semaine: int | None = None
    annee: int | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    solde_theorique: Decimal | None = None
    solde_reel: Decimal | None = None
    ecart_avt: Decimal | None = None
    observations: str | None = None
    ecart_apt: Decimal | None = None
    sig_rep_operations: str | None = None
    sig_comptable: str | None = None
    sig_direction: str | None = None
    sections_par_page: int | None = Field(default=None, ge=1, le=2)


class FicheControleCaisseResponse(FicheControleCaisseBase):
    id: int
    page_id: int | None = None
    slot: int = 1
    sections_par_page: int = 2
    created_by_id: int | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class LigneLivreCaisseSchema(BaseModel):
    numero: int
    date_operation: date | None = None
    numero_piece: str | None = None
    nom_prenoms: str | None = None
    detail_operation: str | None = None
    entree: Decimal | None = None
    sortie: Decimal | None = None
    solde: Decimal | None = None
    signature_beneficiaire: str | None = None


class LivreCaisseHebdoBase(BaseModel):
    annee: int | None = None
    mois: int | None = None
    semaine: int | None = None
    periode_debut: date | None = None
    periode_fin: date | None = None
    montant_caisse_date: date | None = None
    montant_caisse_valeur: Decimal | None = None
    date_signature: date | None = None
    signature_finale: str | None = None
    lignes: list[LigneLivreCaisseSchema] = Field(default_factory=list)


class LivreCaisseHebdoCreate(LivreCaisseHebdoBase):
    pass


class LivreCaisseHebdoUpdate(BaseModel):
    annee: int | None = None
    mois: int | None = None
    semaine: int | None = None
    periode_debut: date | None = None
    periode_fin: date | None = None
    montant_caisse_date: date | None = None
    montant_caisse_valeur: Decimal | None = None
    date_signature: date | None = None
    signature_finale: str | None = None
    lignes: list[LigneLivreCaisseSchema] | None = None


class LigneLivreCaisseResponse(LigneLivreCaisseSchema):
    id: int

    class Config:
        from_attributes = True


class LivreCaisseHebdoResponse(LivreCaisseHebdoBase):
    id: int
    created_by_id: int | None = None
    created_at: datetime
    updated_at: datetime
    lignes: list[LigneLivreCaisseResponse] = Field(default_factory=list)

    class Config:
        from_attributes = True


class CaisseSearchLivreHit(BaseModel):
    livre_id: int
    ligne_id: int
    annee: int | None = None
    semaine: int | None = None
    nom_prenoms: str | None = None
    detail_operation: str | None = None
    solde: Decimal | None = None
    entree: Decimal | None = None
    sortie: Decimal | None = None
    date_operation: date | None = None
    numero_piece: str | None = None


class CaisseSearchControleHit(BaseModel):
    id: int
    annee: int | None = None
    semaine: int | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    solde_theorique: Decimal | None = None
    solde_reel: Decimal | None = None
    ecart_avt: Decimal | None = None
    ecart_apt: Decimal | None = None


class CaisseSearchResponse(BaseModel):
    fiches_controle: list[CaisseSearchControleHit] = Field(default_factory=list)
    livre_lignes: list[CaisseSearchLivreHit] = Field(default_factory=list)


class FicheControlePageResponse(BaseModel):
    page_id: int
    sections_par_page: int = 2
    fiche_slot_1: FicheControleCaisseResponse | None = None
    fiche_slot_2: FicheControleCaisseResponse | None = None
