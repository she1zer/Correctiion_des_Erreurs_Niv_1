import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/devis_model.dart';
import '../models/produit_model.dart';
import '../utils/formatters.dart';

/// Service responsable de la génération du document PDF du devis.
///
/// Reproduit fidèlement la mise en page du modèle papier ISITEK :
/// logo + bloc "Notre proforma N°", encadrés "Nos références" /
/// "Vos références", informations du devis, tableau détaillé des
/// produits, bloc des totaux, conditions de règlement, signature et
/// pied de page avec les coordonnées légales de l'entreprise.
class PdfService {
  PdfService._();

  static const PdfColor _green = PdfColor.fromInt(0xFF1E7D32);
  static const PdfColor _red = PdfColor.fromInt(0xFFB91C1C);
  static const PdfColor _navy = PdfColor.fromInt(0xFF1E3A5F);
  static const PdfColor _border = PdfColor.fromInt(0xFFBFC8C5);
  static const PdfColor _greyText = PdfColor.fromInt(0xFF4A4A4A);

  /// Construit le document PDF complet à partir d'un [DevisModel].
  static Future<Uint8List> genererPdf(DevisModel devis) async {
    final doc = pw.Document();

    // Chargement du logo ISITEK et de la bande des marques partenaires
    // depuis les assets de l'application.
    pw.MemoryImage? logo;
    try {
      final logoBytes = await rootBundle.load('assets/images/logo_isitek.png');
      logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logo = null;
    }

    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final fontItalic = await PdfGoogleFonts.openSansItalic();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 18),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
          italic: fontItalic,
        ),
        header: (context) {
          if (context.pageNumber == 1) return pw.SizedBox();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              'Devis ${devis.numeroDevis} - suite',
              style: pw.TextStyle(
                  fontSize: 9, color: _greyText, fontStyle: pw.FontStyle.italic),
            ),
          );
        },
        footer: (context) => pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Divider(color: _border, thickness: 0.7),
            pw.SizedBox(height: 4),
            pw.Text(
              'ISITEK SARL au capital de 10 000 000 F CFA - RCCM: CI-ABJ-2017-B-21181 N° CC: 1736067S',
              style: const pw.TextStyle(fontSize: 6.8, color: _greyText),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Compte Bancaire: BICICI 010577100067 - Siège: Cocody Angré Chateau - '
              'TEL: +225 25 20 01 19 82/+225 07 97 38 50 35/+225 05 66 66 01 98',
              style: const pw.TextStyle(fontSize: 6.8, color: _greyText),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'Email: contact@isitek.ci/ isitek.sarl@gmail.com',
              style: const pw.TextStyle(fontSize: 6.8, color: _greyText),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Page ${context.pageNumber}/${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 7, color: _greyText),
            ),
          ],
        ),
        build: (context) => [
          _buildHeaderBlock(logo),
          pw.SizedBox(height: 14),
          _buildReferencesBlock(devis),
          pw.SizedBox(height: 12),
          _buildInfosDevisBlock(devis),
          pw.SizedBox(height: 14),
          pw.Text(
            'Détail de votre devis',
            style: pw.TextStyle(
                fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
          ),
          pw.SizedBox(height: 8),
          _buildProduitsTable(devis.listeProduits),
          pw.SizedBox(height: 16),
          _buildTotalsAndConditionsRow(devis),
          pw.SizedBox(height: 26),
          _buildSignatureBlock(),
        ],
      ),
    );

    return doc.save();
  }

  // -----------------------------------------------------------------------
  // En-tête : logo + "NOTRE PROFORMA N°"
  // -----------------------------------------------------------------------
  static pw.Widget _buildHeaderBlock(pw.MemoryImage? logo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Container(height: 62, width: 62, child: pw.Image(logo))
        else
          pw.Container(
            height: 62,
            width: 62,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _green),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text('ISITEK',
                style: pw.TextStyle(
                    color: _green, fontWeight: pw.FontWeight.bold, fontSize: 9)),
          ),
        pw.SizedBox(width: 18),
        pw.Expanded(
          child: pw.Text(
            'NOTRE PROFORMA N°',
            style: pw.TextStyle(
                fontSize: 15, fontWeight: pw.FontWeight.bold, color: _green),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // "Nos références" / "Vos références"
  // -----------------------------------------------------------------------
  static pw.Widget _buildReferencesBlock(DevisModel devis) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Nos références',
                  style:
                      pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: const [
                    pw.Text('ISITEK SARL', style: pw.TextStyle(fontSize: 9)),
                    pw.Text('ETUDE.ING.REALISAT.FORMAT.EXPERTISE',
                        style: pw.TextStyle(fontSize: 9)),
                    pw.Text('2520011982', style: pw.TextStyle(fontSize: 9)),
                    pw.Text('contact@isitek.ci', style: pw.TextStyle(fontSize: 9)),
                    pw.Text('1736067S', style: pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Vos références',
                  style:
                      pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Container(
                width: double.infinity,
                height: 76,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(devis.clientNom, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('N°CC : ${devis.clientNumeroCC}', style: const pw.TextStyle(fontSize: 9)),
                    pw.SizedBox(height: 4),
                    pw.Text('DA : ${devis.clientDA}', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // "Informations sur le devis"
  // -----------------------------------------------------------------------
  static pw.Widget _buildInfosDevisBlock(DevisModel devis) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Informations sur le devis',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 5),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text('N° du devis : ${devis.numeroDevis}',
                    style: const pw.TextStyle(fontSize: 9.5)),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text('Date : ${Formatters.dateCourte(devis.date)}',
                    style: const pw.TextStyle(fontSize: 9.5)),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Text('Contact : ${devis.contact}',
                    style: const pw.TextStyle(fontSize: 9.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Tableau "Détail de votre devis"
  // -----------------------------------------------------------------------
  static pw.Widget _buildProduitsTable(List<ProduitModel> produits) {
    final headers = ['Référence', 'Désignation', 'QTE', 'P.U.H.T.', 'Remise', 'Mont HT NET'];

    final flexes = [2, 4, 1, 2, 1, 2];

    pw.Widget cell(String text, int flex,
        {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
      return pw.Expanded(
        flex: flex,
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: pw.Text(
            text,
            textAlign: align,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
      );
    }

    final headerRow = pw.Container(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFF3F1)),
      child: pw.Row(
        children: List.generate(headers.length, (i) {
          return cell(headers[i], flexes[i], bold: true);
        }),
      ),
    );

    final rows = produits.isEmpty
        ? [
            pw.Container(
              decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: _border, width: 0.6))),
              child: pw.Row(
                children: List.generate(headers.length, (i) => cell('', flexes[i])),
              ),
            ),
          ]
        : produits.map((p) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: _border, width: 0.6))),
              child: pw.Row(
                children: [
                  cell(p.reference, flexes[0]),
                  cell(p.designation, flexes[1]),
                  cell(_fmtQte(p.quantite), flexes[2], align: pw.TextAlign.center),
                  cell(Formatters.montant(p.prixUnitaireHT), flexes[3], align: pw.TextAlign.right),
                  cell(Formatters.pourcentage(p.remisePourcentage), flexes[4], align: pw.TextAlign.center),
                  cell(Formatters.montant(p.montantHTNet), flexes[5], align: pw.TextAlign.right, bold: true),
                ],
              ),
            );
          }).toList();

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
      child: pw.Column(children: [headerRow, ...rows]),
    );
  }

  static String _fmtQte(double q) {
    if (q == q.roundToDouble()) return q.round().toString();
    return q.toString();
  }

  // -----------------------------------------------------------------------
  // Totaux + conditions de règlement (deux colonnes, comme le modèle)
  // -----------------------------------------------------------------------
  static pw.Widget _buildTotalsAndConditionsRow(DevisModel devis) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 5, child: pw.SizedBox()),
        pw.Expanded(
          flex: 6,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildTotalsBlock(devis),
              pw.SizedBox(height: 10),
              _buildConditionsBlock(devis),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTotalsBlock(DevisModel devis) {
    pw.Widget ligne(String label, String valeur, {bool isLast = false}) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            bottom: isLast
                ? pw.BorderSide.none
                : pw.BorderSide(color: _border, width: 0.6),
          ),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
            pw.Text(valeur, style: const pw.TextStyle(fontSize: 9.5)),
          ],
        ),
      );
    }

    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.8)),
      child: pw.Column(
        children: [
          ligne('Total HT Brut:', Formatters.montant(devis.totalHTBrut)),
          ligne('Total Remise:', Formatters.montant(devis.totalRemise)),
          ligne('Total HT NET:', Formatters.montant(devis.totalHTNet), isLast: true),
        ],
      ),
    );
  }

  static pw.Widget _buildConditionsBlock(DevisModel devis) {
    pw.Widget ligne(String label, String valeur, {PdfColor? color}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2.2),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 120,
              child: pw.Text(label,
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _navy)),
            ),
            pw.Expanded(
              child: pw.Text(valeur,
                  style: pw.TextStyle(fontSize: 9.5, color: color ?? PdfColors.black)),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ligne('Validité offre :', devis.validiteOffre),
        ligne('Delai de livraison :', devis.delaiLivraison),
        ligne('Condition de règlement :',
            '${Formatters.pourcentage(devis.acomptePourcentage)} CMDE',
            color: _red),
        ligne('Moyen de règlement :', devis.moyenReglement),
        ligne('Libellé du chèque :', devis.libelleCheque),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Bloc signature "SERVICE COMMERCIAL"
  // -----------------------------------------------------------------------
  static pw.Widget _buildSignatureBlock() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('SERVICE COMMERCIAL',
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline)),
        pw.SizedBox(height: 28),
        pw.Text('ISITEK SARL',
            style: pw.TextStyle(fontSize: 8.5, color: _greyText, fontWeight: pw.FontWeight.bold)),
        pw.Text('COTE D\'IVOIRE / ABIDJAN', style: const pw.TextStyle(fontSize: 7.5, color: _greyText)),
        pw.Text('CI-ABJ-2017-B-21181 / 1736067S / RSI',
            style: const pw.TextStyle(fontSize: 7.5, color: _greyText)),
        pw.Text('BICICI 010S77100067-64', style: const pw.TextStyle(fontSize: 7.5, color: _greyText)),
        pw.Text('(+225) 20 01 19 82 / (+225) 09 48 21 84',
            style: const pw.TextStyle(fontSize: 7.5, color: _greyText)),
      ],
    );
  }
}
