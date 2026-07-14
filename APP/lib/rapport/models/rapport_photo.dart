import 'dart:io';

import 'package:uuid/uuid.dart';

/// Photo du rapport : fichier local (nouveau) ou chemin serveur (enregistré).
class RapportPhoto {
  final String id;
  File? file;
  String? remotePath;
  String legende;
  final bool isNew;

  RapportPhoto({
    String? id,
    this.file,
    this.remotePath,
    this.legende = '',
    this.isNew = false,
  }) : id = id ?? const Uuid().v4();

  bool get needsUpload => file != null && (isNew || remotePath == null);

  factory RapportPhoto.fromRemote({required String path, String legende = ''}) {
    return RapportPhoto(remotePath: path, legende: legende);
  }

  factory RapportPhoto.fromLocal(File file) {
    return RapportPhoto(file: file, isNew: true);
  }
}
