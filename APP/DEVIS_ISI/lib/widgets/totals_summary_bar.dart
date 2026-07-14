import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/devis_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Bandeau récapitulatif affichant les trois totaux du devis :
/// Total HT Brut, Total Remise et Total HT Net.
///
/// Se met à jour instantanément grâce au [DevisProvider] (Consumer),
/// satisfaisant l'exigence de recalcul en temps réel.
class TotalsSummaryBar extends StatelessWidget {
  const TotalsSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DevisProvider>(
      builder: (context, provider, _) {
        final devis = provider.devis;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColors.isitekNavy,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TotalItem(
                  label: 'Total HT Brut',
                  value: Formatters.montantCFA(devis.totalHTBrut),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _TotalItem(
                  label: 'Total Remise',
                  value: Formatters.montantCFA(devis.totalRemise),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _TotalItem(
                  label: 'Total HT Net',
                  value: Formatters.montantCFA(devis.totalHTNet),
                  highlight: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TotalItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _TotalItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFF6EE7A8) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
