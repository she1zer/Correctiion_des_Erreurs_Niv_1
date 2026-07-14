import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../main.dart' show IsitekColors;
import 'satisfaction_rating_screen.dart';

class ClientAffaireDetailScreen extends StatefulWidget {
  final int affaireId;
  const ClientAffaireDetailScreen({super.key, required this.affaireId});

  @override
  State<ClientAffaireDetailScreen> createState() => _ClientAffaireDetailScreenState();
}

class _ClientAffaireDetailScreenState extends State<ClientAffaireDetailScreen> {
  Map<String, dynamic>? _affaire;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await ApiService.instance.getOne('/api/affaires/${widget.affaireId}');
      setState(() {
        _affaire = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Impossible de récupérer les détails du projet.";
        _isLoading = false;
      });
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'termine':
        return Colors.green;
      case 'en_cours':
        return Colors.blue;
      case 'bloque':
        return Colors.orange;
      case 'annule':
        return Colors.red;
      case 'non_entame':
      default:
        return Colors.grey;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'termine':
        return 'Terminé';
      case 'en_cours':
        return 'En cours';
      case 'bloque':
        return 'Bloqué';
      case 'annule':
        return 'Annulé';
      case 'non_entame':
      default:
        return 'Non entamé';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _affaire != null ? (_affaire!['numero_affaire'] ?? 'Détails') : 'Détails du projet',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: IsitekColors.textDark,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(IsitekColors.green),
        ),
      );
    }

    if (_errorMessage.isNotEmpty || _affaire == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 50),
              const SizedBox(height: 16),
              Text(_errorMessage.isNotEmpty ? _errorMessage : "Erreur de chargement"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchDetail,
                style: ElevatedButton.styleFrom(backgroundColor: IsitekColors.green, foregroundColor: Colors.white),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    final actions = List<dynamic>.from(_affaire!['actions'] ?? []);
    final completedCount = actions.where((a) => a['termine'] == true).length;
    final totalCount = actions.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return RefreshIndicator(
      onRefresh: _fetchDetail,
      color: IsitekColors.green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO CARD
            _buildProjectInfoCard(completedCount, totalCount, progress),
            
            // TIMELINE SECTION TITLE
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                "Étapes de réalisation",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: IsitekColors.textDark,
                ),
              ),
            ),

            // TIMELINE LIST
            if (actions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("Aucune étape définie pour ce projet.", style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              _buildTimelineList(actions),
              
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectInfoCard(int completed, int total, double progress) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 10),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: IsitekColors.greenSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _affaire!['numero_affaire'] ?? 'N/A',
                  style: const TextStyle(
                    color: IsitekColors.greenDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                "Ouvert le ${_formatDate(_affaire!['date_ouverture'])}",
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _affaire!['libelle_affaire'] ?? 'Sans libellé',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: IsitekColors.textDark,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          
          // DETAIL ROW
          _buildInfoRow(Icons.domain_rounded, "Domaine", _affaire!['domaine'] ?? 'Non spécifié'),
          const SizedBox(height: 10),
          _buildInfoRow(Icons.person_rounded, "Responsable", "${_affaire!['responsable_prenom']} ${_affaire!['responsable_nom']}"),
          const SizedBox(height: 10),
          if (_affaire!['numero_commande'] != null) ...[
            _buildInfoRow(Icons.receipt_long_rounded, "N° Commande", _affaire!['numero_commande']),
            const SizedBox(height: 10),
          ],
          if (_affaire!['date_livraison_bc'] != null) ...[
            _buildInfoRow(Icons.local_shipping_rounded, "Livraison prévue", _formatDate(_affaire!['date_livraison_bc'])),
            const SizedBox(height: 16),
          ] else ...[
            const SizedBox(height: 6),
          ],

          // PROGRESS BAR
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Progression globale",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
                  ),
                  Text(
                    "$completed / $total étapes (${(progress * 100).toInt()}%)",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IsitekColors.green),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: IsitekColors.greenSoft,
                  valueColor: const AlwaysStoppedAnimation<Color>(IsitekColors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 16),
        const SizedBox(width: 8),
        Text(
          "$label : ",
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: IsitekColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineList(List<dynamic> actions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index];
          final isCompleted = action['termine'] == true;
          final statut = action['statut'] ?? 'non_entame';
          final color = _getStatutColor(statut);
          final isLast = index == actions.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // VERTICAL TIMELINE INDICATOR
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green : Colors.white,
                        border: Border.all(
                          color: isCompleted ? Colors.green : color,
                          width: 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          isCompleted
                              ? Icons.check
                              : (statut == 'en_cours' ? Icons.play_arrow_rounded : Icons.circle),
                          size: isCompleted ? 14 : 10,
                          color: isCompleted ? Colors.white : color,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted
                              ? Colors.green
                              : (statut == 'en_cours' ? Colors.blue.withOpacity(0.5) : Colors.grey[300]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                
                // STEP DETAIL CARD
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: statut == 'en_cours' ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                action['libelle'] ?? 'Étape',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isCompleted ? IsitekColors.textSoft : IsitekColors.textDark,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getStatutLabel(statut),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // EXTRA INFO IF ACTION HAS THEM
                        if (action['observations'] != null && action['observations'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Observations : ${action['observations']}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],

                        // Show percentage for acompte step
                        if (action['pourcentage_accompte'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.percent, size: 14, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  "Acompte : ${action['pourcentage_accompte']}%",
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Show guarantee info for SAV step
                        if (action['garantie_mois'] != null || action['garantie_debut'] != null || action['garantie_fin'] != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (action['garantie_mois'] != null)
                                  Row(
                                    children: [
                                      const Icon(Icons.shield, size: 14, color: Colors.blue),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Garantie : ${action['garantie_mois']} mois",
                                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                if (action['garantie_debut'] != null && action['garantie_fin'] != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Du ${_formatDate(action['garantie_debut'])} au ${_formatDate(action['garantie_fin'])}",
                                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],

                        // Show satisfaction rating button for satisfaction step
                        if (action['libelle'].toString().toLowerCase().contains('satisfaction') && isCompleted) ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SatisfactionRatingScreen(
                                    affaireId: widget.affaireId,
                                    actionId: action['id'],
                                    affaireNumero: _affaire!['numero_affaire'],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.star_rate, size: 16),
                            label: const Text('Noter votre satisfaction'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: IsitekColors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 36),
                            ),
                          ),
                        ],

                        if (action['commentaire'] != null && action['commentaire'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 14, color: Colors.blue),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    action['commentaire'],
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (action['date_debut'] != null || action['date_fin'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 11, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                "${action['date_debut'] != null ? _formatDate(action['date_debut']) : '?'} au ${action['date_fin'] != null ? _formatDate(action['date_fin']) : '?'}",
                                style: TextStyle(color: Colors.grey[400], fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (index * 60).ms, duration: 350.ms).slideX(begin: 0.05, end: 0);
        },
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final parts = dateStr.toString().split('T')[0].split('-');
      if (parts.length == 3) {
        return "${parts[2]}/${parts[1]}/${parts[0]}";
      }
    } catch (_) {}
    return dateStr.toString();
  }
}
