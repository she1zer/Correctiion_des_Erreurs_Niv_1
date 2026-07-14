import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../main.dart' show IsitekColors;
import '../../services/feedback_api_service.dart';

/// Signalement bugs / améliorations — accessible à tous les utilisateurs.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _type = 'bug';
  bool _saving = false;
  bool _loading = true;
  List<dynamic> _mine = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadMine();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    setState(() => _loading = true);
    try {
      final list = await FeedbackApiService.instance.mine();
      if (mounted) setState(() { _mine = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().length < 3) {
      _snack('Titre trop court (min. 3 caractères)');
      return;
    }
    if (_descCtrl.text.trim().length < 5) {
      _snack('Description trop courte');
      return;
    }
    setState(() => _saving = true);
    try {
      await FeedbackApiService.instance.create(
        type: _type,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      );
      _titleCtrl.clear();
      _descCtrl.clear();
      HapticFeedback.mediumImpact();
      _snack('Merci ! Votre signalement a été enregistré.', success: true);
      await _loadMine();
      if (mounted) _tabs.animateTo(1);
    } catch (e) {
      _snack('$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? IsitekColors.green : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Bugs & Améliorations'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Nouveau signalement'),
            Tab(text: 'Mes signalements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildForm(),
          _buildMineList(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: IsitekColors.greenSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Text(
            'Décrivez un bug rencontré, une amélioration souhaitée ou toute suggestion. '
            'L\'équipe ISITEK consulte tous les signalements pour améliorer l\'application.',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'bug', label: Text('🐛 Bug'), icon: Icon(Icons.bug_report_outlined, size: 16)),
            ButtonSegment(value: 'improvement', label: Text('💡 Idée'), icon: Icon(Icons.lightbulb_outline, size: 16)),
            ButtonSegment(value: 'other', label: Text('📝 Autre')),
          ],
          selected: {_type},
          onSelectionChanged: (s) => setState(() => _type = s.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Titre',
            hintText: 'Ex: Impossible d\'exporter le PDF caisse',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            labelText: 'Description détaillée',
            hintText: 'Étapes pour reproduire, capture d\'écran, contexte…',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded),
          label: const Text('Envoyer le signalement'),
          style: FilledButton.styleFrom(
            backgroundColor: IsitekColors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMineList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: IsitekColors.green));
    }
    if (_mine.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Aucun signalement pour le moment.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMine,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mine.length,
        itemBuilder: (_, i) {
          final m = Map<String, dynamic>.from(_mine[i] as Map);
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              title: Text(m['title']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(m['description']?.toString() ?? ''),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _badge(_typeLabel(m['type']), _typeColor(m['type'])),
                      const SizedBox(width: 8),
                      _badge(_statusLabel(m['status']), _statusColor(m['status'])),
                    ],
                  ),
                  if (m['admin_response'] != null && m['admin_response'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: IsitekColors.greenSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Réponse ISITEK : ${m['admin_response']}', style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  String _typeLabel(dynamic t) => {'bug': 'Bug', 'improvement': 'Amélioration', 'other': 'Autre'}[t] ?? '$t';
  Color _typeColor(dynamic t) => {'bug': Colors.red.shade700, 'improvement': Colors.blue.shade700, 'other': Colors.purple.shade700}[t] ?? Colors.grey;
  String _statusLabel(dynamic s) => {
        'pending': 'En attente',
        'in_progress': 'En cours',
        'resolved': 'Résolu',
        'rejected': 'Rejeté',
      }[s] ?? '$s';
  Color _statusColor(dynamic s) => {
        'pending': Colors.orange.shade700,
        'in_progress': Colors.blue.shade600,
        'resolved': IsitekColors.green,
        'rejected': Colors.red.shade400,
      }[s] ?? Colors.grey;
}

/// Bouton ouverture page web bugs (admin).
Future<void> openBugsWebPage() async {
  final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
  final uri = Uri.parse('$base/bugs');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
