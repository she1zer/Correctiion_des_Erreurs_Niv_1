import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../widgets/signature_pad.dart';

class LigneFormData {
  int numero;
  DateTime? dateDemande;
  final TextEditingController client = TextEditingController();
  final TextEditingController refDemande = TextEditingController();
  final TextEditingController resumeDemande = TextEditingController();
  final TextEditingController refDevis = TextEditingController();
  final TextEditingController montantHt = TextEditingController();
  final TextEditingController statut = TextEditingController();

  LigneFormData(this.numero);

  void dispose() {
    client.dispose();
    refDemande.dispose();
    resumeDemande.dispose();
    refDevis.dispose();
    montantHt.dispose();
    statut.dispose();
  }

  Map<String, dynamic> toJson() => {
        'numero': numero,
        'date_demande': dateDemande != null ? DateFormat('yyyy-MM-dd').format(dateDemande!) : null,
        'client': client.text.trim().isEmpty ? null : client.text.trim(),
        'ref_demande': refDemande.text.trim().isEmpty ? null : refDemande.text.trim(),
        'resume_demande': resumeDemande.text.trim().isEmpty ? null : resumeDemande.text.trim(),
        'ref_devis': refDevis.text.trim().isEmpty ? null : refDevis.text.trim(),
        'montant_ht': montantHt.text.trim().isEmpty ? null : double.tryParse(montantHt.text.replaceAll(' ', '')),
        'statut': statut.text.trim().isEmpty ? null : statut.text.trim(),
      };

  bool get isFilled =>
      client.text.isNotEmpty ||
      refDemande.text.isNotEmpty ||
      resumeDemande.text.isNotEmpty ||
      refDevis.text.isNotEmpty ||
      montantHt.text.isNotEmpty ||
      statut.text.isNotEmpty;
}

class PointTraitementFormScreen extends StatefulWidget {
  final int? ficheId;

  const PointTraitementFormScreen({super.key, this.ficheId});

  @override
  State<PointTraitementFormScreen> createState() => _PointTraitementFormScreenState();
}

class _PointTraitementFormScreenState extends State<PointTraitementFormScreen> {
  final _semaineCtrl = TextEditingController();
  final _responsableCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;
  String? _signatureBase64;
  final List<LigneFormData> _lignes = List.generate(10, (i) => LigneFormData(i + 1));
  bool _loading = false;
  bool _saving = false;

