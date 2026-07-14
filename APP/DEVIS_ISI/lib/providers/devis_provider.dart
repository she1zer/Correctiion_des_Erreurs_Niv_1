import 'package:flutter/foundation.dart';
import '../models/devis_model.dart';
import '../models/produit_model.dart';

/// Provider central de l'application.
///
/// Gère le cycle de vie complet d'un [DevisModel] : modification des
/// informations d'en-tête, ajout/suppression/édition des lignes de
/// produits, et changement du pourcentage d'acompte.
///
/// Toute modification appelle [notifyListeners] afin que l'aperçu du
/// devis et les totaux se mettent à jour instantanément dans l'UI
/// (exigence "calculs en temps réel").
class DevisProvider extends ChangeNotifier {
  DevisModel _devis = DevisModel();

  DevisModel get devis => _devis;

  List<ProduitModel> get produits => _devis.listeProduits;

  // ---------------------------------------------------------------------
  // En-tête du devis
  // ---------------------------------------------------------------------

  void updateNumeroDevis(String value) {
    _devis.numeroDevis = value;
    notifyListeners();
  }

  void updateDate(DateTime value) {
    _devis.date = value;
    notifyListeners();
  }

  void updateContact(String value) {
    _devis.contact = value;
    notifyListeners();
  }

  void updateClientNom(String value) {
    _devis.clientNom = value;
    notifyListeners();
  }

  void updateClientNumeroCC(String value) {
    _devis.clientNumeroCC = value;
    notifyListeners();
  }

  void updateClientDA(String value) {
    _devis.clientDA = value;
    notifyListeners();
  }

  void updateValiditeOffre(String value) {
    _devis.validiteOffre = value;
    notifyListeners();
  }

  void updateDelaiLivraison(String value) {
    _devis.delaiLivraison = value;
    notifyListeners();
  }

  void updateMoyenReglement(String value) {
    _devis.moyenReglement = value;
    notifyListeners();
  }

  void updateLibelleCheque(String value) {
    _devis.libelleCheque = value;
    notifyListeners();
  }

  /// Met à jour le pourcentage d'acompte à la commande (ex: 30, 40, 50).
  void updateAcomptePourcentage(double value) {
    _devis.acomptePourcentage = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Gestion des produits (lignes du devis)
  // ---------------------------------------------------------------------

  /// Ajoute une nouvelle ligne de produit vide à la fin de la liste.
  void ajouterProduit() {
    _devis.listeProduits.add(ProduitModel());
    notifyListeners();
  }

  /// Supprime la ligne de produit correspondant à [id].
  void supprimerProduit(String id) {
    _devis.listeProduits.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Supprime toutes les lignes de produits.
  void supprimerTousLesProduits() {
    _devis.listeProduits.clear();
    notifyListeners();
  }

  /// Met à jour la référence d'une ligne de produit.
  void updateReference(String id, String value) {
    _trouverProduit(id)?.reference = value;
    notifyListeners();
  }

  /// Met à jour la désignation d'une ligne de produit.
  void updateDesignation(String id, String value) {
    _trouverProduit(id)?.designation = value;
    notifyListeners();
  }

  /// Met à jour la quantité d'une ligne de produit.
  ///
  /// Toute valeur invalide (négative) est ignorée afin de garantir
  /// la cohérence des calculs (validation des champs numériques).
  void updateQuantite(String id, double value) {
    if (value < 0) return;
    _trouverProduit(id)?.quantite = value;
    notifyListeners();
  }

  /// Met à jour le prix unitaire hors taxe d'une ligne de produit.
  void updatePrixUnitaireHT(String id, double value) {
    if (value < 0) return;
    _trouverProduit(id)?.prixUnitaireHT = value;
    notifyListeners();
  }

  /// Met à jour le pourcentage de remise d'une ligne de produit.
  ///
  /// La remise est bornée entre 0 et 100 % pour éviter des montants
  /// négatifs incohérents dans le devis.
  void updateRemisePourcentage(String id, double value) {
    final clamped = value.clamp(0, 100).toDouble();
    _trouverProduit(id)?.remisePourcentage = clamped;
    notifyListeners();
  }

  /// Réordonne deux lignes (utile pour glisser-déposer si besoin).
  void reordonnerProduits(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _devis.listeProduits.removeAt(oldIndex);
    _devis.listeProduits.insert(newIndex, item);
    notifyListeners();
  }

  /// Réinitialise complètement le devis (nouveau devis vierge).
  void nouveauDevis() {
    _devis = DevisModel();
    notifyListeners();
  }

  ProduitModel? _trouverProduit(String id) {
    for (final p in _devis.listeProduits) {
      if (p.id == id) return p;
    }
    return null;
  }
}
