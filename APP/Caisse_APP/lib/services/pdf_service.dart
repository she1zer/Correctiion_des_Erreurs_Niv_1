import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import '../models/caisse_operation.dart';
import '../models/fiche_controle.dart';
import '../utils/formatters.dart';

/// Service responsable de la génération des PDF identiques aux documents
/// papier ISITEK : "Livre de Caisse Hebdomadaire" et "Fiche de Contrôle Caisse".
class PdfService {
  static pw.MemoryImage? _logoCache;

  static Future<pw.MemoryImage> _getLogo() async {
    if (_logoCache != null) return _logoCache!;
    final bytes = await rootBundle.load('assets/images/logo_isitek.jpg');
    _logoCache = pw.MemoryImage(bytes.buffer.asUint8List());
    return _logoCache!;
  }

  // =====================================================================
  // LIVRE DE CAISSE HEBDOMADAIRE
  // =====================================================================

  /// Génère le PDF du Livre de Caisse Hebdomadaire, au format paysage,
  /// avec les colonnes : DATE | N° PIECE | NOM & PRENOMS | DETAIL DE
  /// L'OPERATION | ENTREE | SORTIE | SOLDE | SIGN. DU BENEFICIAIRE,
  /// identique à la maquette papier ISITEK.
  static Future<Uint8List> genererLivreCaisse({
    required String annee,
    required String mois,
    required String semaine,
    required DateTime periodeDu,
    required DateTime periodeAu,
    required double montantOuverture,
    required List<CaisseOperation> operations,
    int lignesMinimum = 10,
  }) async {
    final doc = pw.Document();
    final logo = await _getLogo();

    final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9);
    final cellStyle = const pw.TextStyle(fontSize: 9);

    // On complète avec des lignes vides pour garder l'allure du document papier
    final List<CaisseOperation?> lignes = [...operations];
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
            pw.Text(Formatters.dateCourte(periodeDu), style: cellStyle),
            pw.Text('  AU ', style: headerStyle),
            pw.Text(Formatters.dateCourte(periodeAu), style: cellStyle),
          ]),
        ],
      );
    }

    // Largeurs des colonnes proportionnelles au document original
    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(1.3), // DATE
      1: const pw.FlexColumnWidth(1.3), // N° PIECE
      2: const pw.FlexColumnWidth(1.8), // NOM & PRENOMS
      3: const pw.FlexColumnWidth(3.6), // DETAIL DE L'OPERATION
      4: const pw.FlexColumnWidth(1.5), // ENTREE
      5: const pw.FlexColumnWidth(1.5), // SORTIE
      6: const pw.FlexColumnWidth(1.5), // SOLDE
      7: const pw.FlexColumnWidth(1.6), // SIGN. DU BENEFICIAIRE
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
          'Montant en caisse au: ${Formatters.dateCourte(periodeDu)}',
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ),
      dataCell(''),
      dataCell(''),
      dataCell(''),
      dataCell(''),
      dataCell(''),
      dataCell(montantOuverture != 0 ? Formatters.montant(montantOuverture) : ''),
      dataCell(''),
    ]);

    final dataRows = lignes.map((op) {
      if (op == null) {
        return pw.TableRow(children: List.generate(8, (_) => dataCell('')));
      }
      return pw.TableRow(children: [
        dataCell(Formatters.dateCourte(op.date)),
        dataCell(op.numPiece),
        dataCell(op.nomPrenoms, align: pw.TextAlign.left),
        dataCell(op.detailOperation, align: pw.TextAlign.left),
        dataCell(op.entree != 0 ? Formatters.montant(op.entree) : ''),
        dataCell(op.sortie != 0 ? Formatters.montant(op.sortie) : ''),
        dataCell(Formatters.montant(op.solde)),
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
                  pw.SizedBox(width: 80), // équilibre visuel avec le logo
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
              // Espace généreux laissé volontairement pour la signature manuscrite à l'impression
              pw.SizedBox(height: 40),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // =====================================================================
  // FICHE DE CONTROLE CAISSE
  // =====================================================================

  /// Génère le PDF de la "Fiche de Contrôle Caisse", deux fiches par page
  /// comme dans le document original, avec large espace pour signatures
  /// manuscrites (Rep. Opérations, Comptable, Direction).
  static Future<Uint8List> genererFicheControle({
    required FicheControle fiche,
    FicheControle? ficheSuivanteVide, // pour reproduire les 2 blocs par page comme le modèle
  }) async {
    final doc = pw.Document();
    final logo = await _getLogo();

    pw.Widget buildFicheBloc(FicheControle? f, {required bool avecLogoEtTitre}) {
      final labelStyle = pw.TextStyle(fontSize: 10);
      final valueBoxStyle = const pw.TextStyle(fontSize: 10);

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

      final semaineTxt = f == null ? '' : f.semaine;
      final duTxt = f == null ? '' : Formatters.dateCourte(f.periodeDu);
      final auTxt = f == null ? '' : Formatters.dateCourte(f.periodeAu);

      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 1, color: PdfColors.black),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Bandeau "Semaine ... : du ... au ..."
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
                  champLigne('Solde Théorique :', f == null ? '' : Formatters.montant(f.soldeTheorique)),
                  champLigne('Solde réel :', f == null ? '' : Formatters.montant(f.soldeReel)),
                  champLigne('Ecart (AVT) :', f == null ? '' : Formatters.montant(f.ecartAvt),
                      negatifRouge: f != null && f.ecartAvt != 0),
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
                    child: pw.Text(f?.observations ?? '', style: const pw.TextStyle(fontSize: 9)),
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
                  champLigne('Ecart (APT) :', f == null ? '' : Formatters.montant(f.ecartApt),
                      negatifRouge: f != null && f.ecartApt != 0),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    children: [
                      pw.SizedBox(width: 110, child: pw.Text('Signatures :', style: labelStyle)),
                      pw.Expanded(
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                // Grand espace blanc réservé à la signature manuscrite
                                pw.SizedBox(height: 34),
                                pw.Text('Rep. Opérations',
                                    style: pw.TextStyle(
                                        fontSize: 9, decoration: pw.TextDecoration.underline)),
                                pw.Text(f?.repOperationsNom ?? '', style: const pw.TextStyle(fontSize: 8)),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.SizedBox(height: 34),
                                pw.Text('Comptable',
                                    style: pw.TextStyle(
                                        fontSize: 9, decoration: pw.TextDecoration.underline)),
                                pw.Text(f?.comptableNom ?? '', style: const pw.TextStyle(fontSize: 8)),
                              ],
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.SizedBox(height: 34),
                                pw.Text('Direction',
                                    style: pw.TextStyle(
                                        fontSize: 9, decoration: pw.TextDecoration.underline)),
                                pw.Text(f?.directionNom ?? '', style: const pw.TextStyle(fontSize: 8)),
                              ],
                            ),
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
              buildFicheBloc(fiche, avecLogoEtTitre: true),
              pw.SizedBox(height: 18),
              buildFicheBloc(ficheSuivanteVide, avecLogoEtTitre: false),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
