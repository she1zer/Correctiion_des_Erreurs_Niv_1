import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;

import '../models/devis_model.dart';
import '../models/proforma_models.dart';
import 'proforma_pdf_generator.dart';

/// Génération PDF proforma ISITEK — calqué sur le modèle HTML / az.jpeg.
class PdfService {
  PdfService._();

  static Future<Uint8List> genererPdf(DevisModel devis) async {
    final logo = await _loadFirst([
      'assets/images/logo_isitek.png',
      'assets/images/logo (1).png',
    ]);
    final signature = await _loadFirst([
      'assets/images/stamp_isitek.png',
    ]);
    final partners = await _loadFirst([
      'assets/images/marques_partenaires.png',
    ]);

    if (logo == null) {
      throw StateError('Logo ISITEK introuvable dans les assets');
    }
    if (signature == null) {
      throw StateError('Cachet ISITEK introuvable dans les assets');
    }
    if (partners == null) {
      throw StateError('Bandeau partenaires introuvable dans les assets');
    }

    return ProformaPdfGenerator.generate(
      quote: ProformaQuote.fromDevis(devis),
      logoBytes: logo,
      signatureBytes: signature,
      partnersBytes: partners,
    );
  }

  static Future<Uint8List?> _loadFirst(List<String> paths) async {
    for (final path in paths) {
      try {
        final b = await rootBundle.load(path);
        return b.buffer.asUint8List();
      } catch (_) {}
    }
    return null;
  }
}
