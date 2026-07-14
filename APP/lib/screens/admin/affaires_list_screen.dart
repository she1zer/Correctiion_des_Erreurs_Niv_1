import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:printing/printing.dart';

import '../../services/api_service.dart';
import 'affaire_detail_screen.dart';
import 'create_affaire_screen.dart';

class AffairesListScreen extends StatefulWidget {
  const AffairesListScreen({super.key});

  @override
  State<AffairesListScreen> createState() => _AffairesListScreenState();
}

class _AffairesListScreenState extends State<AffairesListScreen> {
  List<dynamic> _affaires = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.instance.get('/api/affaires/');
      setState(() => _affaires = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportExcel(int id, String numero) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Génération du fichier Excel...'), duration: Duration(seconds: 1)),
      );
      final bytes = await ApiService.instance.downloadPdf('/api/rapports/fiche-affaire-excel/$id');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'fiche_affaire_$numero.xlsx',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur Excel : $e')));
    }
  }

  Future<void> _deleteAffaire(int id, String numero) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'affaire'),
        content: Text('Voulez-vous vraiment supprimer définitivement l\'affaire $numero ainsi que toutes ses étapes et prises en charge associées ?'),
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
      await ApiService.instance.delete('/api/affaires/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Affaire supprimée avec succès')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression : $e')));
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

  @override
  Widget build(BuildContext context) {
    final filtered = _affaires.where((a) {
      final query = _searchQuery.toLowerCase();
      final numMatches = (a['numero_affaire'] as String).toLowerCase().contains(query);
      final clientMatches = (a['client_nom'] as String).toLowerCase().contains(query);
      final libelleMatches = (a['libelle_affaire'] as String).toLowerCase().contains(query);
      final domaineMatches = (a['domaine'] as String).toLowerCase().contains(query);
      return numMatches || clientMatches || libelleMatches || domaineMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Affaires'),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateAffaireScreen()),
              );
              if (res == true) _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search box
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par N° affaire, client, libellé...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // List view
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: filtered.isEmpty
                        ? const Center(child: Text('Aucune affaire correspondante'))
                        : ListView.builder(
                            itemCount: filtered.length,
                            padding: const EdgeInsets.only(bottom: 24),
                            itemBuilder: (context, i) {
                              final a = filtered[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 2,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  title: Text(
                                    '${a['numero_affaire']} — ${a['client_nom']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(a['libelle_affaire'] as String, maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _statutColor(a['statut'] as String).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _statutLabel(a['statut'] as String),
                                                style: TextStyle(
                                                  color: _statutColor(a['statut'] as String),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              a['domaine'] as String,
                                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'detail') {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AffaireDetailScreen(affaireId: a['id'] as int),
                                          ),
                                        );
                                        _load();
                                      } else if (v == 'edit') {
                                        final res = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CreateAffaireScreen(affaireToEdit: a),
                                          ),
                                        );
                                        if (res == true) _load();
                                      } else if (v == 'excel') {
                                        _exportExcel(a['id'] as int, a['numero_affaire'] as String);
                                      } else if (v == 'delete') {
                                        _deleteAffaire(a['id'] as int, a['numero_affaire'] as String);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                        value: 'detail',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, size: 18, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Détails'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Modifier'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'excel',
                                        child: Row(
                                          children: [
                                            Icon(Icons.table_view, size: 18, color: Colors.teal),
                                            SizedBox(width: 8),
                                            Text('Fiche Excel'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Supprimer', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fade(duration: 200.ms).slideY(begin: 0.05, end: 0);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
