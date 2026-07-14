"""Recherche dans la base ISITEK pour contextualiser les réponses de Easy."""

import json
import re
import unicodedata
from datetime import datetime

from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.enums import UserRole
from app.models.rapport_visite import RapportVisite
from app.models.affaire import Affaire
from app.models.devis_proforma import DevisProforma
from app.models.devis_share import DevisShare
from app.models.demande import Demande
from app.models.user import User

_STOP_WORDS = frozenset(
    """
    a ai as au aux avec ce ces dans de des du elle en et eu fait faire faites
    avoir avais avait ete etes etre est sont sera serait je tu il elle on nous vous ils
    elles mon ma mes ton ta tes son sa ses notre nos votre vos leur leurs un une des les le la
    l d qu que qui quoi dont ou et ou si mais pour par sur sous sans entre vers chez
    plus moins tres bien aussi alors donc car parce lors lorsque quand comment combien
    quel quelle quels quelles deja encore toujours jamais rien quelque quelques tout toute
    tous toutes meme moi toi lui eux y en ne pas plus non oui si deja base donnee donnees
    donne données données devis devises client clients affaire affaires demande demandes
    isitek easy bonjour salut merci bonsoir aide aider question reponse rechercher cherche
    chercher trouve trouver existe existent deja déjà c est s il y a ya avais avait
    """.split()
)

_MAX_DEVIS = 12
_MAX_AFFAIRES = 8
_MAX_DEMANDES = 6
_MAX_RAPPORTS = 8


def _normalize(text: str) -> str:
    text = unicodedata.normalize("NFD", text.lower())
    text = "".join(c for c in text if unicodedata.category(c) != "Mn")
    return text


def _extract_search_terms(message: str) -> list[str]:
    raw = message.strip()
    terms: list[str] = []

    for m in re.finditer(r"['\"]([^'\"]{2,40})['\"]", raw):
        terms.append(m.group(1).strip())

    normalized = _normalize(raw)
    words = re.findall(r"[a-z0-9][a-z0-9\-]{1,}", normalized)
    for w in words:
        if len(w) >= 3 and w not in _STOP_WORDS:
            terms.append(w)

    # Mots capitalisés (ex. UNIWAX, Schneider)
    for m in re.finditer(r"\b([A-Z][A-Za-z0-9\-]{2,})\b", raw):
        terms.append(m.group(1))

    seen: set[str] = set()
    unique: list[str] = []
    for t in terms:
        key = _normalize(t)
        if key and key not in seen:
            seen.add(key)
            unique.append(t)
    return unique[:8]


def _accessible_devis_ids(db: Session, user: User) -> list[int] | None:
    """None = tous les devis (admin). Sinon liste d'ids accessibles."""
    if user.role == UserRole.admin:
        return None
    shared_ids = [
        s.devis_id
        for s in db.query(DevisShare).filter(DevisShare.shared_with_id == user.id).all()
    ]
    own = [
        d.id
        for d in db.query(DevisProforma.id)
        .filter(DevisProforma.created_by_id == user.id)
        .all()
    ]
    return list(dict.fromkeys(own + shared_ids))


def _text_matches(text: str | None, terms: list[str]) -> bool:
    if not text:
        return False
    norm = _normalize(text)
    return any(_normalize(t) in norm for t in terms)


def _lignes_match(lignes_json: str, terms: list[str]) -> list[str]:
    hits: list[str] = []
    try:
        lignes = json.loads(lignes_json or "[]")
    except json.JSONDecodeError:
        return hits
    for ligne in lignes:
        if not isinstance(ligne, dict):
            continue
        ref = str(ligne.get("ref") or ligne.get("reference") or "")
        des = str(ligne.get("designation") or ligne.get("description") or "")
        if _text_matches(ref, terms) or _text_matches(des, terms):
            snippet = f"{ref} — {des}".strip(" —")
            if snippet:
                hits.append(snippet[:120])
    return hits[:5]


