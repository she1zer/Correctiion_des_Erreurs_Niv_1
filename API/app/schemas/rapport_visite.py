from datetime import datetime

from pydantic import BaseModel, Field


class EtatLieuxLigne(BaseModel):
    secteur_zone: str = ""
    etat_des_lieux: str = ""
    actions_correctives: str = ""


class RapportPhotoItem(BaseModel):
    path: str
    legende: str = ""


class RapportVisiteCreate(BaseModel):
    date_visite: datetime
    client: str = Field(min_length=1, max_length=200)
    correspondant_technique: str = Field(min_length=1, max_length=200)
    type_prestation: str = Field(min_length=1, max_length=200)
    type_batiment: str = ""
    note_nb: str = ""
    nom_intervenant: str = ""
    lignes: list[EtatLieuxLigne] = Field(default_factory=list)


class RapportVisiteUpdate(BaseModel):
    date_visite: datetime | None = None
    client: str | None = None
    correspondant_technique: str | None = None
    type_prestation: str | None = None
    type_batiment: str | None = None
    note_nb: str | None = None
    nom_intervenant: str | None = None
    lignes: list[EtatLieuxLigne] | None = None
    photos: list[RapportPhotoItem] | None = None


class RapportVisiteResponse(BaseModel):
    id: int
    numero_rapport: str
    date_visite: datetime
    client: str
    correspondant_technique: str
    type_prestation: str
    type_batiment: str
    note_nb: str
    nom_intervenant: str
    lignes: list[EtatLieuxLigne]
    photos: list[RapportPhotoItem]
    created_by_id: int | None = None
    created_by_name: str | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
