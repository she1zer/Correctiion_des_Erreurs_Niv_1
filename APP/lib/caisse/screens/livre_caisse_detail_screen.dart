import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../main.dart' show IsitekColors;
import '../services/caisse_api_service.dart';
import '../services/caisse_pdf_service.dart';
import '../services/excel_service.dart';
import '../services/file_service.dart';
import '../utils/caisse_formatters.dart';

/// Opération de caisse (ligne livre) — équivalent caisse_app.
class LivreOperation {
  int? id;
  DateTime date;
  String numPiece;
  String nomPrenoms;
  String detailOperation;
  double entree;
  double sortie;
  double solde;

  LivreOperation({
    this.id,
    required this.date,
    this.numPiece = '',
    this.nomPrenoms = '',
    required this.detailOperation,
    this.entree = 0,
    this.sortie = 0,
    this.solde = 0,
  });

  LivreOperation copyWith({
    int? id,
    DateTime? date,
    String? numPiece,
    String? nomPrenoms,
    String? detailOperation,
    double? entree,
    double? sortie,
    double? solde,
  }) {
    return LivreOperation(
      id: id ?? this.id,
      date: date ?? this.date,
      numPiece: numPiece ?? this.numPiece,
      nomPrenoms: nomPrenoms ?? this.nomPrenoms,
      detailOperation: detailOperation ?? this.detailOperation,
      entree: entree ?? this.entree,
      sortie: sortie ?? this.sortie,
      solde: solde ?? this.solde,
    );
  }

  Map<String, dynamic> toJson(int numero) => {
        'numero': numero,
        'date_operation': DateFormat('yyyy-MM-dd').format(date),
        'numero_piece': numPiece,
        'nom_prenoms': nomPrenoms,
        'detail_operation': detailOperation,
        'entree': entree != 0 ? entree : null,
        'sortie': sortie != 0 ? sortie : null,
        'solde': solde,
      };

  static LivreOperation fromApi(Map<String, dynamic> m) {
    return LivreOperation(
      id: m['id'] as int?,
      date: m['date_operation'] != null
          ? DateTime.parse(m['date_operation'])
          : DateTime.now(),
      numPiece: m['numero_piece']?.toString() ?? '',
      nomPrenoms: m['nom_prenoms']?.toString() ?? '',
      detailOperation: m['detail_operation']?.toString() ?? '',
      entree: CaisseFormatters.parseMontant(m['entree']?.toString() ?? ''),
      sortie: CaisseFormatters.parseMontant(m['sortie']?.toString() ?? ''),
      solde: CaisseFormatters.parseMontant(m['solde']?.toString() ?? ''),
    );
  }
}

/// Écran détail livre de caisse — identique caisse_app, données via API.
class LivreCaisseDetailScreen extends StatefulWidget {
  final int? livreId;
  final String? annee;
  final String? mois;
  final String? semaine;
  final DateTime? periodeDu;
  final DateTime? periodeAu;
  final bool isNouvelle;

  const LivreCaisseDetailScreen({
    super.key,
    this.livreId,
    this.annee,
    this.mois,
    this.semaine,
    this.periodeDu,
    this.periodeAu,
    this.isNouvelle = false,
  });

  @override
  State<LivreCaisseDetailScreen> createState() => _LivreCaisseDetailScreenState();
}

class _LivreCaisseDetailScreenState extends State<LivreCaisseDetailScreen> {
  int? _livreId;
  late String _annee;
  late String _moisLabel;
  late int _moisIndex;
  late String _semaine;
  late DateTime _periodeDu;
  late DateTime _periodeAu;

  List<LivreOperation> _operations = [];
  double _montantOuverture = 0;
  bool _loading = true;
  bool _generating = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _livreId = widget.livreId;
    _annee = widget.annee ?? DateTime.now().year.toString();
    _moisIndex = DateTime.now().month;
    _moisLabel = widget.mois ?? CaisseFormatters.moisFrancais[_moisIndex - 1];
    if (widget.mois != null) {
      _moisIndex = CaisseFormatters.moisIndex(widget.mois!) ?? _moisIndex;
    }
    _semaine = widget.semaine ?? '';
    _periodeDu = widget.periodeDu ?? DateTime.now();
    _periodeAu = widget.periodeAu ?? _periodeDu.add(const Duration(days: 6));
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      if (_livreId == null && widget.isNouvelle) {
        final created = await CaisseApiService.instance.createLivre({
          'annee': int.tryParse(_annee),
          'mois': _moisIndex,
          'semaine': int.tryParse(_semaine),
          'periode_debut': DateFormat('yyyy-MM-dd').format(_periodeDu),
          'periode_fin': DateFormat('yyyy-MM-dd').format(_periodeAu),
          'montant_caisse_date': DateFormat('yyyy-MM-dd').format(_periodeDu),
          'montant_caisse_valeur': 0,
          'lignes': [],
        });
        _livreId = created['id'] as int;
      }

