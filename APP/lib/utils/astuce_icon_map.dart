import 'package:flutter/material.dart';

/// Mapping noms d'icônes Material (API) → IconData Flutter.
class AstuceIconMap {
  static const _map = <String, IconData>{
    'outlet_rounded': Icons.outlet_rounded,
    'lightbulb_rounded': Icons.lightbulb_rounded,
    'kitchen_rounded': Icons.kitchen_rounded,
    'shower_rounded': Icons.shower_rounded,
    'tv_rounded': Icons.tv_rounded,
    'electrical_services_rounded': Icons.electrical_services_rounded,
    'water_drop_rounded': Icons.water_drop_rounded,
    'ac_unit_rounded': Icons.ac_unit_rounded,
    'power_rounded': Icons.power_rounded,
    'shield_rounded': Icons.shield_rounded,
    'bed_rounded': Icons.bed_rounded,
    'lan_rounded': Icons.lan_rounded,
    'build_rounded': Icons.build_rounded,
    'home_rounded': Icons.home_rounded,
    'tips_and_updates_rounded': Icons.tips_and_updates_rounded,
    'eco_rounded': Icons.eco_rounded,
    'handyman_rounded': Icons.handyman_rounded,
  };

  static IconData resolve(String? name) {
    if (name == null || name.isEmpty) return Icons.lightbulb_rounded;
    return _map[name] ?? Icons.lightbulb_rounded;
  }

  static List<MapEntry<String, IconData>> get choices => _map.entries.toList();

  static Color parseColor(String? hex, {Color fallback = const Color(0xFFF57F17)}) {
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v != null ? Color(v) : fallback;
  }
}
