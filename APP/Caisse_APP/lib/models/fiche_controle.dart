/// Modèle représentant une "Fiche de Contrôle Caisse" hebdomadaire ISITEK.
/// Reproduit les champs : Semaine, Période, Solde Théorique, Solde réel,
/// Écart (AVT), Observations, Écart (APT), Signatures (Rep. Opérations, Comptable, Direction).
class FicheControle {
  final int? id;
  final String semaine; // ex: "16"
  final DateTime periodeDu;
  final DateTime periodeAu;

  final double soldeTheorique;
  final double soldeReel;
  final double ecartAvt; // écart avant régularisation = soldeReel - soldeTheorique
  final String observations;
  final double ecartApt; // écart après régularisation/observations

  // Signatures : on stocke juste si signé + nom, le tracé est manuscrit à l'impression
  final String repOperationsNom;
  final String comptableNom;
  final String directionNom;

  FicheControle({
    this.id,
    required this.semaine,
    required this.periodeDu,
    required this.periodeAu,
    required this.soldeTheorique,
    required this.soldeReel,
    required this.ecartAvt,
    required this.observations,
    required this.ecartApt,
    this.repOperationsNom = '',
    this.comptableNom = '',
    this.directionNom = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'semaine': semaine,
      'periodeDu': periodeDu.toIso8601String(),
      'periodeAu': periodeAu.toIso8601String(),
      'soldeTheorique': soldeTheorique,
      'soldeReel': soldeReel,
      'ecartAvt': ecartAvt,
      'observations': observations,
      'ecartApt': ecartApt,
      'repOperationsNom': repOperationsNom,
      'comptableNom': comptableNom,
      'directionNom': directionNom,
    };
  }

  factory FicheControle.fromMap(Map<String, dynamic> map) {
    return FicheControle(
      id: map['id'] as int?,
      semaine: map['semaine'] as String,
      periodeDu: DateTime.parse(map['periodeDu'] as String),
      periodeAu: DateTime.parse(map['periodeAu'] as String),
      soldeTheorique: (map['soldeTheorique'] as num).toDouble(),
      soldeReel: (map['soldeReel'] as num).toDouble(),
      ecartAvt: (map['ecartAvt'] as num).toDouble(),
      observations: map['observations'] as String,
      ecartApt: (map['ecartApt'] as num).toDouble(),
      repOperationsNom: map['repOperationsNom'] as String? ?? '',
      comptableNom: map['comptableNom'] as String? ?? '',
      directionNom: map['directionNom'] as String? ?? '',
    );
  }

  FicheControle copyWith({
    int? id,
    String? semaine,
    DateTime? periodeDu,
    DateTime? periodeAu,
    double? soldeTheorique,
    double? soldeReel,
    double? ecartAvt,
    String? observations,
    double? ecartApt,
    String? repOperationsNom,
    String? comptableNom,
    String? directionNom,
  }) {
    return FicheControle(
      id: id ?? this.id,
      semaine: semaine ?? this.semaine,
      periodeDu: periodeDu ?? this.periodeDu,
      periodeAu: periodeAu ?? this.periodeAu,
      soldeTheorique: soldeTheorique ?? this.soldeTheorique,
      soldeReel: soldeReel ?? this.soldeReel,
      ecartAvt: ecartAvt ?? this.ecartAvt,
      observations: observations ?? this.observations,
      ecartApt: ecartApt ?? this.ecartApt,
      repOperationsNom: repOperationsNom ?? this.repOperationsNom,
      comptableNom: comptableNom ?? this.comptableNom,
      directionNom: directionNom ?? this.directionNom,
    );
  }
}
