import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import '../../main.dart' show IsitekColors;
import '../../utils/role_labels.dart';
import '../../devis/screens/devis_hub_screen.dart';
import 'tech_affaires_screen.dart';
import '../shared/staff_messages_screen.dart';
import '../shared/easy_chat_screen.dart';
import '../../rapport/screens/rapport_visite_hub_screen.dart';
import '../auth_pages.dart' show AuthHomePage;
import 'action_prise_screen.dart';
import '../shared/point_traitement_list_screen.dart';
import '../../caisse/screens/caisse_hub_screen.dart';
import '../shared/isitek_hub_screen.dart';
import '../shared/feedback_screen.dart';

class TechRootNavigator extends StatefulWidget {
  const TechRootNavigator({super.key});

  @override
  State<TechRootNavigator> createState() => _TechRootNavigatorState();
}

class _TechRootNavigatorState extends State<TechRootNavigator> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const TechHomeScreen(),
      const TechAffairesScreen(),
      const TechTasksScreen(),
      const TechAdminMessagesScreen(),
      const TechProfileScreen(),
    ];
    
    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 70,
          selectedIndex: _idx,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: IsitekColors.green.withOpacity(0.12),
          onDestinationSelected: (i) => setState(() => _idx = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.today_outlined),
              selectedIcon: Icon(Icons.today_rounded, color: IsitekColors.green),
              label: 'Journée',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_open_outlined),
              selectedIcon: Icon(Icons.folder_open_rounded, color: IsitekColors.green),
              label: 'Affaires',
            ),
            NavigationDestination(
              icon: Icon(Icons.build_outlined),
              selectedIcon: Icon(Icons.build_rounded, color: IsitekColors.green),
              label: 'Actions',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded, color: IsitekColors.green),
              label: 'Messages',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_pin_rounded),
              selectedIcon: Icon(Icons.person_pin_rounded, color: IsitekColors.green),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}

class TechHomeScreen extends StatefulWidget {
  const TechHomeScreen({super.key});

  @override
  State<TechHomeScreen> createState() => _TechHomeScreenState();
}

