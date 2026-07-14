import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/devis_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Bandeau récapitulatif des totaux du devis proforma.
class TotalsSummaryBar extends StatelessWidget {
  const TotalsSummaryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DevisProvider>(
      builder: (context, provider, _) {
        final devis = provider.devis;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.isitekNavy,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _TotalItem(label: 'HT Brut', value: Formatters.montant(devis.totalHTBrut))),
                  _divider(),
                  Expanded(child: _TotalItem(label: 'Remise', value: Formatters.montant(devis.totalRemise))),
                  _divider(),
                  Expanded(child: _TotalItem(label: 'S/Total', value: Formatters.montant(devis.sousTotal))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (devis.remiseExceptionnelleActive) ...[
                    Expanded(
                      child: _TotalItem(
                        label: 'Rem. exc. ${Formatters.pourcentage(devis.remiseExceptionnellePct)}',
                        value: Formatters.montant(devis.remiseExceptionnelleMontant),
                      ),
                    ),
                    _divider(),
                  ],
                  Expanded(
                    child: _TotalItem(
                      label: 'Total HT Net',
                      value: Formatters.montant(devis.totalHTNet),
                      highlight: true,
                    ),
                  ),
                  if (devis.conditionReglement == 'acompte') ...[
                    _divider(),
                    Expanded(
                      child: _TotalItem(
                        label: 'Acompte ${devis.acomptePourcentage}%',
                        value: Formatters.montant(devis.montantAcompte),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white24);
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
          style: const TextStyle(color: Colors.white70, fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFF6EE7A8) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
