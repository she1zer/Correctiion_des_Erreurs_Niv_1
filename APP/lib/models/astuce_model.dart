import 'package:flutter/material.dart';

import '../utils/astuce_icon_map.dart';
import 'client_tip.dart';

/// Astuce depuis l'API ou fallback local.
class AstuceModel {
  final int? id;
  final String emoji;
  final String title;
  final String summary;
  final String detail;
  final String category;
  final String iconName;
  final Color gradientStart;
  final Color gradientEnd;
  final Color accent;
  final bool isActive;

  const AstuceModel({
    this.id,
    required this.emoji,
    required this.title,
    required this.summary,
    required this.detail,
    required this.category,
    required this.iconName,
    required this.gradientStart,
    required this.gradientEnd,
    required this.accent,
    this.isActive = true,
  });

  IconData get icon => AstuceIconMap.resolve(iconName);
  List<Color> get gradient => [gradientStart, gradientEnd];

  factory AstuceModel.fromApi(Map<String, dynamic> m) {
    return AstuceModel(
      id: m['id'] as int?,
      emoji: m['emoji']?.toString() ?? '💡',
      title: m['title']?.toString() ?? '',
      summary: m['summary']?.toString() ?? '',
      detail: m['detail']?.toString() ?? '',
      category: m['category']?.toString() ?? 'Général',
      iconName: m['icon_name']?.toString() ?? 'lightbulb_rounded',
      gradientStart: AstuceIconMap.parseColor(m['gradient_start']?.toString(), fallback: const Color(0xFFFFD54F)),
      gradientEnd: AstuceIconMap.parseColor(m['gradient_end']?.toString(), fallback: const Color(0xFFF9A825)),
      accent: AstuceIconMap.parseColor(m['accent_color']?.toString(), fallback: const Color(0xFFF57F17)),
      isActive: m['is_active'] as bool? ?? true,
    );
  }

  ClientTip toClientTip() => ClientTip(
        emoji: emoji,
        title: title,
        summary: summary,
        detail: detail,
        category: category,
        icon: icon,
        gradient: gradient,
        accent: accent,
      );

  Map<String, dynamic> toApiBody() => {
        'emoji': emoji,
        'title': title,
        'summary': summary,
        'detail': detail,
        'category': category,
        'icon_name': iconName,
        'gradient_start': '#${gradientStart.value.toRadixString(16).substring(2).toUpperCase()}',
        'gradient_end': '#${gradientEnd.value.toRadixString(16).substring(2).toUpperCase()}',
        'accent_color': '#${accent.value.toRadixString(16).substring(2).toUpperCase()}',
        'is_active': isActive,
      };
}