class _TechHomeScreenState extends State<TechHomeScreen> {
  List<dynamic> _actionsAffaires = [];
  List<dynamic> _actionsInternes = [];
  bool _loading = true;
  int _activeTab = 0; // 0 = Actions affaires, 1 = Actions internes

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ApiService.instance.get('/api/technicien/actions-affaires'),
        ApiService.instance.get('/api/technicien/actions-internes'),
      ]);
      setState(() {
        _actionsAffaires = results[0];
        _actionsInternes = results[1];
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _statutLabel(String s) => {
        'non_entame': 'Non entamé',
        'en_cours': 'En cours',
        'termine': 'Terminé',
        'bloque': 'Bloqué',
        'annule': 'Annulé',
      }[s] ?? s;

  Color _getStatutColor(String s) => {
        'non_entame': Colors.grey,
        'en_cours': Colors.blue,
        'termine': Colors.green,
        'bloque': Colors.orange,
        'annule': Colors.red,
      }[s] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final dateFormatted = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
    final isAffaireTab = _activeTab == 0;
    final filtered = isAffaireTab ? _actionsAffaires : _actionsInternes;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
          : RefreshIndicator(
              onRefresh: _load,
              color: IsitekColors.green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Tech Header banner
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF064E3B), IsitekColors.green],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 60, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'ESPACE INTERVENTION',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified_user_rounded, color: Colors.amber, size: 12),
                                    SizedBox(width: 4),
                                    Text('EMPLOYÉ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bonjour, ${user?.fullName ?? ""}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (user?.poste != null && user!.poste!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                user.poste!,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormatted,
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 1,
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: IsitekColors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.hub_rounded, color: IsitekColors.green),
                          ),
                          title: const Text('Centre ISITEK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Résumé du jour · Astuces · Signaler un bug'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const IsitekHubScreen()));
                          },
                        ),
                      ),
                    ).animate().fade(delay: 50.ms, duration: 300.ms).slideX(begin: 0.05, end: 0),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 1,
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.bug_report_outlined, color: Colors.red.shade700),
                          ),
                          title: const Text('Bugs & améliorations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Signaler un problème ou proposer une idée'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen()));
                          },
                        ),
                      ),
                    ).animate().fade(delay: 55.ms, duration: 300.ms).slideX(begin: 0.05, end: 0),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 1,
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.psychology_alt_outlined, color: Color(0xFF2E7D32)),
                          ),
                          title: const Text('Assistant IA — Easy & Ollama', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Easy : base ISITEK · Ollama : chat libre'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(
                                    title: const Text('Assistant IA'),
                                    backgroundColor: IsitekColors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  body: const EasyChatScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ).animate().fade(delay: 60.ms, duration: 300.ms).slideX(begin: 0.05, end: 0),

                    if (user?.canCreateDevisEffective == true) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 1,
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.request_quote_rounded, color: Color(0xFF1565C0)),
                          ),
                          title: const Text('Générer un devis proforma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Analyser emails, rechercher références, exporter PDF'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DevisHubScreen()),
                            );
                          },
                        ),
                      ),
                    ).animate().fade(delay: 80.ms, duration: 300.ms).slideX(begin: 0.05, end: 0),
                    ],
                    const SizedBox(height: 12),
                    if (user?.canCreateRapportEffective == true)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 1,
                          child: ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00695C).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.description_outlined, color: Color(0xFF00695C)),
                            ),
                            title: const Text('Rapport de visite', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: const Text('PDF ISITEK — SERVICE COMMERCIAL à droite'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RapportVisiteHubScreen()),
                              );
                            },
                          ),
                        ),
                      ).animate().fade(delay: 70.ms, duration: 300.ms).slideX(begin: 0.05, end: 0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 1,
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: IsitekColors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.assignment_outlined, color: IsitekColors.green),
                          ),
                          title: const Text('Point traitement des demandes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Saisir et exporter la fiche Excel', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: IsitekColors.green),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PointTraitementListScreen()),
                            );
                          },
                        ),
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 1,
                        child: ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF6C00).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFEF6C00)),
                          ),
                          title: const Text('Caisse ISITEK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Fiche contrôle & livre de caisse hebdomadaire', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: IsitekColors.green),
                          onTap: () {
                            final user = ApiService.instance.currentUser;
                            if (user?.canAccessCaisseEffective != true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Accès Caisse non autorisé — contactez l\'admin')),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CaisseHubScreen()),
                            );
                          },
                        ),
                      ),
                    ).animate().fadeIn(delay: 120.ms),

                    const SizedBox(height: 24),

                    // Sliding segment control
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _activeTab = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 0 ? IsitekColors.green : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.business,
                                          size: 16,
                                          color: _activeTab == 0 ? Colors.white : IsitekColors.textDark,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Affaires (${_actionsAffaires.length})',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _activeTab == 0 ? Colors.white : IsitekColors.textDark,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _activeTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _activeTab == 1 ? IsitekColors.green : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.assignment_turned_in_rounded,
                                          size: 16,
                                          color: _activeTab == 1 ? Colors.white : IsitekColors.textDark,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Internes (${_actionsInternes.length})',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: _activeTab == 1 ? Colors.white : IsitekColors.textDark,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        isAffaireTab
                            ? 'ACTIONS DES AFFAIRES (CLIENTS EXTERNES)'
                            : 'ACTIONS INTERNES (ISITEK)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: IsitekColors.textSoft,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Actions list
                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
                          child: Column(
                            children: [
                              Icon(Icons.event_available_outlined, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                isAffaireTab
                                    ? 'Aucune action d\'affaire disponible.'
                                    : 'Aucune action interne disponible.',
                                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final a = filtered[index];
                            final dejaPrise = a['deja_prise'] == true;
                            final isAffaire = isAffaireTab;
                            final statusColor = _getStatutColor(a['statut'] as String);
                            final isOwn = a['is_own_action'] == true;
                            final hasResp = a['has_responsible'] == true;
                            final respNom = a['responsable_nom'] ?? 'Non assigné';
                            final supportNom = a['support_nom'];

                            final canInteract = !dejaPrise &&
                                (isOwn || !hasResp || a['role_assigne'] == 'support');

                            final cardContent = Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Circular Avatar indicator
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isAffaire
                                          ? IsitekColors.greenSoft
                                          : Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isAffaire ? Icons.business : Icons.assignment_turned_in_rounded,
                                      color: isAffaire ? IsitekColors.greenDark : Colors.blue.shade700,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Action Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          a['libelle'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: IsitekColors.textDark),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isAffaire
                                              ? 'Client : ${a['client']}'
                                              : 'Client interne : ${a['client']}',
                                          style: const TextStyle(fontSize: 12, color: IsitekColors.textSoft),
                                        ),
                                        if (isAffaire && respNom != 'Non assigné') ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Resp. affaire : $respNom',
                                            style: const TextStyle(fontSize: 11, color: IsitekColors.textSoft),
                                          ),
                                        ],
                                        if (!isAffaire && a['priorite'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Priorité : ${a['priorite']}',
                                            style: const TextStyle(fontSize: 11, color: IsitekColors.textSoft),
                                          ),
                                        ],
                                        if (supportNom != null && supportNom.toString().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Support : $supportNom',
                                            style: const TextStyle(fontSize: 11, color: IsitekColors.textSoft),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _statutLabel(a['statut'] as String),
                                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                              ),
                                            ),
                                            if (a['affaire_numero'] != null) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                '#${a['affaire_numero']}',
                                                style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ]
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Trailing Arrow / Chip / Responsible Badge
                                  if (hasResp && !isOwn && !dejaPrise)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.amber.shade200),
                                      ),
                                      child: Text(
                                        'Assignée',
                                        style: TextStyle(color: Colors.amber.shade800, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else if (dejaPrise)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Prise', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                                    )
                                  else
                                    const Icon(Icons.arrow_forward_ios_rounded, color: IsitekColors.green, size: 16),
                                ],
                              ),
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Opacity(
                                opacity: canInteract ? 1.0 : 0.6,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: (!canInteract || dejaPrise)
                                        ? null
                                        : () async {
                                            final result = await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ActionPriseScreen(action: a),
                                              ),
                                            );
                                            if (result == true) _load();
                                          },
                                    child: cardContent,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: (index * 80).ms, duration: 400.ms).slideX(begin: 0.05, end: 0);
                          },
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

