import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../db/db_helper.dart';
import '../../models/fiche_controle.dart';
import '../../services/pdf_service.dart';
import '../../services/file_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/formatters.dart';

/// Écran de saisie et consultation d'une Fiche de Contrôle Caisse,
/// reproduisant les champs du document papier ISITEK : Solde Théorique,
/// Solde réel, Écart (AVT), Observations, Écart (APT), Signatures.
class FicheControleDetailScreen extends StatefulWidget {
  final FicheControle fiche;

  const FicheControleDetailScreen({super.key, required this.fiche});

  @override
  State<FicheControleDetailScreen> createState() => _FicheControleDetailScreenState();
}

class _FicheControleDetailScreenState extends State<FicheControleDetailScreen> {
  final _db = DBHelper.instance;
  late FicheControle _fiche;

  final _soldeTheoCtrl = TextEditingController();
  final _soldeReelCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _ecartAptCtrl = TextEditingController();
  final _repOpCtrl = TextEditingController();
  final _comptableCtrl = TextEditingController();
  final _directionCtrl = TextEditingController();

  bool _saving = false;
  bool _generating = false;

  double get _ecartAvt {
    final theo = Formatters.parseMontant(_soldeTheoCtrl.text);
    final reel = Formatters.parseMontant(_soldeReelCtrl.text);
    return reel - theo;
  }

  @override
  void initState() {
    super.initState();
    _fiche = widget.fiche;
    _soldeTheoCtrl.text =
        _fiche.soldeTheorique != 0 ? Formatters.montant(_fiche.soldeTheorique) : '';
    _soldeReelCtrl.text = _fiche.soldeReel != 0 ? Formatters.montant(_fiche.soldeReel) : '';
    _observationsCtrl.text = _fiche.observations;
    _ecartAptCtrl.text = _fiche.ecartApt != 0 ? Formatters.montant(_fiche.ecartApt) : '';
    _repOpCtrl.text = _fiche.repOperationsNom;
    _comptableCtrl.text = _fiche.comptableNom;
    _directionCtrl.text = _fiche.directionNom;

    _soldeTheoCtrl.addListener(() => setState(() {}));
    _soldeReelCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _soldeTheoCtrl.dispose();
    _soldeReelCtrl.dispose();
    _observationsCtrl.dispose();
    _ecartAptCtrl.dispose();
    _repOpCtrl.dispose();
    _comptableCtrl.dispose();
    _directionCtrl.dispose();
    super.dispose();
  }

  FicheControle _ficheDepuisFormulaire() {
    return _fiche.copyWith(
      soldeTheorique: Formatters.parseMontant(_soldeTheoCtrl.text),
      soldeReel: Formatters.parseMontant(_soldeReelCtrl.text),
      ecartAvt: _ecartAvt,
      observations: _observationsCtrl.text.trim(),
      ecartApt: Formatters.parseMontant(_ecartAptCtrl.text),
      repOperationsNom: _repOpCtrl.text.trim(),
      comptableNom: _comptableCtrl.text.trim(),
      directionNom: _directionCtrl.text.trim(),
    );
  }

  Future<void> _enregistrer() async {
    setState(() => _saving = true);
    final fiche = _ficheDepuisFormulaire();
    await _db.updateFiche(fiche);
    setState(() {
      _fiche = fiche;
      _saving = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Fiche enregistrée')));
  }

  Future<void> _genererPdf() async {
    await _enregistrer();
    setState(() => _generating = true);
    try {
      final bytes = await PdfService.genererFicheControle(fiche: _fiche);
      final nomFichier = 'Fiche_Controle_S${_fiche.semaine}.pdf';
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

  Future<void> _afficherApercuPdf(Uint8List bytes) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Aperçu de la Fiche de Contrôle')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fiche — Semaine ${_fiche.semaine}'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            onPressed: _saving ? null : _enregistrer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.isitekGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Semaine ${_fiche.semaine} : du ${Formatters.dateCourte(_fiche.periodeDu)} '
                'au ${Formatters.dateCourte(_fiche.periodeAu)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            _sectionTitre('Soldes'),
            TextField(
              controller: _soldeTheoCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Solde Théorique (FCFA)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _soldeReelCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Solde réel (FCFA)'),
            ),
            const SizedBox(height: 12),
            _readOnlyField(
              label: 'Écart (AVT) — calculé automatiquement',
              value: Formatters.montantFcfa(_ecartAvt),
              negatif: _ecartAvt != 0,
            ),
            const SizedBox(height: 24),
            _sectionTitre('Observations'),
            TextField(
              controller: _observationsCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ex: RAS (rien à signaler), ou détail de l\'écart constaté...',
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitre('Écart après régularisation'),
            TextField(
              controller: _ecartAptCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Écart (APT) (FCFA)'),
            ),
            const SizedBox(height: 24),
            _sectionTitre('Signatures'),
            const Text(
              "Renseignez les noms ci-dessous ; un espace large est réservé sur le PDF "
              "pour la signature manuscrite à l'impression.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _repOpCtrl,
              decoration: const InputDecoration(labelText: 'Rep. Opérations (nom)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comptableCtrl,
              decoration: const InputDecoration(labelText: 'Comptable (nom)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _directionCtrl,
              decoration: const InputDecoration(labelText: 'Direction (nom)'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _enregistrer,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _genererPdf,
                  icon: _generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Générer PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitre(String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texte,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.isitekGreenDark),
      ),
    );
  }

  Widget _readOnlyField({required String label, required String value, bool negatif = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD0D7D3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: negatif ? AppTheme.soldeNegatif : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