      if (_livreId != null) {
        final d = await CaisseApiService.instance.getLivre(_livreId!);
        _annee = d['annee']?.toString() ?? _annee;
        _moisIndex = d['mois'] as int? ?? _moisIndex;
        _moisLabel = CaisseFormatters.moisLabel(_moisIndex);
        _semaine = d['semaine']?.toString() ?? _semaine;
        if (d['periode_debut'] != null) _periodeDu = DateTime.parse(d['periode_debut']);
        if (d['periode_fin'] != null) _periodeAu = DateTime.parse(d['periode_fin']);
        _montantOuverture =
            CaisseFormatters.parseMontant(d['montant_caisse_valeur']?.toString() ?? '');

        final lignes = (d['lignes'] as List?) ?? [];
        _operations = lignes
            .map((e) => LivreOperation.fromApi(Map<String, dynamic>.from(e as Map)))
            .where((op) =>
                op.detailOperation.trim().isNotEmpty || op.entree != 0 || op.sortie != 0)
            .toList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
        Navigator.pop(context);
        return;
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  double get _soldeActuel {
    if (_operations.isEmpty) return _montantOuverture;
    return _operations.last.solde;
  }

  void _recalculerSoldesEnCascade() {
    double solde = _montantOuverture;
    for (var i = 0; i < _operations.length; i++) {
      final op = _operations[i];
      solde = solde + op.entree - op.sortie;
      _operations[i] = op.copyWith(solde: solde);
    }
  }

  Future<void> _persist() async {
    if (_livreId == null) return;
    setState(() => _saving = true);
    try {
      _recalculerSoldesEnCascade();
      final lignes = _operations.asMap().entries.map((e) => e.value.toJson(e.key + 1)).toList();
      await CaisseApiService.instance.updateLivre(_livreId!, {
        'montant_caisse_valeur': _montantOuverture,
        'montant_caisse_date': DateFormat('yyyy-MM-dd').format(_periodeDu),
        'lignes': lignes,
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _definirOuverture() async {
    final ctrl = TextEditingController(
        text: _montantOuverture != 0 ? CaisseFormatters.montant(_montantOuverture) : '');
    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Montant en caisse au début de semaine'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, CaisseFormatters.parseMontant(ctrl.text)),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (result == null) return;
    setState(() => _montantOuverture = result);
    _recalculerSoldesEnCascade();
    await _persist();
  }

  Future<void> _ajouterOuModifierOperation({LivreOperation? existante}) async {
    final index = existante != null ? _operations.indexOf(existante) : -1;
    final soldeAvant = index > 0
        ? _operations[index - 1].solde
        : (index == 0 ? _montantOuverture : _soldeActuel);

    final result = await showModalBottomSheet<LivreOperation>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OperationForm(
        soldeAvant: soldeAvant,
        operationExistante: existante,
      ),
    );
    if (result == null) return;

    setState(() {
      if (existante != null) {
        _operations[index] = result.copyWith(id: existante.id);
      } else {
        _operations.add(result);
      }
      _recalculerSoldesEnCascade();
    });
    await _persist();
  }

  Future<void> _supprimerOperation(LivreOperation op) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette opération ?'),
        content: Text(op.detailOperation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Oui')),
        ],
      ),
    );
    if (confirme != true) return;
    setState(() {
      _operations.remove(op);
      _recalculerSoldesEnCascade();
    });
    await _persist();
  }

  List<LivreOperationPdf> get _operationsPdf => _operations
      .map((op) => LivreOperationPdf(
            date: op.date,
            numPiece: op.numPiece,
            nomPrenoms: op.nomPrenoms,
            detailOperation: op.detailOperation,
            entree: op.entree,
            sortie: op.sortie,
            solde: op.solde,
          ))
      .toList();

  Future<void> _genererPdf() async {
    setState(() => _generating = true);
    try {
      await _persist();
      final bytes = await CaissePdfService.genererLivreCaisse(
        annee: _annee,
        mois: _moisLabel,
        semaine: _semaine,
        periodeDu: _periodeDu,
        periodeAu: _periodeAu,
        montantOuverture: _montantOuverture,
        operations: _operationsPdf,
      );
      final nomFichier = 'Livre_Caisse_S${_semaine}_${_moisLabel}_$_annee.pdf';
      await CaisseFileService.sauvegarderFichier(bytes, nomFichier);
      if (!mounted) return;
      await _afficherApercuPdf(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur génération PDF : $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _genererExcel() async {
    setState(() => _generating = true);
    try {
      await _persist();
      final bytes = CaisseExcelService.genererLivreCaisseExcel(
        annee: _annee,
        mois: _moisLabel,
        semaine: _semaine,
        periodeDu: _periodeDu,
        periodeAu: _periodeAu,
        montantOuverture: _montantOuverture,
        operations: _operationsPdf,
      );
      final nomFichier = 'Livre_Caisse_S${_semaine}_${_moisLabel}_$_annee.xlsx';
      final file = await CaisseFileService.sauvegarderFichier(bytes, nomFichier);
      if (!mounted) return;
      _proposerActionFichier(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur génération Excel : $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _afficherApercuPdf(Uint8List bytes) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Aperçu du Livre de Caisse'),
            backgroundColor: IsitekColors.green,
            foregroundColor: Colors.white,
          ),
          body: PdfPreview(
            build: (format) async => bytes,
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
          ),
        ),
      ),
    );
  }

  void _proposerActionFichier(File file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fichier généré : ${file.path.split(Platform.pathSeparator).last}'),
        action: SnackBarAction(
          label: 'PARTAGER',
          onPressed: () => CaisseFileService.partagerFichier(file),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Semaine $_semaine — $_moisLabel'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
          : Column(
              children: [
                _buildEnTete(),
                const Divider(height: 1),
                Expanded(
                  child: _operations.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucune opération.\nAppuyez sur + pour en ajouter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                          itemCount: _operations.length,
                          itemBuilder: (context, index) {
                            final op = _operations[index];
                            return _OperationTile(
                              operation: op,
                              onTap: () => _ajouterOuModifierOperation(existante: op),
                              onDelete: () => _supprimerOperation(op),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_generating)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CircularProgressIndicator(color: IsitekColors.green),
            ),
          FloatingActionButton(
            heroTag: 'addOp',
            onPressed: () => _ajouterOuModifierOperation(),
            backgroundColor: IsitekColors.green,
            child: const Icon(Icons.add),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _generating ? null : _genererExcel,
                  icon: const Icon(Icons.grid_on),
                  label: const Text('Excel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _genererPdf,
                  style: ElevatedButton.styleFrom(backgroundColor: IsitekColors.green),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnTete() {
    return Container(
      width: double.infinity,
      color: IsitekColors.greenSoft,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Du ${CaisseFormatters.dateCourte(_periodeDu)} au ${CaisseFormatters.dateCourte(_periodeAu)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _definirOuverture,
                  child: _InfoChip(
                    label: 'Solde ouverture',
                    valeur: CaisseFormatters.montantFcfa(_montantOuverture),
                    editable: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoChip(
                  label: 'Solde actuel',
                  valeur: CaisseFormatters.montantFcfa(_soldeActuel),
                  couleur: IsitekColors.greenDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String valeur;
  final bool editable;
  final Color? couleur;

  const _InfoChip({
    required this.label,
    required this.valeur,
    this.editable = false,
    this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D7D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
              if (editable) ...[
                const SizedBox(width: 4),
                const Icon(Icons.edit, size: 12, color: Colors.black38),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            valeur,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15, color: couleur ?? Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  final LivreOperation operation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _OperationTile({
    required this.operation,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final estEntree = operation.entree > 0;
    return Dismissible(
      key: ValueKey(operation.id ?? operation.hashCode),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: Card(
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: estEntree ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6),
            child: Icon(
              estEntree ? Icons.south_west : Icons.north_east,
              color: estEntree ? IsitekColors.greenDark : Colors.red.shade700,
              size: 18,
            ),
          ),
          title: Text(operation.nomPrenoms.isEmpty ? '—' : operation.nomPrenoms,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${operation.detailOperation}\n${CaisseFormatters.dateCourte(operation.date)}'
            '${operation.numPiece.isNotEmpty ? " · Pièce n°${operation.numPiece}" : ""}',
          ),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                estEntree
                    ? '+${CaisseFormatters.montant(operation.entree)}'
                    : '-${CaisseFormatters.montant(operation.sortie)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: estEntree ? IsitekColors.greenDark : Colors.red.shade700,
                ),
              ),
              Text('Solde: ${CaisseFormatters.montant(operation.solde)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationForm extends StatefulWidget {
  final double soldeAvant;
  final LivreOperation? operationExistante;

  const _OperationForm({required this.soldeAvant, this.operationExistante});

  @override
  State<_OperationForm> createState() => _OperationFormState();
}

class _OperationFormState extends State<_OperationForm> {
  late DateTime _date;
  final _numPieceCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  final _montantCtrl = TextEditingController();
  bool _isEntree = false;

  @override
  void initState() {
    super.initState();
    final op = widget.operationExistante;
    _date = op?.date ?? DateTime.now();
    _numPieceCtrl.text = op?.numPiece ?? '';
    _nomCtrl.text = op?.nomPrenoms ?? '';
    _detailCtrl.text = op?.detailOperation ?? '';
    if (op != null) {
      _isEntree = op.entree > 0;
      _montantCtrl.text = CaisseFormatters.montant(_isEntree ? op.entree : op.sortie);
    }
  }

  @override
  void dispose() {
    _numPieceCtrl.dispose();
    _nomCtrl.dispose();
    _detailCtrl.dispose();
    _montantCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _valider() {
    if (_detailCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Le détail de l\'opération est requis')));
      return;
    }
    final montant = CaisseFormatters.parseMontant(_montantCtrl.text);
    if (montant <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Montant invalide')));
      return;
    }

    final entree = _isEntree ? montant : 0.0;
    final sortie = _isEntree ? 0.0 : montant;
    final solde = widget.soldeAvant + entree - sortie;

    Navigator.pop(
      context,
      LivreOperation(
        date: _date,
        numPiece: _numPieceCtrl.text.trim(),
        nomPrenoms: _nomCtrl.text.trim(),
        detailOperation: _detailCtrl.text.trim(),
        entree: entree,
        sortie: sortie,
        solde: solde,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.operationExistante == null
                  ? 'Nouvelle opération'
                  : 'Modifier l\'opération',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Date : ${CaisseFormatters.dateCourte(_date)}'),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: _choisirDate,
            ),
            TextField(
              controller: _numPieceCtrl,
              decoration: const InputDecoration(labelText: 'N° de pièce'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom & Prénoms'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailCtrl,
              decoration: const InputDecoration(labelText: "Détail de l'opération"),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Entrée'),
                    selected: _isEntree,
                    onSelected: (v) => setState(() => _isEntree = true),
                    selectedColor: IsitekColors.greenSoft,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Sortie'),
                    selected: !_isEntree,
                    onSelected: (v) => setState(() => _isEntree = false),
                    selectedColor: const Color(0xFFFCE8E6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _montantCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant (FCFA)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _valider,
              style: ElevatedButton.styleFrom(backgroundColor: IsitekColors.green),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialogue création nouvelle semaine (comme caisse_app).
class NouvelleSemaineLivreDialog extends StatefulWidget {
  const NouvelleSemaineLivreDialog({super.key});

  @override
  State<NouvelleSemaineLivreDialog> createState() => _NouvelleSemaineLivreDialogState();
}

class _NouvelleSemaineLivreDialogState extends State<NouvelleSemaineLivreDialog> {
  final _anneeCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _semaineCtrl = TextEditingController();
  String _mois = CaisseFormatters.moisFrancais[DateTime.now().month - 1];
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
              items: CaisseFormatters.moisFrancais
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _mois = v ?? _mois),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _semaineCtrl,
              decoration: const InputDecoration(labelText: 'N° Semaine', hintText: 'ex: 16'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_du == null ? 'Période du...' : 'Du ${CaisseFormatters.dateCourte(_du!)}'),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () => _choisirDate(debut: true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_au == null ? 'Période au...' : 'Au ${CaisseFormatters.dateCourte(_au!)}'),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () => _choisirDate(debut: false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
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
