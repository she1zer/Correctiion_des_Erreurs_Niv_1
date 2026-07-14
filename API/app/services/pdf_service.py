import io
from datetime import date

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.enums import PRIORITE_LABELS, STATUT_ACTION_LABELS, STATUT_AFFAIRE_LABELS
from app.models.affaire import Affaire
from app.models.action_interne import ActionInterne
from app.schemas.action import PlanActionLigne


def _fmt_date(d) -> str:
    if not d:
        return ""
    if isinstance(d, date):
        return d.strftime("%d/%m/%Y")
    return str(d)


def _fmt_montant(m) -> str:
    if m is None:
        return ""
    return f"{m:,.0f}".replace(",", " ")


def build_plan_action_pdf(lignes: list[PlanActionLigne], titre: str = "PLAN D'ACTIONS") -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=landscape(A4),
        rightMargin=1 * cm,
        leftMargin=1 * cm,
        topMargin=1.5 * cm,
        bottomMargin=1 * cm,
    )
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "Title",
        parent=styles["Heading1"],
        fontSize=16,
        alignment=2,
        textColor=colors.HexColor("#008940"),
    )
    elements = [
        Paragraph(titre, title_style),
        Spacer(1, 0.3 * cm),
        Paragraph(
            "<b>Priorité :</b> Haute | Moyenne | Basse",
            styles["Normal"],
        ),
        Spacer(1, 0.5 * cm),
    ]

    headers = [
        "N°",
        "ACTION / TÂCHES",
        "CLIENT",
        "RESPONSABLE",
        "SUPPORT",
        "DÉBUT",
        "FIN",
        "STATUT",
        "COMMENTAIRES",
    ]
    data = [headers]
    for ligne in lignes:
        data.append(
            [
                str(ligne.numero),
                ligne.action,
                ligne.client,
                ligne.responsable,
                ligne.support,
                ligne.debut,
                ligne.fin,
                ligne.statut,
                ligne.commentaire,
            ]
        )

    table = Table(data, repeatRows=1, colWidths=[1 * cm, 5.5 * cm, 3 * cm, 3 * cm, 3 * cm, 2 * cm, 2 * cm, 2.5 * cm, 4 * cm])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#008940")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F6FAF8")]),
            ]
        )
    )
    elements.append(table)
    elements.append(Spacer(1, 1 * cm))
    elements.append(Paragraph("Validation Direction : _______________________", styles["Normal"]))

    doc.build(elements)
    buffer.seek(0)
    return buffer.read()


