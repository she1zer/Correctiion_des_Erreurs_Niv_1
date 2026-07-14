import 'package:flutter/material.dart';

class ClientTip {
  final String emoji;
  final String title;
  final String summary;
  final String detail;
  final String category;
  final IconData icon;
  final List<Color> gradient;
  final Color accent;

  const ClientTip({
    required this.emoji,
    required this.title,
    required this.summary,
    required this.detail,
    required this.category,
    required this.icon,
    required this.gradient,
    required this.accent,
  });
}

const clientTips = <ClientTip>[
  ClientTip(
    emoji: '🔌',
    title: 'Où placer vos prises ?',
    summary: 'Installez-les à 30 cm du sol dans les pièces de vie, à 110 cm au-dessus du plan de travail en cuisine.',
    detail:
        'Dans un salon ou une chambre, prévoyez une prise tous les 3 à 4 mètres le long des murs, à 30 cm du sol (norme NFC 15-100). En cuisine, placez les prises à 110 cm au-dessus du plan de travail, à côté du four, du lave-vaisselle et du réfrigérateur. Évitez de les mettre directement derrière un meuble sans accès.',
    category: 'Électricité',
    icon: Icons.outlet_rounded,
    gradient: [Color(0xFFFFB300), Color(0xFFFF6F00)],
    accent: Color(0xFFE65100),
  ),
  ClientTip(
    emoji: '💡',
    title: 'Emplacement des interrupteurs',
    summary: 'Placez-les à 90 cm du sol, côté poignée de la porte, à l\'entrée de chaque pièce.',
    detail:
        'L\'interrupteur se place toujours du côté de la poignée de la porte (main droite en entrant). Hauteur standard : 90 cm du sol. Dans un couloir de plus de 4 m, prévoyez un interrupteur à chaque extrémité (va-et-vient). Ne placez jamais un interrupteur dans une salle de bain zone 0 ou 1.',
    category: 'Électricité',
    icon: Icons.lightbulb_rounded,
    gradient: [Color(0xFFFFD54F), Color(0xFFF9A825)],
    accent: Color(0xFFF57F17),
  ),
  ClientTip(
    emoji: '🍳',
    title: 'Prises en cuisine',
    summary: 'Minimum 4 prises au-dessus du plan de travail + prises dédiées pour gros appareils.',
    detail:
        'La norme impose au minimum 4 prises 16A au-dessus du plan de travail, espacées de 60 cm. Le four, le lave-vaisselle et le réfrigérateur nécessitent chacun une prise dédiée sur circuit séparé. Ne branchez jamais un micro-ondes et une bouilloire sur la même prise multiprise.',
    category: 'Électricité',
    icon: Icons.kitchen_rounded,
    gradient: [Color(0xFFFF8A65), Color(0xFFD84315)],
    accent: Color(0xFFBF360C),
  ),
  ClientTip(
    emoji: '🚿',
    title: 'Électricité en salle de bain',
    summary: 'Respectez les volumes de sécurité : aucune prise à moins de 60 cm de la baignoire ou douche.',
    detail:
        'La salle de bain est divisée en volumes (0, 1, 2). Aucune prise dans le volume 0 (intérieur baignoire/douche). Volume 1 : prises 12V ou rasoir uniquement. Volume 2 : prises avec terre et différentiel 30 mA obligatoire. Le chauffe-eau doit être sur un circuit dédié 20A ou 32A.',
    category: 'Sécurité',
    icon: Icons.shower_rounded,
    gradient: [Color(0xFF4FC3F7), Color(0xFF0277BD)],
    accent: Color(0xFF01579B),
  ),
  ClientTip(
    emoji: '📺',
    title: 'Prises TV et multimédia',
    summary: 'Prévoyez 4 à 6 prises derrière la TV et des gaines pour cacher les câbles.',
    detail:
        'Derrière votre téléviseur, installez 4 à 6 prises à 40-50 cm du sol (TV, décodeur, box internet, console). Faites passer les câbles dans une goulotte ou une gaine encastrée avant de poser le carrelage ou la peinture. Prévoyez aussi une prise RJ45 (fibre/ethernet) à côté pour une connexion stable.',
    category: 'Électricité',
    icon: Icons.tv_rounded,
    gradient: [Color(0xFF7986CB), Color(0xFF3949AB)],
    accent: Color(0xFF283593),
  ),
  ClientTip(
    emoji: '⚡',
    title: 'Tableau électrique',
    summary: 'Installez-le dans un endroit sec, accessible et à moins de 3 m de l\'entrée principale.',
    detail:
        'Le tableau doit être dans un local sec (couloir, garage, cellier), jamais dans une salle de bain. Hauteur : entre 0,90 m et 1,80 m. Laissez 1 m d\'espace libre devant pour l\'intervention. Chaque circuit doit être identifié (prises salon, éclairage chambre 1, etc.).',
    category: 'Électricité',
    icon: Icons.electrical_services_rounded,
    gradient: [Color(0xFFFF7043), Color(0xFFE64A19)],
    accent: Color(0xFFD84315),
  ),
  ClientTip(
    emoji: '🚰',
    title: 'Robinetterie et plomberie',
    summary: 'Installez toujours un robinet d\'arrêt général accessible en cas de fuite.',
    detail:
        'Chaque sanitaire (lavabo, WC, lave-linge) doit avoir son robinet d\'arrêt individuel. Le robinet général se place à l\'entrée de l\'eau, facile d\'accès (garage ou cuisine). Pour les tuyaux encastrés, laissez des trappes de visite. Évitez les coudes serrés qui réduisent la pression.',
    category: 'Plomberie',
    icon: Icons.water_drop_rounded,
    gradient: [Color(0xFF4DD0E1), Color(0xFF00838F)],
    accent: Color(0xFF006064),
  ),
  ClientTip(
    emoji: '❄️',
    title: 'Où installer la climatisation ?',
    summary: 'Unité intérieure face à la pièce, unité extérieure à l\'ombre avec 50 cm d\'espace libre.',
    detail:
        'L\'unité intérieure se place en hauteur (2,10-2,40 m), centrale dans la pièce, loin des sources de chaleur (fenêtre, TV). L\'unité extérieure : à l\'ombre si possible, sur dalle stable, avec 50 cm libre tout autour pour l\'air. Éloignez-la des chambres voisines pour limiter le bruit la nuit.',
    category: 'Climatisation',
    icon: Icons.ac_unit_rounded,
    gradient: [Color(0xFF80DEEA), Color(0xFF0097A7)],
    accent: Color(0xFF00838F),
  ),
  ClientTip(
    emoji: '🔋',
    title: 'Groupe électrogène',
    summary: 'Installez-le à l\'extérieur, loin des fenêtres, avec une arrivée de carburant sécurisée.',
    detail:
        'Le groupe doit être à l\'extérieur ou dans un local ventilé dédié. Distance minimum : 2 m des ouvertures (fenêtres, portes). Prévoyez une bâche ou un abri anti-pluie. L\'échappement doit sortir à l\'air libre. Ne le faites jamais fonctionner en intérieur (risque d\'intoxication au monoxyde de carbone).',
    category: 'Mécanique',
    icon: Icons.power_rounded,
    gradient: [Color(0xFF90A4AE), Color(0xFF455A64)],
    accent: Color(0xFF37474F),
  ),
  ClientTip(
    emoji: '🛡️',
    title: 'Disjoncteur différentiel',
    summary: 'Un différentiel 30 mA protège les personnes. Obligatoire sur toutes les prises.',
    detail:
        'Chaque circuit de prises doit être protégé par un disjoncteur différentiel 30 mA (type A ou AC selon les appareils). En cas de disjonction fréquente, ne forcez pas : c\'est un signe de défaut ou de surcharge. Faites vérifier votre installation tous les 10 ans par un professionnel.',
    category: 'Sécurité',
    icon: Icons.shield_rounded,
    gradient: [Color(0xFFEF5350), Color(0xFFC62828)],
    accent: Color(0xFFB71C1C),
  ),
  ClientTip(
    emoji: '🛏️',
    title: 'Prises en chambre',
    summary: 'De chaque côté du lit : une prise à 20 cm du chevet, idéalement avec port USB.',
    detail:
        'Placez une prise de chaque côté du lit, à environ 20 cm au-dessus du chevet (pour lampe, chargeur). Prévoyez aussi une prise près du bureau et une près de l\'armoire si vous utilisez un fer à repasser. Hauteur standard dans le reste de la chambre : 30 cm du sol.',
    category: 'Maison',
    icon: Icons.bed_rounded,
    gradient: [Color(0xFFCE93D8), Color(0xFF8E24AA)],
    accent: Color(0xFF6A1B9A),
  ),
  ClientTip(
    emoji: '🌐',
    title: 'Câblage réseau (RJ45)',
    summary: 'Passez la fibre ou l\'ethernet avant les travaux de finition, 1 prise par pièce principale.',
    detail:
        'Pour une connexion internet fiable, tirez un câble RJ45 ou fibre vers le salon, le bureau et les chambres avant de poser le placo ou le carrelage. Le boîtier de brassage se place près du tableau électrique ou de la box. Évitez de faire passer le câble à côté de l\'électricité sur plus de 20 cm sans séparation.',
    category: 'Informatique',
    icon: Icons.lan_rounded,
    gradient: [Color(0xFF64B5F6), Color(0xFF1565C0)],
    accent: Color(0xFF0D47A1),
  ),
];
