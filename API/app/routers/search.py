from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.user import User
from app.security import require_roles
from app.services.easy_db_context_service import search_database

router = APIRouter(prefix="/api/search", tags=["Recherche ISITEK"])


class SearchDevisItem(BaseModel):
    id: int
    numero_devis: str
    client_nom: str
    contact: str | None = None
    date_devis: str
    total_ht_net: int
    objet_demande: str | None = None


class SearchAffaireItem(BaseModel):
    id: int
    numero_affaire: str
    client_nom: str
    libelle_affaire: str
    statut: str


class SearchDemandeItem(BaseModel):
    id: int
    client_label: str
    domaine: str
    type_prestation: str
    statut: str
    description: str | None = None


class SearchRapportItem(BaseModel):
    id: int
    numero_rapport: str
    client: str
    date_visite: str
    type_prestation: str
    nom_intervenant: str = ""


class SearchResponse(BaseModel):
    query: str
    terms: list[str] = Field(default_factory=list)
    total: int = 0
    devis: list[SearchDevisItem] = Field(default_factory=list)
    affaires: list[SearchAffaireItem] = Field(default_factory=list)
    demandes: list[SearchDemandeItem] = Field(default_factory=list)
    rapports: list[SearchRapportItem] = Field(default_factory=list)


@router.get("", response_model=SearchResponse)
def search_isitek(
    q: str = Query(..., min_length=2, max_length=120),
    db: Session = Depends(get_db),
    current_user: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    data = search_database(db, current_user, q)
    return SearchResponse(**data)
