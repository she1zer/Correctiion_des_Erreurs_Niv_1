from datetime import datetime
from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

from app.models.devis_proforma import DevisProforma


def _fmt_amount(value: int | float) -> str:
    return f"{int(value):,}".replace(",", " ")


def build_proforma_pdf(devis: DevisProforma) -> bytes:
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, leftMargin=18 * mm, rightMargin=18 * mm, topMargin=15 * mm, bottomMargin=15 * mm)
    styles = getSampleStyleSheet()
    green = colors.HexColor("#1E7D32")
    red = colors.HexColor("#B91C1C")
    navy = colors.HexColor("#1E3A5F")

    title_style = ParagraphStyle("title", parent=styles["Heading1"], textColor=green, fontSize=16, spaceAfter=6)
    section_style = ParagraphStyle("section", parent=styles["Heading3"], textColor=navy, fontSize=10, spaceAfter=4)
    normal = ParagraphStyle("normal", parent=styles["Normal"], fontSize=9, leading=12)

    story = [
        Paragraph("ISITEK SARL", title_style),
        Paragraph(f'<font color="#B91C1C"><b>NOTRE PROFORMA N° {devis.numero_devis}</b></font>', normal),
        Spacer(1, 8),
    ]

    refs_data = [
        [
            Paragraph("<b>Nos références</b>", section_style),
            Paragraph("<b>Vos références</b>", section_style),
        ],
        [
            Paragraph(
                "ISITEK SARL<br/>ETUDE.ING.REALISAT.FORMAT.EXPERTISE<br/>"
                "TEL: 2520011982<br/>Email: contact@isitek.ci<br/>N° CC: 1736067S",
                normal,
            ),
            Paragraph(
                f"{devis.client_nom or ''}<br/>N° CC: {devis.client_numero_cc or ''}<br/>DA: {devis.client_da or ''}",
                normal,
            ),
        ],
    ]
    refs_table = Table(refs_data, colWidths=[90 * mm, 90 * mm])
    refs_table.setStyle(TableStyle([
        ("BOX", (0, 0), (-1, -1), 0.8, colors.grey),
        ("INNERGRID", (0, 0), (-1, -1), 0.4, colors.lightgrey),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#E8F5E9")),
    ]))
    story += [refs_table, Spacer(1, 8)]

    info_data = [[
        Paragraph(f"<b>N° du devis:</b> {devis.numero_devis}", normal),
        Paragraph(f"<b>Date:</b> {devis.date_devis.strftime('%d/%m/%y')}", normal),
        Paragraph(f"<b>Contact:</b> {devis.contact or ''}", normal),
    ]]
    info_table = Table(info_data, colWidths=[60 * mm, 60 * mm, 60 * mm])
    info_table.setStyle(TableStyle([
        ("BOX", (0, 0), (-1, -1), 0.8, colors.grey),
        ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#E3F2FD")),
    ]))
    story += [Paragraph("<b>Informations sur le devis</b>", section_style), info_table, Spacer(1, 10)]

    story.append(Paragraph("<b>Détail de votre devis</b>", section_style))
    table_header = ["Référence", "Désignation", "QTE", "P.U.H.T.", "Remise", "Mont HT NET"]
    table_rows = [table_header]
    for ligne in devis.get_lignes():
        qte = float(ligne.get("quantite", 0))
        pu = float(ligne.get("prix_unitaire_ht", 0))
        remise_pct = float(ligne.get("remise_pourcentage", 0))
        brut = qte * pu
        remise_val = brut * remise_pct / 100
        net = brut - remise_val
        table_rows.append([
            ligne.get("reference", ""),
            Paragraph(str(ligne.get("designation", ""))[:120], normal),
            _fmt_amount(qte),
            _fmt_amount(pu),
            f"{remise_pct:g}%",
            _fmt_amount(net),
        ])

    lines_table = Table(table_rows, colWidths=[22 * mm, 62 * mm, 14 * mm, 22 * mm, 16 * mm, 24 * mm])
    lines_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), green),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.grey),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
    ]))
    story += [lines_table, Spacer(1, 10)]

    totals = [
        ["", "", "", "Total HT Brut:", _fmt_amount(devis.total_ht_brut)],
        ["", "", "", "Total Remise:", _fmt_amount(devis.total_remise)],
        ["", "", "", "Total HT NET:", _fmt_amount(devis.total_ht_net)],
    ]
    totals_table = Table(totals, colWidths=[22 * mm, 62 * mm, 14 * mm, 38 * mm, 24 * mm])
    totals_table.setStyle(TableStyle([
        ("ALIGN", (3, 0), (-1, -1), "RIGHT"),
        ("FONTNAME", (3, 2), (-1, 2), "Helvetica-Bold"),
        ("TEXTCOLOR", (3, 2), (-1, 2), red),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
    ]))
    story += [totals_table, Spacer(1, 10)]

    conditions = (
        f"<b>Validité offre:</b> {devis.validite_offre}<br/>"
        f"<b>Délai de livraison:</b> {devis.delai_livraison}<br/>"
        f"<b>Condition de règlement:</b> <font color='#B91C1C'>{devis.acompte_pourcentage}% CMDE</font><br/>"
        f"<b>Moyen de règlement:</b> {devis.moyen_reglement}<br/>"
        f"<b>Libellé du chèque:</b> {devis.libelle_cheque}"
    )
    story += [
        Paragraph("<b>Conditions commerciales</b>", section_style),
        Paragraph(conditions, normal),
        Spacer(1, 16),
        Paragraph("<b>SERVICE COMMERCIAL</b>", section_style),
        Spacer(1, 8),
        Paragraph(
            "ISITEK SARL au capital de 10 000 000 F CFA - RCCM: CI-ABJ-2017-B-21181 N° CC: 1736067S<br/>"
            "Compte Bancaire: BICICI 010577100067 - Siège: Cocody Angré Chateau<br/>"
            "TEL: +225 25 20 01 19 82 - Email: contact@isitek.ci / isitek.sarl@gmail.com",
            ParagraphStyle("footer", parent=styles["Normal"], fontSize=7, textColor=colors.grey),
        ),
    ]

    doc.build(story)
    return buffer.getvalue()
