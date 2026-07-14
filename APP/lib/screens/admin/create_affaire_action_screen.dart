import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class CreateAffaireActionScreen extends StatefulWidget {
  final int affaireId;
  final String affaireNumero;
  final Map<String, dynamic>? actionToEdit;
  const CreateAffaireActionScreen({
    super.key,
    required this.affaireId,
    required this.affaireNumero,
    this.actionToEdit,
  });

  @override
  State<CreateAffaireActionScreen> createState() => _CreateAffaireActionScreenState();
}

class _CreateAffaireActionScreenState extends State<CreateAffaireActionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _libelleCtrl = TextEditingController();
  final _ordreCtrl = TextEditingController(text: '1');
  final _refCtrl = TextEditingController();
  final _fournisseurCtrl = TextEditingController();
  final _agenceCtrl = TextEditingController();
  final _modeCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _commentaireCtrl = TextEditingController();
  final _pourcentageCtrl = TextEditingController();
  final _garantieMoisCtrl = TextEditingController();
  final _garantieDebutCtrl = TextEditingController();
  final _garantieFinCtrl = TextEditingController();

  int? _responsableId;
  int? _supportId;
  int? _banqueId;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  DateTime? _dateAction;
  String _statut = 'non_entame';
  bool _termine = false;
  bool _loading = false;

  List<dynamic> _techniciens = [];
  List<dynamic> _banques = [];

  @override
  void initState() {
    super.initState();
    if (widget.actionToEdit != null) {
      final a = widget.actionToEdit!;
      _libelleCtrl.text = a['libelle'] ?? '';
      _ordreCtrl.text = a['ordre']?.toString() ?? '1';
      _responsableId = a['responsable_id'];
      _supportId = a['support_id'];
      _banqueId = a['banque_id'];
      if (a['date_debut'] != null) {
        _dateDebut = DateTime.tryParse(a['date_debut']);
      }
      if (a['date_fin'] != null) {
        _dateFin = DateTime.tryParse(a['date_fin']);
      }
      if (a['date_action'] != null) {
        _dateAction = DateTime.tryParse(a['date_action']);
      }
      _refCtrl.text = a['ref'] ?? '';
      _fournisseurCtrl.text = a['fournisseur'] ?? '';
      _agenceCtrl.text = a['agence'] ?? '';
      _modeCtrl.text = a['mode'] ?? '';
      _observationsCtrl.text = a['observations'] ?? '';
      _commentaireCtrl.text = a['commentaire'] ?? '';
      _pourcentageCtrl.text = a['pourcentage_accompte']?.toString() ?? '';
      _garantieMoisCtrl.text = a['garantie_mois']?.toString() ?? '';
      _garantieDebutCtrl.text = a['garantie_debut'] ?? '';
      _garantieFinCtrl.text = a['garantie_fin'] ?? '';
      _statut = a['statut'] ?? 'non_entame';
      _termine = a['termine'] ?? false;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final [techniciens, banques] = await Future.wait([
        ApiService.instance.get('/api/users/techniciens'),
        ApiService.instance.get('/api/affaires/banques/list'),
      ]);
      setState(() {
        _techniciens = techniciens;
        _banques = banques;
      });
    } catch (_) {}
  }

  Future<void> _pickDate(String field) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        switch (field) {
          case 'debut':
            _dateDebut = picked;
            break;
          case 'fin':
            _dateFin = picked;
            break;
          case 'action':
            _dateAction = picked;
            break;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final data = {
        'libelle': _libelleCtrl.text.trim(),
        'ordre': int.tryParse(_ordreCtrl.text.trim()) ?? 1,
        'responsable_id': _responsableId,
        'support_id': _supportId,
        'banque_id': _banqueId,
        'date_debut': _dateDebut != null ? fmt.format(_dateDebut!) : null,
        'date_fin': _dateFin != null ? fmt.format(_dateFin!) : null,
        'date_action': _dateAction != null ? fmt.format(_dateAction!) : null,
        'ref': _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        'fournisseur': _fournisseurCtrl.text.trim().isEmpty ? null : _fournisseurCtrl.text.trim(),
        'agence': _agenceCtrl.text.trim().isEmpty ? null : _agenceCtrl.text.trim(),
        'mode': _modeCtrl.text.trim().isEmpty ? null : _modeCtrl.text.trim(),
        'observations': _observationsCtrl.text.trim().isEmpty ? null : _observationsCtrl.text.trim(),
        'statut': _statut,
        'commentaire': _commentaireCtrl.text.trim().isEmpty ? null : _commentaireCtrl.text.trim(),
        'pourcentage_accompte': _pourcentageCtrl.text.trim().isEmpty ? null : double.tryParse(_pourcentageCtrl.text.trim()),
        'garantie_mois': _garantieMoisCtrl.text.trim().isEmpty ? null : int.tryParse(_garantieMoisCtrl.text.trim()),
        'garantie_debut': _garantieDebutCtrl.text.trim().isEmpty ? null : _garantieDebutCtrl.text.trim(),
        'garantie_fin': _garantieFinCtrl.text.trim().isEmpty ? null : _garantieFinCtrl.text.trim(),
        'termine': _termine,
      };

      if (widget.actionToEdit != null) {
        await ApiService.instance.patch('/api/affaires/actions/${widget.actionToEdit!['id']}', data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action modifiée avec succès')),
        );
      } else {
        await ApiService.instance.post('/api/affaires/${widget.affaireId}/actions', data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action créée avec succès')),
        );
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.actionToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier l\'action' : 'Nouvelle action pour ${widget.affaireNumero}'),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Informations générales'),
            TextFormField(
              controller: _libelleCtrl,
              decoration: const InputDecoration(labelText: 'Libellé de l\'action *'),
              validator: (v) => v!.isEmpty ? 'Requis' : null,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _ordreCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Ordre'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _statut,
                    decoration: const InputDecoration(labelText: 'Statut'),
                    items: const [
                      DropdownMenuItem(value: 'non_entame', child: Text('Non entamé')),
                      DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                      DropdownMenuItem(value: 'termine', child: Text('Terminé')),
                      DropdownMenuItem(value: 'bloque', child: Text('Bloqué')),
                      DropdownMenuItem(value: 'annule', child: Text('Annulé')),
                    ],
                    onChanged: (v) => setState(() => _statut = v!),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: const Text('Action terminée'),
              subtitle: const Text('Cochez si l\'action est complètement terminée'),
              value: _termine,
              onChanged: (v) => setState(() => _termine = v ?? false),
              activeColor: const Color(0xFF008940),
            ),
            const SizedBox(height: 16),
            _section('Assignation'),
            DropdownButtonFormField<int?>(
              value: _responsableId,
              decoration: const InputDecoration(labelText: 'Responsable (optionnel)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Non assigné —')),
                ..._techniciens.map((t) => DropdownMenuItem(
                      value: t['id'] as int,
                      child: Text('${t['prenom']} ${t['nom']}'),
                    )),
              ],
              onChanged: (v) => setState(() => _responsableId = v),
            ),
            DropdownButtonFormField<int?>(
              value: _supportId,
              decoration: const InputDecoration(labelText: 'Support (optionnel)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Non assigné —')),
                ..._techniciens.map((t) => DropdownMenuItem(
                      value: t['id'] as int,
                      child: Text('${t['prenom']} ${t['nom']}'),
                    )),
              ],
              onChanged: (v) => setState(() => _supportId = v),
            ),
            DropdownButtonFormField<int?>(
              value: _banqueId,
              decoration: const InputDecoration(labelText: 'Banque (optionnel)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Aucune —')),
                ..._banques.map((b) => DropdownMenuItem(
                      value: b['id'] as int,
                      child: Text(b['nom'] as String),
                    )),
              ],
              onChanged: (v) => setState(() => _banqueId = v),
            ),
            const SizedBox(height: 16),
            _section('Dates'),
            ListTile(
              title: const Text('Date début'),
              subtitle: Text(_dateDebut != null ? DateFormat('dd/MM/yyyy').format(_dateDebut!) : 'Non définie'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate('debut'),
            ),
            ListTile(
              title: const Text('Date fin'),
              subtitle: Text(_dateFin != null ? DateFormat('dd/MM/yyyy').format(_dateFin!) : 'Non définie'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate('fin'),
            ),
            ListTile(
              title: const Text('Date action'),
              subtitle: Text(_dateAction != null ? DateFormat('dd/MM/yyyy').format(_dateAction!) : 'Non définie'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate('action'),
            ),
            const SizedBox(height: 16),
            _section('Détails'),
            TextFormField(controller: _refCtrl, decoration: const InputDecoration(labelText: 'Référence')),
            TextFormField(controller: _fournisseurCtrl, decoration: const InputDecoration(labelText: 'Fournisseur')),
            TextFormField(controller: _agenceCtrl, decoration: const InputDecoration(labelText: 'Agence')),
            TextFormField(controller: _modeCtrl, decoration: const InputDecoration(labelText: 'Mode')),
            TextFormField(
              controller: _observationsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Observations'),
            ),
            TextFormField(
              controller: _commentaireCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Commentaire'),
            ),
            const SizedBox(height: 16),
            _section('Informations spéciales'),
            TextFormField(
              controller: _pourcentageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Pourcentage acompte (%)',
                hintText: 'Pour l\'étape Avance/Accompte',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _garantieMoisCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durée garantie (mois)',
                hintText: 'Pour l\'étape SAV/Garantie',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _garantieDebutCtrl,
              decoration: const InputDecoration(
                labelText: 'Date début garantie',
                hintText: 'Format: YYYY-MM-DD',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _garantieFinCtrl,
              decoration: const InputDecoration(
                labelText: 'Date fin garantie',
                hintText: 'Format: YYYY-MM-DD',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008940),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(isEdit ? 'ENREGISTRER LES MODIFICATIONS' : 'CRÉER L\'ACTION'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008940), fontSize: 16)),
      );
}
