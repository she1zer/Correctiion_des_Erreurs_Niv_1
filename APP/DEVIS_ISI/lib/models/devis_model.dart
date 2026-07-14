import 'produit_model.dart';

/// Modèle représentant un devis complet ISITEK.
///
/// Regroupe les informations d'en-tête (numéro, date, contact client),
/// la liste des produits/services, le pourcentage d'acompte ainsi que
/// les totaux financiers calculés automatiquement à partir des lignes
/// de produits.
class DevisModel {
  /// Numéro du devis (ex: "26FP1073").
  String numeroDevis;

  /// Date du devis (format libre tel qu'affiché, ex: "15/06/26").
  DateTime date;

  /// Nom du contact côté client (ex: "OUATTARA").
  String contact;

  /// Nom / raison sociale du client (zone "Vos références").
  String clientNom;

  /// Numéro de compte client (N°CC), si disponible.
  String clientNumeroCC;

  /// Référence de la demande d'achat (DA) du client.
  String clientDA;

  /// Liste des produits / services du devis.
  List<ProduitModel> listeProduits;

  /// Pourcentage d'acompte à la commande (ex: 40 pour 40%).
  double acomptePourcentage;

  /// Validité de l'offre, en texte libre (ex: "1 Mois").
  String validiteOffre;

  /// Délai de livraison global du devis (ex: "Disponible", "1 semaine").
  String delaiLivraison;

  /// Moyen de règlement (ex: "Chèque/ virement").
  String moyenReglement;

  /// Libellé du chèque (ex: "ISITEK").
  String libelleCheque;

  DevisModel({
    this.numeroDevis = '',
    DateTime? date,
    this.contact = '',
    this.clientNom = 'COTE D\'IVOIRE TERMINAL',
    this.clientNumeroCC = '',
    this.clientDA = '',
    List<ProduitModel>? listeProduits,
    this.acomptePourcentage = 40,
    this.validiteOffre = '1 Mois',
    this.delaiLivraison = 'Disponible',
    this.moyenReglement = 'Chèque/ virement',
    this.libelleCheque = 'ISITEK',
  })  : date = date ?? DateTime.now(),
        listeProduits = listeProduits ?? [];

  // ---------------------------------------------------------------------
  // Totaux calculés - jamais stockés, toujours dérivés de listeProduits
  // ---------------------------------------------------------------------

  /// Total HT Brut = Σ (Quantité × PUHT) sur toutes les lignes.
  double get totalHTBrut =>
      listeProduits.fold(0.0, (sum, p) => sum + p.montantBrut);

  /// Total Remise = Σ (remise en valeur) sur toutes les lignes.
  double get totalRemise =>
      listeProduits.fold(0.0, (sum, p) => sum + p.remiseValeur);

  /// Total HT Net = Total HT Brut − Total Remise.
  double get totalHTNet => totalHTBrut - totalRemise;

  /// Montant de l'acompte à régler à la commande, en F CFA.
  double get montantAcompte => totalHTNet * (acomptePourcentage / 100);

  Map<String, dynamic> toMap() {
    return {
      'numeroDevis': numeroDevis,
      'date': date.toIso8601String(),
      'contact': contact,
      'clientNom': clientNom,
      'clientNumeroCC': clientNumeroCC,
      'clientDA': clientDA,
      'listeProduits': listeProduits.map((p) => p.toMap()).toList(),
      'acomptePourcentage': acomptePourcentage,
      'validiteOffre': validiteOffre,
      'delaiLivraison': delaiLivraison,
      'moyenReglement': moyenReglement,
      'libelleCheque': libelleCheque,
    };
  }

  factory DevisModel.fromMap(Map<String, dynamic> map) {
    return DevisModel(
      numeroDevis: map['numeroDevis'] as String? ?? '',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      contact: map['contact'] as String? ?? '',
      clientNom: map['clientNom'] as String? ?? 'COTE D\'IVOIRE TERMINAL',
      clientNumeroCC: map['clientNumeroCC'] as String? ?? '',
      clientDA: map['clientDA'] as String? ?? '',
      listeProduits: (map['listeProduits'] as List<dynamic>? ?? [])
          .map((p) => ProduitModel.fromMap(p as Map<String, dynamic>))
          .toList(),
      acomptePourcentage:
          (map['acomptePourcentage'] as num?)?.toDouble() ?? 40,
      validiteOffre: map['validiteOffre'] as String? ?? '1 Mois',
      delaiLivraison: map['delaiLivraison'] as String? ?? 'Disponible',
      moyenReglement: map['moyenReglement'] as String? ?? 'Chèque/ virement',
      libelleCheque: map['libelleCheque'] as String? ?? 'ISITEK',
    );
  }
}
