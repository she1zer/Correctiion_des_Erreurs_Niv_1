import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// Gère la sauvegarde, l'ouverture et le partage des fichiers générés
/// (PDF du Livre de Caisse, PDF de la Fiche de Contrôle, Excel).
class FileService {
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

  static Future<List<File>> listerExports() async {
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) return [];
    final files = exportDir.listSync().whereType<File>().toList();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  static Future<void> supprimerFichier(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
