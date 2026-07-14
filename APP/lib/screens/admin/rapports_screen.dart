import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../services/api_service.dart';
import '../../rapport/screens/rapport_visite_hub_screen.dart';
import '../shared/point_traitement_list_screen.dart';
import '../../caisse/screens/caisse_hub_screen.dart';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  List<dynamic> _affaires = [];
  int? _selectedAffaireId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadAffaires();
  }

  Future<void> _loadAffaires() async {
    try {
      final list = await ApiService.instance.get('/api/affaires/');
      setState(() => _affaires = list);
    } catch (_) {}
  }

  Future<void> _printPlan({int? affaireId}) async {
    setState(() => _loading = true);
    try {
      final path = affaireId != null
          ? '/api/rapports/plan-action?affaire_id=$affaireId'
          : '/api/rapports/plan-action';
      final bytes = await ApiService.instance.downloadPdf(path);
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportPlanExcel({int? affaireId}) async {
    setState(() => _loading = true);
    try {
      final path = affaireId != null
          ? '/api/rapports/plan-action-excel?affaire_id=$affaireId'
          : '/api/rapports/plan-action-excel';
      final bytes = await ApiService.instance.downloadPdf(path);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'plan_actions.xlsx',
      );
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
      appBar: AppBar(
        title: const Text('Rapports & Exports'),
        backgroundColor: const Color(0xFF008940),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            title: 'Plan d\'actions',
            icon: Icons.assignment,
            description: 'Génère le tableau PLAN D\'ACTIONS (affaires + internes) au format PDF ou Excel modifiable.',
            children: [
              DropdownButtonFormField<int?>(
                value: _selectedAffaireId,
                decoration: InputDecoration(
                  labelText: 'Filtrer par affaire (optionnel)',
                  prefixIcon: const Icon(Icons.filter_list),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes les actions')),
                  ..._affaires.map((a) => DropdownMenuItem(
                        value: a['id'] as int,
                        child: Text('${a['numero_affaire']} — ${a['client_nom']}'),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedAffaireId = v),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loading ? null : () => _printPlan(affaireId: _selectedAffaireId),
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf),
                label: const Text('Imprimer en PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008940),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loading ? null : () => _exportPlanExcel(affaireId: _selectedAffaireId),
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.table_view),
                label: const Text('Exporter en Excel (modifiable)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Rapport de visite technique',
            icon: Icons.engineering_outlined,
            description:
                'État des lieux, photos, NB — PDF avec SERVICE COMMERCIAL aligné à droite.',
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RapportVisiteHubScreen()),
                  );
                },
                icon: const Icon(Icons.add_chart),
                label: const Text('Créer un rapport de visite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Caisse ISITEK',
            icon: Icons.account_balance_wallet_outlined,
            description:
                'Fiche de contrôle caisse et livre de caisse hebdomadaire — saisie, PDF identique au modèle papier, recherche par année et solde.',
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CaisseHubScreen()),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Ouvrir le module Caisse'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF6C00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Point traitement des demandes',
            icon: Icons.assignment_outlined,
            description: 'Fiche hebdomadaire des demandes clients — identique au formulaire papier ISITEK, exportable en Excel avec logo et signature.',
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PointTraitementListScreen()),
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Gérer les fiches de demandes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Fiches d\'affaires',
            icon: Icons.description,
            description: 'Pour imprimer ou exporter une fiche d\'affaire individuelle au format Excel ou PDF, accédez à la section "Affaires" du menu principal, ouvrez une affaire, puis choisissez l\'option souhaitée dans le menu supérieur.',
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Les fiches d\'affaires individuelles sont accessibles depuis la page de détail de chaque affaire.',
                        style: TextStyle(color: Colors.blue[900], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required String description,
    required List<Widget> children,
  }) {
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
                Icon(icon, color: const Color(0xFF008940), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF008940),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
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
