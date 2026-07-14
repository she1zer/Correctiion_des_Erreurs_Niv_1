import 'package:uuid/uuid.dart';

/// Modèle représentant une ligne de produit ou de service dans un devis.
///
/// Chaque produit possède une référence, une désignation, une quantité,
/// un prix unitaire hors taxe (PUHT) et une remise exprimée en
/// pourcentage (comme dans le modèle papier ISITEK, ex: "15%").
///
/// Le montant HT Net est calculé automatiquement à partir des autres
/// champs et n'est jamais saisi manuellement par l'utilisateur.
class ProduitModel {
  /// Identifiant unique de la ligne, utilisé pour les listes Flutter
  /// (clé de widget) et pour retrouver/supprimer une ligne précise.
  final String id;

  /// Référence interne du produit (ex: "SEC0010").
  String reference;

  /// Désignation / description du produit ou service.
  String designation;

  /// Quantité commandée.
  double quantite;

  /// Prix unitaire hors taxe.
  double prixUnitaireHT;

  /// Remise appliquée à la ligne, exprimée en pourcentage (0-100).
  double remisePourcentage;

  /// Unité de mesure (ex: U, PCE, M).
  String unite;

  ProduitModel({
    String? id,
    this.reference = '',
    this.designation = '',
    this.quantite = 0,
    this.prixUnitaireHT = 0,
    this.remisePourcentage = 0,
    this.unite = 'U',
  }) : id = id ?? const Uuid().v4();

  /// Montant brut de la ligne, avant remise : Quantité × PUHT.
  double get montantBrut => quantite * prixUnitaireHT;

  /// Valeur de la remise en Francs CFA (et non en %) pour cette ligne.
  ///
  /// remiseValeur = montantBrut × (remisePourcentage / 100)
  double get remiseValeur => montantBrut * (remisePourcentage / 100);

  /// Montant HT Net de la ligne, après application de la remise.
  ///
  /// Montant HT Net = (Quantité × PUHT) − Remise
  double get montantHTNet => montantBrut - remiseValeur;

  /// Crée une copie du produit avec éventuellement certains champs modifiés.
  ProduitModel copyWith({
    String? reference,
    String? designation,
    double? quantite,
    double? prixUnitaireHT,
    double? remisePourcentage,
    String? unite,
  }) {
    return ProduitModel(
      id: id,
      reference: reference ?? this.reference,
      designation: designation ?? this.designation,
      quantite: quantite ?? this.quantite,
      prixUnitaireHT: prixUnitaireHT ?? this.prixUnitaireHT,
      remisePourcentage: remisePourcentage ?? this.remisePourcentage,
      unite: unite ?? this.unite,
    );
  }

  /// Sérialisation en Map (utile pour debug, sauvegarde locale, etc.)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reference': reference,
      'designation': designation,
      'quantite': quantite,
      'prixUnitaireHT': prixUnitaireHT,
      'remisePourcentage': remisePourcentage,
      'unite': unite,
    };
  }

  factory ProduitModel.fromMap(Map<String, dynamic> map) {
    return ProduitModel(
      id: map['id'] as String?,
      reference: map['reference'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      quantite: (map['quantite'] as num?)?.toDouble() ?? 0,
      prixUnitaireHT: (map['prixUnitaireHT'] as num?)?.toDouble() ?? 0,
      remisePourcentage: (map['remisePourcentage'] as num?)?.toDouble() ?? 0,
      unite: map['unite'] as String? ?? 'U',
    );
  }
}
