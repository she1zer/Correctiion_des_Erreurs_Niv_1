from datetime import date, datetime

from pydantic import BaseModel, model_validator

from app.enums import Priorite, RolePrise, StatutAction
from app.schemas.user import UserBrief


class ActionInterneBase(BaseModel):
    nom: str
    responsable_id: int | None = None
    support_id: int | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    statut: StatutAction = StatutAction.non_entame
    priorite: Priorite = Priorite.moyenne
    commentaire: str | None = None


class ActionInterneCreate(ActionInterneBase):
    pass


class ActionInterneUpdate(BaseModel):
    nom: str | None = None
    responsable_id: int | None = None
    support_id: int | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    statut: StatutAction | None = None
    priorite: Priorite | None = None
    commentaire: str | None = None


class ActionInterneResponse(ActionInterneBase):
    id: int
    created_at: datetime
    updated_at: datetime
    responsable: UserBrief | None = None
    support: UserBrief | None = None

    class Config:
        from_attributes = True


class ActionPriseCreate(BaseModel):
    affaire_action_id: int | None = None
    action_interne_id: int | None = None
    role_prise: RolePrise = RolePrise.responsable
    support_id: int | None = None

    @model_validator(mode="after")
    def check_one_action(self):
        if bool(self.affaire_action_id) == bool(self.action_interne_id):
            raise ValueError("Spécifiez soit affaire_action_id soit action_interne_id")
        return self


class ActionPriseUpdate(BaseModel):
    date_debut: date | None = None
    date_fin: date | None = None
    statut: StatutAction | None = None
    commentaire: str | None = None
    support_travail: str | None = None
    support_id: int | None = None


class AffaireActionBrief(BaseModel):
    id: int
    libelle: str
    statut: StatutAction
    termine: bool

    class Config:
        from_attributes = True


class ActionInterneBrief(BaseModel):
    id: int
    nom: str
    statut: StatutAction

    class Config:
        from_attributes = True


class ActionPriseResponse(BaseModel):
    id: int
    technicien_id: int
    affaire_action_id: int | None
    action_interne_id: int | None
    role_prise: RolePrise
    date_prise: date
    date_debut: date | None
    date_fin: date | None
    statut: StatutAction
    commentaire: str | None
    support_travail: str | None
    technicien: UserBrief | None = None
    affaire_action: AffaireActionBrief | None = None
    action_interne: ActionInterneBrief | None = None

    class Config:
        from_attributes = True


class ActionDisponible(BaseModel):
    """Action assignée disponible pour prise par le technicien."""
    type: str  # "affaire" | "interne"
    id: int
    libelle: str
    client: str
    responsable_nom: str | None = None
    support_nom: str | None = None
    statut: StatutAction
    priorite: Priorite | None = None
    affaire_numero: str | None = None
    date_debut: date | None = None
    date_fin: date | None = None
    deja_prise: bool = False
    role_assigne: str | None = None  # responsable | support
    has_responsible: bool = False
    is_own_action: bool = False


class PlanActionLigne(BaseModel):
    numero: int
    action: str
    client: str
    responsable: str
    support: str
    debut: str
    fin: str
    statut: str
    commentaire: str
    priorite: str | None = None
