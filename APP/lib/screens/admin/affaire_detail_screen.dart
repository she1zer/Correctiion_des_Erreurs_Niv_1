import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:printing/printing.dart';

import '../../services/api_service.dart';
import 'create_affaire_action_screen.dart';
import 'create_affaire_screen.dart';

class AffaireDetailScreen extends StatefulWidget {
  final int affaireId;
  const AffaireDetailScreen({super.key, required this.affaireId});

  @override
  State<AffaireDetailScreen> createState() => _AffaireDetailScreenState();
}

class _AffaireDetailScreenState extends State<AffaireDetailScreen> {
  Map<String, dynamic>? _affaire;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.getOne('/api/affaires/${widget.affaireId}');
      setState(() => _affaire = data);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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

  Future<void> _deleteAction(int actionId, String libelle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'action'),
        content: Text('Supprimer l\'action « $libelle » ?'),
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
      await ApiService.instance.delete('/api/affaires/actions/$actionId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action supprimée')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _deleteAffaire(int id, String numero) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'affaire'),
        content: Text('Voulez-vous vraiment supprimer définitivement l\'affaire $numero ? Cette action est irréversible et supprimera toutes les étapes liées.'),
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
        Navigator.pop(context, true);
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_affaire == null) {
      return const Scaffold(body: Center(child: Text('Affaire introuvable')));
    }
    
    final a = _affaire!;
    final actions = (a['actions'] as List<dynamic>? ?? []);
    final hasMontant = a['montant_affaire'] != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(a['numero_affaire'] as String),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Ajouter une action',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateAffaireActionScreen(
                    affaireId: a['id'] as int,
                    affaireNumero: a['numero_affaire'] as String,
                  ),
                ),
              );
              if (res == true) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.table_view),
            tooltip: 'Exporter Excel',
            onPressed: () => _exportExcel(a['id'] as int, a['numero_affaire'] as String),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateAffaireScreen(affaireToEdit: a),
                ),
              );
              if (res == true) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Supprimer',
            onPressed: () => _deleteAffaire(a['id'] as int, a['numero_affaire'] as String),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Client & General details Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['libelle_affaire'] as String,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _detailRow(Icons.business, 'Client', a['client_nom']),
                  _detailRow(Icons.domain, 'Domaine', a['domaine']),
                  _detailRow(Icons.person, 'Responsable', '${a['responsable_prenom']} ${a['responsable_nom']} (${a['responsable_role']})'),
                  if (hasMontant)
                    _detailRow(
                      Icons.monetization_on,
                      'Montant',
                      '${a['montant_affaire']} FCFA',
                      color: Colors.green[800],
                    ),
                  if (a['correspondant_nom'] != null || a['correspondant_telephone'] != null || a['correspondant_email'] != null) ...[
                    const Divider(height: 24),
                    const Text('Correspondant client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    _detailRow(Icons.contact_mail, 'Nom/Contact', '${a['correspondant_nom'] ?? "—"} (Tel: ${a['correspondant_telephone'] ?? "—"})'),
                    if (a['correspondant_email'] != null)
                      _detailRow(Icons.email, 'Email', a['correspondant_email']),
                  ],
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Statut global :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statutColor(a['statut'] as String).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _statutColor(a['statut'] as String).withOpacity(0.2)),
                        ),
                        child: Text(
                          _statutLabel(a['statut'] as String),
                          style: TextStyle(color: _statutColor(a['statut'] as String), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fade(duration: 250.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 20),

          // Steps list title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.format_list_numbered, color: Color(0xFF008940)),
                  SizedBox(width: 8),
                  Text(
                    'Étapes de l\'affaire',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () async {
                  final res = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateAffaireActionScreen(
                        affaireId: a['id'] as int,
                        affaireNumero: a['numero_affaire'] as String,
                      ),
                    ),
                  );
                  if (res == true) _load();
                },
                icon: const Icon(Icons.add, color: Color(0xFF008940)),
                label: const Text('Ajouter étape', style: TextStyle(color: Color(0xFF008940))),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (actions.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.playlist_add, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucune action pour cette affaire',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Appuyez sur + en haut pour créer vos actions une par une.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

          // Steps
          ...actions.map((act) {
            final termine = act['termine'] == true;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ExpansionTile(
                leading: Icon(
                  termine ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: termine ? Colors.green : Colors.grey,
                ),
                title: Text(
                  act['libelle'] as String,
                  style: TextStyle(fontWeight: termine ? FontWeight.bold : FontWeight.normal),
                ),
                subtitle: Text('Statut: ${_statutLabel(act['statut'])}', style: const TextStyle(fontSize: 11)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.send, size: 18, color: Colors.blue),
                      tooltip: 'Envoyer résumé au chat',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Envoyer résumé au chat'),
                            content: Text('Envoyer le résumé de l\'étape « ${act['libelle']} » au chat du client ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                child: const Text('ENVOYER'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        try {
                          await ApiService.instance.post('/api/affaires/${a['id']}/envoyer-resume-chat', {
                            'action_id': act['id'],
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Résumé envoyé au chat')));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                          }
                        }
                      },
                    ),
                    if (act['libelle'].toString().toLowerCase().contains('facturation'))
                      IconButton(
                        icon: const Icon(Icons.receipt_long, size: 18, color: Colors.purple),
                        tooltip: 'Générer et envoyer facture',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                              builder: (context) => AlertDialog(
                              title: const Text('Générer facture'),
                              content: const Text('Générer et envoyer la facture au chat du client ?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                  child: const Text('GÉNÉRER'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          try {
                            await ApiService.instance.post('/api/affaires/${a['id']}/generer-facture', {
                              'action_id': act['id'],
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facture générée et envoyée au chat')));
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                            }
                          }
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 18, color: Colors.orange),
                      tooltip: 'Sauter cette étape',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sauter cette étape'),
                            content: Text('Voulez-vous vraiment sauter l\'étape « ${act['libelle']} » ? Elle ne sera pas visible par le client.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ANNULER')),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                child: const Text('SAUTER'),
                              ),
                            ],
                          ),
                        );
                        if (confirm != true) return;
                        try {
                          await ApiService.instance.patch('/api/affaires/actions/${act['id']}', {'sautee': true});
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Étape sautée')));
                            _load();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      tooltip: 'Modifier',
                      onPressed: () async {
                        final res = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateAffaireActionScreen(
                              affaireId: a['id'] as int,
                              affaireNumero: a['numero_affaire'] as String,
                              actionToEdit: act,
                            ),
                          ),
                        );
                        if (res == true) _load();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      tooltip: 'Supprimer',
                      onPressed: () => _deleteAction(
                        act['id'] as int,
                        act['libelle'] as String,
                      ),
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (act['date_debut'] != null) _tileRow('Début', act['date_debut']),
                        if (act['date_fin'] != null) _tileRow('Fin', act['date_fin']),
                        if (act['ref'] != null) _tileRow('Réf', act['ref']),
                        if (act['fournisseur'] != null) _tileRow('Fournisseur', act['fournisseur']),
                        if (act['mode'] != null) _tileRow('Mode', act['mode']),
                        if (act['agence'] != null) _tileRow('Agence', act['agence']),
                        if (act['observations'] != null && (act['observations'] as String).isNotEmpty)
                          _tileRow('Observations', act['observations']),
                        if (act['commentaire'] != null && (act['commentaire'] as String).isNotEmpty)
                          _tileRow('Commentaire', act['commentaire']),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fade(duration: 150.ms);
          }),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
