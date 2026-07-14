import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart' show IsitekColors;

class ClientSocieteScreen extends StatelessWidget {
  const ClientSocieteScreen({super.key});

  Future<void> _call() async {
    final uri = Uri.parse('tel:+2250797385035');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final uri = Uri.parse('https://wa.me/2250797385035');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _email() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'contact@isitek.ci',
      query: 'subject=${Uri.encodeComponent("Demande d\'information - ISITEK")}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _maps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent("ISITEK SARL, Angré Château, Immeuble DIAWARA, Abidjan, Côte d\'Ivoire")}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openServiceSheet(BuildContext context) {
    final name = TextEditingController();
    final contact = TextEditingController();
    final detail = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Demander une prestation libre',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: IsitekColors.textDark),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contact,
                  decoration: InputDecoration(
                    labelText: 'Téléphone / Email',
                    prefixIcon: const Icon(Icons.call_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: detail,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Détail de votre demande',
                    prefixIcon: const Icon(Icons.build_circle_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Envoyer sur WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final msg =
                          'Demande de prestation libre ISITEK\n\nNom: ${name.text}\nContact: ${contact.text}\nDétail: ${detail.text}';
                      final url =
                          'https://wa.me/2250797385035?text=${Uri.encodeComponent(msg)}';
                      launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Envoyer par e-mail'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final msg =
                          'Demande de prestation libre ISITEK\n\nNom: ${name.text}\nContact: ${contact.text}\nDétail: ${detail.text}';
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'contact@isitek.ci',
                        query:
                            'subject=Demande de prestation libre ISITEK&body=${Uri.encodeComponent(msg)}',
                      );
                      launchUrl(uri);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // BANNER WITH COMPANY IDENTITY
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 72, 24, 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF002810), IsitekColors.green],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.apartment_rounded, color: Colors.white, size: 44),
                SizedBox(height: 16),
                Text(
                  'ISITEK SARL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Intégrateur de solutions industrielles et technologiques.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // CONTACT METRICS
          const Text(
            'RESTEZ EN CONTACT',
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: IsitekColors.textSoft,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // 2x2 CONTACT CARDS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.35,
              children: [
                _contactCard(
                  icon: Icons.phone_rounded,
                  label: 'Appeler',
                  color: IsitekColors.green,
                  onTap: _call,
                ).animate().fadeIn(delay: 50.ms, duration: 300.ms),
                _contactCard(
                  icon: Icons.chat_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: _whatsapp,
                ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                _contactCard(
                  icon: Icons.email_rounded,
                  label: 'E-mail',
                  color: const Color(0xFFEAB308),
                  onTap: _email,
                ).animate().fadeIn(delay: 150.ms, duration: 300.ms),
                _contactCard(
                  icon: Icons.location_on_rounded,
                  label: 'Nous Trouver',
                  color: IsitekColors.danger,
                  onTap: _maps,
                ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // FREE PRESTATION BLOCK
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [IsitekColors.green, IsitekColors.greenDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: IsitekColors.green.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.engineering_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Un projet ou besoin spécifique ?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Décrivez-nous votre projet en quelques clics.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: IsitekColors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _openServiceSheet(context),
                      child: const Text(
                        'DEMANDER UNE PRESTATION',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: IsitekColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
