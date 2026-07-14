import 'package:flutter/material.dart';
import '../../db/db_helper.dart';
import '../../models/fiche_controle.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';
import 'fiche_controle_detail_screen.dart';

/// Liste des fiches de contrôle de caisse déjà créées, avec possibilité
/// d'en créer une nouvelle.
class FicheControleListeScreen extends StatefulWidget {
  const FicheControleListeScreen({super.key});

  @override
  State<FicheControleListeScreen> createState() => _FicheControleListeScreenState();
}

class _FicheControleListeScreenState extends State<FicheControleListeScreen> {
  final _db = DBHelper.instance;
  List<FicheControle> _fiches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final fiches = await _db.getAllFiches();
    setState(() {
      _fiches = fiches;
      _loading = false;
    });
  }

  Future<void> _creerNouvelleFiche() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _NouvelleFicheDialog(),
    );
    if (result == null) return;
    if (!mounted) return;

    final fiche = FicheControle(
      semaine: result['semaine'] as String,
      periodeDu: result['periodeDu'] as DateTime,
      periodeAu: result['periodeAu'] as DateTime,
      soldeTheorique: 0,
      soldeReel: 0,
      ecartAvt: 0,
      observations: '',
      ecartApt: 0,
    );
    final id = await _db.insertFiche(fiche);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FicheControleDetailScreen(fiche: fiche.copyWith(id: id)),
      ),
    ).then((_) => _charger());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiche de Contrôle Caisse')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _fiches.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fact_check_outlined, size: 72, color: Colors.black26),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucune fiche de contrôle.\nCréez votre première fiche.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _fiches.length,
                    itemBuilder: (context, index) {
                      final f = _fiches[index];
                      final ecartNonNul = f.ecartApt != 0;
                      return Card(
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: ecartNonNul
                                ? const Color(0xFFFCE8E6)
                                : AppTheme.isitekGreenLight,
                            child: Icon(
                              ecartNonNul ? Icons.warning_amber_rounded : Icons.check,
                              color: ecartNonNul
                                  ? AppTheme.soldeNegatif
                                  : AppTheme.isitekGreenDark,
                            ),
                          ),
                          title: Text('Semaine ${f.semaine}'),
                          subtitle: Text(
                            'Du ${Formatters.dateCourte(f.periodeDu)} au ${Formatters.dateCourte(f.periodeAu)}\n'
                            'Écart (APT) : ${Formatters.montant(f.ecartApt)} FCFA',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FicheControleDetailScreen(fiche: f),
                            ),
                          ).then((_) => _charger()),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerNouvelleFiche,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle fiche'),
      ),
    );
  }
}

class _NouvelleFicheDialog extends StatefulWidget {
  const _NouvelleFicheDialog();

  @override
  State<_NouvelleFicheDialog> createState() => _NouvelleFicheDialogState();
}

class _NouvelleFicheDialogState extends State<_NouvelleFicheDialog> {
  final _semaineCtrl = TextEditingController();
  DateTime? _du;
  DateTime? _au;

  @override
  void dispose() {
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
      title: const Text('Nouvelle fiche de contrôle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _semaineCtrl,
            decoration: const InputDecoration(labelText: 'N° Semaine', hintText: 'ex: 16'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_du == null ? 'Période du...' : 'Du ${Formatters.dateCourte(_du!)}'),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: () => _choisirDate(debut: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_au == null ? 'Période au...' : 'Au ${Formatters.dateCourte(_au!)}'),
            trailing: const Icon(Icons.calendar_today, size: 18),
            onTap: () => _choisirDate(debut: false),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_semaineCtrl.text.trim().isEmpty || _du == null || _au == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Veuillez remplir tous les champs')),
              );
              return;
            }
            Navigator.pop(context, {
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
