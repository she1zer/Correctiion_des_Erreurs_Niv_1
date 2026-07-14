from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.orm import Session, joinedload

from app.database import get_db
from app.enums import UserRole
from app.models.action_interne import ActionInterne
from app.models.affaire import Affaire, AffaireAction
from app.models.user import User
from app.security import require_roles
from app.services.affaire_service import get_affaire
from app.services.pdf_service import (
    build_fiche_affaire_pdf,
    build_plan_action_lignes,
    build_plan_action_pdf,
)
from app.services.excel_service import (
    build_fiche_affaire_excel,
    build_plan_action_excel,
    build_facture_excel,
    build_point_traitement_excel,
)
from app.models.demande import Demande
from app.models.point_traitement import FichePointTraitement

router = APIRouter(prefix="/api/rapports", tags=["Rapports PDF"])


@router.get("/fiche-affaire/{affaire_id}")
def fiche_affaire_pdf(
    affaire_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    affaire = get_affaire(db, affaire_id)
    if not affaire:
        raise HTTPException(status_code=404, detail="Affaire introuvable")
    pdf = build_fiche_affaire_pdf(affaire)
    filename = f"fiche_affaire_{affaire.numero_affaire}.pdf"
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="{filename}"'},
    )


@router.get("/fiche-affaire-excel/{affaire_id}")
def fiche_affaire_excel(
    affaire_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    affaire = get_affaire(db, affaire_id)
    if not affaire:
        raise HTTPException(status_code=404, detail="Affaire introuvable")
    excel_data = build_fiche_affaire_excel(affaire)
    filename = f"fiche_affaire_{affaire.numero_affaire}.xlsx"
    return Response(
        content=excel_data,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/plan-action")
def plan_action_pdf(
    affaire_id: int | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    if affaire_id:
        affaire = get_affaire(db, affaire_id)
        if not affaire:
            raise HTTPException(status_code=404, detail="Affaire introuvable")
        affaire_actions = affaire.actions
        actions_internes = []
    else:
        affaire_actions = (
            db.query(AffaireAction)
            .options(joinedload(AffaireAction.affaire), joinedload(AffaireAction.responsable), joinedload(AffaireAction.support))
            .join(Affaire)
            .order_by(Affaire.numero_affaire, AffaireAction.ordre)
            .all()
        )
        actions_internes = (
            db.query(ActionInterne)
            .options(joinedload(ActionInterne.responsable), joinedload(ActionInterne.support))
            .order_by(ActionInterne.created_at.desc())
            .all()
        )

    lignes = build_plan_action_lignes(affaire_actions, actions_internes)
    pdf = build_plan_action_pdf(lignes)
    return Response(
        content=pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": 'inline; filename="plan_actions.pdf"'},
    )


@router.get("/plan-action-excel")
def plan_action_excel(
    affaire_id: int | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    if affaire_id:
        affaire = get_affaire(db, affaire_id)
        if not affaire:
            raise HTTPException(status_code=404, detail="Affaire introuvable")
        affaire_actions = affaire.actions
        actions_internes = []
    else:
        affaire_actions = (
            db.query(AffaireAction)
            .options(joinedload(AffaireAction.affaire), joinedload(AffaireAction.responsable), joinedload(AffaireAction.support))
            .join(Affaire)
            .order_by(Affaire.numero_affaire, AffaireAction.ordre)
            .all()
        )
        actions_internes = (
            db.query(ActionInterne)
            .options(joinedload(ActionInterne.responsable), joinedload(ActionInterne.support))
            .order_by(ActionInterne.created_at.desc())
            .all()
        )

    lignes = build_plan_action_lignes(affaire_actions, actions_internes)
    excel_data = build_plan_action_excel(lignes)
    return Response(
        content=excel_data,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": 'attachment; filename="plan_actions.xlsx"'},
    )


@router.get("/facture-excel/{demande_id}")
def facture_excel(
    demande_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien, UserRole.client)),
):
    demande = db.query(Demande).options(joinedload(Demande.client)).get(demande_id)
    if not demande:
        raise HTTPException(status_code=404, detail="Demande introuvable")
    excel_data = build_facture_excel(demande)
    filename = f"facture_FNE_{demande_id}.xlsx"
    return Response(
        content=excel_data,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/point-traitement-excel/{fiche_id}")
def point_traitement_excel(
    fiche_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin, UserRole.technicien)),
):
    fiche = db.query(FichePointTraitement).filter(FichePointTraitement.id == fiche_id).first()
    if not fiche:
        raise HTTPException(status_code=404, detail="Fiche introuvable")
    excel_data = build_point_traitement_excel(fiche)
    semaine = fiche.semaine or fiche.id
    filename = f"point_traitement_semaine_{semaine}.xlsx"
    return Response(
        content=excel_data,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )

