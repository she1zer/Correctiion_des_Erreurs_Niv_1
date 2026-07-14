import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/devis_provider.dart';
import '../services/devis_api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/conditions_reglement_form.dart';
import '../widgets/devis_header_form.dart';
import '../widgets/produit_form_card.dart';
import '../widgets/devis_calculator_sheet.dart';
import '../widgets/totals_summary_bar.dart';
import 'devis_preview_screen.dart';

/// Formulaire de saisie du devis — conçu pour être affiché dans un onglet
/// (sans Scaffold imbriqué, qui provoquait l'écran bleu vide).
class DevisFormScreen extends StatefulWidget {
  const DevisFormScreen({super.key});

  @override
  State<DevisFormScreen> createState() => _DevisFormScreenState();
}

class _DevisFormScreenState extends State<DevisFormScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initDevis());
  }

  Future<void> _initDevis() async {
    final provider = context.read<DevisProvider>();
    if (provider.produits.isEmpty) {
      provider.ajouterProduit();
    }
    if (provider.devis.numeroDevis.isNotEmpty) return;
    try {
      final numero = await DevisApiService.instance.nextDevisNumber();
      if (mounted) provider.setNumeroDevis(numero);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('API hors ligne — saisissez le n° manuellement.\n$e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: TotalsSummaryBar(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Nouveau devis proforma',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Calculatrice devis',
                        icon: const Icon(Icons.calculate_outlined, color: AppColors.isitekGreen),
                        onPressed: () => DevisCalculatorSheet.show(context),
                      ),
                      IconButton(
                        tooltip: 'Nouveau devis vierge',
                        icon: const Icon(Icons.note_add_outlined, color: AppColors.isitekGreen),
                        onPressed: () => _confirmerNouveauDevis(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const DevisHeaderForm(),
                  const SizedBox(height: 20),
                  _buildProduitsSection(context),
                  const SizedBox(height: 20),
                  const ConditionsReglementForm(),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChangeNotifierProvider.value(
                            value: context.read<DevisProvider>(),
                            child: const DevisPreviewScreen(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Aperçu & export PDF'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.isitekGreen,
                      minimumSize: const Size(double.infinity, 52),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProduitsSection(BuildContext context) {
    return Consumer<DevisProvider>(
      builder: (context, provider, _) {
        final produits = provider.produits;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Détail du devis',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${produits.length} article(s)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (produits.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 8),
                    Text('Aucun article — ajoutez une ligne ci-dessous',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: produits.length,
                itemBuilder: (context, index) {
                  return ProduitFormCard(
                    key: ValueKey(produits[index].id),
                    produit: produits[index],
                    index: index,
                  );
                },
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: provider.ajouterProduit,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un article'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.isitekGreen.withOpacity(0.12),
                  foregroundColor: AppColors.isitekGreenDark,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmerNouveauDevis(BuildContext context) async {
    final provider = context.read<DevisProvider>();
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouveau devis'),
        content: const Text(
          'Démarrer un devis vierge ? Les données actuelles seront perdues.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmer == true) {
      provider.nouveauDevis();
      provider.ajouterProduit();
      _initDevis();
    }
  }
}
