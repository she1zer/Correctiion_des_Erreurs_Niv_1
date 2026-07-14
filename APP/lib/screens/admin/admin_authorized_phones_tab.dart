import 'package:flutter/material.dart';

import '../../main.dart' show IsitekColors;
import '../../services/api_service.dart';

class AdminAuthorizedPhonesTab extends StatefulWidget {
  const AdminAuthorizedPhonesTab({super.key});

  @override
  State<AdminAuthorizedPhonesTab> createState() => _AdminAuthorizedPhonesTabState();
}

class _AdminAuthorizedPhonesTabState extends State<AdminAuthorizedPhonesTab> {
  List<Map<String, dynamic>> _phones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.instance.listAuthorizedPhones();
      if (mounted) {
        setState(() {
          _phones = list.cast<Map<String, dynamic>>();
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

  Future<void> _addPhone() async {
    final phoneCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enregistrer un numéro employé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone',
                hintText: '+225 07 XX XX XX XX',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom / poste (optionnel)',
                hintText: 'Ex: Jean — Technicien',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: IsitekColors.green),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (ok != true || phoneCtrl.text.trim().isEmpty) return;
    try {
      await ApiService.instance.createAuthorizedPhone(
        telephone: phoneCtrl.text.trim(),
        label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Numéro enregistré — l\'employé peut s\'inscrire')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> row) async {
    try {
      await ApiService.instance.updateAuthorizedPhone(
        row['id'] as int,
        {'is_active': !(row['is_active'] == true)},
      );
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce numéro ?'),
        content: const Text('L\'employé ne pourra plus s\'inscrire avec ce numéro.'),
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
      await ApiService.instance.deleteAuthorizedPhone(id);
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: IsitekColors.green));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _addPhone,
              icon: const Icon(Icons.add),
              label: const Text('Enregistrer un numéro'),
              style: FilledButton.styleFrom(backgroundColor: IsitekColors.green),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Material(
            color: IsitekColors.greenSoft,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: IsitekColors.greenDark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Seuls les numéros enregistrés ici permettent l\'inscription employé.',
                      style: TextStyle(fontSize: 12, color: IsitekColors.greenDark, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _phones.isEmpty
              ? const Center(child: Text('Aucun numéro enregistré'))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: IsitekColors.green,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _phones.length,
                    itemBuilder: (_, i) {
                      final p = _phones[i];
                      final active = p['is_active'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: active ? IsitekColors.greenSoft : Colors.grey.shade200,
                            child: Icon(
                              Icons.phone_android,
                              color: active ? IsitekColors.greenDark : Colors.grey,
                            ),
                          ),
                          title: Text(
                            p['telephone'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            p['label'] as String? ?? 'Sans libellé',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (action) {
                              if (action == 'toggle') _toggleActive(p);
                              if (action == 'delete') _delete(p['id'] as int);
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(active ? 'Désactiver' : 'Réactiver'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer', style: TextStyle(color: Colors.red)),
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
