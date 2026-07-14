import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart' show IsitekColors, liensPartenaires;

class ClientReferencesScreen extends StatefulWidget {
  const ClientReferencesScreen({super.key});

  @override
  State<ClientReferencesScreen> createState() => _ClientReferencesScreenState();
}

class _ClientReferencesScreenState extends State<ClientReferencesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> partenaires = const [
    {
      'name': 'ABB',
      'desc': 'Automatisation industrielle',
      'img': 'ABB_logo.png',
    },
    {
      'name': 'FESTO',
      'desc': 'Automatisation pneumatique',
      'img': 'festo_logo.png',
    },
    {
      'name': 'FINDER',
      'desc': 'Relais et composants',
      'img': 'Finder_logo.png',
    },
    {
      'name': 'LEGRAND',
      'desc': 'Matériel électrique',
      'img': 'legrand_logo.png',
    },
    {
      'name': 'LG', 
      'desc': 'Équipements électriques', 
      'img': 'LG_logo.png'
    },
    {
      'name': 'NEXANS', 
      'desc': 'Câbles et solutions', 
      'img': 'nexans_logo.png'
    },
    {
      'name': 'PHILIPS',
      'desc': 'Éclairage et solutions',
      'img': 'philips_logo.png',
    },
    {
      'name': 'SAMSUNG',
      'desc': 'Technologies avancées',
      'img': 'samsung_logo.png',
    },
    {
      'name': 'SCHNEIDER ELECTRIC',
      'desc': 'Automatismes industriels',
      'img': 'schneider_logo.png',
    },
    {
      'name': 'SIEMENS',
      'desc': 'Automatisation et énergie',
      'img': 'siemens_logo.png',
    },
  ];

  Future<void> _launchURL(String? name) async {
    if (name == null) return;
    final String? urlString = liensPartenaires[name.toUpperCase()];
    if (urlString != null) {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FILTER PARTERNS BY NAME OR DESCRIPTION
    final filteredPartenaires = partenaires.where((p) {
      final query = _searchQuery.toLowerCase();
      final nameMatches = p['name']!.toLowerCase().contains(query);
      final descMatches = p['desc']!.toLowerCase().contains(query);
      return nameMatches || descMatches;
    }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // HEADER DESIGN
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF002810), IsitekColors.green],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: const Column(
              children: [
                Icon(Icons.verified_outlined, color: Colors.white, size: 44),
                SizedBox(height: 12),
                Text(
                  "NOS PARTENAIRES",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Les plus grands constructeurs mondiaux à nos côtés.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher une marque ou un domaine...",
                prefixIcon: const Icon(Icons.search_rounded, color: IsitekColors.green),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.black.withOpacity(0.03)),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ).animate().fadeIn(delay: 50.ms),

          const SizedBox(height: 24),

          // ADVANTAGES SUMMARY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAdvantageItem(Icons.verified_user_rounded, "Qualité", Colors.green),
                _buildAdvantageItem(Icons.bolt_rounded, "Innovation", Colors.blue),
                _buildAdvantageItem(Icons.headset_mic_rounded, "Support", Colors.purple),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 32),

          // PARTNERS GRID
          filteredPartenaires.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    "Aucun partenaire ne correspond à votre recherche.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredPartenaires.length,
                  itemBuilder: (context, index) {
                    final item = filteredPartenaires[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _launchURL(item['name']),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      "assets/images/${item['img']}",
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[50],
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.business_rounded,
                                              size: 36,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: IsitekColors.textDark,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['desc']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Visiter le site ",
                                      style: TextStyle(
                                        color: IsitekColors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Icon(Icons.open_in_new_rounded, color: IsitekColors.green, size: 10),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.05, end: 0);
                  },
                ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAdvantageItem(IconData i, String t, Color c) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(i, color: c, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          t,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
        ),
      ],
    );
  }
}
