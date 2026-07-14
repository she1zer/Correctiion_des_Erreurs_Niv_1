from datetime import date, datetime

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import StatutAction, StatutAffaire
from app.models.affaire import Affaire
from app.models.action_interne import ActionInterne
from app.models.demande import Demande
from app.models.user import User
from app.models.user_feedback import UserFeedback
from app.security import get_current_user

router = APIRouter(prefix="/api/hub", tags=["Hub ISITEK"])


class HubTaskItem(BaseModel):
    id: int
    label: str
    type: str
    statut: str
    echeance: date | None = None


class HubSummaryResponse(BaseModel):
    role: str
    actions_en_cours: int = 0
    actions_urgentes: int = 0
    demandes_ouvertes: int = 0
    feedback_en_attente: int = 0
    mes_signalements: int = 0
    astuces_disponibles: int = 0
    taches_du_jour: list[HubTaskItem] = Field(default_factory=list)
    message: str = ""


@router.get("/summary", response_model=HubSummaryResponse)
def hub_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    role = current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role)
    today = date.today()
    tasks: list[HubTaskItem] = []
    actions_en_cours = 0
    actions_urgentes = 0
    demandes_ouvertes = 0
    feedback_en_attente = 0

    mes_signalements = (
        db.query(UserFeedback)
        .filter(UserFeedback.user_id == current_user.id)
        .count()
    )

    from app.models.astuce import Astuce
    astuces_count = db.query(Astuce).filter(Astuce.is_active == True).count()

    if role in ("admin", "technicien"):
        affaires = db.query(Affaire).filter(Affaire.statut == StatutAffaire.en_cours).limit(20).all()
        for a in affaires:
            actions_en_cours += 1
            echeance = a.date_livraison_bc
            urgent = echeance is not None and echeance <= today
            if urgent:
                actions_urgentes += 1
            if len(tasks) < 8:
                tasks.append(HubTaskItem(
                    id=a.id,
                    label=f"Affaire {a.numero_affaire} — {a.client_nom}",
                    type="affaire",
                    statut=a.statut.value if hasattr(a.statut, "value") else str(a.statut),
                    echeance=echeance,
                ))

        internes = db.query(ActionInterne).filter(ActionInterne.statut == StatutAction.en_cours).limit(10).all()
        for ac in internes:
            actions_en_cours += 1
            echeance = ac.date_fin
            if echeance and echeance <= today:
                actions_urgentes += 1
            if len(tasks) < 8:
                tasks.append(HubTaskItem(
                    id=ac.id,
                    label=ac.nom or f"Action interne #{ac.id}",
                    type="action_interne",
                    statut=ac.statut.value if hasattr(ac.statut, "value") else str(ac.statut),
                    echeance=echeance,
                ))

        if role == "admin":
            demandes_ouvertes = (
                db.query(Demande)
                .filter(Demande.statut.notin_(["termine", "annule", "cloture"]))
                .count()
            )
            feedback_en_attente = (
                db.query(UserFeedback)
                .filter(UserFeedback.status == "pending")
                .count()
            )

    elif role == "client":
        demandes = (
            db.query(Demande)
            .filter(Demande.client_id == current_user.id)
            .order_by(Demande.created_at.desc())
            .limit(5)
            .all()
        )
        for d in demandes:
            if d.statut not in ("termine", "annule", "cloture"):
                demandes_ouvertes += 1
            tasks.append(HubTaskItem(
                id=d.id,
                label=f"{d.domaine} — {d.type_prestation}",
                type="demande",
                statut=d.statut,
            ))

    greeting_hour = datetime.utcnow().hour
    if greeting_hour < 12:
        msg = "Bonne matinée ! Voici votre résumé ISITEK."
    elif greeting_hour < 18:
        msg = "Bon après-midi ! Restez productif avec ISITEK Connect."
    else:
        msg = "Bonsoir ! Consultez vos tâches et astuces du jour."

    return HubSummaryResponse(
        role=role,
        actions_en_cours=actions_en_cours,
        actions_urgentes=actions_urgentes,
        demandes_ouvertes=demandes_ouvertes,
        feedback_en_attente=feedback_en_attente,
        mes_signalements=mes_signalements,
        astuces_disponibles=astuces_count,
        taches_du_jour=tasks,
        message=msg,
    )
