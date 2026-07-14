import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'livre_caisse/livre_caisse_liste_screen.dart';
import 'fiche_controle/fiche_controle_liste_screen.dart';
import 'recherche/recherche_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISITEK - Gestion de Caisse'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo_isitek.jpg',
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ISITEK',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.isitekGreenDark,
                      ),
                    ),
                    const Text(
                      'Intégrateur de solutions industrielles',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              _MenuCard(
                icon: Icons.menu_book_outlined,
                title: 'Livre de Caisse Hebdomadaire',
                subtitle: 'Enregistrer les entrées et sorties de caisse',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LivreCaisseListeScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _MenuCard(
                icon: Icons.fact_check_outlined,
                title: 'Fiche de Contrôle Caisse',
                subtitle: 'Contrôler le solde théorique et réel chaque semaine',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FicheControleListeScreen()),
                ),
              ),
              const SizedBox(height: 16),
              _MenuCard(
                icon: Icons.search,
                title: 'Recherche',
                subtitle: 'Retrouver une opération par solde, nom, année...',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RechercheScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.isitekGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.isitekGreenDark, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}
