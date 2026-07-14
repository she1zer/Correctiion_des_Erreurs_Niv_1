from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import HTMLResponse
from sqlalchemy.orm import Session

from app.database import get_db
from app.enums import UserRole
from app.models.user import User
from app.models.user_feedback import UserFeedback
from app.schemas.user_feedback import (
    UserFeedbackCreate,
    UserFeedbackResponse,
    UserFeedbackUpdate,
)
from app.security import get_current_user, require_roles

router = APIRouter(prefix="/api/feedback", tags=["Feedback & Bugs"])


def _to_response(fb: UserFeedback) -> UserFeedbackResponse:
    u = fb.user
    return UserFeedbackResponse(
        id=fb.id,
        user_id=fb.user_id,
        type=fb.type,
        title=fb.title,
        description=fb.description,
        status=fb.status,
        admin_response=fb.admin_response,
        created_at=fb.created_at,
        updated_at=fb.updated_at,
        user_nom=u.nom if u else None,
        user_prenom=u.prenom if u else None,
        user_email=u.email if u else None,
        user_role=u.role.value if u and hasattr(u.role, "value") else (str(u.role) if u else None),
    )


@router.post("/", response_model=UserFeedbackResponse, status_code=201)
def create_feedback(
    data: UserFeedbackCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    fb = UserFeedback(
        user_id=current_user.id,
        type=data.type,
        title=data.title.strip(),
        description=data.description.strip(),
    )
    db.add(fb)
    db.commit()
    db.refresh(fb)
    return _to_response(fb)


@router.get("/mine", response_model=list[UserFeedbackResponse])
def list_my_feedback(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    items = (
        db.query(UserFeedback)
        .filter(UserFeedback.user_id == current_user.id)
        .order_by(UserFeedback.created_at.desc())
        .limit(100)
        .all()
    )
    return [_to_response(f) for f in items]


@router.get("/", response_model=list[UserFeedbackResponse])
def list_all_feedback(
    status: str | None = Query(None),
    type: str | None = Query(None),
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    q = db.query(UserFeedback)
    if status:
        q = q.filter(UserFeedback.status == status)
    if type:
        q = q.filter(UserFeedback.type == type)
    items = q.order_by(UserFeedback.created_at.desc()).limit(500).all()
    return [_to_response(f) for f in items]


@router.patch("/{feedback_id}", response_model=UserFeedbackResponse)
def update_feedback(
    feedback_id: int,
    data: UserFeedbackUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    fb = db.query(UserFeedback).filter(UserFeedback.id == feedback_id).first()
    if not fb:
        raise HTTPException(status_code=404, detail="Signalement introuvable")
    payload = data.model_dump(exclude_unset=True)
    for k, v in payload.items():
        setattr(fb, k, v)
    fb.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(fb)
    return _to_response(fb)


@router.delete("/{feedback_id}", status_code=204)
def delete_feedback(
    feedback_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_roles(UserRole.admin)),
):
    fb = db.query(UserFeedback).filter(UserFeedback.id == feedback_id).first()
    if not fb:
        raise HTTPException(status_code=404, detail="Signalement introuvable")
    db.delete(fb)
    db.commit()


def _type_label(t: str) -> str:
    return {"bug": "Bug", "improvement": "Amélioration", "other": "Autre"}.get(t, t)


def _status_label(s: str) -> str:
    return {
        "pending": "En attente",
        "in_progress": "En cours",
        "resolved": "Résolu",
        "rejected": "Rejeté",
    }.get(s, s)


def _status_color(s: str) -> str:
    return {
        "pending": "#FFA000",
        "in_progress": "#0288D1",
        "resolved": "#008940",
        "rejected": "#C62828",
    }.get(s, "#666")


@router.get("/web/bugs", response_class=HTMLResponse, include_in_schema=False)
def bugs_web_page(db: Session = Depends(get_db)):
    """Page web publique (réseau local) — liste des signalements utilisateurs."""
    items = (
        db.query(UserFeedback)
        .order_by(UserFeedback.created_at.desc())
        .limit(500)
        .all()
    )

    rows = ""
    for fb in items:
        u = fb.user
        name = f"{u.prenom} {u.nom}" if u else "—"
        email = u.email if u else "—"
        role = u.role.value if u and hasattr(u.role, "value") else (str(u.role) if u else "—")
        date_str = fb.created_at.strftime("%d/%m/%Y %H:%M") if fb.created_at else ""
        desc = (fb.description or "").replace("<", "&lt;").replace(">", "&gt;").replace("\n", "<br>")
        admin_resp = (fb.admin_response or "").replace("<", "&lt;").replace(">", "&gt;").replace("\n", "<br>")
        rows += f"""
        <tr>
          <td>#{fb.id}</td>
          <td><span class="badge type-{fb.type}">{_type_label(fb.type)}</span></td>
          <td><strong>{fb.title}</strong><br><small class="desc">{desc}</small></td>
          <td>{name}<br><small>{email}</small><br><small class="role">{role}</small></td>
          <td><span class="badge" style="background:{_status_color(fb.status)}">{_status_label(fb.status)}</span></td>
          <td>{date_str}</td>
          <td><small>{admin_resp or '—'}</small></td>
        </tr>"""

    pending = sum(1 for f in items if f.status == "pending")
    bugs = sum(1 for f in items if f.type == "bug")
    improvements = sum(1 for f in items if f.type == "improvement")

    html = f"""<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>ISITEK — Signalements & Bugs</title>
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; }}
    body {{ font-family: 'Segoe UI', system-ui, sans-serif; background: #f0f4f2; color: #1a1a1a; }}
    header {{ background: linear-gradient(135deg, #008940, #005E2B); color: white; padding: 28px 32px; }}
    header h1 {{ font-size: 1.6rem; }}
    header p {{ opacity: 0.9; margin-top: 6px; font-size: 0.95rem; }}
    .stats {{ display: flex; gap: 16px; padding: 20px 32px; flex-wrap: wrap; }}
    .stat {{ background: white; border-radius: 12px; padding: 16px 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); min-width: 140px; }}
    .stat .num {{ font-size: 2rem; font-weight: 700; color: #008940; }}
    .stat .lbl {{ font-size: 0.85rem; color: #666; margin-top: 4px; }}
    .container {{ padding: 0 32px 40px; overflow-x: auto; }}
    table {{ width: 100%; border-collapse: collapse; background: white; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.08); }}
    th {{ background: #008940; color: white; padding: 14px 12px; text-align: left; font-size: 0.85rem; }}
    td {{ padding: 12px; border-bottom: 1px solid #eee; vertical-align: top; font-size: 0.9rem; }}
    tr:hover td {{ background: #f9fdfb; }}
    .badge {{ display: inline-block; padding: 3px 10px; border-radius: 20px; color: white; font-size: 0.75rem; font-weight: 600; }}
    .type-bug {{ background: #C62828; }}
    .type-improvement {{ background: #1565C0; }}
    .type-other {{ background: #6A1B9A; }}
    .desc {{ color: #555; line-height: 1.4; }}
    .role {{ color: #008940; }}
    footer {{ text-align: center; padding: 20px; color: #888; font-size: 0.8rem; }}
    @media (max-width: 768px) {{ .stats {{ padding: 16px; }} .container {{ padding: 0 12px 24px; }} header {{ padding: 20px 16px; }} }}
  </style>
</head>
<body>
  <header>
    <h1>🐛 ISITEK Connect — Signalements utilisateurs</h1>
    <p>Bugs, améliorations et suggestions remontés depuis l'application mobile</p>
  </header>
  <div class="stats">
    <div class="stat"><div class="num">{len(items)}</div><div class="lbl">Total signalements</div></div>
    <div class="stat"><div class="num">{pending}</div><div class="lbl">En attente</div></div>
    <div class="stat"><div class="num">{bugs}</div><div class="lbl">Bugs</div></div>
    <div class="stat"><div class="num">{improvements}</div><div class="lbl">Améliorations</div></div>
  </div>
  <div class="container">
    <table>
      <thead>
        <tr>
          <th>#</th><th>Type</th><th>Titre / Description</th><th>Utilisateur</th>
          <th>Statut</th><th>Date</th><th>Réponse admin</th>
        </tr>
      </thead>
      <tbody>
        {rows if rows else '<tr><td colspan="7" style="text-align:center;padding:40px;color:#888;">Aucun signalement pour le moment</td></tr>'}
      </tbody>
    </table>
  </div>
  <footer>ISITEK SARL — Actualisé le {datetime.utcnow().strftime("%d/%m/%Y à %H:%M")} UTC · API docs : /docs</footer>
</body>
</html>"""
    return HTMLResponse(content=html)
