import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../main.dart' show IsitekColors;
import '../services/caisse_api_service.dart';
import '../services/caisse_pdf_service.dart';
import '../services/file_service.dart';
import '../utils/caisse_formatters.dart';

class FicheControleFormScreen extends StatefulWidget {
  final int? ficheId;

  const FicheControleFormScreen({super.key, this.ficheId});

  @override
  State<FicheControleFormScreen> createState() => _FicheControleFormScreenState();
}

class _FicheControleFormScreenState extends State<FicheControleFormScreen> {
  final _semaineCtrl = TextEditingController();
  final _soldeTheoCtrl = TextEditingController();
  final _soldeReelCtrl = TextEditingController();
  final _ecartAptCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();
  final _sigRepCtrl = TextEditingController();
  final _sigComptCtrl = TextEditingController();
  final _sigDirCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;
  final _ecartAvtCtrl = TextEditingController();
  bool _ecartAvtManuel = false;
  bool _loading = false;
  bool _saving = false;
  int _sectionsParPage = 2;
  int? _pageId;
  int _slot = 1;

  double get _ecartAvtCalcule =>
      CaisseFormatters.parseMontant(_soldeReelCtrl.text) - CaisseFormatters.parseMontant(_soldeTheoCtrl.text);

  void _syncEcartAvtAuto() {
    if (!_ecartAvtManuel) {
      final calc = _ecartAvtCalcule;
      _ecartAvtCtrl.text = calc != 0 ? CaisseFormatters.montant(calc) : '';
    }
  }

  @override
  void initState() {
    super.initState();
    _soldeTheoCtrl.addListener(() {
      setState(() {});
      _syncEcartAvtAuto();
    });
    _soldeReelCtrl.addListener(() {
      setState(() {});
      _syncEcartAvtAuto();
    });
    _ecartAvtCtrl.addListener(() {
      if (!_ecartAvtManuel) return;
      setState(() {});
    });
    if (widget.ficheId != null) _load();
  }

