import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/demande_service.dart';
import '../../utils/role_labels.dart';
import '../../main.dart' show IsitekColors;
import '../../models/demande_steps.dart';
import '../../widgets/demande_timeline.dart';
import 'package:printing/printing.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _conversations = [];
  List<dynamic> _allDemands = [];
  List<dynamic> _satisfactions = [];
  bool _isLoadingConvs = true;
  bool _isLoadingDemands = true;
  bool _isLoadingSatisfactions = true;
  Timer? _timer;
  
  // Sorting state for conversations
  String _convSortField = 'date';
  bool _convSortAsc = false;
  
  // Sorting state for demands
  String _demandSortField = 'date';
  bool _demandSortAsc = false;
  
  // Sorting state for satisfactions
  String _satSortField = 'date';
  bool _satSortAsc = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    _fetchConversations();
    _fetchDemands();
    _fetchSatisfactions();
  }

  Future<void> _fetchSatisfactions() async {
    try {
      final data = await ApiService.instance.get('/api/demandes/satisfactions/list');
      if (mounted) {
        setState(() {
          _satisfactions = data;
          _isLoadingSatisfactions = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingSatisfactions = false);
    }
  }

  Future<void> _fetchConversations() async {
    try {
      final data = await ApiService.instance.get('/api/messages/conversations');
      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoadingConvs = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingConvs = false);
    }
  }

  Future<void> _fetchDemands() async {
    try {
      final data = await ApiService.instance.get('/api/demandes/');
      if (mounted) {
        setState(() {
          _allDemands = data;
          _sortDemands();
          _isLoadingDemands = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDemands = false);
    }
  }

  List<dynamic> _getSortedConversations() {
    final sorted = List<dynamic>.from(_conversations);
    sorted.sort((a, b) {
      int comparison;
      switch (_convSortField) {
        case 'name':
          final nameA = '${a['prenom']} ${a['nom']}'.toLowerCase();
          final nameB = '${b['prenom']} ${b['nom']}'.toLowerCase();
          comparison = nameA.compareTo(nameB);
          break;
        case 'date':
          final dateA = a['last_message_date'] != null ? DateTime.tryParse(a['last_message_date']) : DateTime(1970);
          final dateB = b['last_message_date'] != null ? DateTime.tryParse(b['last_message_date']) : DateTime(1970);
          comparison = dateA!.compareTo(dateB!);
          break;
        default:
          comparison = 0;
      }
      return _convSortAsc ? comparison : -comparison;
    });
    return sorted;
  }

  List<dynamic> _getSortedDemands() {
    final sorted = List<dynamic>.from(_allDemands);
    sorted.sort((a, b) {
      int comparison;
      switch (_demandSortField) {
        case 'name':
          final clientA = a['client'];
          final clientB = b['client'];
          final nameA = clientA != null ? '${clientA['prenom']} ${clientA['nom']}'.toLowerCase() : '';
          final nameB = clientB != null ? '${clientB['prenom']} ${clientB['nom']}'.toLowerCase() : '';
          comparison = nameA.compareTo(nameB);
          break;
        case 'date':
          final dateA = a['date_creation'] != null ? DateTime.tryParse(a['date_creation']) : DateTime(1970);
          final dateB = b['date_creation'] != null ? DateTime.tryParse(b['date_creation']) : DateTime(1970);
          comparison = dateA!.compareTo(dateB!);
          break;
        case 'status':
          comparison = (a['statut'] as String).compareTo(b['statut'] as String);
          break;
        default:
          comparison = 0;
      }
      return _demandSortAsc ? comparison : -comparison;
    });
    return sorted;
  }

  List<dynamic> _getSortedSatisfactions() {
    final sorted = List<dynamic>.from(_satisfactions);
    sorted.sort((a, b) {
      int comparison;
      switch (_satSortField) {
        case 'name':
          final nameA = (a['client_nom'] as String? ?? '').toLowerCase();
          final nameB = (b['client_nom'] as String? ?? '').toLowerCase();
          comparison = nameA.compareTo(nameB);
          break;
        case 'date':
          final dateA = a['date_evaluation'] != null ? DateTime.tryParse(a['date_evaluation']) : DateTime(1970);
          final dateB = b['date_evaluation'] != null ? DateTime.tryParse(b['date_evaluation']) : DateTime(1970);
          comparison = dateA!.compareTo(dateB!);
          break;
        case 'rating':
          comparison = ((a['rating'] as num?)?.toInt() ?? 0).compareTo((b['rating'] as num?)?.toInt() ?? 0);
          break;
        default:
          comparison = 0;
      }
      return _satSortAsc ? comparison : -comparison;
    });
    return sorted;
  }

  void _sortConversations() {
    setState(() {});
  }

  void _sortDemands() {
    setState(() {});
  }

  void _sortSatisfactions() {
    setState(() {});
  }

  Future<void> _deleteConversation(int clientId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la conversation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette conversation ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    try {
      await ApiService.instance.delete('/api/messages/conversations/$clientId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation supprimée')));
        _fetchConversations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _deleteDemand(String demandeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la demande'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette demande ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    try {
      await ApiService.instance.delete('/api/demandes/$demandeId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande supprimée')));
        _fetchDemands();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  Future<void> _deleteSatisfaction(String satisfactionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'évaluation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette évaluation ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    
    try {
      await ApiService.instance.delete('/api/demandes/satisfactions/$satisfactionId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Évaluation supprimée')));
        _fetchSatisfactions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Clients ISITEK', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: IsitekColors.yellow,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Discussions'),
            Tab(icon: Icon(Icons.assignment), text: 'Suivi Demandes'),
            Tab(icon: Icon(Icons.star), text: 'Satisfactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Discussions
          _buildConversationsTab(),

          _buildDemandsTab(),
          _buildSatisfactionsTab(),
        ],
      ),
    );
  }

  Widget _buildSatisfactionsTab() {
    final sortedSats = _getSortedSatisfactions();
    return Column(
      children: [
        // Sort buttons
        _buildSortBar(
          fields: [
            {'value': 'date', 'label': 'Date'},
            {'value': 'name', 'label': 'Nom'},
            {'value': 'rating', 'label': 'Note'},
          ],
          currentField: _satSortField,
          currentAsc: _satSortAsc,
          onSortChanged: (field, asc) {
            setState(() {
              _satSortField = field;
              _satSortAsc = asc;
            });
          },
        ),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchSatisfactions,
            color: IsitekColors.green,
            child: _isLoadingSatisfactions
                ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
                : _satisfactions.isEmpty
                    ? _buildEmptyState('Aucun retour', 'Les évaluations clients apparaîtront ici.')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: sortedSats.length,
                        itemBuilder: (context, index) {
                          final s = sortedSats[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: IsitekColors.greenSoft,
                                        child: Text(
                                          (s['client_nom'] as String? ?? 'C')[0].toUpperCase(),
                                          style: const TextStyle(color: IsitekColors.greenDark, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(s['client_nom'] ?? 'Client', style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text(s['client_email'] ?? '', style: const TextStyle(fontSize: 12, color: IsitekColors.textSoft)),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                            onPressed: () => _deleteSatisfaction(s['id'].toString()),
                                            tooltip: 'Supprimer',
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          const SizedBox(width: 4),
                                          ...List.generate(5, (i) => Icon(
                                            i < (s['rating'] ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
                                            color: Colors.amber,
                                            size: 18,
                                          )),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text('${s['type_prestation']} — ${s['domaine']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  if (s['avis'] != null && (s['avis'] as String).isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text('"${s['avis']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: IsitekColors.textSoft)),
                                  ],
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

  Widget _buildConversationsTab() {
    final sortedConvs = _getSortedConversations();
    return Column(
      children: [
        // Sort buttons
        _buildSortBar(
          fields: [
            {'value': 'date', 'label': 'Date'},
            {'value': 'name', 'label': 'Nom'},
          ],
          currentField: _convSortField,
          currentAsc: _convSortAsc,
          onSortChanged: (field, asc) {
            setState(() {
              _convSortField = field;
              _convSortAsc = asc;
            });
          },
        ),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchConversations,
            color: IsitekColors.green,
            child: _isLoadingConvs
                ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
                : _conversations.isEmpty
                    ? _buildEmptyState('Aucune conversation', 'Les messages envoyés par les clients apparaîtront ici.')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: sortedConvs.length,
                        itemBuilder: (context, index) {
                          final conv = sortedConvs[index];
                          final name = '${conv['prenom']} ${conv['nom']}';
                          final lastMsg = conv['last_message'] ?? '';
                          final phone = conv['telephone'] ?? 'Pas de numéro';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: IsitekColors.greenSoft,
                                child: Text(
                                  conv['prenom'][0].toUpperCase() + conv['nom'][0].toUpperCase(),
                                  style: const TextStyle(color: IsitekColors.greenDark, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (conv['poste'] != null && (conv['poste'] as String).isNotEmpty)
                                    Text(
                                      conv['poste'] as String,
                                      style: const TextStyle(color: IsitekColors.green, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  Text(phone, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    lastMsg,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, color: IsitekColors.textSoft),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                                    onPressed: () => _deleteConversation(conv['client_id']),
                                    tooltip: 'Supprimer',
                                  ),
                                  const Icon(Icons.chat_bubble_outline_rounded, color: IsitekColors.green),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminChatScreen(
                                      clientId: conv['client_id'],
                                      clientName: name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemandsTab() {
    final sortedDemands = _getSortedDemands();
    return Column(
      children: [
        // Sort buttons
        _buildSortBar(
          fields: [
            {'value': 'date', 'label': 'Date'},
            {'value': 'name', 'label': 'Nom client'},
            {'value': 'status', 'label': 'Statut'},
          ],
          currentField: _demandSortField,
          currentAsc: _demandSortAsc,
          onSortChanged: (field, asc) {
            setState(() {
              _demandSortField = field;
              _demandSortAsc = asc;
            });
          },
        ),
        // List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchDemands,
            color: IsitekColors.green,
            child: _isLoadingDemands
                ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
                : _allDemands.isEmpty
                    ? _buildEmptyState('Aucune demande de prestation', 'Les expressions de besoin des clients apparaîtront ici.')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: sortedDemands.length,
                        itemBuilder: (context, index) {
                          final dem = sortedDemands[index];
                          final clientInfo = dem['client'];
                          final clientName = clientInfo != null ? '${clientInfo['prenom']} ${clientInfo['nom']}' : 'Client';
                          final clientEmail = clientInfo != null ? clientInfo['email'] : 'N/A';
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card header
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${dem['type_prestation']} ${dem['domaine']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: IsitekColors.textDark),
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                            onPressed: () => _deleteDemand(dem['id'].toString()),
                                            tooltip: 'Supprimer',
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          const SizedBox(width: 4),
                                          _buildStatusBadge(dem['statut']),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Client : $clientName ($clientEmail)',
                                    style: const TextStyle(fontSize: 12, color: IsitekColors.greenDark, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Description : ${dem['description']}',
                                    style: const TextStyle(fontSize: 13, color: IsitekColors.textSoft),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  _buildStepperMini(dem),
                                  const SizedBox(height: 12),
                                  DemandeTimeline(
                                    statut: dem['statut'],
                                    skippedSteps: DemandeSteps.parseSkipped(dem['etapes_sautees']),
                                    devisMontant: dem['devis_montant'],
                                    accomptePourcentage: dem['accompte_pourcentage'],
                                    garantieMois: dem['garantie_mois'],
                                    garantieDebut: dem['garantie_debut'] != null ? DateTime.tryParse(dem['garantie_debut']) : null,
                                    garantieFin: dem['garantie_fin'] != null ? DateTime.tryParse(dem['garantie_fin']) : null,
                                  ),
                                  const SizedBox(height: 14),
                                  _buildActionRow(dem),
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

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;
    switch (status) {
      case 'recue':
        bg = Colors.grey.shade100;
        text = Colors.grey.shade700;
        label = 'Besoin exprimé';
        break;
      case 'analyse':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade700;
        label = 'En analyse';
        break;
      case 'visite_site':
        bg = Colors.teal.shade50;
        text = Colors.teal.shade700;
        label = 'Visite site';
        break;
      case 'devis_propose':
        bg = const Color(0xFFFFECE0);
        text = const Color(0xFFE05300);
        label = 'Devis envoyé';
        break;
      case 'reception_bc':
        bg = Colors.indigo.shade50;
        text = Colors.indigo.shade700;
        label = 'Commande reçue';
        break;
      case 'avance_accompte':
        bg = Colors.deepPurple.shade50;
        text = Colors.deepPurple.shade700;
        label = 'Acompte';
        break;
      case 'preparation_commande':
        bg = Colors.blueGrey.shade50;
        text = Colors.blueGrey.shade700;
        label = 'Préparation';
        break;
      case 'livraison_bl':
        bg = Colors.cyan.shade50;
        text = Colors.cyan.shade700;
        label = 'Livraison';
        break;
      case 'depot_facture':
        bg = Colors.amber.shade50;
        text = Colors.amber.shade800;
        label = 'Facturation';
        break;
      case 'reglement_cheque':
        bg = Colors.purple.shade50;
        text = Colors.purple.shade700;
        label = 'Règlement';
        break;
      case 'affaire_terminee':
        bg = Colors.green.shade50;
        text = Colors.green.shade700;
        label = 'Affaire terminée';
        break;
      case 'sav_garantie':
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        label = 'SAV Garantie';
        break;
      case 'retour_satisfaction':
        bg = Colors.pink.shade50;
        text = Colors.pink.shade700;
        label = 'Satisfaction';
        break;
      case 'termine':
        bg = IsitekColors.greenSoft;
        text = IsitekColors.greenDark;
        label = 'Terminé';
        break;
      case 'annule':
      default:
        bg = const Color(0xFFFFEAEA);
        text = Colors.red.shade700;
        label = 'Annulé';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildStepperMini(dynamic dem) {
    final status = dem['statut'] as String;
    final stepIdx = DemandeSteps.stepIndexForStatus(status);
    final stepDef = DemandeSteps.stepForStatus(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Avancement : Étape $stepIdx / 12',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
            ),
            Flexible(
              child: Text(
                stepDef?.label ?? 'En cours',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: IsitekColors.green),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: stepIdx / 12.0,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(IsitekColors.green),
            minHeight: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(dynamic dem) {
    final String status = dem['statut'];
    final String id = dem['id'].toString();
    final int currentStep = DemandeSteps.stepIndexForStatus(status);

    if (status == 'annule') return const SizedBox.shrink();

    final List<Widget> buttons = [];

    if (status == 'recue' || status == 'analyse') {
      buttons.add(ElevatedButton(
        onPressed: () => _updateDemandeStatus(id, 'visite_site'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
        child: const Text('Planifier visite site'),
      ));
      buttons.add(const SizedBox(width: 8));
      buttons.add(OutlinedButton(
        onPressed: () => _showDevisDialog(context, id),
        child: const Text('Envoyer devis'),
      ));
    } else if (status == 'visite_site') {
      buttons.add(ElevatedButton(
        onPressed: () => _showDevisDialog(context, id),
        style: ElevatedButton.styleFrom(backgroundColor: IsitekColors.green, foregroundColor: Colors.white),
        child: const Text('Envoyer offre commerciale'),
      ));
    } else if (status == 'devis_propose') {
      buttons.add(Text('Attente validation client...', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)));
    } else if (status == 'reception_bc') {
      buttons.add(ElevatedButton(
        onPressed: () => _showAccompteDialog(id),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
        child: const Text('Définir acompte'),
      ));
    } else if (status == 'avance_accompte') {
      buttons.add(ElevatedButton(
        onPressed: () => _updateDemandeStatus(id, 'preparation_commande'),
        child: const Text('Lancer préparation'),
      ));
    } else if (status == 'preparation_commande') {
      buttons.add(ElevatedButton(
        onPressed: () => _updateDemandeStatus(id, 'livraison_bl'),
        child: const Text('Confirmer livraison'),
      ));
    } else if (status == 'livraison_bl') {
      buttons.add(ElevatedButton(
        onPressed: () => _updateDemandeStatus(id, 'depot_facture'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700, foregroundColor: Colors.white),
        child: const Text('Facturer'),
      ));
    } else if (status == 'depot_facture') {
      buttons.add(Text('Attente règlement client...', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic)));
    } else if (status == 'reglement_cheque') {
      buttons.add(ElevatedButton(
        onPressed: () => _updateDemandeStatus(id, 'affaire_terminee'),
        child: const Text('Clôturer affaire'),
      ));
    } else if (status == 'affaire_terminee') {
      buttons.add(ElevatedButton(
        onPressed: () => _showGarantieDialog(id),
        child: const Text('Configurer garantie SAV'),
      ));
    } else if (status == 'sav_garantie') {
      buttons.add(ElevatedButton(
        onPressed: () => _updateDemandeStatus(id, 'retour_satisfaction'),
        child: const Text('Demander satisfaction'),
      ));
    } else if (status == 'retour_satisfaction' || status == 'termine') {
      if (dem['rating'] != null) {
        return Row(
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            Text(' ${dem['rating']}/5', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(child: Text('"${dem['avis'] ?? ''}"', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic))),
          ],
        );
      }
      return const Text('En attente évaluation client', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }

    if (status != 'termine' && status != 'annule') {
      buttons.add(const SizedBox(width: 8));
      buttons.add(OutlinedButton(
        onPressed: () => _avancerEtape(id),
        child: const Text('Étape suivante'),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (buttons.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: buttons),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (DemandeSteps.canSendResumeToChat(status))
              OutlinedButton.icon(
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Résumé chat'),
                onPressed: () => _sendResume(id),
              ),
            if (DemandeSteps.canGenerateInvoice(status))
              OutlinedButton.icon(
                icon: const Icon(Icons.receipt_long, size: 16),
                label: const Text('Facture chat'),
                onPressed: () => _sendFacture(id),
              ),
            OutlinedButton.icon(
              icon: const Icon(Icons.skip_next, size: 16),
              label: const Text('Sauter'),
              onPressed: () => _skipStep(id, currentStep),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Étape'),
              onPressed: () => _addCustomStep(id, currentStep),
            ),
            if (DemandeSteps.canGenerateInvoice(status))
              OutlinedButton.icon(
                icon: const Icon(Icons.file_download, size: 16),
                label: const Text('Excel'),
                onPressed: () async {
                  try {
                    final bytes = await ApiService.instance.downloadPdf('/api/rapports/facture-excel/$id');
                    await Printing.sharePdf(bytes: bytes, filename: 'Facture_FNE_$id.xlsx');
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateDemandeStatus(String id, String nextStatus) async {
    await ApiService.instance.patch('/api/demandes/$id', {'statut': nextStatus});
    _fetchDemands();
  }

  Future<void> _avancerEtape(String id) async {
    await ApiService.instance.post('/api/demandes/$id/avancer', {});
    _fetchDemands();
  }

  Future<void> _sendResume(String id) async {
    await ApiService.instance.post('/api/demandes/$id/envoyer-resume-chat', {});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Résumé envoyé au chat')));
  }

  Future<void> _sendFacture(String id) async {
    await ApiService.instance.post('/api/demandes/$id/generer-facture', {});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Facture envoyée au chat')));
  }

  Future<void> _skipStep(String id, int step) async {
    await ApiService.instance.post('/api/demandes/$id/sauter-etape', {'etape': step});
    _fetchDemands();
  }

  Future<void> _addCustomStep(String id, int afterStep) async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter une étape'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Libellé de l\'étape'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ajouter')),
        ],
      ),
    );
    if (confirm != true || controller.text.trim().isEmpty) return;
    await ApiService.instance.post('/api/demandes/$id/ajouter-etape', {
      'label': controller.text.trim(),
      'actor': 'Isitek',
      'after_step': afterStep,
    });
    _fetchDemands();
  }

  void _showAccompteDialog(String demandeId) {
    final controller = TextEditingController(text: '30');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Avance (accompte)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Pourcentage (%)', suffixText: '%'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final pct = int.tryParse(controller.text) ?? 30;
              Navigator.pop(ctx);
              await ApiService.instance.patch('/api/demandes/$demandeId', {
                'accompte_pourcentage': pct,
                'statut': 'avance_accompte',
              });
              _fetchDemands();
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showGarantieDialog(String demandeId) {
    final moisController = TextEditingController(text: '12');
    DateTime debut = DateTime.now();
    DateTime fin = DateTime.now().add(const Duration(days: 365));
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('SAV - Garantie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: moisController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Durée garantie (mois)'),
              ),
              ListTile(
                title: Text('Début : ${debut.day}/${debut.month}/${debut.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: debut, firstDate: DateTime(2020), lastDate: DateTime(2035));
                  if (d != null) setDialogState(() => debut = d);
                },
              ),
              ListTile(
                title: Text('Fin : ${fin.day}/${fin.month}/${fin.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: fin, firstDate: DateTime(2020), lastDate: DateTime(2035));
                  if (d != null) setDialogState(() => fin = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ApiService.instance.patch('/api/demandes/$demandeId', {
                  'garantie_mois': int.tryParse(moisController.text) ?? 12,
                  'garantie_debut': '${debut.year}-${debut.month.toString().padLeft(2, '0')}-${debut.day.toString().padLeft(2, '0')}',
                  'garantie_fin': '${fin.year}-${fin.month.toString().padLeft(2, '0')}-${fin.day.toString().padLeft(2, '0')}',
                  'statut': 'sav_garantie',
                });
                _fetchDemands();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDevisDialog(BuildContext context, String demandeId) {
    final priceController = TextEditingController(text: '45000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envoyer l\'offre commerciale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Montant de l\'offre commerciale (FCFA) :'),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                suffixText: 'FCFA',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final price = int.tryParse(priceController.text) ?? 45000;
              Navigator.of(ctx).pop();
              await ApiService.instance.patch('/api/demandes/$demandeId', {
                'statut': 'devis_propose',
                'devis_montant': price,
              });
              _fetchDemands();
            },
            style: ElevatedButton.styleFrom(backgroundColor: IsitekColors.green),
            child: const Text('Envoyer l\'offre'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String desc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_ind_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: IsitekColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: IsitekColors.textSoft, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortBar({
    required List<Map<String, String>> fields,
    required String currentField,
    required bool currentAsc,
    required Function(String, bool) onSortChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text(
            'Trier par :',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: IsitekColors.textDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: fields.map((field) {
                  final isSelected = currentField == field['value'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        if (isSelected) {
                          onSortChanged(field['value']!, !currentAsc);
                        } else {
                          onSortChanged(field['value']!, false);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? IsitekColors.green : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              field['label']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : IsitekColors.textDark,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 4),
                              Icon(
                                currentAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminChatScreen extends StatefulWidget {
  final int clientId;
  final String clientName;
  const AdminChatScreen({super.key, required this.clientId, required this.clientName});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<String> _clientPhotos = [];
  bool _loadingPhotos = true;

  @override
  void initState() {
    super.initState();
    DemandeService.instance.setActiveClient(widget.clientId);
    _loadClientPhotos();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _loadClientPhotos() async {
    setState(() => _loadingPhotos = true);
    try {
      await DemandeService.instance.fetchData();
      final demandes = DemandeService.instance.demandesForClient(widget.clientId);
      final photos = <String>[];
      for (final d in demandes) {
        photos.addAll(d.photos);
      }
      if (mounted) setState(() { _clientPhotos = photos; _loadingPhotos = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPhotos = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    await DemandeService.instance.sendClientMessage(text);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientName),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_loadingPhotos)
            const LinearProgressIndicator(color: IsitekColors.green, minHeight: 2)
          else if (_clientPhotos.isNotEmpty)
            _buildPhotosSection(),
          // Chat thread list
          Expanded(
            child: ListenableBuilder(
              listenable: DemandeService.instance,
              builder: (context, _) {
                final list = DemandeService.instance.messages;
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final msg = list[index];
                    final isSupport = msg.sender == 'support';
                    return _buildMessageBubble(msg, isSupport);
                  },
                );
              },
            ),
          ),

          // Message input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildPhotosSection() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.photo_library_outlined, size: 16, color: IsitekColors.green),
              SizedBox(width: 6),
              Text(
                'Photos des demandes du client',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _clientPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final url = _clientPhotos[index];
                return GestureDetector(
                  onTap: () => _showPhotoFullScreen(url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoFullScreen(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isSupport) {
    final timeStr = '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isSupport ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isSupport ? IsitekColors.greenDark : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isSupport ? const Radius.circular(16) : Radius.zero,
            bottomRight: isSupport ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                color: isSupport ? Colors.white : IsitekColors.textDark,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isSupport ? Colors.white60 : Colors.grey[400],
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Répondre au client...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: IsitekColors.green,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
