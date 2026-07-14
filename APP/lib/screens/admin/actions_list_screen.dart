import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import 'create_action_interne_screen.dart';

class ActionsListScreen extends StatefulWidget {
  const ActionsListScreen({super.key});

  @override
  State<ActionsListScreen> createState() => _ActionsListScreenState();
}

class _ActionsListScreenState extends State<ActionsListScreen> {
  List<dynamic> _actions = [];
  bool _loading = true;
  String _searchQuery = '';
  String _statusFilter = 'Tous';
  String _priorityFilter = 'Toutes';

  final List<String> _statuses = ['Tous', 'non_entame', 'en_cours', 'termine', 'bloque', 'annule'];
  final List<String> _priorities = ['Toutes', 'haute', 'moyenne', 'basse'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.instance.get('/api/actions-internes/');
      setState(() => _actions = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteAction(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette action interne ? Cette opération est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.instance.delete('/api/actions-internes/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action supprimée avec succès')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  String _statutLabel(String s) => {
        'non_entame': 'Non entamé',
        'en_cours': 'En cours',
        'termine': 'Terminé',
        'bloque': 'Bloqué',
        'annule': 'Annulé',
      }[s] ?? s;

  Color _statutColor(String s) => {
        'non_entame': Colors.grey[600]!,
        'en_cours': const Color(0xFF0288D1),
        'termine': const Color(0xFF2E7D32),
        'bloque': const Color(0xFFC62828),
        'annule': Colors.grey[800]!,
      }[s] ?? Colors.grey;

  Color _priorityColor(String p) => {
        'haute': const Color(0xFFE64A19),
        'moyenne': const Color(0xFFFFA000),
        'basse': const Color(0xFF388E3C),
      }[p] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    // Filter and search logic
    final filtered = _actions.where((a) {
      final nameMatches = (a['nom'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      final statusMatches = _statusFilter == 'Tous' || a['statut'] == _statusFilter;
      final priorityMatches = _priorityFilter == 'Toutes' || a['priorite'] == _priorityFilter;
      return nameMatches && statusMatches && priorityMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actions Internes'),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateActionInterneScreen()),
              );
              if (res == true) _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher une action...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _statusFilter,
                        decoration: const InputDecoration(labelText: 'Statut', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                        items: _statuses.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s == 'Tous' ? 'Tous les statuts' : _statutLabel(s), style: const TextStyle(fontSize: 12)),
                        )).toList(),
                        onChanged: (v) => setState(() => _statusFilter = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _priorityFilter,
                        decoration: const InputDecoration(labelText: 'Priorité', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                        items: _priorities.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p == 'Toutes' ? 'Toutes priorités' : p.toUpperCase(), style: const TextStyle(fontSize: 12)),
                        )).toList(),
                        onChanged: (v) => setState(() => _priorityFilter = v!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune action interne trouvée',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8, bottom: 24),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) {
                              final action = filtered[i];
                              final hasDates = action['date_debut'] != null || action['date_fin'] != null;
                              final resp = action['responsable'];
                              final support = action['support'];

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Priority Tag
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _priorityColor(action['priorite'] as String).withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              (action['priorite'] as String).toUpperCase(),
                                              style: TextStyle(
                                                color: _priorityColor(action['priorite'] as String),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                          // Popup menu for edit / delete
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 20),
                                            padding: EdgeInsets.zero,
                                            onSelected: (val) async {
                                              if (val == 'edit') {
                                                final res = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => CreateActionInterneScreen(actionToEdit: action),
                                                  ),
                                                );
                                                if (res == true) _load();
                                              } else if (val == 'delete') {
                                                _deleteAction(action['id'] as int);
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit, size: 16, color: Colors.blue),
                                                    SizedBox(width: 8),
                                                    Text('Modifier'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete, size: 16, color: Colors.red),
                                                    SizedBox(width: 8),
                                                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        action['nom'] as String,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      const SizedBox(height: 8),
                                      if (hasDates) ...[
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${action['date_debut'] ?? "Non démarré"} au ${action['date_fin'] ?? "Non défini"}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      // Stakeholders
                                      Row(
                                        children: [
                                          if (resp != null) ...[
                                            const Icon(Icons.person, size: 14, color: Colors.blue),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Resp: ${resp['prenom']} ${resp['nom']}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                            const SizedBox(width: 12),
                                          ],
                                          if (support != null) ...[
                                            const Icon(Icons.people_outline, size: 14, color: Colors.teal),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Sup: ${support['prenom']} ${support['nom']}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (action['commentaire'] != null && (action['commentaire'] as String).isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                                          child: Text(
                                            action['commentaire'] as String,
                                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                                          ),
                                        ),
                                      ],
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Statut de l\'action :', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _statutColor(action['statut'] as String).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: _statutColor(action['statut'] as String).withOpacity(0.3)),
                                            ),
                                            child: Text(
                                              _statutLabel(action['statut'] as String),
                                              style: TextStyle(
                                                color: _statutColor(action['statut'] as String),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fade(duration: 200.ms).slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
