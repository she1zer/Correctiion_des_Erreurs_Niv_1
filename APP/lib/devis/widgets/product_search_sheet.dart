import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/devis_api_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Ouvre une URL dans le navigateur externe du téléphone (Chrome, Safari…).
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Bottom sheet de recherche produit (SerpApi / Google Shopping via backend).
///
/// Affiche les résultats avec prix et boutique, permet d'ouvrir Google
/// dans le navigateur du téléphone et de sélectionner une offre.
class ProductSearchSheet extends StatefulWidget {
  final String initialQuery;
  final void Function(Map<String, dynamic> result) onSelect;

  const ProductSearchSheet({
    super.key,
    required this.initialQuery,
    required this.onSelect,
  });

  static Future<void> show(
    BuildContext context, {
    required String initialQuery,
    required void Function(Map<String, dynamic> result) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => ProductSearchSheet(
        initialQuery: initialQuery,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<ProductSearchSheet> {
  late final TextEditingController _controller;
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _search());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final data = await DevisApiService.instance.searchReference(query);
      if (mounted) setState(() { _result = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openGoogle({bool shopping = false}) async {
    if (_result == null) {
      final q = Uri.encodeComponent(_controller.text.trim());
      final url = shopping
          ? 'https://www.google.com/search?tbm=shop&q=$q'
          : 'https://www.google.com/search?q=$q+produit+prix';
      await openExternalUrl(url);
      return;
    }
    final url = shopping
        ? (_result!['shopping_url'] as String? ?? _result!['search_url'] as String)
        : _result!['search_url'] as String;
    final ok = await openExternalUrl(url);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le navigateur')),
      );
    }
  }

  void _selectResult(Map<String, dynamic> item) {
    widget.onSelect(item);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final results = (_result?['results'] as List<dynamic>? ?? []);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.isitekGreen),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Recherche produit',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Référence ou nom produit…',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _loading ? null : _search,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.isitekGreen,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Chercher'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openGoogle(shopping: false),
                      icon: const Icon(Icons.open_in_browser, size: 18),
                      label: const Text('Google'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _openGoogle(shopping: true),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Shopping'),
                    ),
                    const Spacer(),
                    if (_result != null)
                      Text(
                        '${results.length} résultat(s)',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.isitekGreen))
                    : results.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _result == null
                                    ? 'Saisissez une référence et lancez la recherche.\n'
                                      'Utilisez Google / Shopping pour comparer les prix dans votre navigateur.'
                                    : 'Aucun résultat automatique.\n'
                                      'Appuyez sur Google Shopping pour chercher manuellement.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: results.length,
                            itemBuilder: (context, index) {
                              final r = results[index] as Map<String, dynamic>;
                              final price = (r['price'] as num?)?.toDouble();
                              final priceLabel = r['price_label'] as String? ?? '';
                              final merchant = r['merchant'] as String? ?? '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _selectResult(r),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          r['title'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        if ((r['snippet'] as String?)?.isNotEmpty == true) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            r['snippet'],
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            if (price != null && price > 0)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AppColors.isitekGreen.withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  priceLabel.isNotEmpty ? priceLabel : Formatters.montantCFA(price),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.isitekGreenDark,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            if (merchant.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  merchant,
                                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                            IconButton(
                                              tooltip: 'Ouvrir le lien',
                                              icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.isitekGreen),
                                              onPressed: () => openExternalUrl(r['url'] ?? ''),
                                            ),
                                            FilledButton.tonal(
                                              onPressed: () => _selectResult(r),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: AppColors.isitekGreen.withOpacity(0.12),
                                                foregroundColor: AppColors.isitekGreenDark,
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                              ),
                                              child: const Text('Utiliser', style: TextStyle(fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Applique un résultat de recherche sur une ligne produit via le provider.
void applySearchResultToLine({
  required void Function(String id, String value) updateReference,
  required void Function(String id, String value) updateDesignation,
  required void Function(String id, double value) updatePrix,
  required String productId,
  required String fallbackReference,
  required Map<String, dynamic> result,
}) {
  final ref = (result['reference'] as String?) ?? fallbackReference;
  if (ref.isNotEmpty) updateReference(productId, ref.toUpperCase());

  final designation = (result['title'] as String?)?.trim() ?? '';
  final snippet = (result['snippet'] as String?)?.trim() ?? '';
  if (designation.isNotEmpty) {
    updateDesignation(productId, snippet.isNotEmpty ? '$designation\n$snippet' : designation);
  }

  final price = (result['price'] as num?)?.toDouble();
  if (price != null && price > 0) {
    updatePrix(productId, price);
  }
}
