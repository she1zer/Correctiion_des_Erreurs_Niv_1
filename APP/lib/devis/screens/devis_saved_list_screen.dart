import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart' show IsitekColors;
import '../../services/api_service.dart';
import '../providers/devis_provider.dart';
import '../services/devis_api_service.dart';
import 'devis_preview_screen.dart';

/// Liste des devis enregistrés — ouverture, modification, suppression, partage.
class DevisSavedListScreen extends StatefulWidget {
  final void Function(int tabIndex)? onOpenInForm;

  const DevisSavedListScreen({super.key, this.onOpenInForm});

  @override
  State<DevisSavedListScreen> createState() => _DevisSavedListScreenState();
}

class _DevisSavedListScreenState extends State<DevisSavedListScreen> {
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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchDatabase() async {
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saisissez au moins 2 caractères (ex: uniwax, cle usb)')),
      );
      return;
    }
    setState(() { _searchLoading = true; _searchQuery = q; });
    try {
      final res = await ApiService.instance.getOne('/api/search?q=${Uri.encodeQueryComponent(q)}');
      final devisHits = (res['devis'] as List?) ?? [];
      if (mounted) {
        setState(() {
          _items = devisHits.map((d) {
            final m = Map<String, dynamic>.from(d as Map);
            m['lignes'] = m['lignes'] ?? [];
            return m;
          }).toList();
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

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await DevisApiService.instance.listDevis();
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return _items;
    final q = _searchQuery.toLowerCase();
    return _items.where((item) {
      final numDevis = (item['numero_devis'] ?? '').toString().toLowerCase();
      final clientNom = (item['client_nom'] ?? '').toString().toLowerCase();
      final contact = (item['contact'] ?? '').toString().toLowerCase();
      final objet = (item['objet_demande'] ?? '').toString().toLowerCase();
      final author = (item['created_by_name'] ?? '').toString().toLowerCase();
      
      bool matchProducts = false;
      final lignes = item['lignes'] as List<dynamic>?;
      if (lignes != null) {
        for (final l in lignes) {
          final des = (l['designation'] ?? '').toString().toLowerCase();
          final ref = (l['reference'] ?? '').toString().toLowerCase();
          if (des.contains(q) || ref.contains(q)) {
            matchProducts = true;
            break;
          }
        }
      }
      return numDevis.contains(q) ||
          clientNom.contains(q) ||
          contact.contains(q) ||
          objet.contains(q) ||
          author.contains(q) ||
          matchProducts;
    }).toList();
  }

  bool get _isAdmin => ApiService.instance.currentUser?.role == 'admin';

  Future<void> _openDevis(Map<String, dynamic> item, {bool preview = false}) async {
    try {
      final full = await DevisApiService.instance.getDevis(item['id'] as int);
      if (!mounted) return;
      final provider = context.read<DevisProvider>();
      provider.loadFromSaved(full);
      if (preview) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DevisPreviewScreen()),
        );
      } else {
        widget.onOpenInForm?.call(2);
        if (widget.onOpenInForm == null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Devis chargé dans l\'onglet Devis')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteDevis(Map<String, dynamic> item) async {
    final isOwner = item['is_owner'] == true;
    if (!_isAdmin && !isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous ne pouvez pas supprimer ce devis')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le devis ?'),
        content: Text('Devis ${item['numero_devis']} — action irréversible.'),
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
      await DevisApiService.instance.deleteDevis(item['id'] as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Devis supprimé'), backgroundColor: IsitekColors.green),
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

  Future<void> _shareDevis(Map<String, dynamic> item) async {
    final isOwner = item['is_owner'] == true;
    if (!_isAdmin && !isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seul le propriétaire peut partager')),
      );
      return;
    }
    List<dynamic> techniciens = [];
    List<dynamic> shares = [];
    try {
      techniciens = await ApiService.instance.get('/api/users/techniciens');
      shares = await DevisApiService.instance.listShares(item['id'] as int);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
      return;
    }
    final currentId = ApiService.instance.currentUser?.id;
    final sharedIds = shares.map((s) => s['shared_with_id'] as int).toSet();
    final candidates = techniciens.where((t) {
      final id = t['id'] as int;
      return id != currentId && !sharedIds.contains(id);
    }).toList();

    if (!mounted) return;
    int? selectedId;
    var canEdit = true;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Partager ${item['numero_devis']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shares.isNotEmpty) ...[
                const Text('Déjà partagé avec :', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                ...shares.map((s) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(s['shared_with_name'] as String? ?? ''),
                      subtitle: Text(s['can_edit'] == true ? 'Peut modifier' : 'Lecture seule'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () async {
                          try {
                            await DevisApiService.instance.unshareDevis(
                              item['id'] as int,
                              s['shared_with_id'] as int,
                            );
                            shares.remove(s);
                            setDlg(() {});
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Erreur : $e')),
                              );
                            }
                          }
                        },
                      ),
                    )),
                const Divider(),
              ],
              if (candidates.isEmpty)
                const Text('Aucun utilisateur disponible à ajouter.')
              else ...[
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Utilisateur'),
                  items: candidates.map((t) {
                    final id = t['id'] as int;
                    final name = '${t['prenom'] ?? ''} ${t['nom'] ?? ''}'.trim();
                    return DropdownMenuItem(value: id, child: Text(name.isEmpty ? t['email'] : name));
                  }).toList(),
                  onChanged: (v) => setDlg(() => selectedId = v),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Autoriser la modification'),
                  value: canEdit,
                  onChanged: (v) => setDlg(() => canEdit = v ?? true),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
            if (candidates.isNotEmpty)
              FilledButton(
                onPressed: selectedId == null
                    ? null
                    : () async {
                        try {
                          await DevisApiService.instance.shareDevis(
                            item['id'] as int,
                            selectedId!,
                            canEdit: canEdit,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Devis partagé'),
                                backgroundColor: IsitekColors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(content: Text('Erreur : $e')),
                            );
                          }
                        }
                      },
                child: const Text('Partager'),
              ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(dynamic v) {
    if (v == null) return '—';
    final n = (v as num).toInt();
    return '${n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')} F CFA';
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
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Aucun devis enregistré',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez un devis puis enregistrez-le sur ISITEK Connect',
              style: TextStyle(fontSize: 12, color: IsitekColors.textSoft),
            ),
          ],
        ),
      );
    }

    final filtered = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Rechercher (ex: cle usb, uniwax)...',
                    prefixIcon: const Icon(Icons.search, color: IsitekColors.green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onSubmitted: (_) => _searchDatabase(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _searchLoading ? null : _searchDatabase,
                style: FilledButton.styleFrom(
                  backgroundColor: IsitekColors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: _searchLoading
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Chercher'),
              ),
              IconButton(
                tooltip: 'Tout recharger',
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: IsitekColors.green),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun résultat pour "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: IsitekColors.green,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = filtered[i] as Map<String, dynamic>;
                      final canEdit = item['can_edit'] == true;
                      final isShared = item['is_shared'] == true;
                      final isOwner = item['is_owner'] == true;
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          title: Text(
                            item['numero_devis'] as String? ?? '—',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['client_nom'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatMoney(item['total_ht_net'])} HT — ${item['created_by_name'] ?? '—'}',
                                style: const TextStyle(fontSize: 11, color: IsitekColors.textSoft),
                              ),
                              if (isShared)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Chip(
                                    label: Text('Partagé avec moi', style: TextStyle(fontSize: 10)),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              switch (action) {
                                case 'open':
                                  _openDevis(item);
                                  break;
                                case 'preview':
                                  _openDevis(item, preview: true);
                                  break;
                                case 'share':
                                  _shareDevis(item);
                                  break;
                                case 'delete':
                                  _deleteDevis(item);
                                  break;
                              }
                            },
                            itemBuilder: (_) => [
                              if (canEdit)
                                const PopupMenuItem(value: 'open', child: Text('Modifier')),
                              const PopupMenuItem(value: 'preview', child: Text('Aperçu PDF')),
                              if (isOwner || _isAdmin)
                                const PopupMenuItem(value: 'share', child: Text('Partager')),
                              if (isOwner || _isAdmin)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Supprimer', style: TextStyle(color: Colors.red)),
                                ),
                            ],
                          ),
                          onTap: () => _openDevis(item, preview: false),
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
