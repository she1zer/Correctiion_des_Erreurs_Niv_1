import 'package:flutter/foundation.dart';
import '../models/devis_model.dart';
import '../models/produit_model.dart';
import '../utils/formatters.dart';

/// Provider central du module devis proforma ISITEK.
class DevisProvider extends ChangeNotifier {
  DevisModel _devis = DevisModel();
  int? _savedDevisId;

  DevisModel get devis => _devis;
  int? get savedDevisId => _savedDevisId;
  List<ProduitModel> get produits => _devis.listeProduits;

  void updateNumeroDevis(String value) {
    _devis.numeroDevis = value;
    notifyListeners();
  }

  void updateDate(DateTime value) {
    _devis.date = value;
    notifyListeners();
  }

  void updateAffaireSuiviePar(String value) {
    _devis.affaireSuiviePar = value;
    notifyListeners();
  }

  void updateRefDemande(String value) {
    _devis.refDemande = value;
    notifyListeners();
  }

  void updateClientNom(String value) {
    _devis.clientNom = value;
    notifyListeners();
  }

  void updateContact(String value) {
    _devis.contact = value;
    notifyListeners();
  }

  void updateTelephone(String value) {
    _devis.telephone = value;
    notifyListeners();
  }

  void updateObjetDemande(String value) {
    _devis.objetDemande = value;
    notifyListeners();
  }

  void updateRemiseExceptionnelleActive(bool value) {
    _devis.remiseExceptionnelleActive = value;
    notifyListeners();
  }