def _fmt_date(dt: datetime | None) -> str:
    if not dt:
        return "—"
    return dt.strftime("%d/%m/%Y")


def _ilike_filters(terms: list[str], columns: list) -> list:
    clauses = []
    for term in terms:
        pattern = f"%{term}%"
        for col in columns:
            clauses.append(col.ilike(pattern))
    return clauses


def _search_devis(
    db: Session,
    user: User,
    terms: list[str],
) -> list[str]:
    if not terms:
        return []

    allowed_ids = _accessible_devis_ids(db, user)
    q = db.query(DevisProforma)
    if allowed_ids is not None:
        if not allowed_ids:
            return []
        q = q.filter(DevisProforma.id.in_(allowed_ids))

    columns = [
        DevisProforma.numero_devis,
        DevisProforma.client_nom,
        DevisProforma.contact,
        DevisProforma.client_da,
        DevisProforma.ref_demande,
        DevisProforma.objet_demande,
        DevisProforma.telephone,
        DevisProforma.email_from,
        DevisProforma.email_subject,
        DevisProforma.lignes_json,
    ]
    q = q.filter(or_(*_ilike_filters(terms, columns)))
    candidates = q.order_by(DevisProforma.created_at.desc()).limit(_MAX_DEVIS).all()

    lines: list[str] = []
    for d in candidates:
        ligne_hits = _lignes_match(d.lignes_json, terms)
        owner = (
            db.query(User).filter(User.id == d.created_by_id).first()
            if d.created_by_id
            else None
        )
        owner_name = (
            f"{owner.prenom} {owner.nom}".strip() if owner else "—"
        )
        refs = ", ".join(ligne_hits) if ligne_hits else "—"
        lines.append(
            f"• Devis {d.numero_devis} — client: {d.client_nom or '—'} — "
            f"contact: {d.contact or '—'} — date: {_fmt_date(d.date_devis)} — "
            f"montant HT net: {d.total_ht_net} FCFA — objet: {d.objet_demande or '—'} — "
            f"références produits: {refs} — créé par: {owner_name}"
        )

    return lines


def _search_affaires(db: Session, terms: list[str]) -> list[str]:
    if not terms:
        return []
    columns = [
        Affaire.numero_affaire,
        Affaire.client_nom,
        Affaire.libelle_affaire,
        Affaire.correspondant_nom,
        Affaire.correspondant_email,
        Affaire.domaine,
        Affaire.numero_commande,
    ]
    candidates = (
        db.query(Affaire)
        .filter(or_(*_ilike_filters(terms, columns)))
        .order_by(Affaire.created_at.desc())
        .limit(_MAX_AFFAIRES)
        .all()
    )
    lines: list[str] = []
    for a in candidates:
        lines.append(
            f"• Affaire {a.numero_affaire} — client: {a.client_nom} — "
            f"libellé: {a.libelle_affaire[:80]} — statut: {a.statut.value if a.statut else '—'} — "
            f"montant: {a.montant_affaire or '—'} — ouverture: {a.date_ouverture}"
        )
    return lines


def _search_demandes(db: Session, terms: list[str]) -> list[str]:
    if not terms:
        return []
    columns = [
        Demande.domaine,
        Demande.type_prestation,
        Demande.description,
        Demande.adresse,
        Demande.statut,
    ]
    candidates = (
        db.query(Demande)
        .filter(or_(*_ilike_filters(terms, columns)))
        .order_by(Demande.created_at.desc())
        .limit(_MAX_DEMANDES)
        .all()
    )
    lines: list[str] = []
    for dm in candidates:
        client = db.query(User).filter(User.id == dm.client_id).first()
        client_label = (
            f"{client.prenom} {client.nom}".strip() if client else f"client #{dm.client_id}"
        )
        desc = (dm.description or "")[:100].replace("\n", " ")
        lines.append(
            f"• Demande #{dm.id} — client: {client_label} — domaine: {dm.domaine} — "
            f"type: {dm.type_prestation} — statut: {dm.statut} — "
            f"montant devis: {dm.devis_montant or '—'} — description: {desc}"
        )
    return lines


