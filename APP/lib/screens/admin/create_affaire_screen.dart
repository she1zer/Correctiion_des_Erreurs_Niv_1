import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';

class CreateAffaireScreen extends StatefulWidget {
  final Map<String, dynamic>? affaireToEdit;
  final Map<String, dynamic>? prefilledData;
  const CreateAffaireScreen({super.key, this.affaireToEdit, this.prefilledData});

  @override
  State<CreateAffaireScreen> createState() => _CreateAffaireScreenState();
}

class _CreateAffaireScreenState extends State<CreateAffaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroCtrl = TextEditingController(text: '26DA');
  final _respNomCtrl = TextEditingController();
  final _respPrenomCtrl = TextEditingController();
  final _respRoleCtrl = TextEditingController(text: 'Responsable affaire');
  final _clientCtrl = TextEditingController();
  final _commandeCtrl = TextEditingController();
  final _libelleCtrl = TextEditingController();
  final _domaineCtrl = TextEditingController();
  final _typeCtrl = TextEditingController(text: 'FOURNITURE');
  final _montantCtrl = TextEditingController();
  final _corrNomCtrl = TextEditingController();
  final _corrTelCtrl = TextEditingController();
  final _corrEmailCtrl = TextEditingController();

  DateTime _dateOuverture = DateTime.now();
  DateTime? _dateLivraisonBc;
  String _statut = 'non_entame';
  bool _loading = false;

  final _domaines = [
    'Électricité générale',
    'Électronique',
    'Informatique',
    'Mécanique',
    'Plomberie',
    'Froid & Climatisation',
    'Menuiserie',
    'Groupes électrogènes',
    'Électricité industrielle',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.affaireToEdit != null) {
      final a = widget.affaireToEdit!;
      _numeroCtrl.text = a['numero_affaire'] ?? '';
      _respNomCtrl.text = a['responsable_nom'] ?? '';
      _respPrenomCtrl.text = a['responsable_prenom'] ?? '';
      _respRoleCtrl.text = a['responsable_role'] ?? '';
      if (a['date_ouverture'] != null) {
        _dateOuverture = DateTime.tryParse(a['date_ouverture']) ?? DateTime.now();
      }
      _clientCtrl.text = a['client_nom'] ?? '';
      _commandeCtrl.text = a['numero_commande'] ?? '';
      _libelleCtrl.text = a['libelle_affaire'] ?? '';
      _domaineCtrl.text = a['domaine'] ?? '';
      _typeCtrl.text = a['type_affaire'] ?? '';
      _montantCtrl.text = a['montant_affaire'] != null ? a['montant_affaire'].toString() : '';
      if (a['date_livraison_bc'] != null) {
        _dateLivraisonBc = DateTime.tryParse(a['date_livraison_bc']);
      }
      _corrNomCtrl.text = a['correspondant_nom'] ?? '';
      _corrTelCtrl.text = a['correspondant_telephone'] ?? '';
      _corrEmailCtrl.text = a['correspondant_email'] ?? '';
      _statut = a['statut'] ?? 'non_entame';
    } else {
      _initNewAffaire();
    }
  }

  Future<void> _initNewAffaire() async {
    final user = ApiService.instance.currentUser;
    if (user != null) {
      _respNomCtrl.text = user.nom;
      _respPrenomCtrl.text = user.prenom;
      _respRoleCtrl.text = user.poste ?? 'Technicien ISITEK';
    }
    if (widget.prefilledData != null) {
      final p = widget.prefilledData!;
      if (p['client_nom'] != null) _clientCtrl.text = p['client_nom'];
      if (p['libelle_affaire'] != null) _libelleCtrl.text = p['libelle_affaire'];
      if (p['montant_affaire'] != null) _montantCtrl.text = p['montant_affaire'].toString();
      if (p['numero_commande'] != null) _commandeCtrl.text = p['numero_commande'];
      if (p['correspondant_nom'] != null) _corrNomCtrl.text = p['correspondant_nom'];
      if (p['correspondant_email'] != null) _corrEmailCtrl.text = p['correspondant_email'];
    }
    try {
      final data = await ApiService.instance.getOne('/api/affaires/next-number');
      if (mounted) _numeroCtrl.text = data['numero_affaire'] ?? _numeroCtrl.text;
    } catch (_) {}
  }

  Future<void> _pickDate(bool isOuverture) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isOuverture ? _dateOuverture : (_dateLivraisonBc ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isOuverture) {
          _dateOuverture = picked;
        } else {
          _dateLivraisonBc = picked;
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
        'responsable_nom': _respNomCtrl.text.trim(),
        'responsable_prenom': _respPrenomCtrl.text.trim(),
        'responsable_role': _respRoleCtrl.text.trim(),
        'date_ouverture': fmt.format(_dateOuverture),
        'client_nom': _clientCtrl.text.trim(),
        'numero_commande': _commandeCtrl.text.trim().isEmpty ? null : _commandeCtrl.text.trim(),
        'libelle_affaire': _libelleCtrl.text.trim(),
        'domaine': _domaineCtrl.text.trim(),
        'type_affaire': _typeCtrl.text.trim(),
        'montant_affaire': _montantCtrl.text.trim().isEmpty ? null : double.tryParse(_montantCtrl.text.trim()),
        'date_livraison_bc': _dateLivraisonBc != null ? fmt.format(_dateLivraisonBc!) : null,
        'correspondant_nom': _corrNomCtrl.text.trim().isEmpty ? null : _corrNomCtrl.text.trim(),
        'correspondant_telephone': _corrTelCtrl.text.trim().isEmpty ? null : _corrTelCtrl.text.trim(),
        'correspondant_email': _corrEmailCtrl.text.trim().isEmpty ? null : _corrEmailCtrl.text.trim(),
        'statut': _statut,
      };

      if (widget.affaireToEdit != null) {
        await ApiService.instance.patch('/api/affaires/${widget.affaireToEdit!['id']}', data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Affaire modifiée avec succès')),
        );
      } else {
        data['numero_affaire'] = _numeroCtrl.text.trim().toUpperCase();
        data['creer_etapes_standard'] = true;
        await ApiService.instance.post('/api/affaires/', data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Affaire créée avec les 12 étapes standard.')),
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
    final isEdit = widget.affaireToEdit != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Modifier l\'affaire' : 'Nouvelle affaire'),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              title: 'Identification',
              icon: Icons.badge,
              children: [
                TextFormField(
                  controller: _numeroCtrl,
                  enabled: !isEdit,
                  decoration: InputDecoration(
                    labelText: 'N° Affaire (ex: 26DA069)',
                    prefixIcon: const Icon(Icons.tag),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => RegExp(r'^\d{2}DA\d{3}$').hasMatch(v?.toUpperCase() ?? '')
                      ? null
                      : 'Format: 26DAXXX',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _respNomCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nom responsable',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _respPrenomCtrl,
                        decoration: InputDecoration(
                          labelText: 'Prénom',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _respRoleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Rôle responsable',
                    prefixIcon: const Icon(Icons.work),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickDate(true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date d\'ouverture',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(DateFormat('dd/MM/yyyy').format(_dateOuverture)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Client & commande',
              icon: Icons.business,
              children: [
                TextFormField(
                  controller: _clientCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom client',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _commandeCtrl,
                  decoration: InputDecoration(
                    labelText: 'N° commande',
                    prefixIcon: const Icon(Icons.receipt_long),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _libelleCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Libellé affaire',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (v) => v!.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _domaines.contains(_domaineCtrl.text) ? _domaineCtrl.text : null,
                  decoration: InputDecoration(
                    labelText: 'Domaine',
                    prefixIcon: const Icon(Icons.category),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _domaines.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => _domaineCtrl.text = v ?? ''),
                  validator: (v) => v == null ? 'Choisir un domaine' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _typeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Type affaire',
                    prefixIcon: const Icon(Icons.label),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _montantCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Montant (FCFA)',
                    prefixIcon: const Icon(Icons.euro),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickDate(false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date livraison bon de commande',
                      prefixIcon: const Icon(Icons.event),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(_dateLivraisonBc != null ? DateFormat('dd/MM/yyyy').format(_dateLivraisonBc!) : 'Non définie'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Correspondant client',
              icon: Icons.contact_mail,
              children: [
                TextFormField(
                  controller: _corrNomCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _corrTelCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _corrEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCard(
              title: 'Statut',
              icon: Icons.info,
              children: [
                DropdownButtonFormField<String>(
                  value: _statut,
                  decoration: InputDecoration(
                    labelText: 'Statut affaire',
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
                      isEdit ? 'ENREGISTRER LES MODIFICATIONS' : 'CRÉER L\'AFFAIRE',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF008940), fontSize: 16)),
      );
}
