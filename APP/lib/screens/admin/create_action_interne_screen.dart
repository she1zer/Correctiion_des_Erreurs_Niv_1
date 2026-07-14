import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class CreateActionInterneScreen extends StatefulWidget {
  final Map<String, dynamic>? actionToEdit;
  const CreateActionInterneScreen({super.key, this.actionToEdit});

  @override
  State<CreateActionInterneScreen> createState() => _CreateActionInterneScreenState();
}

class _CreateActionInterneScreenState extends State<CreateActionInterneScreen> {
  final _nomCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  int? _responsableId;
  int? _supportId;
  DateTime? _debut;
  DateTime? _fin;
  String _statut = 'non_entame';
  String _priorite = 'moyenne';
  bool _loading = false;
  List<dynamic> _techniciens = [];

  @override
  void initState() {
    super.initState();
    if (widget.actionToEdit != null) {
      final a = widget.actionToEdit!;
      _nomCtrl.text = a['nom'] ?? '';
      _responsableId = a['responsable_id'];
      _supportId = a['support_id'];
      if (a['date_debut'] != null) {
        _debut = DateTime.tryParse(a['date_debut']);
      }
      if (a['date_fin'] != null) {
        _fin = DateTime.tryParse(a['date_fin']);
      }
      _statut = a['statut'] ?? 'non_entame';
      _priorite = a['priorite'] ?? 'moyenne';
      _commentCtrl.text = a['commentaire'] ?? '';
    }
    _loadTechniciens();
  }

  Future<void> _loadTechniciens() async {
    try {
      final list = await ApiService.instance.get('/api/users/techniciens');
      setState(() => _techniciens = list);
    } catch (_) {}
  }

  Future<void> _pickDate(bool debut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => debut ? _debut = picked : _fin = picked);
    }
  }

  Future<void> _submit() async {
    if (_nomCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom de l\'action requis')));
      return;
    }
    setState(() => _loading = true);
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final Map<String, dynamic> data = {
        'nom': _nomCtrl.text.trim(),
        'responsable_id': _responsableId,
        'support_id': _supportId,
        'date_debut': _debut != null ? fmt.format(_debut!) : null,
        'date_fin': _fin != null ? fmt.format(_fin!) : null,
        'statut': _statut,
        'priorite': _priorite,
        'commentaire': _commentCtrl.text.isNotEmpty ? _commentCtrl.text.trim() : null,
      };

      if (widget.actionToEdit != null) {
        await ApiService.instance.patch('/api/actions-internes/${widget.actionToEdit!['id']}', data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action interne modifiée')));
      } else {
        await ApiService.instance.post('/api/actions-internes/', data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action interne créée')));
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
        title: Text(isEdit ? 'Modifier l\'action interne' : 'Nouvelle action interne'),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Informations générales',
            icon: Icons.info,
            children: [
              TextFormField(
                controller: _nomCtrl,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'action *',
                  prefixIcon: const Icon(Icons.label),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _statut,
                decoration: InputDecoration(
                  labelText: 'Statut',
                  prefixIcon: const Icon(Icons.flag),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'non_entame', child: Text('Non entamé')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'termine', child: Text('Terminé')),
                  DropdownMenuItem(value: 'bloque', child: Text('Bloqué')),
                  DropdownMenuItem(value: 'annule', child: Text('Annulé')),
                ],
                onChanged: (v) => setState(() => _statut = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _priorite,
                decoration: InputDecoration(
                  labelText: 'Priorité',
                  prefixIcon: const Icon(Icons.priority_high),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: const [
                  DropdownMenuItem(value: 'haute', child: Text('Haute')),
                  DropdownMenuItem(value: 'moyenne', child: Text('Moyenne')),
                  DropdownMenuItem(value: 'basse', child: Text('Basse')),
                ],
                onChanged: (v) => setState(() => _priorite = v!),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Assignation',
            icon: Icons.people,
            children: [
              DropdownButtonFormField<int?>(
                value: _responsableId,
                decoration: InputDecoration(
                  labelText: 'Responsable (optionnel)',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Non assigné —')),
                  ..._techniciens.map((t) => DropdownMenuItem(
                        value: t['id'] as int,
                        child: Text('${t['prenom']} ${t['nom']}'),
                      )),
                ],
                onChanged: (v) => setState(() => _responsableId = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _supportId,
                decoration: InputDecoration(
                  labelText: 'Support (optionnel)',
                  prefixIcon: const Icon(Icons.support_agent),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Non assigné —')),
                  ..._techniciens.map((t) => DropdownMenuItem(
                        value: t['id'] as int,
                        child: Text('${t['prenom']} ${t['nom']}'),
                      )),
                ],
                onChanged: (v) => setState(() => _supportId = v),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Dates',
            icon: Icons.calendar_today,
            children: [
              InkWell(
                onTap: () => _pickDate(true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date début (optionnel)',
                    prefixIcon: const Icon(Icons.play_arrow),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_debut != null ? DateFormat('dd/MM/yyyy').format(_debut!) : 'Non définie'),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _pickDate(false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date fin (optionnel)',
                    prefixIcon: const Icon(Icons.stop),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_fin != null ? DateFormat('dd/MM/yyyy').format(_fin!) : 'Non définie'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Commentaire',
            icon: Icons.comment,
            children: [
              TextFormField(
                controller: _commentCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF008940),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    isEdit ? 'ENREGISTRER LES MODIFICATIONS' : 'CRÉER L\'ACTION',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF008940), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF008940),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
