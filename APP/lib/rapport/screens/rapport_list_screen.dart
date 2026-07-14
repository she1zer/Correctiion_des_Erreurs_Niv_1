import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../main.dart' show IsitekColors;
import '../../services/api_service.dart';
import '../services/rapport_api_service.dart';
import '../services/rapport_mapper.dart';
import 'preview_screen.dart';
import 'rapport_form_screen.dart';

/// Liste des rapports enregistrés — recherche, aperçu PDF, modification, suppression.
class RapportListScreen extends StatefulWidget {
  final int refreshTick;

  const RapportListScreen({super.key, this.refreshTick = 0});

  @override
  State<RapportListScreen> createState() => _RapportListScreenState();
}

class _RapportListScreenState extends State<RapportListScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _searchLoading = false;
  String? _error;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RapportListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _load();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _isAdmin => ApiService.instance.currentUser?.role == 'admin';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _searchQuery = '';
    });
    try {
      final list = await RapportApiService.instance.list();
      if (mounted) setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _searchDatabase() async {
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez au moins 2 caractères (ex: uniwax, maintenance)')),
      );
      return;
    }
    setState(() {
      _searchLoading = true;
      _searchQuery = q;
    });
    try {
      final list = await RapportApiService.instance.list(q: q);
      if (mounted) {
        setState(() {
          _items = list;
          _searchLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _searchLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recherche : $e')));
      }
    }
  }

  Future<void> _openPreview(Map<String, dynamic> item) async {
    try {
      final full = await RapportApiService.instance.get(item['id'] as int);
      if (!mounted) return;
      final data = RapportMapper.fromApi(full);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewScreen(
            data: data,
            numeroRapport: full['numero_rapport'] as String?,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openEdit(Map<String, dynamic> item) async {
    final id = item['id'] as int;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RapportFormScreen(rapportId: id)),
    );
    _load();
  }

  Future<void> _deleteRapport(Map<String, dynamic> item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le rapport ?'),
        content: Text(
          'Rapport ${item['numero_rapport']} — ${item['client']}\nAction irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await RapportApiService.instance.delete(item['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport supprimé'), backgroundColor: IsitekColors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDate(dynamic v) {
    if (v == null) return '—';
    final d = DateTime.tryParse(v.toString());
    if (d == null) return v.toString();
    return DateFormat('dd/MM/yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: IsitekColors.green));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Client, prestation, numéro…',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (_) => _searchDatabase(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _searchLoading ? null : _searchDatabase,
                style: FilledButton.styleFrom(backgroundColor: IsitekColors.green),
                child: _searchLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Chercher'),
              ),
            ],
          ),
        ),
        if (_searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Résultats pour « $_searchQuery » (${_items.length})',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    _load();
                  },
                  child: const Text('Tout afficher'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun rapport enregistré',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Créez un rapport puis enregistrez-le sur ISITEK Connect',
                        style: TextStyle(fontSize: 12, color: IsitekColors.textSoft),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: IsitekColors.green,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = Map<String, dynamic>.from(_items[index] as Map);
                      final numero = (item['numero_rapport'] ?? '') as String;
                      final client = (item['client'] ?? '') as String;
                      final prestation = (item['type_prestation'] ?? '') as String;
                      final author = (item['created_by_name'] ?? '') as String;
                      final date = _formatDate(item['date_visite']);

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: IsitekColors.greenSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.assignment_outlined, color: IsitekColors.greenDark),
                          ),
                          title: Text(
                            client.isNotEmpty ? client : numero,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (client.isNotEmpty && numero.isNotEmpty)
                                Text(numero, style: const TextStyle(fontSize: 12)),
                              Text(
                                '$date · $prestation',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                              if (_isAdmin && author.isNotEmpty)
                                Text(
                                  'Par $author',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              switch (action) {
                                case 'preview':
                                  _openPreview(item);
                                  break;
                                case 'edit':
                                  _openEdit(item);
                                  break;
                                case 'delete':
                                  _deleteRapport(item);
                                  break;
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'preview',
                                child: ListTile(
                                  leading: Icon(Icons.picture_as_pdf_outlined),
                                  title: Text('Aperçu PDF'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Modifier'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(Icons.delete_outline, color: Colors.red),
                                  title: Text('Supprimer', style: TextStyle(color: Colors.red)),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
