// lib/widgets/article_card.dart
import 'package:flutter/material.dart';
import '../models.dart';

class ArticleCard extends StatelessWidget {
  final int index;
  final LigneArticle ligne;
  final Map<String, TextEditingController> controllers;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const ArticleCard({
    super.key,
    required this.index,
    required this.ligne,
    required this.controllers,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final qte      = double.tryParse(controllers['qte']!.text) ?? 0;
    final prixUnit = double.tryParse(controllers['prixUnit']!.text) ?? 0;
    final remise   = double.tryParse(controllers['remise']!.text) ?? 0;
    final totHT    = qte * prixUnit * (1 - remise / 100);
    final showTot  = qte > 0 && prixUnit > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Article $index',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF),
                  fontSize: 13,
                ),
              ),
              if (canRemove)
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 14),
                  label: const Text('Retirer'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEE2E2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Item + Description
          Row(
            children: [
              SizedBox(
                width: 90,
                child: _field('Item / Réf', controllers['item']!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _field('Description', controllers['description']!),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Unite + Qte + Prix + Remise
          Row(
            children: [
              SizedBox(
                width: 60,
                child: _field('Unité', controllers['unite']!),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: _numField('Qté', controllers['qte']!),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numField('Prix Unit.', controllers['prixUnit']!),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: _numField('Remise %', controllers['remise']!),
              ),
            ],
          ),

          if (showTot) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Prix Tot. HT = ${_fmt(totHT)} F CFA',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E3A8A),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _numField(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      onChanged: (_) => onChanged(),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.right,
      decoration: InputDecoration(
        labelText: label,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  String _fmt(double n) {
    if (n == 0) return '0';
    return n.round().toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}\u00a0',
        );
  }
}
