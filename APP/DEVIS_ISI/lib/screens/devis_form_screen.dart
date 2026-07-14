import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/devis_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/conditions_reglement_form.dart';
import '../widgets/devis_header_form.dart';
import '../widgets/produit_form_card.dart';
import '../widgets/totals_summary_bar.dart';
import 'devis_preview_screen.dart';

/// Écran principal de l'application : formulaire complet de saisie
/// d'un devis (en-tête, lignes de produits, conditions de règlement),
/// avec un bandeau de totaux toujours visible et un bouton flottant
/// pour accéder à l'aperçu / export PDF.
class DevisFormScreen extends StatelessWidget {
  const DevisFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau devis ISITEK'),
        actions: [
          IconButton(
            tooltip: 'Nouveau devis vierge',
            icon: const Icon(Icons.note_add_outlined),
            onPressed: () => _confirmerNouveauDevis(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DevisHeaderForm(),
                  const SizedBox(height: 24),
                  _buildProduitsSection(context),
                  const SizedBox(height: 24),
                  const ConditionsReglementForm(),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DevisPreviewScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Voir l\'aperçu et exporter en PDF'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.isitekNavy,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            child: TotalsSummaryBar(),
          ),
        ),
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
                      fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  '${produits.length} référence(s)',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (produits.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 36, color: AppColors.textSecondary),
                    SizedBox(height: 10),
                    Text(
                      'Aucune référence ajoutée',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: provider.ajouterProduit,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une référence'),
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
            'Voulez-vous démarrer un nouveau devis vierge ? Les données actuelles seront perdues.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmer == true) {
      provider.nouveauDevis();
    }
  }
}
