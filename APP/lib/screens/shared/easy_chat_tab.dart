import 'package:flutter/material.dart';

import '../../main.dart' show IsitekColors;
import '../../models/ai_chat_mode.dart';
import 'isi_chat_screen.dart';

/// Accueil IA : choix Easy (base ISITEK) ou Ollama (chat libre).
class EasyChatTab extends StatefulWidget {
  const EasyChatTab({super.key});

  @override
  State<EasyChatTab> createState() => _EasyChatTabState();
}

class _EasyChatTabState extends State<EasyChatTab> {
  AiChatMode? _openMode;

  void _openChat(AiChatMode mode) => setState(() => _openMode = mode);

  @override
  Widget build(BuildContext context) {
    if (_openMode != null) {
      return EasyChatScreen(
        initialMode: _openMode!,
        onBack: () => setState(() => _openMode = null),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Icon(Icons.psychology_alt_outlined, size: 64, color: IsitekColors.green),
          const SizedBox(height: 16),
          const Text(
            'Assistant IA',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: IsitekColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez Easy (base ISITEK) ou Ollama (chat libre)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: IsitekColors.textSoft),
          ),
          const SizedBox(height: 28),
          _ModeCard(
            icon: Icons.storage_rounded,
            title: 'Easy',
            subtitle: AiChatMode.easy.subtitle,
            color: IsitekColors.green,
            onTap: () => _openChat(AiChatMode.easy),
          ),
          const SizedBox(height: 14),
          _ModeCard(
            icon: Icons.smart_toy_outlined,
            title: 'Ollama',
            subtitle: AiChatMode.ollama.subtitle,
            color: const Color(0xFF1565C0),
            onTap: () => _openChat(AiChatMode.ollama),
          ),
          const SizedBox(height: 20),
          Text(
            'Easy : historique sauvegardé · Ollama : session locale',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: IsitekColors.textSoft),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: IsitekColors.textDark,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