class TechTasksScreen extends StatefulWidget {
  const TechTasksScreen({super.key});

  @override
  State<TechTasksScreen> createState() => _TechTasksScreenState();
}

class _TechTasksScreenState extends State<TechTasksScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _prises = [];
  bool _loading = true;
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.instance.get('/api/technicien/mes-actions');
      setState(() => _prises = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _prisesAffaires =>
      _prises.where((p) => p['affaire_action_id'] != null).toList();

  List<dynamic> get _prisesInternes =>
      _prises.where((p) => p['action_interne_id'] != null).toList();

  List<dynamic> _filter(List<dynamic> list, bool isAffaire) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((p) {
      final status = _statutLabel(p['statut'] as String? ?? '').toLowerCase();
      final dateStr = p['date_prise'] != null
          ? DateFormat('dd/MM/yyyy').format(DateTime.parse(p['date_prise'])).toLowerCase()
          : '';
      final comment = (p['commentaire'] ?? '').toString().toLowerCase();
      final supportTravail = (p['support_travail'] ?? '').toString().toLowerCase();

      final affaireAction = p['affaire_action'] as Map<String, dynamic>?;
      final actionInterne = p['action_interne'] as Map<String, dynamic>?;
      
      final title = isAffaire
          ? (affaireAction?['libelle'] ?? '').toString().toLowerCase()
          : (actionInterne?['nom'] ?? '').toString().toLowerCase();

      final description = isAffaire
          ? ''
          : (actionInterne?['commentaire'] ?? '').toString().toLowerCase();

      final client = isAffaire
          ? (p['client'] ?? '').toString().toLowerCase()
          : '';

      return title.contains(q) ||
          status.contains(q) ||
          dateStr.contains(q) ||
          comment.contains(q) ||
          supportTravail.contains(q) ||
          description.contains(q) ||
          client.contains(q);
    }).toList();
  }

  Color _getStatusColor(String s) => {
        'non_entame': Colors.grey,
        'en_cours': Colors.blue,
        'termine': Colors.green,
        'bloque': Colors.orange,
        'annule': Colors.red,
      }[s] ?? Colors.grey;

  String _statutLabel(String s) => {
        'non_entame': 'Non entamé',
        'en_cours': 'En cours',
        'termine': 'Terminé',
        'bloque': 'Bloqué',
        'annule': 'Annulé',
      }[s] ?? s;

  @override
  Widget build(BuildContext context) {
    final filteredAffaires = _filter(_prisesAffaires, true);
    final filteredInternes = _filter(_prisesInternes, false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mes Actions en Cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: IsitekColors.textDark,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: IsitekColors.green,
          unselectedLabelColor: IsitekColors.textSoft,
          indicatorColor: IsitekColors.green,
          tabs: [
            Tab(text: 'Affaires (${filteredAffaires.length})'),
            Tab(text: 'Internes (${filteredInternes.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: IsitekColors.greenDark),
            onPressed: _load,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
          : Column(
              children: [
                if (_prises.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher une action...',
                        prefixIcon: const Icon(Icons.search, color: IsitekColors.green),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: IsitekColors.green, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPrisesList(filteredAffaires, isAffaire: true),
                      _buildPrisesList(filteredInternes, isAffaire: false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPrisesList(List<dynamic> list, {required bool isAffaire}) {
    if (list.isEmpty) {
      if (_searchQuery.isNotEmpty) {
        return Center(
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
        );
      }
      return _buildEmptyState(isAffaire: isAffaire);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final p = list[i];
        final dateFormatted = p['date_prise'] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(p['date_prise']))
            : '—';
        final statusColor = _getStatusColor(p['statut'] as String? ?? 'en_cours');
        final affaireAction = p['affaire_action'] as Map<String, dynamic>?;
        final actionInterne = p['action_interne'] as Map<String, dynamic>?;
        final title = isAffaire
            ? (affaireAction?['libelle'] ?? 'Action affaire #${p['affaire_action_id']}')
            : (actionInterne?['nom'] ?? 'Action interne #${p['action_interne_id']}');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: isAffaire ? IsitekColors.greenSoft : Colors.blue.shade50,
              child: Icon(
                isAffaire ? Icons.business : Icons.assignment_turned_in_rounded,
                color: isAffaire ? IsitekColors.greenDark : Colors.blue.shade700,
              ),
            ),
            title: Text(
              title as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: IsitekColors.textDark),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Rôle : ${p['role_prise']}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text('Pris le : $dateFormatted', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statutLabel(p['statut'] as String? ?? 'en_cours'),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.edit_note_rounded, color: IsitekColors.green, size: 28),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActionPriseUpdateScreen(prise: p),
                ),
              );
              _load();
            },
          ),
        ).animate().fadeIn(delay: (i * 80).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildEmptyState({required bool isAffaire}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAffaire ? Icons.business_outlined : Icons.assignment_outlined,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              isAffaire ? 'Aucune action d\'affaire prise' : 'Aucune action interne prise',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: IsitekColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Allez sur l\'onglet "Journée" pour choisir une action et commencer votre travail.',
              textAlign: TextAlign.center,
              style: TextStyle(color: IsitekColors.textSoft, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class TechSupportScreen extends StatefulWidget {
  const TechSupportScreen({super.key});

  @override
  State<TechSupportScreen> createState() => _TechSupportScreenState();
}

class _TechSupportScreenState extends State<TechSupportScreen> {
  List<dynamic> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await ApiService.instance.get('/api/technicien/support-tasks');
      setState(() => _tasks = list);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mes Tâches Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: IsitekColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: IsitekColors.greenDark),
            onPressed: _load,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
          : _tasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, i) {
                    final t = _tasks[i];
                    final dateFormatted = t['date_prise'] != null
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(t['date_prise']))
                        : '—';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Support du $dateFormatted',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: IsitekColors.textDark),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    t['statut'].toString().toUpperCase(),
                                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 9),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (t['support_travail'] != null && t['support_travail'].toString().isNotEmpty) ...[
                              Text(
                                'Travail effectué :',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t['support_travail'],
                                style: const TextStyle(fontSize: 13, color: IsitekColors.textSoft),
                              ),
                              const SizedBox(height: 12),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: IsitekColors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SupportUpdateScreen(prise: t),
                                    ),
                                  );
                                  _load();
                                },
                                icon: const Icon(Icons.edit_rounded, size: 16),
                                label: const Text('Décrire mon travail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (i * 80).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent_rounded, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aucune tâche support',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: IsitekColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Les actions pour lesquelles vous êtes assigné comme support technique apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(color: IsitekColors.textSoft, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class TechProfileScreen extends StatelessWidget {
  const TechProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final initials = user != null
        ? '${user.prenom.substring(0, 1).toUpperCase()}${user.nom.substring(0, 1).toUpperCase()}'
        : 'T';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: IsitekColors.textDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // User Avatar header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: IsitekColors.greenSoft,
                    child: Text(
                      initials,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: IsitekColors.greenDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: IsitekColors.greenSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      displayRole(user?.poste, user?.role ?? 'technicien').toUpperCase(),
                      style: const TextStyle(color: IsitekColors.greenDark, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: 32),

            // Profile info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email_outlined, 'Adresse e-mail', user?.email ?? 'N/A'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ),
                  _buildInfoRow(Icons.phone_android_outlined, 'Téléphone', user?.telephone ?? 'N/A'),
                ],
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 400.ms),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IsitekHubScreen())),
                icon: const Icon(Icons.hub_rounded, color: IsitekColors.green),
                label: const Text('CENTRE ISITEK', style: TextStyle(color: IsitekColors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: IsitekColors.green, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ).animate().fadeIn(delay: 120.ms, duration: 400.ms),

            const SizedBox(height: 12),

            // Logout button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ApiService.instance.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthHomePage()),
                    (_) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: const Text('SE DÉCONNECTER', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: IsitekColors.textDark, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}
