import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../utils/caisse_formatters.dart';

/// Génération PDF identique à caisse_app (Livre de caisse + Fiche de contrôle).
class CaissePdfService {
  static pw.MemoryImage? _logoCache;

  /// Espace signatures manuscrites (bic) — plus grand que caisse_app (34).
  static const double _signatureSpaceHeight = 56;

  static Future<pw.MemoryImage> _getLogo() async {
    if (_logoCache != null) return _logoCache!;
    try {
      final bytes = await rootBundle.load('assets/images/logo_isitek.jpg');
      _logoCache = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      final bytes = await rootBundle.load('assets/images/logo_isitek.png');
      _logoCache = pw.MemoryImage(bytes.buffer.asUint8List());
    }
    return _logoCache!;
  }

  // ── Livre de caisse ───────────────────────────────────────────────────────

  static Future<Uint8List> genererLivreCaisse({
    required String annee,
    required String mois,
    required String semaine,
    required DateTime periodeDu,
    required DateTime periodeAu,
    required double montantOuverture,
    required List<LivreOperationPdf> operations,
    int lignesMinimum = 10,
  }) async {
    final doc = pw.Document();
    final logo = await _getLogo();

    final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
    const cellStyle = pw.TextStyle(fontSize: 9);

    final List<LivreOperationPdf?> lignes = [...operations];
    while (lignes.length < lignesMinimum) {
      lignes.add(null);
    }

    pw.Widget buildHeaderInfo() {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Text('ANNEE: ', style: headerStyle),
            pw.Text(annee, style: cellStyle),
          ]),
          pw.SizedBox(height: 2),
          pw.Row(children: [
            pw.Text('MOIS: ', style: headerStyle),
            pw.Text(mois, style: cellStyle),
          ]),
          pw.SizedBox(height: 2),
          pw.Row(children: [
            pw.Text('SEMAINE: ', style: headerStyle),
            pw.Text(semaine, style: cellStyle),
          ]),
          pw.SizedBox(height: 2),
          pw.Row(children: [
            pw.Text('PERIODE: DU ', style: headerStyle),
            pw.Text(CaisseFormatters.dateCourte(periodeDu), style: cellStyle),
            pw.Text('  AU ', style: headerStyle),
            pw.Text(CaisseFormatters.dateCourte(periodeAu), style: cellStyle),
          ]),
        ],
      );
    }

    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(1.3),
      1: const pw.FlexColumnWidth(1.3),
      2: const pw.FlexColumnWidth(1.8),
      3: const pw.FlexColumnWidth(3.6),
      4: const pw.FlexColumnWidth(1.5),
      5: const pw.FlexColumnWidth(1.5),
      6: const pw.FlexColumnWidth(1.5),
      7: const pw.FlexColumnWidth(1.6),
    };

    pw.Widget headerCell(String text) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          alignment: pw.Alignment.center,
          child: pw.Text(text, style: headerStyle, textAlign: pw.TextAlign.center),
        );

    pw.Widget dataCell(String text, {pw.TextAlign align = pw.TextAlign.center}) =>
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 3),
          alignment: align == pw.TextAlign.left
              ? pw.Alignment.centerLeft
              : pw.Alignment.center,
          height: 28,
          child: pw.Text(text, style: cellStyle, textAlign: align),
        );

    final tableBorder = pw.TableBorder.all(width: 0.7, color: PdfColors.black);

    final headerRow = pw.TableRow(children: [
      headerCell('DATE'),
      headerCell('N° DE PIECE'),
      headerCell('NOM & PRENOMS'),
      headerCell("DETAIL DE L'OPERATION"),
      headerCell('ENTREE'),
      headerCell('SORTIE'),
      headerCell('SOLDE'),
      headerCell('SIGN. DU\nBENEFICIAIRE'),
    ]);

    final ouvertureRow = pw.TableRow(children: [
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 3),
        height: 28,
        child: pw.Text(
          'Montant en caisse au: ${CaisseFormatters.dateCourte(periodeDu)}',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
      dataCell(''),
      dataCell(''),
      dataCell(''),
      dataCell(''),
      dataCell(''),
      dataCell(montantOuverture != 0 ? CaisseFormatters.montant(montantOuverture) : ''),
      dataCell(''),
    ]);

    final dataRows = lignes.map((op) {
      if (op == null) {
        return pw.TableRow(children: List.generate(8, (_) => dataCell('')));
      }
      return pw.TableRow(children: [
        dataCell(CaisseFormatters.dateCourte(op.date)),
        dataCell(op.numPiece),
        dataCell(op.nomPrenoms, align: pw.TextAlign.left),
        dataCell(op.detailOperation, align: pw.TextAlign.left),
        dataCell(op.entree != 0 ? CaisseFormatters.montant(op.entree) : ''),
        dataCell(op.sortie != 0 ? CaisseFormatters.montant(op.sortie) : ''),
        dataCell(CaisseFormatters.montant(op.solde)),
        dataCell(''),
      ]);
    }).toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Image(logo, width: 55, height: 55),
                      pw.Text('ISITEK',
                          style: pw.TextStyle(
                              fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'LIVRE  DE  CAISSE  HEBDOMADAIRE',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          decoration: pw.TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 80),
                ],
              ),
              pw.SizedBox(height: 8),
              buildHeaderInfo(),
              pw.SizedBox(height: 10),
              pw.Table(
                border: tableBorder,
                columnWidths: colWidths,
                children: [headerRow, ouvertureRow, ...dataRows],
              ),
              pw.SizedBox(height: 24),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text('Date & Signature',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                        fontSize: 10)),
              ),
              pw.SizedBox(height: 40),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> genererLivreCaisseFromApi(Map<String, dynamic> data) async {
    final lignesRaw = (data['lignes'] as List?) ?? [];
    final operations = <LivreOperationPdf>[];
    for (final raw in lignesRaw) {
      final l = Map<String, dynamic>.from(raw as Map);
      final detail = l['detail_operation']?.toString().trim() ?? '';
      final entree = CaisseFormatters.parseMontant(l['entree']?.toString() ?? '');
      final sortie = CaisseFormatters.parseMontant(l['sortie']?.toString() ?? '');
      if (detail.isEmpty && entree == 0 && sortie == 0) continue;
      operations.add(LivreOperationPdf(
        date: l['date_operation'] != null ? DateTime.parse(l['date_operation']) : null,
        numPiece: l['numero_piece']?.toString() ?? '',
        nomPrenoms: l['nom_prenoms']?.toString() ?? '',
        detailOperation: detail,
        entree: entree,
        sortie: sortie,
        solde: CaisseFormatters.parseMontant(l['solde']?.toString() ?? ''),
      ));
    }

    final periodeDu = data['periode_debut'] != null
        ? DateTime.parse(data['periode_debut'])
        : DateTime.now();
    final periodeAu = data['periode_fin'] != null
        ? DateTime.parse(data['periode_fin'])
        : periodeDu;

    return genererLivreCaisse(
      annee: data['annee']?.toString() ?? '',
      mois: CaisseFormatters.moisLabel(data['mois']),
      semaine: data['semaine']?.toString() ?? '',
      periodeDu: periodeDu,
      periodeAu: periodeAu,
      montantOuverture: CaisseFormatters.parseMontant(data['montant_caisse_valeur']?.toString() ?? ''),
      operations: operations,
    );
  }

  // ── Fiche de contrôle ─────────────────────────────────────────────────────

  static Future<Uint8List> genererFicheControle({
    required Map<String, dynamic>? ficheHaut,
    Map<String, dynamic>? ficheBas,
    int sectionsParPage = 2,
  }) async {
    final doc = pw.Document();
    final logo = await _getLogo();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Image(logo, width: 45, height: 45),
                  pw.SizedBox(width: 8),
                  pw.Text('ISITEK',
                      style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(
                        'FICHE DE CONTROLE CAISSE',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 53),
                ],
              ),
              pw.SizedBox(height: 16),
              _buildFicheBloc(ficheHaut),
              if (sectionsParPage >= 2) ...[
                pw.SizedBox(height: 18),
                _buildFicheBloc(ficheBas),
              ],
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildFicheBloc(Map<String, dynamic>? f) {
    const labelStyle = pw.TextStyle(fontSize: 10);
    const valueBoxStyle = pw.TextStyle(fontSize: 10);

    pw.Widget champLigne(String label, String valeur, {bool negatifRouge = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.SizedBox(width: 110, child: pw.Text(label, style: labelStyle)),
            pw.Container(
              width: 140,
              height: 22,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.8, color: PdfColors.black),
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                valeur,
                style: valueBoxStyle.copyWith(
                  color: negatifRouge ? PdfColors.red : PdfColors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final semaineTxt = f?['semaine']?.toString() ?? '';
    final duTxt = CaisseFormatters.dateCourte(f?['date_debut']);
    final auTxt = CaisseFormatters.dateCourte(f?['date_fin']);
    final ecartAvt = CaisseFormatters.parseMontant(f?['ecart_avt']?.toString() ?? '');
    final ecartApt = CaisseFormatters.parseMontant(f?['ecart_apt']?.toString() ?? '');

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1, color: PdfColors.black),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
            child: pw.Text(
              'Semaine $semaineTxt : du $duTxt  au  $auTxt',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                champLigne('Solde Théorique :',
                    f == null ? '' : CaisseFormatters.montant(f['solde_theorique'])),
                champLigne('Solde réel :',
                    f == null ? '' : CaisseFormatters.montant(f['solde_reel'])),
                champLigne('Ecart (AVT) :',
                    f == null ? '' : CaisseFormatters.montant(f['ecart_avt']),
                    negatifRouge: ecartAvt != 0),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Observations:',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline)),
                pw.Container(
                  width: double.infinity,
                  height: 40,
                  margin: const pw.EdgeInsets.only(top: 4),
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(f?['observations']?.toString() ?? '',
                      style: const pw.TextStyle(fontSize: 9)),
                ),
              ],
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.fromLTRB(12, 6, 12, 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(width: 1)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                champLigne('Ecart (APT) :',
                    f == null ? '' : CaisseFormatters.montant(f['ecart_apt']),
                    negatifRouge: ecartApt != 0),
                pw.SizedBox(height: 6),
                pw.Row(
                  children: [
                    pw.SizedBox(width: 110, child: pw.Text('Signatures :', style: labelStyle)),
                    pw.Expanded(
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          _sigCol('Rep. Opérations', f?['sig_rep_operations']),
                          _sigCol('Comptable', f?['sig_comptable']),
                          _sigCol('Direction', f?['sig_direction']),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sigCol(String title, dynamic name) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: _signatureSpaceHeight),
        pw.Text(title,
            style: pw.TextStyle(fontSize: 9, decoration: pw.TextDecoration.underline)),
        pw.Text(name?.toString() ?? '', style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }
}

class LivreOperationPdf {
  final DateTime? date;
  final String numPiece;
  final String nomPrenoms;
  final String detailOperation;
  final double entree;
  final double sortie;
  final double solde;

  LivreOperationPdf({
    this.date,
    this.numPiece = '',
    this.nomPrenoms = '',
    this.detailOperation = '',
    this.entree = 0,
    this.sortie = 0,
    this.solde = 0,
  });
}
