import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../db/db_helper.dart';
import '../../models/caisse_operation.dart';
import '../../services/pdf_service.dart';
import '../../services/excel_service.dart';
import '../../services/file_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

/// Écran de saisie et consultation du Livre de Caisse Hebdomadaire pour
/// une semaine donnée. Permet d'ajouter / modifier / supprimer des
/// opérations, puis de générer le PDF ou l'Excel identique au modèle papier.
class LivreCaisseDetailScreen extends StatefulWidget {
  final String annee;
  final String mois;
  final String semaine;
  final DateTime periodeDu;
  final DateTime periodeAu;
  final bool isNouvelle;

  const LivreCaisseDetailScreen({
    super.key,
    required this.annee,
    required this.mois,
    required this.semaine,
    required this.periodeDu,
    required this.periodeAu,
    this.isNouvelle = false,
  });

  @override
  State<LivreCaisseDetailScreen> createState() => _LivreCaisseDetailScreenState();
}

class _LivreCaisseDetailScreenState extends State<LivreCaisseDetailScreen> {
  final _db = DBHelper.instance;
  List<CaisseOperation> _operations = [];
  double _montantOuverture = 0;
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final ops = await _db.getOperationsBySemaine(
      annee: widget.annee,
      mois: widget.mois,
      semaine: widget.semaine,
    );
    double ouverture = 0;
    final operations = <CaisseOperation>[];
    for (final op in ops) {
      if (op.estSoldeOuverture) {
        ouverture = op.solde;
      } else {
        operations.add(op);
      }
    }
    setState(() {
      _montantOuverture = ouverture;
      _operations = operations;
      _loading = false;
    });
  }

  double get _soldeActuel {
    if (_operations.isEmpty) return _montantOuverture;
    return _operations.last.solde;
  }

  /// Recalcule en cascade le solde de toutes les opérations de la semaine,
  /// à partir du solde d'ouverture. Nécessaire après toute modification,
  /// insertion ou suppression d'une opération qui n'est pas forcément la
  /// dernière de la liste (les opérations sont triées par date).
  Future<void> _recalculerSoldesEnCascade() async {
    final ops = await _db.getOperationsBySemaine(
      annee: widget.annee,
      mois: widget.mois,
      semaine: widget.semaine,
    );
    double solde = _montantOuverture;
    for (final op in ops) {
      if (op.estSoldeOuverture) continue;
      solde = solde + op.entree - op.sortie;
      if (op.solde != solde) {
        await _db.updateOperation(op.copyWith(solde: solde));
      }
    }
  }

  Future<void> _definirOuverture() async {
    final ctrl = TextEditingController(
        text: _montantOuverture != 0 ? Formatters.montant(_montantOuverture) : '');
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
            onPressed: () => Navigator.pop(context, Formatters.parseMontant(ctrl.text)),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (result == null) return;

    // Supprime l'ancienne ligne d'ouverture s'il y en a une, puis recrée
    final all = await _db.getOperationsBySemaine(
      annee: widget.annee,
      mois: widget.mois,
      semaine: widget.semaine,
    );
    for (final op in all) {
      if (op.estSoldeOuverture && op.id != null) {
        await _db.deleteOperation(op.id!);
      }
    }
    await _db.insertOperation(CaisseOperation(
      annee: widget.annee,
      mois: widget.mois,
      semaine: widget.semaine,
      periodeDu: widget.periodeDu,
      periodeAu: widget.periodeAu,
      date: widget.periodeDu,
      numPiece: '',
      nomPrenoms: '',
      detailOperation: 'Montant en caisse en début de semaine',
      entree: 0,
      sortie: 0,
      solde: result,
      estSoldeOuverture: true,
    ));
    await _recalculerSoldesEnCascade();
    _charger();
  }

  Future<void> _ajouterOuModifierOperation({CaisseOperation? existante}) async {
    final result = await showModalBottomSheet<CaisseOperation>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OperationForm(
        soldeAvant: existante != null
            ? (_operations.indexOf(existante) > 0
                ? _operations[_operations.indexOf(existante) - 1].solde
                : _montantOuverture)
            : _soldeActuel,
        operationExistante: existante,
      ),
    );
    if (result == null) return;

    final operation = result.copyWith(
      annee: widget.annee,
      mois: widget.mois,
      semaine: widget.semaine,
      periodeDu: widget.periodeDu,
      periodeAu: widget.periodeAu,
    );

    if (existante != null && existante.id != null) {
      await _db.updateOperation(operation.copyWith(id: existante.id));
    } else {
      await _db.insertOperation(operation);
    }
    await _recalculerSoldesEnCascade();
    _charger();
  }

  Future<void> _supprimerOperation(CaisseOperation op) async {
    if (op.id == null) return;
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
    if (confirme == true) {
      await _db.deleteOperation(op.id!);
      await _recalculerSoldesEnCascade();
      _charger();
    }
  }

  Future<void> _genererPdf() async {
    setState(() => _generating = true);
    try {
      final bytes = await PdfService.genererLivreCaisse(
        annee: widget.annee,
        mois: widget.mois,
        semaine: widget.semaine,
        periodeDu: widget.periodeDu,
        periodeAu: widget.periodeAu,
        montantOuverture: _montantOuverture,
        operations: _operations,
      );
      final nomFichier =
          'Livre_Caisse_S${widget.semaine}_${widget.mois}_${widget.annee}.pdf';
      await FileService.sauvegarderFichier(bytes, nomFichier);
      if (!mounted) return;
      await _afficherApercuPdf(bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur génération PDF : $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _genererExcel() async {
    setState(() => _generating = true);
    try {
      final bytes = ExcelService.genererLivreCaisseExcel(
        annee: widget.annee,
        mois: widget.mois,
        semaine: widget.semaine,
        periodeDu: widget.periodeDu,
        periodeAu: widget.periodeAu,
        montantOuverture: _montantOuverture,
        operations: _operations,
      );
      final nomFichier =
          'Livre_Caisse_S${widget.semaine}_${widget.mois}_${widget.annee}.xlsx';
      final file = await FileService.sauvegarderFichier(bytes, nomFichier);
      if (!mounted) return;
      _proposerActionFichier(file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur génération Excel : $e')));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _afficherApercuPdf(Uint8List bytes) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Aperçu du Livre de Caisse')),
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
        content: Text('Fichier généré : ${file.path.split('/').last}'),
        action: SnackBarAction(
          label: 'PARTAGER',
          onPressed: () => FileService.partagerFichier(file),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Semaine ${widget.semaine} — ${widget.mois}'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
              child: CircularProgressIndicator(),
            ),
          FloatingActionButton(
            heroTag: 'addOp',
            onPressed: () => _ajouterOuModifierOperation(),
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
      color: AppTheme.isitekGreenLight,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Du ${Formatters.dateCourte(widget.periodeDu)} au ${Formatters.dateCourte(widget.periodeAu)}',
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
                    valeur: Formatters.montantFcfa(_montantOuverture),
                    editable: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoChip(
                  label: 'Solde actuel',
                  valeur: Formatters.montantFcfa(_soldeActuel),
                  couleur: AppTheme.isitekGreenDark,
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
  final CaisseOperation operation;
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
              color: estEntree ? AppTheme.isitekGreenDark : AppTheme.soldeNegatif,
              size: 18,
            ),
          ),
          title: Text(operation.nomPrenoms.isEmpty ? '—' : operation.nomPrenoms,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${operation.detailOperation}\n${Formatters.dateCourte(operation.date)}'
            '${operation.numPiece.isNotEmpty ? " · Pièce n°${operation.numPiece}" : ""}',
          ),
          isThreeLine: true,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                estEntree
                    ? '+${Formatters.montant(operation.entree)}'
                    : '-${Formatters.montant(operation.sortie)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: estEntree ? AppTheme.isitekGreenDark : AppTheme.soldeNegatif,
                ),
              ),
              Text('Solde: ${Formatters.montant(operation.solde)}',
                  style: const TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formulaire d'ajout / modification d'une opération de caisse.
class _OperationForm extends StatefulWidget {
  final double soldeAvant;
  final CaisseOperation? operationExistante;

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
      _montantCtrl.text = Formatters.montant(_isEntree ? op.entree : op.sortie);
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
    final montant = Formatters.parseMontant(_montantCtrl.text);
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
      CaisseOperation(
        annee: '', mois: '', semaine: '', // remplis par l'appelant
        periodeDu: DateTime.now(), periodeAu: DateTime.now(),
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
              title: Text('Date : ${Formatters.dateCourte(_date)}'),
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
                    selectedColor: AppTheme.isitekGreenLight,
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
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
