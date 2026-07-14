import 'package:intl/intl.dart';

/// Fonctions utilitaires de formatage utilisées partout dans l'application.
class Formatters {
  static final NumberFormat _montant = NumberFormat('#,##0', 'fr_FR');
  static final DateFormat _dateCourte = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateLongue = DateFormat('dd MMMM yyyy', 'fr_FR');

  /// Formate un montant avec séparateur de milliers, ex: 12 500
  static String montant(double value) {
    if (value == 0) return '0';
    final formatted = _montant.format(value.abs());
    return value < 0 ? '-$formatted' : formatted;
  }

  /// Formate un montant avec le suffixe FCFA
  static String montantFcfa(double value) {
    return '${montant(value)} FCFA';
  }

  static String dateCourte(DateTime date) => _dateCourte.format(date);

  static String dateLongue(DateTime date) => _dateLongue.format(date);

  /// Liste des mois en français, pour les listes déroulantes
  static const List<String> moisFrancais = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  /// Parse un texte de montant saisi par l'utilisateur (gère espaces, virgules)
  static double parseMontant(String text) {
    if (text.trim().isEmpty) return 0.0;
    final cleaned = text.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }
}
