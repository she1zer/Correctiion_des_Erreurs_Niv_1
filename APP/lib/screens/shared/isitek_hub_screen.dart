import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../main.dart' show IsitekColors;
import '../../services/api_service.dart';
import '../../services/hub_api_service.dart';
import '../../widgets/client_tips_carousel.dart';
import 'feedback_screen.dart';

/// Centre ISITEK — résumé quotidien, astuces, signalements, contacts.
/// Accessible à tous les rôles (admin, technicien, client).
class IsitekHubScreen extends StatefulWidget {
  const IsitekHubScreen({super.key});

  @override
  State<IsitekHubScreen> createState() => _IsitekHubScreenState();
}

class _IsitekHubScreenState extends State<IsitekHubScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await HubApiService.instance.summary();
      if (mounted) setState(() { _summary = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _isAdmin => ApiService.instance.currentUser?.isAdmin ?? false;

  Future<void> _callSupport() async {
    const phone = '+2252722247856';
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _emailSupport() async {
    final uri = Uri.parse('mailto:contact@isitek.ci?subject=ISITEK%20Connect%20Support');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Centre ISITEK'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: IsitekColors.green,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(color: IsitekColors.green)),
              )
            else ...[
              _buildGreeting(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 20),
              _buildTasksSection(),
            ],
            const SizedBox(height: 24),
            const Text('Actions rapides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _actionTile(
              icon: Icons.bug_report_rounded,
              color: Colors.red.shade700,
              title: 'Signaler un bug ou une idée',
              subtitle: 'Améliorations, suggestions, problèmes rencontrés',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen())),
            ),
            _actionTile(
              icon: Icons.phone_in_talk_rounded,
              color: IsitekColors.greenDark,
              title: 'Appeler le support ISITEK',
              subtitle: '+225 27 22 24 78 56',
              onTap: _callSupport,
            ),
            _actionTile(
              icon: Icons.email_outlined,
              color: Colors.blue.shade700,
              title: 'Envoyer un e-mail',
              subtitle: 'contact@isitek.ci',
              onTap: _emailSupport,
            ),
            if (_isAdmin)
              _actionTile(
                icon: Icons.language_rounded,
                color: Colors.deepPurple,
                title: 'Page web des signalements',
                subtitle: 'Voir tous les bugs sur le navigateur (/bugs)',
                onTap: openBugsWebPage,
              ),
            const SizedBox(height: 28),
            const Text('Astuces ISITEK', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const ClientTipsCarousel(loadFromApi: true, showHeader: false),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    final msg = _summary?['message']?.toString() ?? 'Bienvenue sur ISITEK Connect';
    final name = ApiService.instance.currentUser?.prenom ?? '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF008940), Color(0xFF005E2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: IsitekColors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isNotEmpty ? 'Bonjour $name 👋' : 'Bonjour 👋',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.92), fontSize: 14, height: 1.4)),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildStatsGrid() {
    final s = _summary ?? {};
    final role = s['role']?.toString() ?? '';
    final cards = <Widget>[
      _statChip('Mes signalements', s['mes_signalements'] ?? 0, Icons.feedback_outlined, Colors.orange),
      _statChip('Astuces', s['astuces_disponibles'] ?? 0, Icons.tips_and_updates_rounded, IsitekColors.green),
    ];
    if (role == 'admin' || role == 'technicien') {
      cards.insertAll(0, [
        _statChip('En cours', s['actions_en_cours'] ?? 0, Icons.pending_actions_rounded, Colors.blue),
        _statChip('Urgentes', s['actions_urgentes'] ?? 0, Icons.priority_high_rounded, Colors.red),
      ]);
    }
    if (role == 'admin') {
      cards.add(_statChip('Bugs en attente', s['feedback_en_attente'] ?? 0, Icons.bug_report, Colors.deepPurple));
      cards.add(_statChip('Demandes ouvertes', s['demandes_ouvertes'] ?? 0, Icons.inbox_rounded, Colors.teal));
    }
    if (role == 'client') {
      cards.insert(0, _statChip('Mes demandes', s['demandes_ouvertes'] ?? 0, Icons.assignment_rounded, Colors.blue));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards,
    );
  }

  Widget _statChip(String label, dynamic value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    final tasks = (_summary?['taches_du_jour'] as List?) ?? [];
    if (tasks.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('À traiter aujourd\'hui', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...tasks.map((t) {
          final m = Map<String, dynamic>.from(t as Map);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: IsitekColors.greenSoft,
                child: Icon(
                  m['type'] == 'demande' ? Icons.assignment : Icons.folder_open,
                  color: IsitekColors.greenDark,
                  size: 20,
                ),
              ),
              title: Text(m['label']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text('Statut : ${m['statut'] ?? ''}${m['echeance'] != null ? ' · Échéance ${m['echeance']}' : ''}'),
            ),
          );
        }),
      ],
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