def build_easy_db_context(db: Session, user: User, message: str) -> tuple[str, int]:
    """Retourne le contexte texte et le nombre d'enregistrements trouvés."""
    terms = _extract_search_terms(message)
    devis_lines = _search_devis(db, user, terms)
    affaire_lines = _search_affaires(db, terms)
    demande_lines = _search_demandes(db, terms)

    total = len(devis_lines) + len(affaire_lines) + len(demande_lines)
    if total == 0 and terms:
        # Recherche plus souple : préfixe du mot le plus long (ex. « uniwa » pour « uniwax »)
        longest = max(terms, key=len)
        if len(longest) >= 5:
            partial_terms = [longest[: len(longest) - 1]]
            devis_lines = _search_devis(db, user, partial_terms)
            affaire_lines = _search_affaires(db, partial_terms)
            demande_lines = _search_demandes(db, partial_terms)
            total = len(devis_lines) + len(affaire_lines) + len(demande_lines)
            if total > 0:
                terms = partial_terms

    if total == 0:
        if not terms:
            return (
                "Aucun mot-clé exploitable pour la recherche. "
                "Demandez avec un nom de client, une référence ou un numéro de devis.",
                0,
            )
        return (
            f"Aucun enregistrement trouvé pour : {', '.join(terms)}.",
            0,
        )

    parts: list[str] = []
    if devis_lines:
        parts.append("DEVIS PROFORMA :\n" + "\n".join(devis_lines))
    if affaire_lines:
        parts.append("AFFAIRES :\n" + "\n".join(affaire_lines))
    if demande_lines:
        parts.append("DEMANDES CLIENTS :\n" + "\n".join(demande_lines))

    parts.append(f"Mots-clés utilisés : {', '.join(terms)}")
    return "\n\n".join(parts), total


def augment_message_with_db_context(user_message: str, db_context: str) -> str:
    return (
        "=== DONNÉES ISITEK (base de données — source exclusive) ===\n"
        f"{db_context}\n"
        "=== FIN DONNÉES ===\n\n"
        f"Question de l'utilisateur : {user_message}"
    )


def _collect_search_terms(message: str) -> list[str]:
    terms = _extract_search_terms(message)
    if terms:
        return terms
    raw = message.strip().lower()
    words = [w for w in raw.split() if len(w) >= 2]
    return words[:8]


def _search_devis_records(db: Session, user: User, terms: list[str]) -> list[dict]:
    if not terms:
        return []
    allowed_ids = _accessible_devis_ids(db, user)
    q = db.query(DevisProforma)
    if allowed_ids is not None:
        if not allowed_ids:
            return []
        q = q.filter(DevisProforma.id.in_(allowed_ids))
    columns = [
        DevisProforma.numero_devis,
        DevisProforma.client_nom,
        DevisProforma.contact,
        DevisProforma.client_da,
        DevisProforma.ref_demande,
        DevisProforma.objet_demande,
        DevisProforma.telephone,
        DevisProforma.email_from,
        DevisProforma.email_subject,
        DevisProforma.lignes_json,
    ]
    q = q.filter(or_(*_ilike_filters(terms, columns)))
    rows = q.order_by(DevisProforma.created_at.desc()).limit(_MAX_DEVIS).all()
    return [
        {
            "id": d.id,
            "numero_devis": d.numero_devis,
            "client_nom": d.client_nom or "",
            "contact": d.contact,
            "date_devis": _fmt_date(d.date_devis),
            "total_ht_net": d.total_ht_net,
            "objet_demande": d.objet_demande,
        }
        for d in rows
    ]


