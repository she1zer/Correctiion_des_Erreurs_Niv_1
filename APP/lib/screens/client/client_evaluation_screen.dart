import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/demande_service.dart';
import '../../main.dart' show IsitekColors;

class ClientEvaluationScreen extends StatefulWidget {
  final String demandeId;
  const ClientEvaluationScreen({super.key, required this.demandeId});

  @override
  State<ClientEvaluationScreen> createState() => _ClientEvaluationScreenState();
}

class _ClientEvaluationScreenState extends State<ClientEvaluationScreen> {
  int _rating = 4; // Default to 4 stars as shown in screenshot
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    final comment = _commentController.text.trim();
    // Use default comment if empty
    final finalComment = comment.isNotEmpty ? comment : 'Très professionnel, intervention rapide...';
    
    await DemandeService.instance.evaluateDemande(widget.demandeId, _rating, finalComment);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Merci pour votre avis !'),
        backgroundColor: IsitekColors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Find the demand to display details
    final demands = DemandeService.instance.demandes;
    final demand = demands.firstWhere((d) => d.id == widget.demandeId, orElse: () => demands.first);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Retour de satisfaction',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: IsitekColors.textDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Green Checkbox Icon Box (Écran 6)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: IsitekColors.greenSoft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: IsitekColors.green.withOpacity(0.2)),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: IsitekColors.green,
                size: 60,
              ),
            ).animate().scale(duration: 450.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),

            // Titles
            const Text(
              'Étape 12 : Retour satisfaction',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: IsitekColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${demand.typePrestation} — ${demand.adresse.split(',').first}',
              style: const TextStyle(
                fontSize: 14,
                color: IsitekColors.textSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32),

            // Question
            const Text(
              'Comment s\'est passée l\'intervention ?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: IsitekColors.textDark,
              ),
            ),
            const SizedBox(height: 20),

            // Stars Row (Interative)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final isSelected = index < _rating;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 40,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Text input for review
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Très professionnel, intervention rapide...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Button Envoyer mon avis
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: IsitekColors.greenDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _submitReview,
                child: const Text('Envoyer mon avis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 18),

            // Text Link "Passer pour l'instant"
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Passer pour l\'instant',
                style: TextStyle(
                  color: IsitekColors.textSoft,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
