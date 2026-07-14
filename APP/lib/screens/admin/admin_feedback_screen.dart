import 'package:flutter/material.dart';

import '../../main.dart' show IsitekColors;
import '../../services/feedback_api_service.dart';
import '../shared/feedback_screen.dart';

/// Gestion des signalements utilisateurs (admin).
class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await FeedbackApiService.instance.listAll(status: _filterStatus);
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    await FeedbackApiService.instance.update(id, {'status': status});
    _load();
  }

  Future<void> _respond(int id) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réponse à l\'utilisateur'),
        content: TextField(controller: ctrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Votre réponse…')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('Envoyer')),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    await FeedbackApiService.instance.update(id, {'admin_response': text, 'status': 'resolved'});
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signalements utilisateurs'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Page web',
            icon: const Icon(Icons.language),
            onPressed: openBugsWebPage,
          ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) { _filterStatus = v; _load(); },
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Tous')),
              PopupMenuItem(value: 'pending', child: Text('En attente')),
              PopupMenuItem(value: 'in_progress', child: Text('En cours')),
              PopupMenuItem(value: 'resolved', child: Text('Résolus')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final m = Map<String, dynamic>.from(_items[i] as Map);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      title: Text('#${m['id']} — ${m['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('${m['user_prenom']} ${m['user_nom']} · ${m['user_role']}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(m['description']?.toString() ?? ''),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  _statusBtn(m['id'] as int, 'pending', 'En attente'),
                                  _statusBtn(m['id'] as int, 'in_progress', 'En cours'),
                                  _statusBtn(m['id'] as int, 'resolved', 'Résolu'),
                                  _statusBtn(m['id'] as int, 'rejected', 'Rejeté'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _respond(m['id'] as int),
                                icon: const Icon(Icons.reply),
                                label: const Text('Répondre & marquer résolu'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _statusBtn(int id, String status, String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () => _updateStatus(id, status),
    );
  }
}
