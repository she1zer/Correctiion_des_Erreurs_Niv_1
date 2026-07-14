import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/produit_model.dart';
import '../providers/devis_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/number_parser.dart';
import '../widgets/devis_calculator_sheet.dart';
import '../widgets/product_search_sheet.dart';

/// Carte de saisie pour une ligne de produit/service du devis.
///
/// Affiche les champs Référence, Désignation, Quantité, PUHT et Remise,
/// avec validation des champs numériques, ainsi que le montant HT Net
/// calculé en temps réel et un bouton de suppression de la ligne.
class ProduitFormCard extends StatefulWidget {
  final ProduitModel produit;
  final int index;

  const ProduitFormCard({
    super.key,
    required this.produit,
    required this.index,
  });

  @override
  State<ProduitFormCard> createState() => _ProduitFormCardState();
}

class _ProduitFormCardState extends State<ProduitFormCard> {
  late TextEditingController _refCtrl;
  late TextEditingController _designationCtrl;
  late TextEditingController _uniteCtrl;
  late TextEditingController _quantiteCtrl;
  late TextEditingController _prixCtrl;
  late TextEditingController _remiseCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.produit;
    _refCtrl = TextEditingController(text: p.reference);
    _designationCtrl = TextEditingController(text: p.designation);
    _uniteCtrl = TextEditingController(text: p.unite);
    _quantiteCtrl =
        TextEditingController(text: p.quantite == 0 ? '' : _trim(p.quantite));
    _prixCtrl = TextEditingController(
        text: p.prixUnitaireHT == 0 ? '' : _trim(p.prixUnitaireHT));
    _remiseCtrl = TextEditingController(
        text: p.remisePourcentage == 0 ? '' : _trim(p.remisePourcentage));
  }

  String _trim(double value) {
    if (value == value.roundToDouble()) return value.round().toString();
    return value.toString();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _designationCtrl.dispose();
    _uniteCtrl.dispose();
    _quantiteCtrl.dispose();
    _prixCtrl.dispose();
    _remiseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DevisProvider>();
    final p = widget.produit;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.isitekGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Article',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary),
                  ),
                ),
                IconButton(
                  tooltip: 'Supprimer cet article',
                  icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                  onPressed: () => _confirmerSuppression(context, provider, p.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rechercherProduit(context, provider, p),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Rechercher'),
                ),
                OutlinedButton.icon(
                  onPressed: () => openExternalUrl(
                    'https://www.google.com/search?tbm=shop&q=${Uri.encodeComponent(_refCtrl.text.trim().isEmpty ? p.reference : _refCtrl.text.trim())}',
                  ),
                  icon: const Icon(Icons.open_in_browser, size: 18),
                  label: const Text('Google Shopping'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openCalculator(context, provider, p),
                  icon: const Icon(Icons.calculate_outlined, size: 18),
                  label: const Text('Calculatrice'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _refCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ref',
                      hintText: 'INF0219',
                    ),
                    onChanged: (v) => provider.updateReference(p.id, v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _designationCtrl,
                    minLines: 1,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Désignation',
                      hintText: 'REPARTITEUR HDMI 4K 2E/1S',
                    ),
                    onChanged: (v) => provider.updateDesignation(p.id, v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    controller: _uniteCtrl,
                    decoration: const InputDecoration(labelText: 'Unité'),
                    onChanged: (v) => provider.updateUnite(p.id, v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _quantiteCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s.,]+')),
                    ],
                    decoration: const InputDecoration(labelText: 'Qté'),
                    onChanged: (v) {
                      final value = NumberParser.parse(v);
                      if (value != null) provider.updateQuantite(p.id, value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _prixCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s.,]+')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Prix Unit.',
                      suffixText: 'FCFA',
                    ),
                    onChanged: (v) {
                      final value = NumberParser.parse(v);
                      if (value != null) provider.updatePrixUnitaireHT(p.id, value);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _remiseCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\s.,]+')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Remise',
                      suffixText: '%',
                    ),
                    onChanged: (v) {
                      final value = NumberParser.parse(v);
                      if (value != null && value <= 100) {
                        provider.updateRemisePourcentage(p.id, value);
                      }
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.isitekGreen.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Montant HT Net',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                  Text(
                    Formatters.montantCFA(p.montantHTNet),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.isitekGreenDark,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rechercherProduit(
      BuildContext context, DevisProvider provider, ProduitModel p) async {
    await ProductSearchSheet.show(
      context,
      initialQuery: _refCtrl.text.trim().isEmpty ? p.reference : _refCtrl.text.trim(),
      onSelect: (result) {
        provider.applySearchResult(p.id, result, fallbackReference: _refCtrl.text.trim());
        final updated = provider.produits.firstWhere((x) => x.id == p.id);
        _refCtrl.text = updated.reference;
        _designationCtrl.text = updated.designation;
        if (updated.prixUnitaireHT > 0) {
          _prixCtrl.text = _trim(updated.prixUnitaireHT);
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produit appliqué à la ligne')),
        );
      },
    );
  }

  Future<void> _openCalculator(
      BuildContext context, DevisProvider provider, ProduitModel p) async {
    await DevisCalculatorSheet.show(
      context,
      quantite: p.quantite,
      prix: p.prixUnitaireHT,
      remise: p.remisePourcentage,
      onApply: (target, value) {
        switch (target) {
          case CalculatorApplyTarget.quantite:
            provider.updateQuantite(p.id, value);
            _quantiteCtrl.text = _trim(value);
          case CalculatorApplyTarget.prixUnitaire:
            provider.updatePrixUnitaireHT(p.id, value);
            _prixCtrl.text = _trim(value);
          case CalculatorApplyTarget.remise:
            provider.updateRemisePourcentage(p.id, value);
            _remiseCtrl.text = _trim(value);
          case CalculatorApplyTarget.none:
            break;
        }
        setState(() {});
      },
    );
  }

  Future<void> _confirmerSuppression(
      BuildContext context, DevisProvider provider, String id) async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'article'),
        content: const Text(
            'Voulez-vous vraiment supprimer cet article du devis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmer == true) {
      provider.supprimerProduit(id);
    }
  }
}
