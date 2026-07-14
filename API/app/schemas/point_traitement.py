from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class LignePointTraitementBase(BaseModel):
    numero: int = Field(ge=1, le=10)
    date_demande: date | None = None
    client: str | None = None
    ref_demande: str | None = None
    resume_demande: str | None = None
    ref_devis: str | None = None
    montant_ht: Decimal | None = None
    statut: str | None = None


class LignePointTraitementCreate(LignePointTraitementBase):
    pass


class LignePointTraitementResponse(LignePointTraitementBase):
    id: int

    class Config:
        from_attributes = True


class FichePointTraitementCreate(BaseModel):
    semaine: int | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    responsable: str = ""
    signature_base64: str | None = None
    lignes: list[LignePointTraitementCreate] = Field(default_factory=list)


class FichePointTraitementUpdate(BaseModel):
    semaine: int | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    responsable: str | None = None
    signature_base64: str | None = None
    lignes: list[LignePointTraitementCreate] | None = None


class FichePointTraitementListItem(BaseModel):
    id: int
    semaine: int | None
    date_debut: date | None
    date_fin: date | None
    responsable: str
    created_at: datetime
    nb_lignes_remplies: int = 0
    total_montant_ht: Decimal | None = None

    class Config:
        from_attributes = True


class FichePointTraitementResponse(BaseModel):
    id: int
    semaine: int | None
    date_debut: date | None
    date_fin: date | None
    responsable: str
    signature_base64: str | None
    created_at: datetime
    updated_at: datetime
    lignes: list[LignePointTraitementResponse]

    class Config:
        from_attributes = True
