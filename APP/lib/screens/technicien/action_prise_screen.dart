import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import '../../main.dart' show IsitekColors;

class ActionPriseScreen extends StatefulWidget {
  final Map<String, dynamic> action;
  const ActionPriseScreen({super.key, required this.action});

  @override
  State<ActionPriseScreen> createState() => _ActionPriseScreenState();
}

class _ActionPriseScreenState extends State<ActionPriseScreen> {
  String _role = 'responsable';
  int? _supportId;
  List<dynamic> _techniciens = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadTechniciens();
    if (widget.action['role_assigne'] == 'support') {
      _role = 'support';
    }
  }

  Future<void> _loadTechniciens() async {
    try {
      final list = await ApiService.instance.get('/api/users/techniciens');
      setState(() => _techniciens = list);
    } catch (_) {}
  }

  Future<void> _prendre() async {
    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{
        'role_prise': _role,
        if (_supportId != null) 'support_id': _supportId,
      };
      if (widget.action['type'] == 'affaire') {
        body['affaire_action_id'] = widget.action['id'];
      } else {
        body['action_interne_id'] = widget.action['id'];
      }
      await ApiService.instance.post('/api/technicien/prendre-action', body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action prise avec succès !'),
          backgroundColor: IsitekColors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    final isAffaire = a['type'] == 'affaire';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Prendre l\'action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: IsitekColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAffaire ? IsitekColors.greenSoft : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAffaire ? 'AFFAIRE' : 'ACTION INTERNE',
                      style: TextStyle(
                        color: isAffaire ? IsitekColors.greenDark : Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    a['libelle'] as String,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: IsitekColors.textDark, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.person_outline_rounded, 'Client', a['client'].toString()),
                  if (isAffaire && a['responsable_nom'] != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.account_circle_outlined, 'Responsable', a['responsable_nom'].toString()),
                  ]
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95)),
            
            const SizedBox(height: 24),

            // Form inputs
            if (!isAffaire) ...[
              const Text(
                'Votre rôle pour cette action :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: IsitekColors.textDark),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Responsable'),
                      selected: _role == 'responsable',
                      onSelected: (selected) {
                        if (selected) setState(() => _role = 'responsable');
                      },
                      selectedColor: IsitekColors.green,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _role == 'responsable' ? Colors.white : IsitekColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Support'),
                      selected: _role == 'support',
                      onSelected: (selected) {
                        if (selected) setState(() => _role = 'support');
                      },
                      selectedColor: IsitekColors.green,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: _role == 'support' ? Colors.white : IsitekColors.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (isAffaire || _role == 'responsable') ...[
              const SizedBox(height: 20),
              const Text(
                'Ajouter un collaborateur support (optionnel) :',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: IsitekColors.textDark),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                value: _supportId,
                style: const TextStyle(fontSize: 14, color: IsitekColors.textDark),
                decoration: InputDecoration(
                  labelText: 'Employé de support',
                  prefixIcon: const Icon(Icons.person_add_alt_1_rounded, color: IsitekColors.green),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                  ..._techniciens.map((t) => DropdownMenuItem(
                        value: t['id'] as int,
                        child: Text('${t['prenom']} ${t['nom']}'),
                      )),
                ],
                onChanged: (v) => setState(() => _supportId = v),
              ),
            ],
            
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _prendre,
                style: ElevatedButton.styleFrom(
                  backgroundColor: IsitekColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('COMMENCER CETTE ACTION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text('$label : ', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, color: IsitekColors.textDark, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class ActionPriseUpdateScreen extends StatefulWidget {
  final Map<String, dynamic> prise;
  const ActionPriseUpdateScreen({super.key, required this.prise});

  @override
  State<ActionPriseUpdateScreen> createState() => _ActionPriseUpdateScreenState();
}

class _ActionPriseUpdateScreenState extends State<ActionPriseUpdateScreen> {
  String _statut = 'en_cours';
  final _commentCtrl = TextEditingController();
  DateTime? _debut;
  DateTime? _fin;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _statut = widget.prise['statut'] as String? ?? 'en_cours';
    _commentCtrl.text = widget.prise['commentaire'] as String? ?? '';
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool debut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: IsitekColors.green,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => debut ? _debut = picked : _fin = picked);
  }

  Future<void> _save() async {
    if (['non_entame', 'annule', 'bloque'].contains(_statut) && _commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commentaire/justification obligatoire pour ce statut'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      await ApiService.instance.patch('/api/technicien/prises/${widget.prise['id']}', {
        'statut': _statut,
        'commentaire': _commentCtrl.text.trim(),
        if (_debut != null) 'date_debut': fmt.format(_debut!),
        if (_fin != null) 'date_fin': fmt.format(_fin!),
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Mettre à Jour l\'Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: IsitekColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selection block
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Date début', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(_debut != null ? DateFormat('dd/MM/yyyy').format(_debut!) : '—', style: const TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.calendar_today_rounded, color: IsitekColors.green),
                    onTap: () => _pickDate(true),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ListTile(
                    title: const Text('Date fin', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: Text(_fin != null ? DateFormat('dd/MM/yyyy').format(_fin!) : '—', style: const TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.calendar_today_rounded, color: IsitekColors.green),
                    onTap: () => _pickDate(false),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // Dropdown selection
            const Text(
              'Statut de l\'intervention :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: IsitekColors.textDark),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _statut,
              style: const TextStyle(fontSize: 14, color: IsitekColors.textDark),
              decoration: InputDecoration(
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'non_entame', child: Text('Non entamé (justification requise)')),
                DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                DropdownMenuItem(value: 'termine', child: Text('Terminé')),
                DropdownMenuItem(value: 'annule', child: Text('Annulé (justification requise)')),
                DropdownMenuItem(value: 'bloque', child: Text('Bloqué (justification requise)')),
              ],
              onChanged: (v) => setState(() => _statut = v!),
            ),
            
            const SizedBox(height: 20),

            // Comment textfield
            const Text(
              'Commentaires / Justification :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: IsitekColors.textDark),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Saisissez vos observations...',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            
            const SizedBox(height: 36),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: IsitekColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ENREGISTRER LES MODIFICATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportUpdateScreen extends StatefulWidget {
  final Map<String, dynamic> prise;
  const SupportUpdateScreen({super.key, required this.prise});

  @override
  State<SupportUpdateScreen> createState() => _SupportUpdateScreenState();
}

class _SupportUpdateScreenState extends State<SupportUpdateScreen> {
  final _travailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _travailCtrl.text = widget.prise['support_travail'] as String? ?? '';
  }

  @override
  void dispose() {
    _travailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiService.instance.patch('/api/technicien/prises/${widget.prise['id']}', {
        'support_travail': _travailCtrl.text.trim(),
        'statut': 'en_cours',
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Rapport Support', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: IsitekColors.textDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Décrivez le travail technique effectué en tant que support :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: IsitekColors.textDark),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _travailCtrl,
                maxLines: 12,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Indiquez les détails de l\'intervention de support technique...',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: IsitekColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ENREGISTRER LE RAPPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
