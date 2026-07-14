import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart' show PdfGoogleFonts;
import '../models/rapport_data.dart';
import '../models/rapport_photo.dart';
import 'rapport_api_service.dart';

/// Service responsable de la construction du document PDF
/// "Rapport de visite technique" ISITEK, fidèle au modèle fourni :
/// page 1 = informations générales + tableau état des lieux + NB,
/// Bloc signature "Service Commercial" aligné à droite.
class PdfReportService {
  static const PdfColor green = PdfColor.fromInt(0xFF1B6B2C);
  static const PdfColor darkGreen = PdfColor.fromInt(0xFF114D1F);
  static const PdfColor lightGreen = PdfColor.fromInt(0xFFE7F3E9);
  static const PdfColor headerGrey = PdfColor.fromInt(0xFFD9D9D9);
  static const PdfColor borderGrey = PdfColor.fromInt(0xFFBFBFBF);
  static const PdfColor yellow = PdfColor.fromInt(0xFFFFF200);
  static const PdfColor textDark = PdfColor.fromInt(0xFF1F2A24);

  static Future<Uint8List> generate(RapportData data) async {
    final pdf = pw.Document();

    final logoBytes = await rootBundle.load('assets/images/logo_isitek.png');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final fontRegular = await PdfGoogleFonts.nunitoSansRegular();
    final fontBold = await PdfGoogleFonts.nunitoSansBold();
    final fontItalic = await PdfGoogleFonts.nunitoSansItalic();

    // ---------- PAGE(S) PRINCIPALE(S) : infos + tableau + NB ----------
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 24),
        header: (context) => _buildHeader(logoImage, fontBold, context),
        footer: (context) => _buildFooter(fontRegular, fontBold, context),
        build: (context) => [
          pw.SizedBox(height: 8),
          _titleBanner('RAPPORT DE VISITE TECHNIQUE', fontBold),
          pw.SizedBox(height: 12),
          _buildInfoTable(data, fontRegular, fontBold),
          pw.SizedBox(height: 14),
          _sectionLabel('État des lieux', fontBold),
          pw.SizedBox(height: 6),
          _buildEtatLieuxTable(data, fontRegular, fontBold),
          pw.SizedBox(height: 10),
          if (data.noteNB.trim().isNotEmpty) _buildNBBlock(data, fontRegular, fontBold),
        ],
      ),
    );

    // ---------- PAGE(S) PHOTOS + SIGNATURE ----------
    if (data.photos.isNotEmpty) {
      final photoPages = await _buildPhotoPages(
        data,
        logoImage,
        fontRegular,
        fontBold,
        fontItalic,
      );
      for (final page in photoPages) {
        pdf.addPage(page);
      }
    } else {
      // Même sans photos, on inclut la page de signature.
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 24),
          header: (context) => _buildHeader(logoImage, fontBold, context),
          footer: (context) => _buildFooter(fontRegular, fontBold, context),
          build: (context) => [
            pw.SizedBox(height: 20),
            _buildSignatureBlock(data, fontRegular, fontBold, fontItalic),
          ],
        ),
      );
    }

    return pdf.save();
  }

  // ============================================================
  // HEADER / FOOTER
  // ============================================================

  static pw.Widget _buildHeader(pw.MemoryImage logo, pw.Font fontBold, pw.Context context) {
    if (context.pageNumber > 1) {
      // En-tête simplifié pour les pages suivantes.
      return pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.SizedBox(width: 34, height: 34, child: pw.Image(logo)),
              pw.SizedBox(width: 8),
              pw.Text(
                'ISITEK',
                style: pw.TextStyle(font: fontBold, fontSize: 13, color: green),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(color: borderGrey, thickness: 0.8),
        ],
      );
    }
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.SizedBox(width: 46, height: 46, child: pw.Image(logo)),
            pw.SizedBox(width: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ISITEK',
                  style: pw.TextStyle(font: fontBold, fontSize: 17, color: green),
                ),
                pw.Text(
                  "Intégrateur de solutions industrielles",
                  style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: darkGreen),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 2.2, color: green),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font fontRegular, pw.Font fontBold, pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(color: borderGrey, thickness: 0.8),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'S.A.R.L au capital de 10.000.000 F CFA - Siège social : Abidjan Cocody Angré - RCCM : CI-ABJ-2017-B-20181',
            style: pw.TextStyle(font: fontRegular, fontSize: 6.7, color: darkGreen),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Center(
          child: pw.Text(
            'Compte bancaire BICICI : CI006-01693-010577100067-64',
            style: pw.TextStyle(font: fontRegular, fontSize: 6.7, color: darkGreen),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Center(
          child: pw.Text(
            'www.isitek.ci/ contact@isitek.ci/ TEL: (+225) 25 20 01 19 82 / (+225) 07 97 38 50 35 / (+225) 05 66 66 01 98',
            style: pw.TextStyle(font: fontRegular, fontSize: 6.7, color: darkGreen),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey600),
          ),
        ),
      ],
    );
  }

  static pw.Widget _titleBanner(String text, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      decoration: pw.BoxDecoration(
        color: yellow,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(font: fontBold, fontSize: 12, color: textDark),
        ),
      ),
    );
  }

  static pw.Widget _sectionLabel(String text, pw.Font fontBold) {
    return pw.Row(
      children: [
        pw.Container(width: 5, height: 14, color: green),
        pw.SizedBox(width: 6),
        pw.Text(
          text.toUpperCase(),
          style: pw.TextStyle(font: fontBold, fontSize: 10.5, color: darkGreen),
        ),
      ],
    );
  }

  // ============================================================
  // TABLE: INFOS GÉNÉRALES
  // ============================================================

  static pw.Widget _buildInfoTable(
    RapportData data,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    final rows = <List<String>>[
      ['Date', data.dateFormatee],
      ['Client', data.client],
      ['Correspondant technique', data.correspondantTechnique],
      ['Type de prestation', data.typePrestation],
      ['Type de bâtiment/Ouvrage', data.typeBatiment],
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: borderGrey, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.3),
        1: pw.FlexColumnWidth(2.7),
      },
      children: rows.map((r) {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(color: lightGreen),
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFC828)),
              child: pw.Text(r[0], style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: textDark)),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: PdfColors.white,
              child: pw.Text(
                r[1].isEmpty ? '-' : r[1],
                style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: textDark),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ============================================================
  // TABLE: ÉTAT DES LIEUX
  // ============================================================

  static pw.Widget _buildEtatLieuxTable(
    RapportData data,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    final nonEmptyRows = data.lignes.where((l) => !l.isEmpty).toList();
    final rowsToRender = nonEmptyRows.isEmpty ? data.lignes : nonEmptyRows;

    pw.Widget headerCell(String text) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          color: headerGrey,
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            text,
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: textDark),
          ),
        );

    pw.Widget bodyCell(String text) => pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          alignment: pw.Alignment.topLeft,
          child: pw.Text(
            text.isEmpty ? '-' : text,
            style: pw.TextStyle(font: fontRegular, fontSize: 8.8, color: textDark),
          ),
        );

    return pw.Table(
      border: pw.TableBorder.all(color: borderGrey, width: 0.7),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.1),
        1: pw.FlexColumnWidth(2.0),
        2: pw.FlexColumnWidth(1.9),
      },
      children: [
        pw.TableRow(children: [
          headerCell('SECTEUR/ZONE'),
          headerCell('ÉTAT DES LIEUX'),
          headerCell('ACTIONS CORRECTIVES'),
        ]),
        ...rowsToRender.map((row) {
          return pw.TableRow(children: [
            bodyCell(row.secteurZone),
            bodyCell(row.etatDesLieux),
            bodyCell(row.actionsCorrectives),
          ]);
        }),
      ],
    );
  }

  // ============================================================
  // NB
  // ============================================================

  static pw.Widget _buildNBBlock(RapportData data, pw.Font fontRegular, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderGrey, width: 0.7),
        color: const PdfColor.fromInt(0xFFFFF8E5),
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: 'NB : ',
              style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromInt(0xFFB23B3B)),
            ),
            pw.TextSpan(
              text: data.noteNB.trim(),
              style: pw.TextStyle(font: fontRegular, fontSize: 9, color: textDark),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SIGNATURE
  // ============================================================

  static pw.Widget _buildSignatureBlock(
    RapportData data,
    pw.Font fontRegular,
    pw.Font fontBold,
    pw.Font fontItalic,
  ) {
    final contactText = data.nomIntervenant.trim().isEmpty
        ? '+225 07 97 38 50 35'
        : data.nomIntervenant.trim();

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            'SERVICE COMMERCIAL',
            style: pw.TextStyle(font: fontBold, fontStyle: pw.FontStyle.italic, fontSize: 10.5, color: textDark),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            contactText,
            style: pw.TextStyle(font: fontBold, fontStyle: pw.FontStyle.italic, fontSize: 10.5, color: textDark),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGES PHOTOS (grille 2 colonnes, plusieurs pages si besoin)
  // ============================================================

  static Future<List<pw.Page>> _buildPhotoPages(
    RapportData data,
    pw.MemoryImage logo,
    pw.Font fontRegular,
    pw.Font fontBold,
    pw.Font fontItalic,
  ) async {
    // On charge toutes les images en mémoire en pw.MemoryImage.
    final images = <pw.MemoryImage>[];
    for (final photo in data.photos) {
      final bytes = await _photoBytes(photo);
      images.add(pw.MemoryImage(bytes));
    }

    const perPage = 4; // 2x2 grille par page, comme le modèle d'origine
    final pages = <pw.Page>[];
    final totalPages = (data.photos.length / perPage).ceil();

    for (int p = 0; p < totalPages; p++) {
      final startIdx = p * perPage;
      final endIdx = ((p + 1) * perPage).clamp(0, data.photos.length);
      final pagePhotos = data.photos.sublist(startIdx, endIdx);
      final pageImages = images.sublist(startIdx, endIdx);
      final isLastPage = p == totalPages - 1;

      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(28, 26, 28, 24),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(logo, fontBold, context),
                pw.SizedBox(height: 10),
                _titleBanner('QUELQUES IMAGES', fontBold),
                pw.SizedBox(height: 10),
                pw.Expanded(
                  child: _buildPhotoGrid(pagePhotos, pageImages, fontRegular),
                ),
                if (isLastPage) ...[
                  pw.SizedBox(height: 14),
                  _buildSignatureBlock(data, fontRegular, fontBold, fontItalic),
                ],
                pw.SizedBox(height: 10),
                _buildFooter(fontRegular, fontBold, context),
              ],
            );
          },
        ),
      );
    }

    return pages;
  }

  static pw.Widget _buildPhotoGrid(
    List<RapportPhoto> photos,
    List<pw.MemoryImage> images,
    pw.Font fontRegular,
  ) {
    // Grille 2 colonnes, lignes successives.
    final rows = <pw.Widget>[];
    for (int i = 0; i < photos.length; i += 2) {
      final hasSecond = i + 1 < photos.length;
      rows.add(
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _photoCell(photos[i].legende, images[i], fontRegular),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: hasSecond
                    ? _photoCell(photos[i + 1].legende, images[i + 1], fontRegular)
                    : pw.SizedBox(),
              ),
            ],
          ),
        ),
      );
      rows.add(pw.SizedBox(height: 10));
    }

    return pw.Column(children: rows);
  }

  static pw.Widget _photoCell(String legende, pw.MemoryImage image, pw.Font fontRegular) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderGrey, width: 0.8),
      ),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.ClipRRect(
            horizontalRadius: 2,
            verticalRadius: 2,
            child: pw.Container(
              height: 150,
              width: double.infinity,
              color: PdfColors.grey200,
              child: pw.Image(image, fit: pw.BoxFit.cover),
            ),
          ),
          if (legende.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              legende.trim(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: fontRegular, fontSize: 8, color: textDark),
            ),
          ],
        ],
      ),
    );
  }

  static Future<Uint8List> _photoBytes(RapportPhoto photo) async {
    if (photo.file != null) {
      return await photo.file!.readAsBytes();
    }
    if (photo.remotePath != null && photo.remotePath!.isNotEmpty) {
      final url = RapportApiService.instance.photoUrl(photo.remotePath!);
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('Photo introuvable ($response.statusCode)');
    }
    throw Exception('Photo sans fichier');
  }
}
