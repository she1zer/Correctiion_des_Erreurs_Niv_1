import '../models/etat_lieux_row.dart';
import '../models/rapport_data.dart';
import '../models/rapport_photo.dart';

/// Conversion API ↔ modèles rapport de visite.
class RapportMapper {
  static RapportData fromApi(Map<String, dynamic> json) {
    final lignesRaw = (json['lignes'] as List?) ?? [];
    final lignes = lignesRaw.map((l) {
      final m = Map<String, dynamic>.from(l as Map);
      return EtatLieuxRow(
        secteurZone: (m['secteur_zone'] ?? '') as String,
        etatDesLieux: (m['etat_des_lieux'] ?? '') as String,
        actionsCorrectives: (m['actions_correctives'] ?? '') as String,
      );
    }).toList();
    if (lignes.isEmpty) lignes.add(EtatLieuxRow());

    final photosRaw = (json['photos'] as List?) ?? [];
    final photos = photosRaw.map((p) {
      final m = Map<String, dynamic>.from(p as Map);
      return RapportPhoto.fromRemote(
        path: (m['path'] ?? '') as String,
        legende: (m['legende'] ?? '') as String,
      );
    }).toList();

    final dateStr = json['date_visite'] as String?;
    DateTime date = DateTime.now();
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr) ?? date;
    }

    return RapportData(
      date: date,
      client: (json['client'] ?? '') as String,
      correspondantTechnique: (json['correspondant_technique'] ?? '') as String,
      typePrestation: (json['type_prestation'] ?? '') as String,
      typeBatiment: (json['type_batiment'] ?? '') as String,
      noteNB: (json['note_nb'] ?? '') as String,
      nomIntervenant: (json['nom_intervenant'] ?? '') as String,
      lignes: lignes,
      photos: photos,
    );
  }

  static Map<String, dynamic> toApiBody(RapportData data) {
    return {
      'date_visite': data.date.toIso8601String(),
      'client': data.client.trim(),
      'correspondant_technique': data.correspondantTechnique.trim(),
      'type_prestation': data.typePrestation.trim(),
      'type_batiment': data.typeBatiment.trim(),
      'note_nb': data.noteNB,
      'nom_intervenant': data.nomIntervenant.trim(),
      'lignes': data.lignes
          .where((l) => !l.isEmpty)
          .map((l) => {
                'secteur_zone': l.secteurZone,
                'etat_des_lieux': l.etatDesLieux,
                'actions_correctives': l.actionsCorrectives,
              })
          .toList(),
    };
  }

  static List<Map<String, String>> remotePhotosPayload(List<RapportPhoto> photos) {
    return photos
        .where((p) => p.remotePath != null && p.remotePath!.isNotEmpty)
        .map((p) => {'path': p.remotePath!, 'legende': p.legende})
        .toList();
  }
}