def build_fiche_affaire_pdf(affaire: Affaire) -> bytes:
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        rightMargin=1.5 * cm,
        leftMargin=1.5 * cm,
        topMargin=1.5 * cm,
        bottomMargin=1.5 * cm,
    )
    styles = getSampleStyleSheet()
    green = colors.HexColor("#008940")

    elements = [
        Paragraph(
            '<font color="#008940"><b>ISITEK SARL</b></font> — Depuis 2012, votre partenaire technique de confiance',
            styles["Normal"],
        ),
        Spacer(1, 0.3 * cm),
        Paragraph(
            '<para align="center"><b>FICHE D\'AFFAIRE</b></para>',
            styles["Heading2"],
        ),
        Spacer(1, 0.5 * cm),
    ]

    info_data = [
        ["N° AFFAIRE", affaire.numero_affaire, "RESPONSABLE", f"{affaire.responsable_prenom} {affaire.responsable_nom}"],
        ["DATE D'OUVERTURE", _fmt_date(affaire.date_ouverture), "CLIENT", affaire.client_nom],
        ["N° COMMANDE", affaire.numero_commande or "", "DATE LIVRAISON BC", _fmt_date(affaire.date_livraison_bc)],
    ]
    info_table = Table(info_data, colWidths=[3.5 * cm, 4.5 * cm, 3.5 * cm, 4.5 * cm])
    info_table.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("FONTNAME", (2, 0), (2, -1), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#F6FAF8")),
            ]
        )
    )
    elements.append(info_table)
    elements.append(Spacer(1, 0.3 * cm))

    extra = [
        ["LIBELLÉ AFFAIRE", affaire.libelle_affaire],
        ["DOMAINE", affaire.domaine],
        ["TYPE AFFAIRE", affaire.type_affaire or ""],
        [
            "CORRESPONDANT",
            f"{affaire.correspondant_nom or ''} — {affaire.correspondant_telephone or ''} — {affaire.correspondant_email or ''}",
        ],
        ["MONTANT", _fmt_montant(affaire.montant_affaire)],
        ["STATUT", STATUT_AFFAIRE_LABELS.get(affaire.statut.value, affaire.statut.value)],
    ]
    extra_table = Table(extra, colWidths=[4 * cm, 12 * cm])
    extra_table.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ("FONTNAME", (0, 0), (0, -1), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 9),
            ]
        )
    )
    elements.append(extra_table)
    elements.append(Spacer(1, 0.5 * cm))
    elements.append(Paragraph("<b>PROGRESSION AFFAIRE</b>", styles["Heading3"]))

    prog_headers = ["ÉTAPE", "COL. 1", "COL. 2", "OBSERVATIONS"]
    prog_data = [prog_headers]
    for action in affaire.actions:
        col1 = _fmt_date(action.date_debut or action.date_action)
        col2 = _fmt_date(action.date_fin) or (action.ref or "")
        if action.fournisseur:
            col2 = action.fournisseur
        if action.mode:
            col2 = action.mode
        if action.agence:
            col2 = action.agence
        if action.banque:
            col2 = action.banque.nom
        obs = action.observations or action.commentaire or ""
        check = "☑" if action.termine else "☐"
        prog_data.append([f"{check} {action.libelle}", col1, col2, obs])

    prog_table = Table(prog_data, colWidths=[5.5 * cm, 3 * cm, 3.5 * cm, 4 * cm])
    prog_table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), green),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
            ]
        )
    )
    elements.append(prog_table)
    elements.append(Spacer(1, 1 * cm))

    sig_data = [
        ["Responsable affaire", "Comptable", "Business Controller", "Direction"],
        ["", "", "", ""],
    ]
    sig_table = Table(sig_data, colWidths=[4 * cm, 4 * cm, 4 * cm, 4 * cm], rowHeights=[0.8 * cm, 2 * cm])
    sig_table.setStyle(
        TableStyle(
            [
                ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
                ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
                ("FONTSIZE", (0, 0), (-1, -1), 8),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ]
        )
    )
    elements.append(sig_table)

    doc.build(elements)
    buffer.seek(0)
    return buffer.read()


def build_plan_action_lignes(
    affaire_actions: list,
    actions_internes: list[ActionInterne],
) -> list[PlanActionLigne]:
    lignes = []
    numero = 1

    for aa in affaire_actions:
        resp = ""
        if aa.affaire:
            resp = f"{aa.affaire.responsable_prenom} {aa.affaire.responsable_nom}"
        elif aa.responsable:
            resp = f"{aa.responsable.prenom} {aa.responsable.nom}"
        support = ""
        if aa.support:
            support = f"{aa.support.prenom} {aa.support.nom}"
        lignes.append(
            PlanActionLigne(
                numero=numero,
                action=aa.libelle,
                client=aa.affaire.client_nom if aa.affaire else "",
                responsable=resp,
                support=support,
                debut=_fmt_date(aa.date_debut or aa.date_action),
                fin=_fmt_date(aa.date_fin),
                statut=STATUT_ACTION_LABELS.get(aa.statut.value, aa.statut.value),
                commentaire=aa.commentaire or "",
            )
        )
        numero += 1

    for ai in actions_internes:
        resp = f"{ai.responsable.prenom} {ai.responsable.nom}" if ai.responsable else ""
        support = f"{ai.support.prenom} {ai.support.nom}" if ai.support else ""
        lignes.append(
            PlanActionLigne(
                numero=numero,
                action=ai.nom,
                client="INTERNE (ISITEK)",
                responsable=resp,
                support=support,
                debut=_fmt_date(ai.date_debut),
                fin=_fmt_date(ai.date_fin),
                statut=STATUT_ACTION_LABELS.get(ai.statut.value, ai.statut.value),
                commentaire=ai.commentaire or "",
                priorite=PRIORITE_LABELS.get(ai.priorite.value, ai.priorite.value),
            )
        )
        numero += 1

    return lignes
