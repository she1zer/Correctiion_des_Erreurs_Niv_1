import 'package:flutter/material.dart';

import '../../main.dart' show IsitekColors;
import '../../services/api_service.dart';
import 'rapport_form_screen.dart';
import 'rapport_list_screen.dart';

/// Accueil rapports de visite — liste en base, recherche, création.
class RapportVisiteHubScreen extends StatefulWidget {
  const RapportVisiteHubScreen({super.key});

  @override
  State<RapportVisiteHubScreen> createState() => _RapportVisiteHubScreenState();
}

class _RapportVisiteHubScreenState extends State<RapportVisiteHubScreen> {
  int _refreshTick = 0;

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    final canRapport = user?.canCreateRapportEffective ?? user?.role == 'admin';

    if (!canRapport) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rapport de visite'),
          backgroundColor: IsitekColors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Génération de rapports non autorisée',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Demandez à l\'administrateur ISITEK d\'activer '
                  '« Générer des rapports » sur votre compte.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Rapports de visite'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
      ),
      body: RapportListScreen(refreshTick: _refreshTick),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RapportFormScreen()),
          );
          if (mounted) setState(() => _refreshTick++);
        },
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau rapport'),
      ),
    );
  }
}
