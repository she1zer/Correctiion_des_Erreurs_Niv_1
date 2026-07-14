import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/api_service.dart';
import '../../main.dart' show IsitekColors;
import 'client_affaire_detail_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  List<dynamic> _affaires = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAffaires();
  }

  Future<void> _fetchAffaires() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final data = await ApiService.instance.get('/api/affaires/');
      setState(() {
        _affaires = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Impossible de récupérer vos projets. Veuillez réessayer.";
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

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'termine':
        return Icons.check_circle_rounded;
      case 'en_cours':
        return Icons.run_circle_rounded;
      case 'bloque':
        return Icons.block_flipped;
      case 'annule':
        return Icons.cancel_rounded;
      case 'non_entame':
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final userName = user != null ? '${user.prenom} ${user.nom}' : 'Client';

    final activeProjects = _affaires.where((a) => a['statut'] == 'en_cours').length;
    final completedProjects = _affaires.where((a) => a['statut'] == 'termine').length;

    return RefreshIndicator(
      onRefresh: _fetchAffaires,
      color: IsitekColors.green,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO BANNER WITH GRADIENT & USER INFO
            _buildHero(userName, activeProjects, completedProjects),
            const SizedBox(height: 24),

            // SECTION TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Mes Projets & Affaires",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: IsitekColors.textDark,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: IsitekColors.green),
                    onPressed: _fetchAffaires,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // LIST OF PROJECTS
            _buildProjectList(),

            const SizedBox(height: 24),

            // TIPS SECTION
            _buildTipsSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(String name, int active, int completed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 72, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF002810), IsitekColors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  'ESPACE CLIENT SÉCURISÉ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Bonjour,\n$name !",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Suivez en temps réel l'avancement de vos projets industriels et électriques.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          
          // MINI STATS CARD ROW
          Row(
            children: [
              Expanded(
                child: _buildMiniStatCard(
                  title: "En Cours",
                  value: active.toString(),
                  icon: Icons.trending_up_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniStatCard(
                  title: "Terminés",
                  value: completed.toString(),
                  icon: Icons.assignment_turned_in_rounded,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildMiniStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(IsitekColors.green),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchAffaires,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_affaires.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
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
        child: Center(
          child: Column(
            children: [
              Icon(Icons.folder_open_rounded, color: Colors.grey[300], size: 60),
              const SizedBox(height: 16),
              const Text(
                "Aucun projet trouvé",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
              ),
              const SizedBox(height: 6),
              Text(
                "Vous n'avez pas encore d'affaire en cours d'étude ou de réalisation associée à votre adresse e-mail.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _affaires.length,
        itemBuilder: (context, index) {
          final a = _affaires[index];
          final color = _getStatutColor(a['statut']);
          final label = _getStatutLabel(a['statut']);
          final icon = _getStatutIcon(a['statut']);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ClientAffaireDetailScreen(affaireId: a['id']),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: IsitekColors.greenSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              a['numero_affaire'] ?? 'N/A',
                              style: const TextStyle(
                                color: IsitekColors.greenDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, color: color, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        a['libelle_affaire'] ?? 'Sans titre',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: IsitekColors.textDark,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 6),
                          Text(
                            a['domaine'] ?? 'Général',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          const Spacer(),
                          const Text(
                            "Voir détails",
                            style: TextStyle(
                              color: IsitekColors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded, color: IsitekColors.green, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: (index * 80).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
        },
      ),
    );
  }

  Widget _buildTipsSection() {
    final tips = [
      {
        'icon': Icons.description_outlined,
        'title': 'Détaillez votre projet',
        'content': 'Incluez les dimensions, la puissance électrique souhaitée et le type d\'installation pour un devis précis.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.camera_alt_outlined,
        'title': 'Photos du site',
        'content': 'Prenez des photos de l\'emplacement actuel, des tableaux électriques et des accès pour faciliter l\'intervention.',
        'color': Colors.green,
      },
      {
        'icon': Icons.calendar_today_outlined,
        'title': 'Planifiez à l\'avance',
        'content': 'Réservez vos interventions 2 à 3 semaines à l\'avance pour garantir la disponibilité de nos techniciens.',
        'color': Colors.orange,
      },
      {
        'icon': Icons.verified_user_outlined,
        'title': 'Normes de sécurité',
        'content': 'Vérifiez que votre installation respecte les normes NFC 15-100 avant toute intervention électrique.',
        'color': Colors.red,
      },
      {
        'icon': Icons.phone_in_talk_outlined,
        'title': 'Contactez-nous',
        'content': 'Pour les urgences électriques, appelez notre ligne prioritaire disponible 24h/24 et 7j/7.',
        'color': Colors.purple,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tips_and_updates, color: IsitekColors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Conseils & Astuces",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: IsitekColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tips.length,
              itemBuilder: (context, index) {
                final tip = tips[index];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        tip['color'] as Color? ?? Colors.blue,
                        (tip['color'] as Color?)?.withOpacity(0.7) ?? Colors.blue.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (tip['color'] as Color?)?.withOpacity(0.3) ?? Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tip['icon'] is IconData ? tip['icon'] as IconData : Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tip['content'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: 0.1, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}
