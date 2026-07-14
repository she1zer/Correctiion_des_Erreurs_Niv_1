import 'package:flutter/material.dart';
import '../../db/db_helper.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import 'livre_caisse_detail_screen.dart';

/// Liste des semaines de livre de caisse déjà créées, avec possibilité
/// d'en créer une nouvelle.
class LivreCaisseListeScreen extends StatefulWidget {
  const LivreCaisseListeScreen({super.key});

  @override
  State<LivreCaisseListeScreen> createState() => _LivreCaisseListeScreenState();
}

class _LivreCaisseListeScreenState extends State<LivreCaisseListeScreen> {
  final _db = DBHelper.instance;
  List<Map<String, dynamic>> _semaines = [];
  bool _loading = true;
  String? _filtreAnnee;
  List<String> _annees = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final annees = await _db.getAnneesDisponibles();
    final semaines = await _db.getSemainesDisponibles(annee: _filtreAnnee);
    setState(() {
      _annees = annees;
      _semaines = semaines;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livre de Caisse'),
        actions: [
          if (_annees.isNotEmpty)
            PopupMenuButton<String?>(
              icon: const Icon(Icons.filter_alt_outlined),
              onSelected: (val) {
                setState(() => _filtreAnnee = val);
                _charger();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: null, child: Text('Toutes les années')),
                ..._annees.map((a) => PopupMenuItem(value: a, child: Text(a))),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _semaines.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _semaines.length,
                    itemBuilder: (context, index) {
                      final s = _semaines[index];
                      final periodeDu = DateTime.parse(s['periodeDu'] as String);
                      final periodeAu = DateTime.parse(s['periodeAu'] as String);
                      return Card(
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.isitekGreenLight,
                            child: Text(
                              s['semaine'].toString(),
                              style: const TextStyle(
                                  color: AppTheme.isitekGreenDark, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text('Semaine ${s['semaine']} — ${s['mois']} ${s['annee']}'),
                          subtitle: Text(
                              'Du ${Formatters.dateCourte(periodeDu)} au ${Formatters.dateCourte(periodeAu)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LivreCaisseDetailScreen(
                                annee: s['annee'] as String,
                                mois: s['mois'] as String,
                                semaine: s['semaine'] as String,
                                periodeDu: periodeDu,
                                periodeAu: periodeAu,
                              ),
                            ),
                          ).then((_) => _charger()),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerNouvelleSemaine,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle semaine'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 72, color: Colors.black26),
            const SizedBox(height: 16),
            const Text(
              'Aucun livre de caisse pour le moment.\nCréez votre première semaine.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _creerNouvelleSemaine() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _NouvelleSemaineDialog(),
    );
    if (result == null) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LivreCaisseDetailScreen(
          annee: result['annee'] as String,
          mois: result['mois'] as String,
          semaine: result['semaine'] as String,
          periodeDu: result['periodeDu'] as DateTime,
          periodeAu: result['periodeAu'] as DateTime,
          isNouvelle: true,
        ),
      ),
    ).then((_) => _charger());
  }
}

class _NouvelleSemaineDialog extends StatefulWidget {
  const _NouvelleSemaineDialog();

  @override
  State<_NouvelleSemaineDialog> createState() => _NouvelleSemaineDialogState();
}

class _NouvelleSemaineDialogState extends State<_NouvelleSemaineDialog> {
  final _anneeCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _semaineCtrl = TextEditingController();
  String _mois = Formatters.moisFrancais[DateTime.now().month - 1];
  DateTime? _du;
  DateTime? _au;

  @override
  void dispose() {
    _anneeCtrl.dispose();
    _semaineCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate({required bool debut}) async {
    final initial = (debut ? _du : _au) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (debut) {
          _du = picked;
          _au ??= picked.add(const Duration(days: 6));
        } else {
          _au = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle semaine de caisse'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _anneeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Année'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _mois,
              decoration: const InputDecoration(labelText: 'Mois'),
              items: Formatters.moisFrancais
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _mois = v ?? _mois),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _semaineCtrl,
              decoration: const InputDecoration(
                  labelText: 'N° Semaine', hintText: 'ex: 16'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_du == null
                  ? 'Période du...'
                  : 'Du ${Formatters.dateCourte(_du!)}'),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () => _choisirDate(debut: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_au == null
                  ? 'Période au...'
                  : 'Au ${Formatters.dateCourte(_au!)}'),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () => _choisirDate(debut: false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_anneeCtrl.text.trim().isEmpty ||
                _semaineCtrl.text.trim().isEmpty ||
                _du == null ||
                _au == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez remplir tous les champs')),
              );
              return;
            }
            Navigator.pop(context, {
              'annee': _anneeCtrl.text.trim(),
              'mois': _mois,
              'semaine': _semaineCtrl.text.trim(),
              'periodeDu': _du,
              'periodeAu': _au,
            });
          },
          child: const Text('Créer'),
        ),
      ],
    );
  }
}
