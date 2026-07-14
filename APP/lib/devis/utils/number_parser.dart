/// Parse les nombres saisis au format français (espaces, virgule décimale).
class NumberParser {
  NumberParser._();

  static double? parse(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty) return null;
    s = s.replaceAll(RegExp(r'\s'), '');
    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '.');
    }
    return double.tryParse(s);
  }
}