  void updateRemiseExceptionnellePct(double value) {
    _devis.remiseExceptionnellePct = value.clamp(0, 100).toDouble();
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

  void updateConditionReglement(String value) {
    _devis.conditionReglement = value;
    notifyListeners();
  }

  void updateAcomptePourcentage(double value) {
    _devis.acomptePourcentage = value.round();
    notifyListeners();
  }

  void ajouterProduit() {
    _devis.listeProduits.add(ProduitModel(unite: 'U'));
    notifyListeners();
  }

  void supprimerProduit(String id) {
    _devis.listeProduits.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void supprimerTousLesProduits() {
    _devis.listeProduits.clear();
    notifyListeners();
  }

  void updateReference(String id, String value) {
    _trouverProduit(id)?.reference = value;
    notifyListeners();
  }

  void updateDesignation(String id, String value) {
    _trouverProduit(id)?.designation = value;
    notifyListeners();
  }

  void updateUnite(String id, String value) {
    _trouverProduit(id)?.unite = value.isEmpty ? 'U' : value;
    notifyListeners();
  }

  void updateQuantite(String id, double value) {
    if (value < 0) return;
    _trouverProduit(id)?.quantite = value;
    notifyListeners();
  }

  void updatePrixUnitaireHT(String id, double value) {
    if (value < 0) return;
    _trouverProduit(id)?.prixUnitaireHT = value;
    notifyListeners();
  }

  void updateRemisePourcentage(String id, double value) {
    _trouverProduit(id)?.remisePourcentage = value.clamp(0, 100).toDouble();
    notifyListeners();
  }

  void applySearchResult(String productId, Map<String, dynamic> result, {String? fallbackReference}) {
    final ref = result['reference'] as String? ?? fallbackReference ?? '';
    if (ref.isNotEmpty) updateReference(productId, ref.toUpperCase());

    final title = (result['title'] as String?)?.trim() ?? '';
    final snippet = (result['snippet'] as String?)?.trim() ?? '';
    if (title.isNotEmpty) {
      updateDesignation(productId, snippet.isNotEmpty ? '$title\n$snippet' : title);
    }

    final price = (result['price'] as num?)?.toDouble();
    if (price != null && price > 0) updatePrixUnitaireHT(productId, price);
  }

  void reordonnerProduits(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _devis.listeProduits.removeAt(oldIndex);
    _devis.listeProduits.insert(newIndex, item);
    notifyListeners();
  }

  void setSavedDevisId(int id) {
    _savedDevisId = id;
    notifyListeners();
  }

  void nouveauDevis() {
    _devis = DevisModel();
    _savedDevisId = null;
    notifyListeners();
  }

  void loadFromAnalysis({
    required List<String> references,
    String? clientNom,
    String? contact,
    String? refDemande,
    Map<String, String>? suggestedDesignations,
    String? numeroDevis,
    String? objetDemande,
  }) {
    _devis = DevisModel(
      numeroDevis: numeroDevis ?? _devis.numeroDevis,
      clientNom: clientNom ?? _devis.clientNom,
      contact: contact ?? _devis.contact,
      refDemande: refDemande ?? _devis.refDemande,
      objetDemande: objetDemande ?? _devis.objetDemande,
    );
    _devis.listeProduits.clear();
    for (final ref in references) {
      _devis.listeProduits.add(
        ProduitModel(
          reference: ref,
          designation: suggestedDesignations?[ref] ?? '',
          quantite: 1,
          unite: 'U',
        ),
      );
    }
    notifyListeners();
  }

  void setNumeroDevis(String value) => updateNumeroDevis(value);

  Map<String, dynamic> toApiPayload({int? demandeId, String? emailMessageId, String? emailSubject, String? emailFrom}) {
    return {
      'numero_devis': _devis.numeroDevis,
      'contact': _devis.contact,
      'client_nom': _devis.clientNom,
      'client_numero_cc': _devis.telephone,
      'client_da': _devis.refDemande,
      'affaire_suivie_par': _devis.affaireSuiviePar,
      'ref_demande': _devis.refDemande,
      'telephone': _devis.telephone,
      'objet_demande': _devis.objetDemande,
      'remise_exceptionnelle_active': _devis.remiseExceptionnelleActive,
      'remise_exceptionnelle_pct': _devis.remiseExceptionnellePct,
      'acompte_pourcentage': _devis.acomptePourcentage,
      'validite_offre': _devis.validiteOffre,
      'delai_livraison': _devis.delaiLivraison,
      'moyen_reglement': _devis.moyenReglement,
      'libelle_cheque': _devis.libelleCheque,
      'condition_reglement': _devis.conditionReglement,
      if (demandeId != null) 'demande_id': demandeId,
      if (emailMessageId != null) 'email_message_id': emailMessageId,
      if (emailSubject != null) 'email_subject': emailSubject,
      if (emailFrom != null) 'email_from': emailFrom,
      'lignes': _devis.listeProduits.map((p) => {
        'reference': p.reference,
        'designation': p.designation,
        'quantite': p.quantite,
        'prix_unitaire_ht': p.prixUnitaireHT,
        'remise_pourcentage': p.remisePourcentage,
        'unite': p.unite,
      }).toList(),
    };
  }

  void loadFromSaved(Map<String, dynamic> data) {
    _devis = DevisModel(
      numeroDevis: data['numero_devis'] as String? ?? '',
      date: data['date_devis'] != null
          ? DateTime.tryParse(data['date_devis'].toString()) ?? DateTime.now()
          : DateTime.now(),
      affaireSuiviePar: data['affaire_suivie_par'] as String? ?? 'Amadou OUATTARA',
      refDemande: data['ref_demande'] as String? ?? data['client_da'] as String? ?? 'N/A',
      clientNom: data['client_nom'] as String? ?? '',
      contact: data['contact'] as String? ?? '',
      telephone: data['telephone'] as String? ?? data['client_numero_cc'] as String? ?? '',
      objetDemande: data['objet_demande'] as String? ?? '',
      remiseExceptionnelleActive: data['remise_exceptionnelle_active'] as bool? ?? true,
      remiseExceptionnellePct: (data['remise_exceptionnelle_pct'] as num?)?.toDouble() ?? 10,
      validiteOffre: data['validite_offre'] as String? ?? '1 mois',
      delaiLivraison: data['delai_livraison'] as String? ?? '1 semaine',
      moyenReglement: data['moyen_reglement'] as String? ?? 'Chèque/Virement',
      libelleCheque: data['libelle_cheque'] as String? ?? 'ISITEK',
      conditionReglement: data['condition_reglement'] as String? ?? 'habituelles',
      acomptePourcentage: (data['acompte_pourcentage'] as num?)?.toInt() ?? 40,
    );
    _devis.listeProduits.clear();
    for (final raw in (data['lignes'] as List<dynamic>? ?? [])) {
      if (raw is! Map) continue;
      _devis.listeProduits.add(
        ProduitModel(
          reference: raw['reference'] as String? ?? '',
          designation: raw['designation'] as String? ?? '',
          quantite: (raw['quantite'] as num?)?.toDouble() ?? 0,
          prixUnitaireHT: (raw['prix_unitaire_ht'] as num?)?.toDouble() ?? 0,
          remisePourcentage: (raw['remise_pourcentage'] as num?)?.toDouble() ?? 0,
          unite: raw['unite'] as String? ?? 'U',
        ),
      );
    }
    _savedDevisId = data['id'] as int?;
    notifyListeners();
  }

  /// Payload pour génération Excel/PDF (modèle az.jpeg).
  Map<String, dynamic> toRenderPayload() {
    return {
      'numero_devis': _devis.numeroDevis,
      'date_emission': Formatters.dateProforma(_devis.date),
      'affaire_suivie_par': _devis.affaireSuiviePar,
      'ref_demande': _devis.refDemande,
      'contact': _devis.contact,
      'client_nom': _devis.clientNom,
      'telephone': _devis.telephone,
      'objet_demande': _devis.objetDemande,
      'validite_offre': _devis.validiteOffre,
      'delai_livraison': _devis.delaiLivraison,
      'moyen_reglement': _devis.moyenReglement,
      'libelle_cheque': _devis.libelleCheque,
      'condition_reglement': _devis.conditionReglement,
      'acompte_pourcentage': _devis.acomptePourcentage,
      'remise_exceptionnelle_active': _devis.remiseExceptionnelleActive,
      'remise_exceptionnelle_pct': _devis.remiseExceptionnellePct,
      'lignes': _devis.listeProduits.map((p) => {
        'reference': p.reference,
        'designation': p.designation,
        'quantite': p.quantite,
        'prix_unitaire_ht': p.prixUnitaireHT,
        'remise_pourcentage': p.remisePourcentage,
        'unite': p.unite,
      }).toList(),
    };
  }

  ProduitModel? _trouverProduit(String id) {
    for (final p in _devis.listeProduits) {
      if (p.id == id) return p;
    }
    return null;
  }
}
