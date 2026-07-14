/// Fonctions utilitaires de formatage partagées entre l'UI et le PDF.
///
/// NB: le formatage des nombres est fait manuellement (sans dépendre de
/// `NumberFormat` localisé) afin d'éviter tout besoin d'appeler
/// `initializeDateFormatting`/données ICU au démarrage de l'app.
class Formatters {
  Formatters._();

  /// Ajoute un séparateur de milliers "espace" à un entier positif,
  /// comme utilisé dans le modèle ISITEK (ex: 30600000 -> "30 600 000").
  static String _separateurMilliers(int value) {
    final str = value.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
    }
    return (value < 0 ? '-' : '') + buffer.toString();
  }

  /// Formate un montant en Francs CFA, ex: 30600000 -> "30 600 000 F CFA".
  static String montantCFA(double value) {
    final formatted = _separateurMilliers(value.round());
    return '$formatted F CFA';
  }

  /// Formate un montant sans le suffixe de devise, ex: "30 600 000".
  static String montant(double value) {
    return _separateurMilliers(value.round());
  }

  /// Formate un pourcentage, ex: 15 -> "15%".
  static String pourcentage(double value) {
    if (value == value.roundToDouble()) {
      return '${value.round()}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }

  /// Formate une date au format jj/mm/aa, comme dans le modèle ISITEK
  /// (ex: 15/06/26).
  static String dateCourte(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yy = (date.year % 100).toString().padLeft(2, '0');
    return '$dd/$mm/$yy';
  }

  /// Formate une date complète pour affichage dans les sélecteurs
  /// (ex: 15 juin 2026).
  static String dateLongue(DateTime date) {
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}
