import 'produit_model.dart';

/// Modèle représentant un devis proforma ISITEK (format PROFORMA).
class DevisModel {
  String numeroDevis;
  DateTime date;
  String affaireSuiviePar;
  String refDemande;
  String clientNom;
  String contact;
  String telephone;
  String objetDemande;
  List<ProduitModel> listeProduits;
  bool remiseExceptionnelleActive;
  double remiseExceptionnellePct;
  String validiteOffre;
  String delaiLivraison;
  String moyenReglement;
  String libelleCheque;
  String conditionReglement; // 'habituelles' ou 'acompte'
  int acomptePourcentage;

  DevisModel({
    this.numeroDevis = '',
    DateTime? date,
    this.affaireSuiviePar = 'Amadou OUATTARA',
    this.refDemande = 'N/A',
    this.clientNom = '',
    this.contact = '',
    this.telephone = '',
    this.objetDemande = '',
    List<ProduitModel>? listeProduits,
    this.remiseExceptionnelleActive = true,
    this.remiseExceptionnellePct = 10,
    this.validiteOffre = '1 mois',
    this.delaiLivraison = '1 semaine',
    this.moyenReglement = 'Chèque/Virement',
    this.libelleCheque = 'ISITEK',
    this.conditionReglement = 'habituelles',
    this.acomptePourcentage = 40,
  })  : date = date ?? DateTime.now(),
        listeProduits = listeProduits ?? [];

  double get totalHTBrut =>
      listeProduits.fold(0.0, (sum, p) => sum + p.montantBrut);

  double get totalRemise =>
      listeProduits.fold(0.0, (sum, p) => sum + p.remiseValeur);

  double get sousTotal => totalHTBrut - totalRemise;

  double get remiseExceptionnelleMontant =>
      remiseExceptionnelleActive ? sousTotal * (remiseExceptionnellePct / 100) : 0;

  double get totalHTNet => sousTotal - remiseExceptionnelleMontant;

  double get montantAcompte => totalHTNet * (acomptePourcentage / 100);

  /// Libellé affiché sur le PDF / Excel.
  String get conditionReglementLabel => conditionReglement == 'acompte'
      ? 'Acompte $acomptePourcentage%'
      : 'Conditions habituelles';

  Map<String, dynamic> toMap() {
    return {
      'numeroDevis': numeroDevis,
      'date': date.toIso8601String(),
      'affaireSuiviePar': affaireSuiviePar,
      'refDemande': refDemande,
      'clientNom': clientNom,
      'contact': contact,
      'telephone': telephone,
      'objetDemande': objetDemande,
      'listeProduits': listeProduits.map((p) => p.toMap()).toList(),
      'remiseExceptionnelleActive': remiseExceptionnelleActive,
      'remiseExceptionnellePct': remiseExceptionnellePct,
      'validiteOffre': validiteOffre,
      'delaiLivraison': delaiLivraison,
      'moyenReglement': moyenReglement,
      'libelleCheque': libelleCheque,
      'conditionReglement': conditionReglement,
      'acomptePourcentage': acomptePourcentage,
    };
  }

  factory DevisModel.fromMap(Map<String, dynamic> map) {
    return DevisModel(
      numeroDevis: map['numeroDevis'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      affaireSuiviePar: map['affaireSuiviePar'] as String? ?? 'Amadou OUATTARA',
      refDemande: map['refDemande'] as String? ?? map['clientDA'] as String? ?? 'N/A',
      clientNom: map['clientNom'] as String? ?? '',
      contact: map['contact'] as String? ?? '',
      telephone: map['telephone'] as String? ?? map['clientNumeroCC'] as String? ?? '',
      objetDemande: map['objetDemande'] as String? ?? '',
      listeProduits: (map['listeProduits'] as List<dynamic>? ?? [])
          .map((p) => ProduitModel.fromMap(p as Map<String, dynamic>))
          .toList(),
      remiseExceptionnelleActive: map['remiseExceptionnelleActive'] as bool? ?? false,
      remiseExceptionnellePct:
          (map['remiseExceptionnellePct'] as num?)?.toDouble() ?? 10,
      validiteOffre: map['validiteOffre'] as String? ?? '1 mois',
      delaiLivraison: map['delaiLivraison'] as String? ?? '1 semaine',
      moyenReglement: map['moyenReglement'] as String? ?? 'Chèque/Virement',
      libelleCheque: map['libelleCheque'] as String? ?? 'ISITEK',
      conditionReglement: map['conditionReglement'] as String? ?? 'habituelles',
      acomptePourcentage:
          (map['acomptePourcentage'] as num?)?.toInt() ?? 40,
    );
  }
}
