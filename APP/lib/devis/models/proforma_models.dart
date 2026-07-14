import 'devis_model.dart';
import 'produit_model.dart';

/// Ligne article pour le PDF proforma (modèle HTML / ProformaPdfGenerator).
class ProformaItem {
  final String code;
  final String description;
  final String unit;
  final double qte;
  final double prixUnit;
  final double remisePct;

  const ProformaItem({
    this.code = '',
    this.description = '',
    this.unit = 'U',
    this.qte = 0,
    this.prixUnit = 0,
    this.remisePct = 0,
  });

  factory ProformaItem.fromProduit(ProduitModel p) => ProformaItem(
        code: p.reference,
        description: p.designation,
        unit: p.unite,
        qte: p.quantite,
        prixUnit: p.prixUnitaireHT,
        remisePct: p.remisePourcentage,
      );

  double get brut => qte * prixUnit;

  double get remiseMontant => brut * (remisePct / 100);

  double get net => brut - remiseMontant;
}

/// Données complètes d'un devis proforma pour génération PDF.
class ProformaQuote {
  final String proformaNum;
  final String attClient;
  final String contactNom;
  final String contactPhone;
  final DateTime dateEmission;
  final String affaireSuivie;
  final String refDemande;
  final String objetDemande;
  final List<ProformaItem> items;
  final bool remiseExcEnabled;
  final double remiseExcPct;
  final String validiteOffre;
  final String delaiLivraison;
  final String conditionReglement;
  final String moyenReglement;
  final String libelleCheque;

  const ProformaQuote({
    this.proformaNum = '',
    this.attClient = '',
    this.contactNom = '',
    this.contactPhone = '',
    required this.dateEmission,
    this.affaireSuivie = '',
    this.refDemande = 'N/A',
    this.objetDemande = '',
    this.items = const [],
    this.remiseExcEnabled = false,
    this.remiseExcPct = 10,
    this.validiteOffre = '1 mois',
    this.delaiLivraison = '1 semaine',
    this.conditionReglement = 'Conditions habituelles',
    this.moyenReglement = 'Chèque/Virement',
    this.libelleCheque = 'ISITEK',
  });

  factory ProformaQuote.fromDevis(DevisModel d) => ProformaQuote(
        proformaNum: d.numeroDevis,
        attClient: d.clientNom,
        contactNom: d.contact,
        contactPhone: d.telephone,
        dateEmission: d.date,
        affaireSuivie: d.affaireSuiviePar,
        refDemande: d.refDemande,
        objetDemande: d.objetDemande,
        items: d.listeProduits.map(ProformaItem.fromProduit).toList(),
        remiseExcEnabled: d.remiseExceptionnelleActive,
        remiseExcPct: d.remiseExceptionnellePct,
        validiteOffre: d.validiteOffre,
        delaiLivraison: d.delaiLivraison,
        conditionReglement: d.conditionReglementLabel,
        moyenReglement: d.moyenReglement,
        libelleCheque: d.libelleCheque,
      );

  double get totalBrut =>
      items.fold(0.0, (sum, it) => sum + it.brut);

  double get totalRemiseCommerciale =>
      items.fold(0.0, (sum, it) => sum + it.remiseMontant);

  double get sousTotalHT => totalBrut - totalRemiseCommerciale;

  double get remiseExcMontant =>
      remiseExcEnabled ? sousTotalHT * (remiseExcPct / 100) : 0;

  double get totalNet => sousTotalHT - remiseExcMontant;
}
