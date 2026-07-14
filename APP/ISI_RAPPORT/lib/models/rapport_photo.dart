import 'dart:io';
import 'package:uuid/uuid.dart';

/// Représente une photo ajoutée au rapport, avec sa légende optionnelle.
class RapportPhoto {
  final String id;
  final File file;
  String legende;

  RapportPhoto({
    String? id,
    required this.file,
    this.legende = '',
  }) : id = id ?? const Uuid().v4();
}
