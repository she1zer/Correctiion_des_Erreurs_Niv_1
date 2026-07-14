import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../services/api_service.dart';
import 'point_traitement_form_screen.dart';

class PointTraitementListScreen extends StatefulWidget {
  const PointTraitementListScreen({super.key});

  @override
  State<PointTraitementListScreen> createState() => _PointTraitementListScreenState();
}

class _PointTraitementListScreenState extends State<PointTraitementListScreen> {
  List<dynamic> _fiches = [];
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.instance.get('/api/point-traitement/');
      setState(() => _fiches = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportExcel(int ficheId, int? semaine) async {
    setState(() => _exporting = true);
    try {
      final bytes = await ApiService.instance.downloadPdf('/api/rapports/point-traitement-excel/$ficheId');
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'point_traitement_semaine_${semaine ?? ficheId}.xlsx',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _deleteFiche(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette fiche ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.instance.delete('/api/point-traitement/$id');
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');
    final montantFmt = NumberFormat('#,##0', 'fr_FR');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes clients — Point traitement'),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PointTraitementFormScreen()),
          );
          if (res == true) _load();
        },
        backgroundColor: const Color(0xFF008940),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle fiche'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008940)))
          : _fiches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Aucune fiche de traitement', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Créez une fiche pour suivre les demandes clients', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fiches.length,
                    itemBuilder: (ctx, i) {
                      final f = _fiches[i];
                      final semaine = f['semaine'];
                      final debut = f['date_debut'] != null ? dateFmt.format(DateTime.parse(f['date_debut'])) : '—';
                      final fin = f['date_fin'] != null ? dateFmt.format(DateTime.parse(f['date_fin'])) : '—';
                      final nb = f['nb_lignes_remplies'] ?? 0;
                      final totalRaw = f['total_montant_ht'];
                      final total = totalRaw != null ? num.tryParse(totalRaw.toString()) : null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF008940).withOpacity(0.1),
                            child: Text(
                              semaine?.toString() ?? '${f['id']}',
                              style: const TextStyle(color: Color(0xFF008940), fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            'Semaine ${semaine ?? '—'} — $debut au $fin',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Responsable : ${f['responsable'] ?? ''}\n$nb demande(s)${total != null ? ' — Total : ${montantFmt.format(total)} FCFA' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PointTraitementFormScreen(ficheId: f['id'])),
                                );
                                if (res == true) _load();
                              } else if (v == 'excel') {
                                await _exportExcel(f['id'], semaine);
                              } else if (v == 'delete') {
                                await _deleteFiche(f['id']);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Modifier'))),
                              PopupMenuItem(
                                value: 'excel',
                                enabled: !_exporting && nb > 0,
                                child: ListTile(
                                  leading: Icon(Icons.table_view, color: nb > 0 ? null : Colors.grey),
                                  title: Text(nb > 0 ? 'Exporter Excel' : 'Exporter Excel (aucune demande)'),
                                ),
                              ),
                              const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Supprimer', style: TextStyle(color: Colors.red)))),
                            ],
                          ),
                          onTap: () async {
                            final res = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PointTraitementFormScreen(ficheId: f['id'])),
                            );
                            if (res == true) _load();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
