from datetime import date, datetime
from pydantic import BaseModel
from app.schemas.user import UserBrief

class DemandeBase(BaseModel):
    domaine: str
    type_prestation: str
    description: str
    adresse: str
    photos: str | None = None
    latitude: float | None = None
    longitude: float | None = None

class DemandeCreate(DemandeBase):
    pass

class DemandeUpdate(BaseModel):
    statut: str | None = None
    devis_montant: int | None = None
    rating: int | None = None
    avis: str | None = None
    photos: str | None = None
    accompte_pourcentage: int | None = None
    garantie_mois: int | None = None
    garantie_debut: date | None = None
    garantie_fin: date | None = None
    etapes_sautees: str | None = None
    etapes_custom: str | None = None

class DemandeResponse(DemandeBase):
    id: int
    client_id: int
    client: UserBrief | None = None
    statut: str
    devis_montant: int | None = None
    rating: int | None = None
    avis: str | None = None
    photos: str | None = None
    accompte_pourcentage: int | None = None
    garantie_mois: int | None = None
    garantie_debut: date | None = None
    garantie_fin: date | None = None
    etapes_sautees: str | None = None
    etapes_custom: str | None = None
    created_at: datetime

    class Config:
        from_attributes = True
