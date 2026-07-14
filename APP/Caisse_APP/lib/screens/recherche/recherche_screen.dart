import 'package:flutter/material.dart';
import '../../db/db_helper.dart';
import '../../models/caisse_operation.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

/// Écran de recherche puissante : permet de retrouver une opération en
/// tapant un nom, un montant de solde, une année, un mois ou une semaine.
/// Le résultat affiche directement toutes les informations associées
/// (nom & prénoms, détail, date, montants, période...).
class RechercheScreen extends StatefulWidget {
  const RechercheScreen({super.key});

  @override
  State<RechercheScreen> createState() => _RechercheScreenState();
}

class _RechercheScreenState extends State<RechercheScreen> {
  final _db = DBHelper.instance;
  final _texteCtrl = TextEditingController();
  final _soldeCtrl = TextEditingController();

  String? _annee;
  String? _mois;
  String? _semaine;
  List<String> _anneesDisponibles = [];

  List<CaisseOperation> _resultats = [];
  bool _recherche = false;
  bool _aLance = false;

  @override
  void initState() {
    super.initState();
    _chargerAnnees();
  }

  Future<void> _chargerAnnees() async {
    final annees = await _db.getAnneesDisponibles();
    setState(() => _anneesDisponibles = annees);
  }

  @override
  void dispose() {
    _texteCtrl.dispose();
    _soldeCtrl.dispose();
    super.dispose();
  }

  Future<void> _rechercher() async {
    setState(() {
      _recherche = true;
      _aLance = true;
    });
    final solde = _soldeCtrl.text.trim().isEmpty
        ? null
        : Formatters.parseMontant(_soldeCtrl.text);

    final resultats = await _db.rechercherOperations(
      texte: _texteCtrl.text.trim().isEmpty ? null : _texteCtrl.text.trim(),
      solde: solde,
      annee: _annee,
      mois: _mois,
      semaine: _semaine,
    );

    setState(() {
      _resultats = resultats;
      _recherche = false;
    });
  }

  void _reinitialiser() {
    _texteCtrl.clear();
    _soldeCtrl.clear();
    setState(() {
      _annee = null;
      _mois = null;
      _semaine = null;
      _resultats = [];
      _aLance = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recherche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reinitialiser,
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppTheme.isitekGreenLight,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _texteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom, prénom, détail ou n° de pièce',
                    prefixIcon: Icon(Icons.person_search_outlined),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _rechercher(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _soldeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Solde (FCFA)',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _rechercher(),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _annee,
                        decoration: const InputDecoration(
                          labelText: 'Année',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Toutes')),
                          ..._anneesDisponibles
                              .map((a) => DropdownMenuItem(value: a, child: Text(a))),
                        ],
                        onChanged: (v) => setState(() => _annee = v),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _mois,
                        decoration: const InputDecoration(
                          labelText: 'Mois',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Tous')),
                          ...Formatters.moisFrancais
                              .map((m) => DropdownMenuItem(value: m, child: Text(m))),
                        ],
                        onChanged: (v) => setState(() => _mois = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _recherche ? null : _rechercher,
                    icon: _recherche
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Rechercher'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: !_aLance
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Saisissez un critère (nom, solde, année...) puis appuyez sur Rechercher.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                : _resultats.isEmpty
                    ? const Center(
                        child: Text('Aucun résultat trouvé.',
                            style: TextStyle(color: Colors.black54)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _resultats.length,
                        itemBuilder: (context, index) {
                          final op = _resultats[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          op.nomPrenoms.isEmpty ? '—' : op.nomPrenoms,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                      ),
                                      Text(
                                        Formatters.dateCourte(op.date),
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(op.detailOperation),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      _miniInfo('N° pièce', op.numPiece),
                                      _miniInfo('Semaine', '${op.semaine} (${op.mois} ${op.annee})'),
                                      if (op.entree > 0)
                                        _miniInfo('Entrée', '+${Formatters.montant(op.entree)}',
                                            couleur: AppTheme.isitekGreenDark),
                                      if (op.sortie > 0)
                                        _miniInfo('Sortie', '-${Formatters.montant(op.sortie)}',
                                            couleur: AppTheme.soldeNegatif),
                                      _miniInfo('Solde', Formatters.montantFcfa(op.solde),
                                          couleur: AppTheme.isitekGreenDark),
                                    ],
                                  ),
                                ],
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

  Widget _miniInfo(String label, String valeur, {Color? couleur}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
                text: '$label: ',
                style: const TextStyle(fontSize: 11, color: Colors.black54)),
            TextSpan(
              text: valeur,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: couleur ?? Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
