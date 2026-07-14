/// Étapes standard du workflow demande client ISITEK (12 étapes).
class DemandeStepDef {
  final int number;
  final String label;
  final String actor; // 'vous', 'Isitek', 'client'
  final String status;

  const DemandeStepDef({
    required this.number,
    required this.label,
    required this.actor,
    required this.status,
  });

  String get displayLabel => 'Étape $number : $label - $actor';
}

class DemandeSteps {
  DemandeSteps._();

  static const List<DemandeStepDef> standard = [
    DemandeStepDef(number: 1, label: 'Expression du besoin', actor: 'vous', status: 'recue'),
    DemandeStepDef(number: 2, label: 'Visiter le site', actor: 'Isitek', status: 'visite_site'),
    DemandeStepDef(number: 3, label: 'Offre commerciale (devis)', actor: 'Isitek', status: 'devis_propose'),
    DemandeStepDef(number: 4, label: 'Réception de la commande', actor: 'vous', status: 'reception_bc'),
    DemandeStepDef(number: 5, label: 'Avance (accompte)', actor: 'vous', status: 'avance_accompte'),
    DemandeStepDef(number: 6, label: 'Préparation de la commande', actor: 'Isitek', status: 'preparation_commande'),
    DemandeStepDef(number: 7, label: 'Livraison de la commande', actor: 'Isitek', status: 'livraison_bl'),
    DemandeStepDef(number: 8, label: 'Facturation', actor: 'Isitek', status: 'depot_facture'),
    DemandeStepDef(number: 9, label: 'Règlement', actor: 'vous', status: 'reglement_cheque'),
    DemandeStepDef(number: 10, label: 'Affaire terminée', actor: 'Isitek', status: 'affaire_terminee'),
    DemandeStepDef(number: 11, label: 'SAV - garantie', actor: 'Isitek', status: 'sav_garantie'),
    DemandeStepDef(number: 12, label: 'Retour satisfaction', actor: 'client', status: 'retour_satisfaction'),
  ];

  /// Statuts intermédiaires mappés sur l'étape 1.
  static const Map<String, int> _statusToStep = {
    'recue': 1,
    'analyse': 1,
    'visite_site': 2,
    'devis_propose': 3,
    'reception_bc': 4,
    'travaux_planifies': 4,
    'avance_accompte': 5,
    'preparation_commande': 6,
    'livraison_bl': 7,
    'depot_facture': 8,
    'reglement_cheque': 9,
    'affaire_terminee': 10,
    'sav_garantie': 11,
    'retour_satisfaction': 12,
    'termine': 12,
  };

  static int stepIndexForStatus(String statut) => _statusToStep[statut] ?? 1;

  static DemandeStepDef? stepForStatus(String statut) {
    final idx = stepIndexForStatus(statut);
    if (idx < 1 || idx > standard.length) return null;
    return standard[idx - 1];
  }

  static String statusForStep(int stepNumber) {
    if (stepNumber < 1 || stepNumber > standard.length) return 'recue';
    return standard[stepNumber - 1].status;
  }

  static Set<int> parseSkipped(String? raw) {
    if (raw == null || raw.trim().isEmpty) return {};
    return raw.split(',').map((s) => int.tryParse(s.trim())).whereType<int>().toSet();
  }

  static String encodeSkipped(Set<int> skipped) {
    final list = skipped.toList()..sort();
    return list.join(',');
  }

  static List<DemandeStepDef> visibleSteps(Set<int> skipped, {bool forClient = false}) {
    return standard.where((s) => !skipped.contains(s.number)).toList();
  }

  static String? nextStatus(String current, Set<int> skipped) {
    final currentStep = stepIndexForStatus(current);
    for (var i = currentStep + 1; i <= standard.length; i++) {
      if (!skipped.contains(i)) return statusForStep(i);
    }
    return null;
  }

  /// À partir de l'étape 3, l'admin peut envoyer le résumé au chat.
  static bool canSendResumeToChat(String statut) => stepIndexForStatus(statut) >= 3;

  static bool canGenerateInvoice(String statut) => stepIndexForStatus(statut) >= 8;
}
