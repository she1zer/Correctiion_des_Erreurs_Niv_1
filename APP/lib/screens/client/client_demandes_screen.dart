import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/demande_service.dart';
import '../../services/api_service.dart';
import '../../main.dart' show IsitekColors;
import '../../models/demande_steps.dart';
import '../../widgets/demande_timeline.dart';
import 'client_evaluation_screen.dart';
import 'package:printing/printing.dart';

class ClientDemandesScreen extends StatefulWidget {
  const ClientDemandesScreen({super.key});

  @override
  State<ClientDemandesScreen> createState() => _ClientDemandesScreenState();
}

class _ClientDemandesScreenState extends State<ClientDemandesScreen> {
  String _searchQuery = '';

  List<DemandeModel> _filter(List<DemandeModel> list) {
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((d) {
      final dateStr = '${d.dateCreation.day.toString().padLeft(2, '0')} ${_getMonthName(d.dateCreation.month)} ${d.dateCreation.year}';
      return d.domaine.toLowerCase().contains(q) ||
          d.typePrestation.toLowerCase().contains(q) ||
          d.description.toLowerCase().contains(q) ||
          d.adresse.toLowerCase().contains(q) ||
          d.statut.toLowerCase().contains(q) ||
          dateStr.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bolt_rounded, color: IsitekColors.yellow, size: 24),
            SizedBox(width: 6),
            Text(
              'ISITEK',
              style: TextStyle(
                color: IsitekColors.greenDark,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: IsitekColors.greenDark),
            onPressed: () => DemandeService.instance.fetchData(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: DemandeService.instance,
        builder: (context, _) {
          final list = DemandeService.instance.demandes;
          final filtered = _filter(list);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title "Mes demandes"
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Mes demandes',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: IsitekColors.textDark,
                  ),
                ),
              ),

              // Search Bar
              if (list.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher une demande (ex: clim, électricité)...',
                      prefixIcon: const Icon(Icons.search, color: IsitekColors.green),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: IsitekColors.green, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),

              // Demands List
              Expanded(
                child: list.isEmpty
                    ? _buildEmptyState()
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Aucun résultat pour "$_searchQuery"',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final demande = filtered[index];
                              return _buildDemandCard(context, demande, index);
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Aucune demande en cours',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: IsitekColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vous n\'avez pas encore créé de demande de prestation. Cliquez sur l\'icône + sur l\'accueil pour commencer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: IsitekColors.textSoft, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandCard(BuildContext context, DemandeModel item, int index) {
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    final stepNum = DemandeSteps.stepIndexForStatus(item.statut);
    final stepDef = DemandeSteps.stepForStatus(item.statut);
    switch (item.statut) {
      case 'annule':
        badgeBg = const Color(0xFFFFEAEA);
        badgeText = Colors.red.shade700;
        badgeLabel = 'Annulé';
        break;
      case 'termine':
        badgeBg = IsitekColors.greenSoft;
        badgeText = IsitekColors.greenDark;
        badgeLabel = 'Terminé ✔';
        break;
      default:
        badgeBg = IsitekColors.greenSoft;
        badgeText = IsitekColors.greenDark;
        badgeLabel = stepDef != null ? 'Étape $stepNum' : 'En cours';
        break;
    }

    final dateStr = '${item.dateCreation.day.toString().padLeft(2, '0')} ${_getMonthName(item.dateCreation.month)} ${item.dateCreation.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
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
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.typePrestation} ${item.domaine.toLowerCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: IsitekColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.domaine} • $dateStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: IsitekColors.textSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: badgeText,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (item.statut != 'annule') ...[
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 16),
              DemandeTimeline(
                statut: item.statut,
                skippedSteps: item.etapesSautees,
                devisMontant: item.devisMontant,
                accomptePourcentage: item.accomptePourcentage,
                garantieMois: item.garantieMois,
                garantieDebut: item.garantieDebut,
                garantieFin: item.garantieFin,
              ),
              const SizedBox(height: 8),
            ],

            // Action Buttons
            if (item.statut == 'devis_propose') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: IsitekColors.green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        // Accept devis
                        await DemandeService.instance.acceptDevis(item.id);
                      },
                      child: const Text('Accepter & Envoyer BC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: IsitekColors.greenDark,
                        side: const BorderSide(color: IsitekColors.green, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => DemandeService.instance.refuseDevis(item.id),
                      child: const Text('Refuser', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],

            if (item.statut == 'depot_facture') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('Confirmer le Règlement (Chèque/Virement)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IsitekColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    await ApiService.instance.patch('/api/demandes/${item.id}', {
                      'statut': 'reglement_cheque',
                    });
                    await DemandeService.instance.fetchData();
                  },
                ),
              ),
            ],

            if (item.statut == 'depot_facture' || item.statut == 'reglement_cheque' || item.statut == 'termine') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.file_download_rounded, size: 18),
                  label: const Text('Télécharger la Facture (Excel)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    try {
                      final bytes = await ApiService.instance.downloadPdf('/api/rapports/facture-excel/${item.id}');
                      await Printing.sharePdf(bytes: bytes, filename: 'Facture_FNE_${item.id}.xlsx');
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur lors du téléchargement : $e'))
                      );
                    }
                  },
                ),
              ),
            ],

            if ((item.statut == 'retour_satisfaction' || item.statut == 'termine') && !item.isRated) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  label: const Text('Donner mon avis (étoiles)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: IsitekColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClientEvaluationScreen(demandeId: item.id),
                      ),
                    );
                  },
                ),
              ),
            ],

            if (item.statut == 'termine' && item.isRated) ...[
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: IsitekColors.green, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Prestation évaluée (${item.rating} / 5 étoiles)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: IsitekColors.greenDark,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (starIdx) {
                      return Icon(
                        starIdx < (item.rating ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 14,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  String _getMonthName(int month) {
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
