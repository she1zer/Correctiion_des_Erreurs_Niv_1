import 'package:uuid/uuid.dart';

/// Représente une ligne du tableau "État des lieux" du rapport :
/// Secteur/Zone | État des lieux | Actions correctives
class EtatLieuxRow {
  final String id;
  String secteurZone;
  String etatDesLieux;
  String actionsCorrectives;

  EtatLieuxRow({
    String? id,
    this.secteurZone = '',
    this.etatDesLieux = '',
    this.actionsCorrectives = '',
  }) : id = id ?? const Uuid().v4();

  bool get isEmpty =>
      secteurZone.trim().isEmpty &&
      etatDesLieux.trim().isEmpty &&
      actionsCorrectives.trim().isEmpty;
}
