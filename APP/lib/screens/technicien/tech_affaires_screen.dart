import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../main.dart' show IsitekColors;
import '../../services/api_service.dart';
import '../admin/affaire_detail_screen.dart';
import '../admin/create_affaire_screen.dart';

class TechAffairesScreen extends StatefulWidget {
  const TechAffairesScreen({super.key});

  @override
  State<TechAffairesScreen> createState() => _TechAffairesScreenState();
}

class _TechAffairesScreenState extends State<TechAffairesScreen> {
  List<dynamic> _affaires = [];
  bool _loading = true;
  String _search = '';

  bool get _canCreate => ApiService.instance.currentUser?.canCreateAffaireEffective ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.get('/api/affaires/');
      if (mounted) setState(() { _affaires = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  List<dynamic> get _filtered {
    if (_search.isEmpty) return _affaires;
    final q = _search.toLowerCase();
    return _affaires.where((a) {
      return (a['numero_affaire'] ?? '').toString().toLowerCase().contains(q) ||
          (a['client_nom'] ?? '').toString().toLowerCase().contains(q) ||
          (a['libelle_affaire'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  Color _statutColor(String s) {
    switch (s) {
      case 'termine': return Colors.green;
      case 'en_cours': return Colors.blue;
      case 'bloque': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dossiers d\'affaires', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: IsitekColors.textDark,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: IsitekColors.green)),
        ],
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAffaireScreen()),
                );
                if (res == true) _load();
              },
              backgroundColor: IsitekColors.green,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nouvelle affaire', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        children: [
          if (!_canCreate)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Création d\'affaires non autorisée. Demandez l\'accès à l\'administrateur.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une affaire...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
                : _filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open, size: 56, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text('Aucune affaire', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: IsitekColors.green,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final a = _filtered[i];
                            final color = _statutColor(a['statut'] ?? '');
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AffaireDetailScreen(affaireId: a['id'])),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: IsitekColors.greenSoft,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              a['numero_affaire'] ?? '',
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: IsitekColors.greenDark, fontSize: 12),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              (a['statut'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(a['libelle_affaire'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 6),
                                      Text(a['client_nom'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: (i * 40).ms);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
