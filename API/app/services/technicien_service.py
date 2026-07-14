from datetime import date

from fastapi import HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session, joinedload

from app.enums import RolePrise, StatutAction, UserRole
from app.models.action_interne import ActionInterne
from app.models.action_prise import ActionPrise
from app.models.affaire import AffaireAction
from app.models.user import User
from app.schemas.action import ActionDisponible, ActionPriseCreate, ActionPriseUpdate


def _user_name(user: User | None) -> str | None:
    if not user:
        return None
    return f"{user.prenom} {user.nom}"


def _validate_statut_comment(statut: StatutAction, commentaire: str | None):
    if statut in (StatutAction.non_entame, StatutAction.annule, StatutAction.bloque):
        if not commentaire or not commentaire.strip():
            raise HTTPException(
                status_code=400,
                detail=f"Un commentaire/justification est obligatoire pour le statut '{statut.value}'",
            )


def get_actions_disponibles(db: Session, technicien: User) -> list[ActionDisponible]:
    result: list[ActionDisponible] = []
    today_prises = {
        (p.affaire_action_id, p.action_interne_id, p.role_prise)
        for p in db.query(ActionPrise)
        .filter(ActionPrise.technicien_id == technicien.id, ActionPrise.date_prise == date.today())
        .all()
    }

    affaire_actions = (
        db.query(AffaireAction)
        .options(
            joinedload(AffaireAction.affaire),
            joinedload(AffaireAction.responsable),
            joinedload(AffaireAction.support),
        )
        .filter(
            (AffaireAction.responsable_id == technicien.id)
            | (AffaireAction.support_id == technicien.id)
            | (
                (AffaireAction.responsable_id.is_(None))
                & (AffaireAction.support_id.is_(None))
            )
        )
        .all()
    )

    for aa in affaire_actions:
        role = None
        if aa.responsable_id == technicien.id:
            role = "responsable"
        elif aa.support_id == technicien.id:
            role = "support"
        deja = (aa.id, None, RolePrise.responsable) in today_prises or (
            aa.id,
            None,
            RolePrise.support,
        ) in today_prises
        resp = f"{aa.affaire.responsable_prenom} {aa.affaire.responsable_nom}"

        has_resp = aa.responsable_id is not None or aa.support_id is not None
        is_own = aa.responsable_id == technicien.id or aa.support_id == technicien.id
        if not is_own and aa.affaire.responsable_nom and aa.affaire.responsable_prenom:
            existing_resp = (
                db.query(User)
                .filter(
                    func.lower(User.nom) == func.lower(aa.affaire.responsable_nom),
                    func.lower(User.prenom) == func.lower(aa.affaire.responsable_prenom),
                )
                .first()
            )
            if existing_resp and existing_resp.id == technicien.id:
                is_own = True

        result.append(
            ActionDisponible(
                type="affaire",
                id=aa.id,
                libelle=aa.libelle,
                client=aa.affaire.client_nom,
                responsable_nom=resp,
                support_nom=_user_name(aa.support),
                statut=aa.statut,
                affaire_numero=aa.affaire.numero_affaire,
                date_debut=aa.date_debut,
                date_fin=aa.date_fin,
                deja_prise=deja,
                role_assigne=role,
                has_responsible=has_resp,
                is_own_action=is_own,
            )
        )

    internes = (
        db.query(ActionInterne)
        .options(
            joinedload(ActionInterne.responsable),
            joinedload(ActionInterne.support),
        )
        .filter(
            (ActionInterne.responsable_id == technicien.id)
            | (ActionInterne.support_id == technicien.id)
            | (
                (ActionInterne.responsable_id.is_(None))
                & (ActionInterne.support_id.is_(None))
            )
        )
        .all()
    )

    for ai in internes:
        role = None
        if ai.responsable_id == technicien.id:
            role = "responsable"
        elif ai.support_id == technicien.id:
            role = "support"
        deja = (None, ai.id, RolePrise.responsable) in today_prises or (
            None,
            ai.id,
            RolePrise.support,
        ) in today_prises
        
        has_resp = ai.responsable_id is not None
        is_own = ai.responsable_id == technicien.id or ai.support_id == technicien.id

        result.append(
            ActionDisponible(
                type="interne",
                id=ai.id,
                libelle=ai.nom,
                client="INTERNE (ISITEK)",
                responsable_nom=_user_name(ai.responsable),
                support_nom=_user_name(ai.support),
                statut=ai.statut,
                priorite=ai.priorite,
                date_debut=ai.date_debut,
                date_fin=ai.date_fin,
                deja_prise=deja,
                role_assigne=role,
                has_responsible=has_resp,
                is_own_action=is_own,
            )
        )

    return result


def get_actions_affaires(db: Session, technicien: User) -> list[ActionDisponible]:
    return [a for a in get_actions_disponibles(db, technicien) if a.type == "affaire"]


def get_actions_internes(db: Session, technicien: User) -> list[ActionDisponible]:
    return [a for a in get_actions_disponibles(db, technicien) if a.type == "interne"]


