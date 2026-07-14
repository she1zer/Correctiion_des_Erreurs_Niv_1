import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

/// Gère l'enregistrement local et le partage du PDF généré.
class FileService {
  /// Enregistre les octets du PDF dans le répertoire documents de l'app
  /// et retourne le fichier créé.
  static Future<File> savePdf(Uint8List bytes, {String? clientName}) async {
    final dir = await getApplicationDocumentsDirectory();
    final safeName = (clientName ?? 'rapport')
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]+'), '_');
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'Rapport_ISITEK_${safeName}_$timestamp.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Ouvre la feuille de partage native (WhatsApp, email, Bluetooth, etc.)
  static Future<void> sharePdf(File file, {String? subject}) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject ?? 'Rapport de visite technique ISITEK',
      text: 'Veuillez trouver ci-joint le rapport de visite technique ISITEK.',
    );
  }
}
