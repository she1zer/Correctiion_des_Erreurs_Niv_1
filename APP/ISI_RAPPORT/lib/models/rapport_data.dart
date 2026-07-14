import 'package:intl/intl.dart';
import 'etat_lieux_row.dart';
import 'rapport_photo.dart';

/// Modèle central du rapport de visite technique ISITEK.
/// Regroupe toutes les informations saisies dans le formulaire.
class RapportData {
  DateTime date;
  String client;
  String correspondantTechnique;
  String typePrestation;
  String typeBatiment;

  List<EtatLieuxRow> lignes;

  String noteNB;

  List<RapportPhoto> photos;

  String nomIntervenant;

  RapportData({
    DateTime? date,
    this.client = '',
    this.correspondantTechnique = '',
    this.typePrestation = '',
    this.typeBatiment = '',
    List<EtatLieuxRow>? lignes,
    this.noteNB = '',
    List<RapportPhoto>? photos,
    this.nomIntervenant = '',
  })  : date = date ?? DateTime.now(),
        lignes = lignes ?? [EtatLieuxRow()],
        photos = photos ?? [];

  String get dateFormatee => DateFormat('dd/MM/yyyy').format(date);

  /// Vérifie que les champs essentiels sont remplis avant génération du PDF.
  String? validate() {
    if (client.trim().isEmpty) {
      return "Le nom du client est obligatoire.";
    }
    if (correspondantTechnique.trim().isEmpty) {
      return "Le correspondant technique est obligatoire.";
    }
    if (typePrestation.trim().isEmpty) {
      return "Le type de prestation est obligatoire.";
    }
    final hasContent = lignes.any((l) => !l.isEmpty);
    if (!hasContent) {
      return "Veuillez remplir au moins une ligne de l'état des lieux.";
    }
    return null;
  }
}
