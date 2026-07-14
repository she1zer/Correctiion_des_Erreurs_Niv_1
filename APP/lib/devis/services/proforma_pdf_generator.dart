import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/proforma_models.dart';
import '../utils/formatters.dart';

/// Reconstruit le document PROFORMA ISITEK en PDF natif (texte/tableaux vectoriels),
/// fidèle au modèle HTML / Excel d'origine (az.jpeg).
class ProformaPdfGenerator {
  static const PdfColor green = PdfColor.fromInt(0xFF1F7A3D);
  static const PdfColor greenDark = PdfColor.fromInt(0xFF14552A);
  static const PdfColor tableHead = PdfColor.fromInt(0xFFE3E9DE);
  static const PdfColor lineGrey = PdfColor.fromInt(0xFF999999);
  static const PdfColor red = PdfColor.fromInt(0xFFC0392B);
  static const PdfColor netBg = PdfColor.fromInt(0xFFDDE9DA);

  static Future<Uint8List> generate({
    required ProformaQuote quote,
    required Uint8List logoBytes,
    required Uint8List signatureBytes,
    required Uint8List partnersBytes,
  }) async {
    final doc = pw.Document();

    final logoImg = pw.MemoryImage(logoBytes);
    final sigImg = pw.MemoryImage(signatureBytes);
    final partnersImg = pw.MemoryImage(partnersBytes);

    final baseStyle = const pw.TextStyle(fontSize: 9.5);
    final boldStyle = baseStyle.copyWith(fontWeight: pw.FontWeight.bold);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 24, 28, 18),
        footer: (context) => _buildFooter(),
        build: (context) => [
          _buildHeader(logoImg, boldStyle),
          pw.SizedBox(height: 8),
          _buildProformaBar(quote, boldStyle),
          pw.SizedBox(height: 10),
          _buildAttentionBlock(quote, baseStyle, boldStyle),
          pw.SizedBox(height: 8),
          _buildInfoLines(quote, baseStyle, boldStyle),
          pw.SizedBox(height: 8),
          _buildObjet(quote, boldStyle),
          pw.SizedBox(height: 10),
          _buildItemsTable(quote, baseStyle, boldStyle),
          pw.SizedBox(height: 0),
          _buildTotalsTable(quote, baseStyle, boldStyle),
          pw.SizedBox(height: 10),
          _buildBottomRow(quote, sigImg, baseStyle, boldStyle),
          pw.SizedBox(height: 16),
          pw.Divider(color: lineGrey, thickness: 0.6),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Image(partnersImg, width: 480),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo, pw.TextStyle boldStyle) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 64,
          height: 64,
          child: pw.Image(logo),
        ),
        pw.Expanded(child: pw.SizedBox()),
      ],
    );
  }

  static pw.Widget _buildProformaBar(ProformaQuote quote, pw.TextStyle boldStyle) {
    final num = quote.proformaNum.isEmpty ? '________' : quote.proformaNum;
    return pw.Container(
      width: double.infinity,
      color: tableHead,
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      alignment: pw.Alignment.center,
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: 'PROFORMA  ',
              style: boldStyle.copyWith(fontSize: 13, letterSpacing: 0.5),
            ),
            pw.TextSpan(
              text: num,
              style: boldStyle.copyWith(
                fontSize: 13,
                color: greenDark,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildAttentionBlock(
    ProformaQuote quote,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 260,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.only(right: 14),
              child: pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      "À l'attention de :",
                      style: baseStyle.copyWith(fontSize: 9),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      quote.attClient.isEmpty ? '—' : quote.attClient.toUpperCase(),
                      style: boldStyle.copyWith(fontSize: 10),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Table(
              border: pw.TableBorder.all(color: lineGrey, width: 0.6),
              columnWidths: const {
                0: pw.FixedColumnWidth(62),
                1: pw.FlexColumnWidth(),
              },
              children: [
                pw.TableRow(children: [
                  _cell(
                    'Contact',
                    boldStyle.copyWith(fontSize: 9),
                    bg: const PdfColor.fromInt(0xFFF7F7F7),
                  ),
                  _cell(
                    quote.contactNom.isEmpty ? '—' : quote.contactNom,
                    boldStyle.copyWith(fontSize: 9),
                    align: pw.TextAlign.center,
                  ),
                ]),
                pw.TableRow(children: [
                  _cell(
                    'Phone',
                    boldStyle.copyWith(fontSize: 9),
                    bg: const PdfColor.fromInt(0xFFF7F7F7),
                  ),
                  _cell(
                    quote.contactPhone.isEmpty ? '—' : quote.contactPhone,
                    baseStyle.copyWith(fontSize: 9),
                    align: pw.TextAlign.center,
                  ),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildInfoLines(
    ProformaQuote quote,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.RichText(
          text: pw.TextSpan(
            style: baseStyle.copyWith(fontSize: 9.5),
            children: [
              pw.TextSpan(
                text: 'DATE EMISSION: ',
                style: boldStyle.copyWith(fontSize: 9.5),
              ),
              pw.TextSpan(
                text: Formatters.frDate(quote.dateEmission),
                style: boldStyle.copyWith(fontSize: 9.5, color: red),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        pw.RichText(
          text: pw.TextSpan(
            style: baseStyle.copyWith(fontSize: 9.5),
            children: [
              pw.TextSpan(
                text: 'AFFAIRE SUIVIE PAR: ',
                style: boldStyle.copyWith(fontSize: 9.5),
              ),
              pw.TextSpan(
                text: quote.affaireSuivie.isEmpty ? '—' : quote.affaireSuivie,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        pw.RichText(
          text: pw.TextSpan(
            style: baseStyle.copyWith(fontSize: 9.5),
            children: [
              pw.TextSpan(
                text: 'REF DEMANDE: ',
                style: boldStyle.copyWith(fontSize: 9.5),
              ),
              pw.TextSpan(
                text: quote.refDemande.isEmpty ? 'N/A' : quote.refDemande,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildObjet(ProformaQuote quote, pw.TextStyle boldStyle) {
    return pw.Container(
      width: double.infinity,
      color: tableHead,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: 'OBJET DEMANDE: ',
              style: boldStyle.copyWith(fontSize: 9.5, color: red),
            ),
            pw.TextSpan(
              text: quote.objetDemande.isEmpty
                  ? '—'
                  : quote.objetDemande.toUpperCase(),
              style: boldStyle.copyWith(fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    ProformaQuote quote,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    final headerStyle =
        boldStyle.copyWith(fontSize: 9, fontStyle: pw.FontStyle.italic);

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.white),
        children: [
          _headCell('Ref', headerStyle),
          _headCell('DÉSIGNATION', headerStyle),
          _headCell('Unit', headerStyle),
          _headCell('Qté', headerStyle),
          _headCell('Prix Unit', headerStyle),
          _headCell('REMISE', headerStyle),
          _headCell('Prix Tot. HT', headerStyle),
        ],
      ),
    ];

    for (int i = 0; i < quote.items.length; i++) {
      final it = quote.items[i];
      rows.add(pw.TableRow(children: [
        _cell(
          it.code.isEmpty ? '—' : it.code,
          baseStyle,
          align: pw.TextAlign.center,
        ),
        _cell(
          it.description.isEmpty ? '—' : it.description,
          baseStyle,
        ),
        _cell(it.unit, baseStyle, align: pw.TextAlign.center),
        _cell(_numStr(it.qte), baseStyle, align: pw.TextAlign.center),
        _cell(
          Formatters.money(it.prixUnit),
          baseStyle,
          align: pw.TextAlign.right,
          bold: true,
        ),
        _cell(
          it.remisePct == 0 ? '—' : Formatters.pct(it.remisePct),
          baseStyle,
          align: pw.TextAlign.center,
        ),
        _cell(
          Formatters.money(it.net),
          baseStyle,
          align: pw.TextAlign.right,
          bold: true,
        ),
      ]));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: lineGrey, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.6),
        1: pw.FlexColumnWidth(3.6),
        2: pw.FlexColumnWidth(0.8),
        3: pw.FlexColumnWidth(0.8),
        4: pw.FlexColumnWidth(1.4),
        5: pw.FlexColumnWidth(1.0),
        6: pw.FlexColumnWidth(1.6),
      },
      children: rows,
    );
  }

  static pw.Widget _buildTotalsTable(
    ProformaQuote quote,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    final rows = <pw.TableRow>[
      _totalRow('TOTAL HT BRUT', Formatters.money(quote.totalBrut), boldStyle),
      _totalRow(
        'TOTAL REMISE COMMERCIALE',
        Formatters.money(quote.totalRemiseCommerciale),
        boldStyle,
      ),
      _totalRow('S/TOTAL HT', Formatters.money(quote.sousTotalHT), boldStyle),
    ];

    if (quote.remiseExcEnabled) {
      rows.add(_totalRow(
        'REMISE EXCEPTIONNELLE (${Formatters.pct(quote.remiseExcPct)})',
        Formatters.money(quote.remiseExcMontant),
        boldStyle,
      ));
    }

    rows.add(_totalRow(
      'TOTAL HT NET',
      Formatters.money(quote.totalNet),
      boldStyle.copyWith(fontSize: 10.5),
      bg: netBg,
    ));

    return pw.Table(
      border: pw.TableBorder.all(color: lineGrey, width: 0.6),
      columnWidths: const {
        0: pw.FlexColumnWidth(7),
        1: pw.FlexColumnWidth(3),
      },
      children: rows,
    );
  }

  static pw.Widget _buildBottomRow(
    ProformaQuote quote,
    pw.MemoryImage sig,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.SizedBox(
          width: 155,
          child: pw.Image(sig, width: 155),
        ),
        pw.Expanded(child: pw.SizedBox()),
        _buildConditionsBlock(quote, baseStyle, boldStyle),
      ],
    );
  }

  /// Bloc SERVICE COMMERCIAL + conditions (comme image de référence).
  static pw.Widget _buildConditionsBlock(
    ProformaQuote quote,
    pw.TextStyle baseStyle,
    pw.TextStyle boldStyle,
  ) {
    const labelWidth = 148.0;
    final condStyle = baseStyle.copyWith(fontSize: 10);
    final condBold = boldStyle.copyWith(fontSize: 10);

    return pw.SizedBox(
      width: 320,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Center(
            child: pw.Text(
              'SERVICE COMMERCIAL',
              style: condBold.copyWith(
                fontStyle: pw.FontStyle.italic,
                decoration: pw.TextDecoration.underline,
                fontSize: 10.5,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          _condLine('Validité offre', quote.validiteOffre, labelWidth, condBold, condStyle),
          _condLine('Delai de livraison', quote.delaiLivraison, labelWidth, condBold, condStyle),
          _condLine(
            'Condition de règlement',
            quote.conditionReglement,
            labelWidth,
            condBold,
            condStyle,
          ),
          _condLine('Moyen de règlement', quote.moyenReglement, labelWidth, condBold, condStyle),
          _condLine('Libellé du chèque', quote.libelleCheque, labelWidth, condBold, condStyle),
        ],
      ),
    );
  }

  static pw.Widget _condLine(
    String label,
    String value,
    double labelWidth,
    pw.TextStyle labelStyle,
    pw.TextStyle valueStyle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text('$label :', style: labelStyle),
          ),
          pw.Expanded(
            child: pw.Text(
              value.isEmpty ? '—' : value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 6),
        pw.Divider(color: lineGrey, thickness: 0.5),
        pw.Text(
          'ISITEK S.A.R.L au capital de 10.000.000 F CFA - Siège social : Abidjan Cocody Angré - RCCM : CI-ABJ-2017-B-20181',
          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          'BICICI : CI006-01693-010577100067-64  contact@isitek.ci / TEL: (+225) 25 20 01 19 82 / (+225) 07 59 48 21 84',
          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  static pw.TableRow _totalRow(
    String label,
    String value,
    pw.TextStyle style, {
    PdfColor? bg,
  }) {
    return pw.TableRow(
      decoration: bg != null ? pw.BoxDecoration(color: bg) : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: pw.Text(label, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: pw.Text(value, style: style, textAlign: pw.TextAlign.right),
        ),
      ],
    );
  }

  static pw.Widget _headCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(text, style: style, textAlign: pw.TextAlign.center),
    );
  }

  static pw.Widget _cell(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    PdfColor? bg,
  }) {
    final content = pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: pw.Text(
        text,
        style: bold ? style.copyWith(fontWeight: pw.FontWeight.bold) : style,
        textAlign: align,
      ),
    );
    if (bg != null) {
      return pw.Container(color: bg, child: content);
    }
    return content;
  }

  static String _numStr(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toString();
  }
}