def _search_affaire_records(db: Session, terms: list[str]) -> list[dict]:
    if not terms:
        return []
    columns = [
        Affaire.numero_affaire,
        Affaire.client_nom,
        Affaire.libelle_affaire,
        Affaire.correspondant_nom,
        Affaire.correspondant_email,
        Affaire.domaine,
        Affaire.numero_commande,
    ]
    rows = (
        db.query(Affaire)
        .filter(or_(*_ilike_filters(terms, columns)))
        .order_by(Affaire.created_at.desc())
        .limit(_MAX_AFFAIRES)
        .all()
    )
    return [
        {
            "id": a.id,
            "numero_affaire": a.numero_affaire,
            "client_nom": a.client_nom,
            "libelle_affaire": a.libelle_affaire,
            "statut": a.statut.value if a.statut else "",
        }
        for a in rows
    ]


def _search_demande_records(db: Session, terms: list[str]) -> list[dict]:
    if not terms:
        return []
    columns = [
        Demande.domaine,
        Demande.type_prestation,
        Demande.description,
        Demande.adresse,
        Demande.statut,
    ]
    rows = (
        db.query(Demande)
        .filter(or_(*_ilike_filters(terms, columns)))
        .order_by(Demande.created_at.desc())
        .limit(_MAX_DEMANDES)
        .all()
    )
    out: list[dict] = []
    for dm in rows:
        client = db.query(User).filter(User.id == dm.client_id).first()
        client_label = (
            f"{client.prenom} {client.nom}".strip() if client else f"client #{dm.client_id}"
        )
        out.append(
            {
                "id": dm.id,
                "client_label": client_label,
                "domaine": dm.domaine,
                "type_prestation": dm.type_prestation,
                "statut": dm.statut,
                "description": (dm.description or "")[:120],
            }
        )
    return out


def _search_rapport_records(db: Session, user: User, terms: list[str]) -> list[dict]:
    if not terms:
        return []
    q = db.query(RapportVisite)
    if user.role != UserRole.admin:
        q = q.filter(RapportVisite.created_by_id == user.id)
    columns = [
        RapportVisite.numero_rapport,
        RapportVisite.client,
        RapportVisite.correspondant_technique,
        RapportVisite.type_prestation,
        RapportVisite.type_batiment,
        RapportVisite.nom_intervenant,
        RapportVisite.note_nb,
        RapportVisite.lignes_json,
    ]
    rows = (
        q.filter(or_(*_ilike_filters(terms, columns)))
        .order_by(RapportVisite.date_visite.desc())
        .limit(_MAX_RAPPORTS)
        .all()
    )
    return [
        {
            "id": r.id,
            "numero_rapport": r.numero_rapport,
            "client": r.client,
            "date_visite": _fmt_date(r.date_visite),
            "type_prestation": r.type_prestation,
            "nom_intervenant": r.nom_intervenant or "",
        }
        for r in rows
    ]


def search_database(db: Session, user: User, query: str) -> dict:
    terms = _collect_search_terms(query)
    devis = _search_devis_records(db, user, terms)
    affaires = _search_affaire_records(db, user, terms)
    demandes = _search_demande_records(db, user, terms)
    rapports = _search_rapport_records(db, user, terms)
    total = len(devis) + len(affaires) + len(demandes) + len(rapports)

    if total == 0 and terms:
        longest = max(terms, key=len)
        if len(longest) >= 5:
            partial = [longest[: len(longest) - 1]]
            devis = _search_devis_records(db, user, partial)
            affaires = _search_affaire_records(db, user, partial)
            demandes = _search_demande_records(db, user, partial)
            rapports = _search_rapport_records(db, user, partial)
            total = len(devis) + len(affaires) + len(demandes) + len(rapports)
            if total > 0:
                terms = partial

    return {
        "query": query.strip(),
        "terms": terms,
        "total": total,
        "devis": devis,
        "affaires": affaires,
        "demandes": demandes,
        "rapports": rapports,
    }
