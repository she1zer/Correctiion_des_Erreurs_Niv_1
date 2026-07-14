import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import '../auth_pages.dart' show AuthHomePage;
import 'affaires_list_screen.dart';
import 'actions_list_screen.dart';
import 'create_action_interne_screen.dart';
import 'create_affaire_screen.dart';
import 'rapports_screen.dart';
import 'admin_support_screen.dart';
import 'admin_users_screen.dart';
import '../../devis/screens/devis_hub_screen.dart';
import '../shared/staff_messages_screen.dart';
import '../shared/easy_chat_tab.dart';
import '../shared/easy_chat_screen.dart';
import '../shared/point_traitement_list_screen.dart';
import '../../caisse/screens/caisse_hub_screen.dart';
import '../shared/isitek_hub_screen.dart';
import '../shared/feedback_screen.dart';
import 'admin_astuces_screen.dart';
import 'admin_feedback_screen.dart';

class AdminRootNavigator extends StatefulWidget {
  const AdminRootNavigator({super.key});

  @override
  State<AdminRootNavigator> createState() => _AdminRootNavigatorState();
}

class _AdminRootNavigatorState extends State<AdminRootNavigator> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const AdminDashboard(),
      const AffairesListScreen(),
      const RapportsScreen(),
      const AdminSupportScreen(),
    ];

    return Scaffold(
      body: pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Admin'),
          NavigationDestination(icon: Icon(Icons.folder_open), label: 'Affaires'),
          NavigationDestination(icon: Icon(Icons.assessment_outlined), label: 'Rapports'),
          NavigationDestination(icon: Icon(Icons.forum_rounded), label: 'Support'),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _loading = true;
  int _totalAffaires = 0;
  int _totalActionsInternes = 0;
  int _enCoursCount = 0;
  int _termineCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final affaires = await ApiService.instance.get('/api/affaires/');
      final actions = await ApiService.instance.get('/api/actions-internes/');

      int enCours = 0;
      int termine = 0;

      for (var a in affaires) {
        if (a['statut'] == 'en_cours') enCours++;
        if (a['statut'] == 'termine') termine++;
      }

      for (var ac in actions) {
        if (ac['statut'] == 'en_cours') enCours++;
        if (ac['statut'] == 'termine') termine++;
      }

      if (mounted) {
        setState(() {
          _totalAffaires = affaires.length;
          _totalActionsInternes = actions.length;
          _enCoursCount = enCours;
          _termineCount = termine;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await ApiService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthHomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration ISITEK'),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bonjour ${user?.fullName ?? "Admin"}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Expertise industrielle & Suivi opérationnel',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      if (user?.poste != null && user!.poste!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            user.poste!,
                            style: const TextStyle(color: Color(0xFF008940), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: const Color(0xFF008940).withOpacity(0.1),
                  radius: 24,
                  child: const Icon(Icons.admin_panel_settings, color: Color(0xFF008940), size: 28),
                ),
              ],
            ).animate().fade(duration: 300.ms).slideY(begin: -0.1, end: 0),
            const SizedBox(height: 24),

            // Statistics Grid Section
            const Text(
              'Aperçu de l\'activité',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _loading
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _statCard(
                        title: 'Affaires',
                        value: _totalAffaires.toString(),
                        gradient: const [Color(0xFF008940), Color(0xFF005E2B)],
                        icon: Icons.folder,
                      ),
                      _statCard(
                        title: 'Actions Internes',
                        value: _totalActionsInternes.toString(),
                        gradient: const [Color(0xFF0288D1), Color(0xFF01579B)],
                        icon: Icons.playlist_add_check,
                      ),
                      _statCard(
                        title: 'En cours',
                        value: _enCoursCount.toString(),
                        gradient: const [Color(0xFFFFA000), Color(0xFFF57C00)],
                        icon: Icons.hourglass_empty,
                      ),
                      _statCard(
                        title: 'Clôturées',
                        value: _termineCount.toString(),
                        gradient: const [Color(0xFF00897B), Color(0xFF004D40)],
                        icon: Icons.done_all,
                      ),
                    ],
                  ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 28),

            const Text(
              'Actions rapides',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            _menuCard(
              context,
              icon: Icons.add_business,
              title: 'Créer une affaire',
              subtitle: 'Numéro d\'affaire, client, étapes...',
              color: const Color(0xFF008940),
              onTap: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateAffaireScreen()),
                );
                if (res == true) _loadStats();
              },
            ).animate().fade(delay: 50.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.task_alt,
              title: 'Créer une action interne',
              subtitle: 'Tâche avec priorité et intervenants',
              color: const Color(0xFF0288D1),
              onTap: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateActionInterneScreen()),
                );
                if (res == true) _loadStats();
              },
            ).animate().fade(delay: 100.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.list_alt_rounded,
              title: 'Gérer les affaires',
              subtitle: 'Consulter, exporter Excel, modifier ou supprimer',
              color: Colors.orange[800]!,
              onTap: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AffairesListScreen()),
                );
                _loadStats();
              },
            ).animate().fade(delay: 150.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.checklist_rtl_rounded,
              title: 'Gérer les actions internes',
              subtitle: 'Lister, chercher, modifier ou supprimer les tâches',
              color: Colors.purple[700]!,
              onTap: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActionsListScreen()),
                );
                _loadStats();
              },
            ).animate().fade(delay: 200.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.request_quote_rounded,
              title: 'Générer un devis proforma',
              subtitle: 'Emails clients, recherche références, PDF ISITEK',
              color: const Color(0xFF1565C0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DevisHubScreen()),
                );
              },
            ).animate().fade(delay: 240.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.smart_toy_rounded,
              title: 'Assistant IA — Easy & Ollama',
              subtitle: 'Easy : base ISITEK · Ollama : chat libre',
              color: const Color(0xFF2E7D32),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: const Text('Assistant IA'),
                        backgroundColor: const Color(0xFF008940),
                        foregroundColor: Colors.white,
                      ),
                      body: const EasyChatScreen(),
                    ),
                  ),
                );
              },
            ).animate().fade(delay: 242.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.folder_copy_outlined,
              title: 'Mes devis enregistrés',
              subtitle: 'Consulter, modifier, partager ou supprimer',
              color: const Color(0xFF0277BD),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DevisHubScreen(initialTabIndex: 3)),
                );
              },
            ).animate().fade(delay: 245.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.groups_rounded,
              title: 'Messages équipe',
              subtitle: 'Discuter avec les techniciens',
              color: const Color(0xFF00897B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminStaffInboxScreen()),
                );
              },
            ).animate().fade(delay: 245.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.people_alt_rounded,
              title: 'Gérer les utilisateurs',
              subtitle: 'Employés et clients : modifier, désactiver ou supprimer',
              color: const Color(0xFF6A1B9A),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                );
              },
            ).animate().fade(delay: 250.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.assignment_outlined,
              title: 'Point traitement des demandes',
              subtitle: 'Saisir les demandes clients et exporter la fiche Excel',
              color: const Color(0xFF00695C),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PointTraitementListScreen()),
                );
              },
            ).animate().fade(delay: 250.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.hub_rounded,
              title: 'Centre ISITEK',
              subtitle: 'Résumé du jour, astuces, signalements, contacts',
              color: const Color(0xFF008940),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const IsitekHubScreen()));
              },
            ).animate().fade(delay: 248.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.bug_report_rounded,
              title: 'Signalements & bugs',
              subtitle: 'Consulter et traiter les retours utilisateurs',
              color: Colors.red.shade700,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeedbackScreen()));
              },
            ).animate().fade(delay: 249.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.tips_and_updates_rounded,
              title: 'Gérer les astuces',
              subtitle: 'Ajouter, modifier ou supprimer les conseils clients',
              color: const Color(0xFFF9A825),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAstucesScreen()));
              },
            ).animate().fade(delay: 250.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 10),

            _menuCard(
              context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Caisse ISITEK',
              subtitle: 'Fiche contrôle caisse & livre hebdomadaire — PDF + recherche',
              color: const Color(0xFFEF6C00),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CaisseHubScreen()),
                );
              },
            ).animate().fade(delay: 250.ms, duration: 250.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required List<Color> gradient,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: gradient.last.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
