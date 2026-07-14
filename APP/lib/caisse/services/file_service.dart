import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Sauvegarde, ouverture et partage des exports PDF / Excel.
class CaisseFileService {
  static Future<File> sauvegarderFichier(Uint8List bytes, String nomFichier) async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File('${exportDir.path}/$nomFichier');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<void> ouvrirFichier(File file) async {
    await OpenFilex.open(file.path);
  }

  static Future<void> partagerFichier(File file, {String? texte}) async {
    await Share.shareXFiles([XFile(file.path)], text: texte);
  }
}
