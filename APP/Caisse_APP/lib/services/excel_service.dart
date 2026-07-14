import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/caisse_operation.dart';
import '../utils/formatters.dart';

/// Service de génération du Livre de Caisse Hebdomadaire au format Excel (.xlsx),
/// avec la même structure de colonnes que le document papier et le PDF.
class ExcelService {
  static Uint8List genererLivreCaisseExcel({
    required String annee,
    required String mois,
    required String semaine,
    required DateTime periodeDu,
    required DateTime periodeAu,
    required double montantOuverture,
    required List<CaisseOperation> operations,
  }) {
    final excelDoc = Excel.createExcel();
    final sheetName = 'Livre Caisse S$semaine';
    excelDoc.rename(excelDoc.getDefaultSheet()!, sheetName);
    final sheet = excelDoc[sheetName];

    // Style en-tête
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      backgroundColorHex: ExcelColor.fromHexString('#D9E1F2'),
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
    );

    final cellBorderStyle = CellStyle(
      topBorder: Border(borderStyle: BorderStyle.Thin),
      bottomBorder: Border(borderStyle: BorderStyle.Thin),
      leftBorder: Border(borderStyle: BorderStyle.Thin),
      rightBorder: Border(borderStyle: BorderStyle.Thin),
      verticalAlign: VerticalAlign.Center,
    );

    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
    );

    // Titre
    sheet.merge(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: 0));
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('LIVRE DE CAISSE HEBDOMADAIRE - ISITEK');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = titleStyle;

    // Infos période
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2)).value =
        TextCellValue('ANNEE:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2)).value =
        TextCellValue(annee);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3)).value =
        TextCellValue('MOIS:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3)).value =
        TextCellValue(mois);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).value =
        TextCellValue('SEMAINE:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4)).value =
        TextCellValue(semaine);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5)).value =
        TextCellValue('PERIODE:');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5)).value = TextCellValue(
        'DU ${Formatters.dateCourte(periodeDu)} AU ${Formatters.dateCourte(periodeAu)}');

    const headerRowIndex = 7;
    final headers = [
      'DATE',
      'N° DE PIECE',
      'NOM & PRENOMS',
      "DETAIL DE L'OPERATION",
      'ENTREE',
      'SORTIE',
      'SOLDE',
      'SIGN. DU BENEFICIAIRE',
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: headerRowIndex));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Ligne "Montant en caisse au"
    int rowIdx = headerRowIndex + 1;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).value =
        TextCellValue('Montant en caisse au: ${Formatters.dateCourte(periodeDu)}');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).value =
        DoubleCellValue(montantOuverture);
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx)).cellStyle =
          cellBorderStyle;
    }
    rowIdx++;

    // Lignes d'opérations
    for (final op in operations) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIdx)).value =
          TextCellValue(Formatters.dateCourte(op.date));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIdx)).value =
          TextCellValue(op.numPiece);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIdx)).value =
          TextCellValue(op.nomPrenoms);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIdx)).value =
          TextCellValue(op.detailOperation);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIdx)).value =
          op.entree != 0 ? DoubleCellValue(op.entree) : null;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIdx)).value =
          op.sortie != 0 ? DoubleCellValue(op.sortie) : null;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).value =
          DoubleCellValue(op.solde);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIdx)).value = null;

      for (var c = 0; c < headers.length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx)).cellStyle =
            cellBorderStyle;
      }
      rowIdx++;
    }

    // Lignes vides supplémentaires pour garder l'apparence du document papier
    final minRows = 10;
    final currentDataRows = operations.length + 1; // + ligne ouverture
    for (var i = currentDataRows; i < minRows; i++) {
      for (var c = 0; c < headers.length; c++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rowIdx)).cellStyle =
            cellBorderStyle;
      }
      rowIdx++;
    }

    rowIdx += 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).value =
        TextCellValue('Date & Signature');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIdx)).cellStyle =
        CellStyle(bold: true, underline: Underline.Single);

    // Largeurs de colonnes proportionnelles au modèle papier
    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 13);
    sheet.setColumnWidth(2, 20);
    sheet.setColumnWidth(3, 40);
    sheet.setColumnWidth(4, 14);
    sheet.setColumnWidth(5, 14);
    sheet.setColumnWidth(6, 14);
    sheet.setColumnWidth(7, 18);

    final bytes = excelDoc.encode();
    return Uint8List.fromList(bytes!);
  }
}