  @override
  void dispose() {
    _semaineCtrl.dispose();
    _soldeTheoCtrl.dispose();
    _soldeReelCtrl.dispose();
    _ecartAvtCtrl.dispose();
    _ecartAptCtrl.dispose();
    _obsCtrl.dispose();
    _sigRepCtrl.dispose();
    _sigComptCtrl.dispose();
    _sigDirCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await CaisseApiService.instance.getControle(widget.ficheId!);
      _semaineCtrl.text = d['semaine']?.toString() ?? '';
      _soldeTheoCtrl.text = d['solde_theorique']?.toString() ?? '';
      _soldeReelCtrl.text = d['solde_reel']?.toString() ?? '';
      final ecartAvt = d['ecart_avt'];
      if (ecartAvt != null) {
        _ecartAvtCtrl.text = CaisseFormatters.montant(ecartAvt);
        final calc = CaisseFormatters.parseMontant(d['solde_reel']?.toString() ?? '') -
            CaisseFormatters.parseMontant(d['solde_theorique']?.toString() ?? '');
        _ecartAvtManuel = CaisseFormatters.parseMontant(ecartAvt.toString()) != calc;
      }
      _ecartAptCtrl.text = d['ecart_apt']?.toString() ?? '';
      _obsCtrl.text = d['observations'] ?? '';
      _sigRepCtrl.text = d['sig_rep_operations'] ?? '';
      _sigComptCtrl.text = d['sig_comptable'] ?? '';
      _sigDirCtrl.text = d['sig_direction'] ?? '';
      _sectionsParPage = d['sections_par_page'] as int? ?? 2;
      _pageId = d['page_id'] as int?;
      _slot = d['slot'] as int? ?? 1;
      if (d['date_debut'] != null) _dateDebut = DateTime.parse(d['date_debut']);
      if (d['date_fin'] != null) _dateFin = DateTime.parse(d['date_fin']);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Navigator.pop(context);
      }
    }
  }

  Map<String, dynamic> _body() => {
        'semaine': int.tryParse(_semaineCtrl.text),
        'annee': _dateDebut?.year ?? DateTime.now().year,
        'date_debut': _dateDebut != null ? DateFormat('yyyy-MM-dd').format(_dateDebut!) : null,
        'date_fin': _dateFin != null ? DateFormat('yyyy-MM-dd').format(_dateFin!) : null,
        'solde_theorique': CaisseFormatters.parseMontant(_soldeTheoCtrl.text),
        'solde_reel': CaisseFormatters.parseMontant(_soldeReelCtrl.text),
        'ecart_avt': CaisseFormatters.parseMontant(_ecartAvtCtrl.text),
        'ecart_apt': CaisseFormatters.parseMontant(_ecartAptCtrl.text),
        'observations': _obsCtrl.text,
        'sig_rep_operations': _sigRepCtrl.text,
        'sig_comptable': _sigComptCtrl.text,
        'sig_direction': _sigDirCtrl.text,
        'sections_par_page': _sectionsParPage,
      };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      Map<String, dynamic> saved;
      if (widget.ficheId == null) {
        saved = await CaisseApiService.instance.createControle(_body());
      } else {
        saved = await CaisseApiService.instance.updateControle(widget.ficheId!, _body());
      }
      _pageId = saved['page_id'] as int?;
      _slot = saved['slot'] as int? ?? _slot;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fiche enregistrée — section $_slot${_sectionsParPage == 2 ? ' (page $_pageId)' : ''}',
            ),
            backgroundColor: IsitekColors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generatePdf() async {
    try {
      Map<String, dynamic>? ficheHaut;
      Map<String, dynamic>? ficheBas;
      int sections = _sectionsParPage;

      if (_pageId != null) {
        final page = await CaisseApiService.instance.getControlePage(_pageId!);
        sections = page['sections_par_page'] as int? ?? 2;
        ficheHaut = page['fiche_slot_1'] as Map<String, dynamic>?;
        ficheBas = page['fiche_slot_2'] as Map<String, dynamic>?;
      } else {
        final data = _body();
        if (widget.ficheId != null) {
          ficheHaut = await CaisseApiService.instance.getControle(widget.ficheId!);
        } else {
          ficheHaut = data;
        }
      }

      final bytes = await CaissePdfService.genererFicheControle(
        ficheHaut: ficheHaut,
        ficheBas: sections >= 2 ? ficheBas : null,
        sectionsParPage: sections,
      );
      final nomFichier = 'Fiche_Controle_S${ficheHaut?['semaine'] ?? _semaineCtrl.text}.pdf';
      await CaisseFileService.sauvegarderFichier(bytes, nomFichier);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: const Text('Aperçu Fiche de Contrôle'),
              backgroundColor: IsitekColors.green,
              foregroundColor: Colors.white,
            ),
            body: PdfPreview(
              build: (_) => bytes,
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _pickDate(bool debut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (debut ? _dateDebut : _dateFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) setState(() {
      if (debut) _dateDebut = picked; else _dateFin = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fiche contrôle caisse'), backgroundColor: IsitekColors.green, foregroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: IsitekColors.green)),
      );
    }

    final slotLabel = widget.ficheId == null
        ? (_sectionsParPage == 2 ? 'Prochaine section disponible (auto)' : 'Une section par page')
        : 'Section $_slot sur la page ${_pageId ?? '—'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ficheId == null ? 'Nouvelle fiche contrôle' : 'Fiche S${_semaineCtrl.text}'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: _generatePdf),
          IconButton(icon: const Icon(Icons.save_outlined), onPressed: _saving ? null : _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: IsitekColors.greenSoft, borderRadius: BorderRadius.circular(10)),
            child: Text(slotLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          const SizedBox(height: 12),
          if (widget.ficheId == null) ...[
            const Text('Sections par page PDF', style: TextStyle(fontWeight: FontWeight.bold)),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1 section')),
                ButtonSegment(value: 2, label: Text('2 sections')),
              ],
              selected: {_sectionsParPage},
              onSelectionChanged: (s) => setState(() => _sectionsParPage = s.first),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 12),
              child: Text(
                'Avec 2 sections : semaine 20 → section haute, semaine 21 → section basse (même page).',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
          Row(children: [
            Expanded(child: TextField(controller: _semaineCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Semaine', isDense: true))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _pickDate(true), child: Text(_dateDebut == null ? 'Du' : DateFormat('dd/MM/yyyy').format(_dateDebut!)))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _pickDate(false), child: Text(_dateFin == null ? 'Au' : DateFormat('dd/MM/yyyy').format(_dateFin!)))),
          ]),
          const SizedBox(height: 16),
          const Text('Soldes', style: TextStyle(fontWeight: FontWeight.bold, color: IsitekColors.greenDark)),
          TextField(controller: _soldeTheoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Solde Théorique (FCFA)')),
          TextField(controller: _soldeReelCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Solde réel (FCFA)')),
          TextField(
            controller: _ecartAvtCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Écart (AVT) (FCFA)',
              helperText: _ecartAvtManuel
                  ? 'Valeur modifiée manuellement'
                  : 'Calculé automatiquement (solde réel − théorique)',
              suffixIcon: IconButton(
                tooltip: 'Recalculer automatiquement',
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  setState(() {
                    _ecartAvtManuel = false;
                    _syncEcartAvtAuto();
                  });
                },
              ),
            ),
            onChanged: (_) => _ecartAvtManuel = true,
          ),
          const SizedBox(height: 16),
          const Text('Observations', style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(controller: _obsCtrl, maxLines: 4, decoration: const InputDecoration(hintText: 'Ex: RAS')),
          const SizedBox(height: 12),
          TextField(controller: _ecartAptCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Écart (APT) (FCFA)')),
          const SizedBox(height: 16),
          const Text('Signatures', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
            'Noms ci-dessous — espace réservé sur le PDF pour signature manuscrite.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          TextField(controller: _sigRepCtrl, decoration: const InputDecoration(labelText: 'Rep. Opérations')),
          TextField(controller: _sigComptCtrl, decoration: const InputDecoration(labelText: 'Comptable')),
          TextField(controller: _sigDirCtrl, decoration: const InputDecoration(labelText: 'Direction')),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
            style: FilledButton.styleFrom(backgroundColor: IsitekColors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _generatePdf, icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Générer PDF')),
        ],
      ),
    );
  }
}
