import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../main.dart' show IsitekColors;

class ClientServicesScreen extends StatelessWidget {
  const ClientServicesScreen({super.key});

  void _openServiceSheet(BuildContext context, String serviceTitle) {
    final name = TextEditingController();
    final contact = TextEditingController();
    final detail = TextEditingController(text: "Bonjour, je suis intéressé par votre service : $serviceTitle.\n\nVoici plus de détails sur mon besoin : ");

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
                Text(
                  'Demander une prestation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: IsitekColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Service sélectionné : $serviceTitle',
                  style: const TextStyle(
                    fontSize: 12,
                    color: IsitekColors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'Nom complet',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contact,
                  decoration: InputDecoration(
                    labelText: 'Téléphone / Email',
                    prefixIcon: const Icon(Icons.call_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detail,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Détail de votre besoin',
                    prefixIcon: const Icon(Icons.build_circle_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
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
                          'Demande de service ISITEK\n\nService: $serviceTitle\nNom: ${name.text}\nContact: ${contact.text}\nDétail: ${detail.text}';
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
                          'Demande de service ISITEK\n\nService: $serviceTitle\nNom: ${name.text}\nContact: ${contact.text}\nDétail: ${detail.text}';
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'contact@isitek.ci',
                        query:
                            'subject=Demande de prestation : $serviceTitle&body=${Uri.encodeComponent(msg)}',
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
    final services = [
      (
        icon: Icons.architecture_rounded,
        title: 'Études & Conception',
        desc:
            'Schémas électriques, diagrammes P&ID et dimensionnements sur-mesure pour une ingénierie précise.',
        color: const Color(0xFF0284C7),
      ),
      (
        icon: Icons.inventory_2_rounded,
        title: 'Fourniture de Matériel',
        desc:
            'Équipements et matériels industriels certifiés, provenant des plus grands constructeurs mondiaux.',
        color: const Color(0xFFD97706),
      ),
      (
        icon: Icons.construction_rounded,
        title: 'Projets Clés en Main',
        desc:
            'De la conception initiale à la mise en service sur site, nous pilotons l’intégralité de vos chantiers.',
        color: const Color(0xFF008940),
      ),
      (
        icon: Icons.school_rounded,
        title: 'Formation & Conseil',
        desc:
            'Audits techniques, renforcement des compétences et accompagnement personnalisé vers l’industrie 4.0.',
        color: const Color(0xFF7C3AED),
      ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // HEADER BANNER
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
                Icon(Icons.layers_rounded, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  'NOS PRESTATIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Des compétences pointues à votre service.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // LIST OF SERVICES
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: services.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final s = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: s.color,
                              width: 6,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: s.color.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    s.icon,
                                    color: s.color,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    s.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: IsitekColors.textDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              s.desc,
                              style: const TextStyle(
                                fontSize: 13,
                                color: IsitekColors.textSoft,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  label: const Text(
                                    'Demander un devis',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: s.color,
                                    side: BorderSide(color: s.color.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  onPressed: () => _openServiceSheet(context, s.title),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: 0.05, end: 0);
                },
              ).toList(),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
