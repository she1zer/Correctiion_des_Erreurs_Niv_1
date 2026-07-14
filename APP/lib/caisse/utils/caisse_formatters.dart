import 'package:intl/intl.dart';

/// Formatage montants et dates (aligné caisse_app).
class CaisseFormatters {
  static final NumberFormat _montant = NumberFormat('#,##0', 'fr_FR');
  static final DateFormat _dateCourte = DateFormat('dd/MM/yyyy');

  static String montant(dynamic value) {
    final n = parseMontant(value?.toString() ?? '');
    if (n == 0) return '0';
    final formatted = _montant.format(n.abs());
    return n < 0 ? '-$formatted' : formatted;
  }

  static String montantFcfa(dynamic value) => '${montant(value)} FCFA';

  static String dateCourte(dynamic v) {
    if (v == null || v.toString().isEmpty) return '';
    final d = DateTime.tryParse(v.toString());
    if (d == null) return v.toString();
    return _dateCourte.format(d);
  }

  static double parseMontant(String text) {
    if (text.trim().isEmpty) return 0.0;
    final cleaned = text.replaceAll(' ', '').replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

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

  static String moisLabel(dynamic mois) {
    if (mois == null) return '';
    final n = int.tryParse(mois.toString());
    if (n != null && n >= 1 && n <= 12) return moisFrancais[n - 1];
    return mois.toString();
  }

  static int? moisIndex(String label) {
    final i = moisFrancais.indexOf(label);
    return i >= 0 ? i + 1 : null;
  }
}