  double get _totalMontant {
    double total = 0;
    for (final l in _lignes) {
      final v = double.tryParse(l.montantHt.text.replaceAll(' ', ''));
      if (v != null) total += v;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    final user = ApiService.instance.currentUser;
    if (user != null) {
      _responsableCtrl.text = '${user.prenom} ${user.nom}'.trim();
    }
    if (widget.ficheId != null) _loadFiche();
  }

  Future<void> _loadFiche() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.getOne('/api/point-traitement/${widget.ficheId}');
      _semaineCtrl.text = data['semaine']?.toString() ?? '';
      _responsableCtrl.text = data['responsable'] ?? '';
      _signatureBase64 = data['signature_base64'];
      if (data['date_debut'] != null) _dateDebut = DateTime.parse(data['date_debut']);
      if (data['date_fin'] != null) _dateFin = DateTime.parse(data['date_fin']);

      final lignes = data['lignes'] as List<dynamic>? ?? [];
      for (final raw in lignes) {
        final num = raw['numero'] as int;
        if (num < 1 || num > 10) continue;
        final l = _lignes[num - 1];
        if (raw['date_demande'] != null) l.dateDemande = DateTime.parse(raw['date_demande']);
        l.client.text = raw['client'] ?? '';
        l.refDemande.text = raw['ref_demande'] ?? '';
        l.resumeDemande.text = raw['resume_demande'] ?? '';
        l.refDevis.text = raw['ref_devis'] ?? '';
        if (raw['montant_ht'] != null) l.montantHt.text = raw['montant_ht'].toString();
        l.statut.text = raw['statut'] ?? '';
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDebut ? _dateDebut : _dateFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Future<int?> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'semaine': int.tryParse(_semaineCtrl.text.trim()),
        'date_debut': _dateDebut != null ? DateFormat('yyyy-MM-dd').format(_dateDebut!) : null,
        'date_fin': _dateFin != null ? DateFormat('yyyy-MM-dd').format(_dateFin!) : null,
        'responsable': _responsableCtrl.text.trim(),
        'signature_base64': _signatureBase64,
        'lignes': _lignes.map((l) => l.toJson()).toList(),
      };

      Map<String, dynamic> result;
      if (widget.ficheId != null) {
        result = await ApiService.instance.patch('/api/point-traitement/${widget.ficheId}', body);
      } else {
        result = await ApiService.instance.post('/api/point-traitement/', body);
      }

      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fiche enregistrée avec succès'), backgroundColor: Color(0xFF008940)),
      );
      return result['id'] as int?;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      return null;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _semaineCtrl.dispose();
    _responsableCtrl.dispose();
    for (final l in _lignes) {
      l.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy', 'fr_FR');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point Traitement des Demandes'),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final id = await _save();
                if (id != null && mounted) Navigator.pop(context, true);
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF008940)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(dateFmt),
                  const SizedBox(height: 16),
                  _buildTablePreview(),
                  const SizedBox(height: 16),
                  ..._lignes.map(_buildLigneCard),
                  const SizedBox(height: 16),
                  _buildFooterCard(),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _saving
                        ? null
                        : () async {
                            final id = await _save();
                            if (id != null && mounted) Navigator.pop(context, true);
                          },
                    icon: const Icon(Icons.save),
                    label: const Text('Enregistrer la fiche'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008940),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderCard(DateFormat dateFmt) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black26)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Image.asset('assets/images/logo_isitek.png', width: 60, height: 60, fit: BoxFit.contain),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9),
                      border: Border.all(color: Colors.black),
                    ),
                    child: const Text(
                      'POINT TRAITEMENT DES DEMANDES',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _semaineCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'SEMAINE',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'DU', isDense: true, border: OutlineInputBorder()),
                      child: Text(_dateDebut != null ? dateFmt.format(_dateDebut!) : 'Choisir...'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(false),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'AU', isDense: true, border: OutlineInputBorder()),
                      child: Text(_dateFin != null ? dateFmt.format(_dateFin!) : 'Choisir...'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _responsableCtrl,
              decoration: const InputDecoration(
                labelText: 'RESPONSABLE',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablePreview() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.black)),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.white),
          border: TableBorder.all(color: Colors.black),
          columnSpacing: 8,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 48,
          columns: const [
            DataColumn(label: Text('N°', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
            DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
            DataColumn(label: Text('CLIENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
            DataColumn(label: Text('REF DEMANDE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
            DataColumn(label: Text('RESUME DEMANDE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
            DataColumn(label: Text('REF DEVIS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
            DataColumn(label: Text('MONTANT HT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
            DataColumn(label: Text('STATUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10))),
          ],
          rows: _lignes.map((l) {
            return DataRow(cells: [
              DataCell(Text('${l.numero}', style: const TextStyle(fontSize: 10))),
              DataCell(Text(l.dateDemande != null ? DateFormat('dd/MM/yy').format(l.dateDemande!) : '', style: const TextStyle(fontSize: 10))),
              DataCell(Text(l.client.text, style: const TextStyle(fontSize: 10))),
              DataCell(Text(l.refDemande.text, style: const TextStyle(fontSize: 10))),
              DataCell(SizedBox(width: 120, child: Text(l.resumeDemande.text, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis))),
              DataCell(Text(l.refDevis.text, style: const TextStyle(fontSize: 10))),
              DataCell(Text(l.montantHt.text, style: const TextStyle(fontSize: 10))),
              DataCell(Text(l.statut.text, style: const TextStyle(fontSize: 10))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLigneCard(LigneFormData l) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: l.isFilled ? const Color(0xFF008940) : Colors.grey.shade300),
      ),
      child: ExpansionTile(
        initiallyExpanded: l.numero <= 3,
        title: Text(
          'Ligne ${l.numero}${l.client.text.isNotEmpty ? ' — ${l.client.text}' : ''}',
          style: TextStyle(fontWeight: FontWeight.w600, color: l.isFilled ? const Color(0xFF008940) : null),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('DATE'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: l.dateDemande ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => l.dateDemande = picked);
                    },
                    child: Text(l.dateDemande != null ? DateFormat('dd/MM/yyyy').format(l.dateDemande!) : 'Choisir'),
                  ),
                ),
                TextField(controller: l.client, decoration: const InputDecoration(labelText: 'CLIENT', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
                const SizedBox(height: 8),
                TextField(controller: l.refDemande, decoration: const InputDecoration(labelText: 'REF DEMANDE', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
                const SizedBox(height: 8),
                TextField(controller: l.resumeDemande, decoration: const InputDecoration(labelText: 'RESUME DEMANDE', border: OutlineInputBorder()), maxLines: 3, onChanged: (_) => setState(() {})),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: l.refDevis, decoration: const InputDecoration(labelText: 'REF DEVIS', border: OutlineInputBorder()), onChanged: (_) => setState(() {}))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(controller: l.montantHt, decoration: const InputDecoration(labelText: 'MONTANT HT', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (_) => setState(() {}))),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(controller: l.statut, decoration: const InputDecoration(labelText: 'STATUT', border: OutlineInputBorder()), onChanged: (_) => setState(() {})),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterCard() {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.black26)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SignaturePad(
              initialBase64: _signatureBase64,
              onChanged: (v) => _signatureBase64 = v,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 12),
                Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.5)),
                  child: Text(
                    fmt.format(_totalMontant),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
