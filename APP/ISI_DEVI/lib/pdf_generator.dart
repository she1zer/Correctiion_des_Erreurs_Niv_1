// lib/pdf_generator.dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models.dart';

String fmtNum(double n) {
  if (n == 0) return '';
  final f = NumberFormat('#,###', 'fr_FR');
  return f.format(n.round()).replaceAll(',', '\u00a0');
}

String applyUpper(String text, bool upper) =>
    upper ? text.toUpperCase() : text;

pw.FontWeight applyBold(bool bold) =>
    bold ? pw.FontWeight.bold : pw.FontWeight.normal;

Future<Uint8List> generateDevisPDF(DevisData d) async {
  final pdf = pw.Document();

  // Load assets
  final logoBytes   = await rootBundle.load('assets/logo.png');
  final stampBytes  = await rootBundle.load('assets/stamp.png');
  final brandsBytes = await rootBundle.load('assets/brands.png');

  final logoImg   = pw.MemoryImage(logoBytes.buffer.asUint8List());
  final stampImg  = pw.MemoryImage(stampBytes.buffer.asUint8List());
  final brandsImg = pw.MemoryImage(brandsBytes.buffer.asUint8List());

  final grey     = PdfColor.fromHex('#D8D8D8');
  final red      = PdfColor.fromHex('#CC0000');
  final black    = PdfColors.black;
  final darkGrey = PdfColor.fromHex('#333333');

  final st = d.style;

  // ── Border style ──
  pw.TableBorder tableBorder() => pw.TableBorder.all(
        color: darkGrey,
        width: 0.5,
      );

  pw.TextStyle ts({
    double size = 9,
    bool bold = false,
    PdfColor? color,
    bool italic = false,
  }) =>
      pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
        color: color ?? black,
      );

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 20),
      build: (ctx) {
        final rows = d.lignes.map((l) => l).toList();
        final termRows = [
          ['Validité offre', d.vld],
          ['Delai de livraison', d.dlv],
          ['Condition de règlement', 'Conditions habituelles'],
          ['Moyen de règlement', 'Chèque/Virement'],
          ['Libellé du chèque', 'ISITEK'],
          ['Devise', 'Franc CFA (XOF)'],
        ];

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── LOGO ──
            pw.Image(logoImg, height: 65),
            pw.SizedBox(height: 10),

            // ── PROFORMA BAR ──
            pw.Container(
              width: double.infinity,
              color: grey,
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('PROFORMA   ',
                      style: ts(size: 13, bold: true)),
                  pw.Text(d.num,
                      style: ts(size: 13, bold: true, color: red)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),

            // ── CLIENT BLOCK (right aligned) ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(child: pw.SizedBox()),
                pw.SizedBox(
                  width: 270,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('A l\'attention de:',
                          style: ts(size: 9), textAlign: pw.TextAlign.right),
                      pw.Text(
                        applyUpper(d.att, st.clientUpper),
                        style: ts(size: 9, bold: st.clientBold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 3),
                      pw.Table(
                        border: tableBorder(),
                        columnWidths: {
                          0: const pw.FixedColumnWidth(70),
                          1: const pw.FlexColumnWidth(),
                        },
                        children: [
                          pw.TableRow(children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text('Contact',
                                  style: ts(size: 9, bold: true)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                applyUpper(d.cont, st.clientUpper),
                                style: ts(size: 9, bold: st.clientBold),
                              ),
                            ),
                          ]),
                          pw.TableRow(children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text('Phone',
                                  style: ts(size: 9, bold: true)),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(3),
                              child: pw.Text(
                                applyUpper(d.tel, st.clientUpper),
                                style: ts(size: 9, bold: st.clientBold),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 6),

            // ── META ──
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                        text: 'DATE EMISSION: ',
                        style: ts(size: 9, bold: true)),
                    pw.TextSpan(
                        text: d.date,
                        style: ts(size: 9, bold: true, color: red)),
                  ]),
                ),
                pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                        text: 'AFFAIRE SUIVIE PAR: ',
                        style: ts(size: 9, bold: true)),
                    pw.TextSpan(
                        text: applyUpper(d.suivi, st.metaUpper),
                        style: ts(size: 9, bold: st.metaBold)),
                  ]),
                ),
                pw.RichText(
                  text: pw.TextSpan(children: [
                    pw.TextSpan(
                        text: 'REF DEMANDE: ',
                        style: ts(size: 9, bold: true)),
                    pw.TextSpan(
                        text: applyUpper(d.ref, st.metaUpper),
                        style: ts(size: 9, bold: true, color: red)),
                  ]),
                ),
              ],
            ),
            pw.SizedBox(height: 6),

            // ── OBJET BAR ──
            pw.Container(
              width: double.infinity,
              color: grey,
              padding: const pw.EdgeInsets.symmetric(
                  vertical: 4, horizontal: 6),
              child: pw.RichText(
                text: pw.TextSpan(children: [
                  pw.TextSpan(
                      text: 'OBJET DEMANDE: ',
                      style: ts(size: 9, bold: true, color: red)),
                  pw.TextSpan(
                      text: applyUpper(d.obj, st.objUpper),
                      style:
                          ts(size: 9, bold: st.objBold)),
                ]),
              ),
            ),
            pw.SizedBox(height: 8),

            // ── ARTICLES TABLE ──
            pw.Table(
              border: tableBorder(),
              columnWidths: {
                0: const pw.FixedColumnWidth(45),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FixedColumnWidth(30),
                3: const pw.FixedColumnWidth(28),
                4: const pw.FixedColumnWidth(60),
                5: const pw.FixedColumnWidth(38),
                6: const pw.FixedColumnWidth(60),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: grey),
                  children: [
                    'Item', 'DESCRIPTION', 'Unit', 'Qté',
                    'Prix Unit\n(F CFA)', 'REMISE', 'Prix Tot. HT\n(F CFA)'
                  ].map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Text(h,
                        style: ts(size: 8, bold: true, italic: true),
                        textAlign: pw.TextAlign.center),
                  )).toList(),
                ),

                // Article rows
                ...rows.map((r) => pw.TableRow(
                  children: [
                    _cell(applyUpper(r.item, st.articlesUpper),
                        bold: st.articlesBold, align: pw.TextAlign.center),
                    _cell(applyUpper(r.description, st.articlesUpper),
                        bold: st.articlesBold),
                    _cell(r.unite, align: pw.TextAlign.center),
                    _cell(r.qte > 0 ? r.qte.toStringAsFixed(r.qte == r.qte.roundToDouble() ? 0 : 1) : '',
                        align: pw.TextAlign.center),
                    _cell(r.prixUnit > 0 ? fmtNum(r.prixUnit) : '',
                        align: pw.TextAlign.right),
                    _cell(r.remise > 0 ? '${r.remise.toStringAsFixed(0)}%' : '',
                        align: pw.TextAlign.center),
                    _cell(r.prixTotHT > 0 ? fmtNum(r.prixTotHT) : '',
                        align: pw.TextAlign.right),
                  ],
                )),

                // Finance rows
                _finRow('TOTAL HT BRUT', fmtNum(d.totalBrut),
                    bold: st.financeBold, upper: st.financeUpper),
                _finRow('TOTAL REMISE COMMERCIALE', fmtNum(d.totalRemise),
                    bold: st.financeBold, upper: st.financeUpper),
                _finRow('S/TOTAL HT', fmtNum(d.sousTotal),
                    bold: st.financeBold, upper: st.financeUpper),
                if (d.rxOn)
                  _finRow(
                    'REMISE EXCEPTIONNELLE (${d.rxPct.toStringAsFixed(0)}%)',
                    fmtNum(d.remExcMontant),
                    bold: st.financeBold,
                    upper: st.financeUpper,
                    bgColor: grey,
                  ),
                _finRow('TOTAL HT NET', fmtNum(d.totalNet),
                    bold: st.financeBold, upper: st.financeUpper),
              ],
            ),
            pw.SizedBox(height: 5),

            // ── SERVICE COMMERCIAL ──
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('SERVICE COMMERCIAL',
                  style: ts(
                      size: 8.5,
                      bold: true,
                      italic: true)),
            ),
            pw.SizedBox(height: 6),

            // ── STAMP + TERMS ──
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 170,
                  child: pw.Image(stampImg),
                ),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 16),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: termRows.map((row) {
                        final k = st.termsUpper
                            ? row[0].toUpperCase()
                            : row[0];
                        final v = st.termsUpper
                            ? row[1].toUpperCase()
                            : row[1];
                        return pw.Padding(
                          padding:
                              const pw.EdgeInsets.symmetric(vertical: 1.5),
                          child: pw.Row(
                            children: [
                              pw.SizedBox(
                                width: 130,
                                child: pw.Text(k,
                                    style: ts(size: 8.5, bold: st.termsBold)),
                              ),
                              pw.Text(v,
                                  style:
                                      ts(size: 8.5, bold: st.termsBold)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // ── BRANDS ──
            pw.Image(brandsImg, width: double.infinity),
            pw.SizedBox(height: 8),

            // ── FOOTER ──
            pw.Divider(color: darkGrey, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'ISITEK S.A.R.L au capital de 10.000.000 F CFA - Siège social : Abidjan Cocody Angré - RCCM : CI-ABJ-2017-B-20181',
                    style: ts(size: 7, color: darkGrey),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'BICICI : CI006-01693-010577100067-64 contact@isitek.ci/ TEL: (+225) 25 20 01 19 82 / (+225) 07 59 48 21 84',
                    style: ts(size: 7, color: darkGrey),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _cell(
  String text, {
  bool bold = false,
  pw.TextAlign align = pw.TextAlign.left,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 8.5,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
      textAlign: align,
    ),
  );
}

pw.TableRow _finRow(
  String label,
  String value, {
  bool bold = true,
  bool upper = true,
  PdfColor? bgColor,
}) {
  final lbl = upper ? label.toUpperCase() : label;
  return pw.TableRow(
    decoration: bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
    children: [
      pw.TableCell(
        columnSpan: 4,
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(lbl,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ),
      pw.TableCell(
        columnSpan: 3,
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ),
    ],
  );
}