def prendre_action(db: Session, technicien: User, data: ActionPriseCreate) -> ActionPrise:
    if technicien.role not in (UserRole.technicien, UserRole.admin):
        raise HTTPException(status_code=403, detail="Réservé aux techniciens")

    if data.affaire_action_id:
        action = db.query(AffaireAction).options(joinedload(AffaireAction.affaire)).get(
            data.affaire_action_id
        )
        if not action:
            raise HTTPException(status_code=404, detail="Action d'affaire introuvable")

        if data.role_prise == RolePrise.responsable:
            if action.responsable_id and action.responsable_id != technicien.id:
                raise HTTPException(status_code=400, detail="Cette action a déjà un responsable assigné.")

        # Pour les actions d'affaire, le responsable est toujours celui de l'affaire
        affaire = action.affaire
        existing = (
            db.query(User)
            .filter(
                func.lower(User.nom) == func.lower(affaire.responsable_nom),
                func.lower(User.prenom) == func.lower(affaire.responsable_prenom),
            )
            .first()
        )
        if existing:
            action.responsable_id = existing.id
            if data.role_prise == RolePrise.responsable and existing.id != technicien.id:
                raise HTTPException(
                    status_code=400,
                    detail="Vous n'êtes pas le responsable assigné à cette affaire.",
                )
        else:
            if data.role_prise == RolePrise.responsable:
                raise HTTPException(
                    status_code=400,
                    detail=f"Cette affaire est affectée à {affaire.responsable_prenom} {affaire.responsable_nom}."
                )

        if data.role_prise == RolePrise.support:
            action.support_id = technicien.id
        elif data.support_id:
            action.support_id = data.support_id

    else:
        action = db.query(ActionInterne).get(data.action_interne_id)
        if not action:
            raise HTTPException(status_code=404, detail="Action interne introuvable")

        if data.role_prise == RolePrise.responsable:
            if action.responsable_id and action.responsable_id != technicien.id:
                raise HTTPException(
                    status_code=400,
                    detail="Cette action interne a déjà un responsable assigné.",
                )
            action.responsable_id = technicien.id
        if data.support_id:
            action.support_id = data.support_id
        elif data.role_prise == RolePrise.support:
            action.support_id = technicien.id

    prise = ActionPrise(
        technicien_id=technicien.id,
        affaire_action_id=data.affaire_action_id,
        action_interne_id=data.action_interne_id,
        role_prise=data.role_prise,
        date_prise=date.today(),
        statut=StatutAction.en_cours,
    )
    db.add(prise)
    db.commit()
    db.refresh(prise)
    return prise


def update_prise(
    db: Session, technicien: User, prise_id: int, data: ActionPriseUpdate
) -> ActionPrise:
    prise = db.query(ActionPrise).get(prise_id)
    if not prise:
        raise HTTPException(status_code=404, detail="Prise d'action introuvable")
    if prise.technicien_id != technicien.id and technicien.role != UserRole.admin:
        raise HTTPException(status_code=403, detail="Non autorisé")

    update_data = data.model_dump(exclude_unset=True)
    if "statut" in update_data:
        _validate_statut_comment(update_data["statut"], update_data.get("commentaire", prise.commentaire))

    for key, value in update_data.items():
        setattr(prise, key, value)

    if prise.affaire_action_id:
        aa = db.query(AffaireAction).get(prise.affaire_action_id)
        if aa:
            if data.date_debut:
                aa.date_debut = data.date_debut
            if data.date_fin:
                aa.date_fin = data.date_fin
            if data.statut:
                aa.statut = data.statut
                aa.termine = data.statut == StatutAction.termine
            if data.commentaire:
                aa.commentaire = data.commentaire
            if data.support_id and prise.role_prise == RolePrise.responsable:
                aa.support_id = data.support_id

    if prise.action_interne_id:
        ai = db.query(ActionInterne).get(prise.action_interne_id)
        if ai:
            if data.date_debut:
                ai.date_debut = data.date_debut
            if data.date_fin:
                ai.date_fin = data.date_fin
            if data.statut:
                ai.statut = data.statut
            if data.commentaire:
                ai.commentaire = data.commentaire
            if data.support_id and prise.role_prise == RolePrise.responsable:
                ai.support_id = data.support_id

    db.commit()
    db.refresh(prise)
    return prise


def get_mes_prises(db: Session, technicien: User) -> list[ActionPrise]:
    return (
        db.query(ActionPrise)
        .options(
            joinedload(ActionPrise.affaire_action).joinedload(AffaireAction.affaire),
            joinedload(ActionPrise.action_interne),
        )
        .filter(ActionPrise.technicien_id == technicien.id)
        .order_by(ActionPrise.date_prise.desc())
        .all()
    )


def get_support_tasks(db: Session, technicien: User) -> list[ActionPrise]:
    """Actions où le technicien est support (prises ou assigné)."""
    return (
        db.query(ActionPrise)
        .options(
            joinedload(ActionPrise.affaire_action).joinedload(AffaireAction.affaire),
            joinedload(ActionPrise.action_interne),
            joinedload(ActionPrise.technicien),
        )
        .filter(
            ActionPrise.role_prise == RolePrise.support,
            ActionPrise.technicien_id == technicien.id,
        )
        .order_by(ActionPrise.date_prise.desc())
        .all()
    )
