import 'package:flutter/material.dart';

import '../../main.dart' show IsitekColors;
import '../../models/astuce_model.dart';
import '../../services/astuce_api_service.dart';
import '../../utils/astuce_icon_map.dart';

/// Gestion des astuces ISITEK — admin uniquement.
class AdminAstucesScreen extends StatefulWidget {
  const AdminAstucesScreen({super.key});

  @override
  State<AdminAstucesScreen> createState() => _AdminAstucesScreenState();
}

class _AdminAstucesScreenState extends State<AdminAstucesScreen> {
  List<AstuceModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await AstuceApiService.instance.listAllAdmin();
      if (mounted) {
        setState(() {
          _items = list.map((e) => AstuceModel.fromApi(Map<String, dynamic>.from(e as Map))).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _openForm({AstuceModel? existing}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => _AstuceFormScreen(existing: existing)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(AstuceModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette astuce ?'),
        content: Text(a.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok != true || a.id == null) return;
    await AstuceApiService.instance.delete(a.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les astuces'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: IsitekColors.green,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle astuce'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? const Center(child: Text('Aucune astuce'))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final a = _items[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: a.accent.withOpacity(0.15),
                              child: Text(a.emoji, style: const TextStyle(fontSize: 20)),
                            ),
                            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${a.category} · ${a.isActive ? "Active" : "Inactive"}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') _openForm(existing: a);
                                if (v == 'del') _delete(a);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                PopupMenuItem(value: 'del', child: Text('Supprimer')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _AstuceFormScreen extends StatefulWidget {
  final AstuceModel? existing;
  const _AstuceFormScreen({this.existing});

  @override
  State<_AstuceFormScreen> createState() => _AstuceFormScreenState();
}

class _AstuceFormScreenState extends State<_AstuceFormScreen> {
  late final TextEditingController _emojiCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _summaryCtrl;
  late final TextEditingController _detailCtrl;
  late final TextEditingController _categoryCtrl;
  String _iconName = 'lightbulb_rounded';
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _emojiCtrl = TextEditingController(text: e?.emoji ?? '💡');
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _summaryCtrl = TextEditingController(text: e?.summary ?? '');
    _detailCtrl = TextEditingController(text: e?.detail ?? '');
    _categoryCtrl = TextEditingController(text: e?.category ?? 'Électricité');
    _iconName = e?.iconName ?? 'lightbulb_rounded';
    _active = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _emojiCtrl.dispose();
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _detailCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final body = {
        'emoji': _emojiCtrl.text.trim(),
        'title': _titleCtrl.text.trim(),
        'summary': _summaryCtrl.text.trim(),
        'detail': _detailCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'icon_name': _iconName,
        'gradient_start': '#FFD54F',
        'gradient_end': '#F9A825',
        'accent_color': '#F57F17',
        'is_active': _active,
      };
      if (widget.existing?.id != null) {
        await AstuceApiService.instance.update(widget.existing!.id!, body);
      } else {
        await AstuceApiService.instance.create(body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Nouvelle astuce' : 'Modifier astuce'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _emojiCtrl, decoration: const InputDecoration(labelText: 'Emoji / Icône (ex: 💡)')),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Titre')),
          TextField(controller: _summaryCtrl, decoration: const InputDecoration(labelText: 'Résumé court'), maxLines: 2),
          TextField(controller: _detailCtrl, decoration: const InputDecoration(labelText: 'Détail complet'), maxLines: 5),
          TextField(controller: _categoryCtrl, decoration: const InputDecoration(labelText: 'Catégorie')),
          const SizedBox(height: 12),
          const Text('Icône Material', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AstuceIconMap.choices.map((entry) {
              final selected = _iconName == entry.key;
              return ChoiceChip(
                label: Icon(entry.value, size: 20),
                selected: selected,
                onSelected: (_) => setState(() => _iconName = entry.key),
                selectedColor: IsitekColors.greenSoft,
              );
            }).toList(),
          ),
          SwitchListTile(
            title: const Text('Astuce active'),
            value: _active,
            activeColor: IsitekColors.green,
            onChanged: (v) => setState(() => _active = v),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: IsitekColors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
