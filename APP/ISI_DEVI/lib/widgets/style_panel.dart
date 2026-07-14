// lib/widgets/style_panel.dart
import 'package:flutter/material.dart';
import '../models.dart';

class StylePanel extends StatelessWidget {
  final StyleDevis style;
  final ValueChanged<StyleDevis> onChanged;

  const StylePanel({super.key, required this.style, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final zones = [
      _Zone('Objet demande',              'obj'),
      _Zone('Infos client',               'client'),
      _Zone('Date / Affaire / Ref',       'meta'),
      _Zone('Articles',                   'articles'),
      _Zone('Totaux financiers',          'finance'),
      _Zone('Conditions commerciales',    'terms'),
    ];

    return Column(
      children: zones.map((z) => _buildZone(z)).toList(),
    );
  }

  Widget _buildZone(_Zone z) {
    final bold  = _getBold(z.id);
    final upper = _getUpper(z.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: const Color(0xFFE0EAFF)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            z.label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF1E40AF),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ToggleTile(
                  label: 'Gras',
                  icon: Icons.format_bold,
                  value: bold,
                  onChanged: (v) => _setBold(z.id, v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ToggleTile(
                  label: 'MAJUSCULES',
                  icon: Icons.text_fields,
                  value: upper,
                  onChanged: (v) => _setUpper(z.id, v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _getBold(String id) {
    switch (id) {
      case 'obj':      return style.objBold;
      case 'client':   return style.clientBold;
      case 'meta':     return style.metaBold;
      case 'articles': return style.articlesBold;
      case 'finance':  return style.financeBold;
      case 'terms':    return style.termsBold;
      default: return false;
    }
  }

  bool _getUpper(String id) {
    switch (id) {
      case 'obj':      return style.objUpper;
      case 'client':   return style.clientUpper;
      case 'meta':     return style.metaUpper;
      case 'articles': return style.articlesUpper;
      case 'finance':  return style.financeUpper;
      case 'terms':    return style.termsUpper;
      default: return false;
    }
  }

  void _setBold(String id, bool v) {
    switch (id) {
      case 'obj':      onChanged(style.copyWith(objBold: v));
      case 'client':   onChanged(style.copyWith(clientBold: v));
      case 'meta':     onChanged(style.copyWith(metaBold: v));
      case 'articles': onChanged(style.copyWith(articlesBold: v));
      case 'finance':  onChanged(style.copyWith(financeBold: v));
      case 'terms':    onChanged(style.copyWith(termsBold: v));
    }
  }

  void _setUpper(String id, bool v) {
    switch (id) {
      case 'obj':      onChanged(style.copyWith(objUpper: v));
      case 'client':   onChanged(style.copyWith(clientUpper: v));
      case 'meta':     onChanged(style.copyWith(metaUpper: v));
      case 'articles': onChanged(style.copyWith(articlesUpper: v));
      case 'finance':  onChanged(style.copyWith(financeUpper: v));
      case 'terms':    onChanged(style.copyWith(termsUpper: v));
    }
  }
}

class _Zone {
  final String label;
  final String id;
  const _Zone(this.label, this.id);
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF1E40AF) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value
                ? const Color(0xFF1E40AF)
                : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: value ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: value ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
