/// Modèle représentant une ligne du "Livre de Caisse Hebdomadaire".
/// Reproduit fidèlement les colonnes du document papier ISITEK :
/// DATE | N° DE PIECE | NOM & PRENOMS | DETAIL DE L'OPERATION | ENTREE | SORTIE | SOLDE | SIGN. DU BENEFICIAIRE
class CaisseOperation {
  final int? id;
  final String annee; // ex: "2026"
  final String mois; // ex: "Avril"
  final String semaine; // ex: "16"
  final DateTime periodeDu;
  final DateTime periodeAu;

  final DateTime date; // date de l'opération (ligne)
  final String numPiece;
  final String nomPrenoms;
  final String detailOperation;
  final double entree; // montant entrée (0 si vide)
  final double sortie; // montant sortie (0 si vide)
  final double solde; // solde après l'opération
  final bool signataireOk; // simple indicateur (signature manuscrite à l'impression)

  /// Ligne spéciale "Montant en caisse au .../.../..." (solde d'ouverture de la semaine)
  final bool estSoldeOuverture;

  CaisseOperation({
    this.id,
    required this.annee,
    required this.mois,
    required this.semaine,
    required this.periodeDu,
    required this.periodeAu,
    required this.date,
    required this.numPiece,
    required this.nomPrenoms,
    required this.detailOperation,
    required this.entree,
    required this.sortie,
    required this.solde,
    this.signataireOk = false,
    this.estSoldeOuverture = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'annee': annee,
      'mois': mois,
      'semaine': semaine,
      'periodeDu': periodeDu.toIso8601String(),
      'periodeAu': periodeAu.toIso8601String(),
      'date': date.toIso8601String(),
      'numPiece': numPiece,
      'nomPrenoms': nomPrenoms,
      'detailOperation': detailOperation,
      'entree': entree,
      'sortie': sortie,
      'solde': solde,
      'signataireOk': signataireOk ? 1 : 0,
      'estSoldeOuverture': estSoldeOuverture ? 1 : 0,
    };
  }

  factory CaisseOperation.fromMap(Map<String, dynamic> map) {
    return CaisseOperation(
      id: map['id'] as int?,
      annee: map['annee'] as String,
      mois: map['mois'] as String,
      semaine: map['semaine'] as String,
      periodeDu: DateTime.parse(map['periodeDu'] as String),
      periodeAu: DateTime.parse(map['periodeAu'] as String),
      date: DateTime.parse(map['date'] as String),
      numPiece: map['numPiece'] as String,
      nomPrenoms: map['nomPrenoms'] as String,
      detailOperation: map['detailOperation'] as String,
      entree: (map['entree'] as num).toDouble(),
      sortie: (map['sortie'] as num).toDouble(),
      solde: (map['solde'] as num).toDouble(),
      signataireOk: (map['signataireOk'] as int) == 1,
      estSoldeOuverture: (map['estSoldeOuverture'] as int) == 1,
    );
  }

  CaisseOperation copyWith({
    int? id,
    String? annee,
    String? mois,
    String? semaine,
    DateTime? periodeDu,
    DateTime? periodeAu,
    DateTime? date,
    String? numPiece,
    String? nomPrenoms,
    String? detailOperation,
    double? entree,
    double? sortie,
    double? solde,
    bool? signataireOk,
    bool? estSoldeOuverture,
  }) {
    return CaisseOperation(
      id: id ?? this.id,
      annee: annee ?? this.annee,
      mois: mois ?? this.mois,
      semaine: semaine ?? this.semaine,
      periodeDu: periodeDu ?? this.periodeDu,
      periodeAu: periodeAu ?? this.periodeAu,
      date: date ?? this.date,
      numPiece: numPiece ?? this.numPiece,
      nomPrenoms: nomPrenoms ?? this.nomPrenoms,
      detailOperation: detailOperation ?? this.detailOperation,
      entree: entree ?? this.entree,
      sortie: sortie ?? this.sortie,
      solde: solde ?? this.solde,
      signataireOk: signataireOk ?? this.signataireOk,
      estSoldeOuverture: estSoldeOuverture ?? this.estSoldeOuverture,
    );
  }
}
