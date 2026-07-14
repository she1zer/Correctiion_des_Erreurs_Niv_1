import 'dart:io';
import 'package:flutter/material.dart';
import '../models/rapport_photo.dart';
import '../theme/app_theme.dart';

/// Carte d'une photo dans la grille : aperçu, champ légende, bouton suppression.
class PhotoGridCard extends StatefulWidget {
  final RapportPhoto photo;
  final VoidCallback onDelete;
  final ValueChanged<String> onLegendeChanged;

  const PhotoGridCard({
    super.key,
    required this.photo,
    required this.onDelete,
    required this.onLegendeChanged,
  });

  @override
  State<PhotoGridCard> createState() => _PhotoGridCardState();
}

class _PhotoGridCardState extends State<PhotoGridCard> {
  late TextEditingController _legendeCtrl;

  @override
  void initState() {
    super.initState();
    _legendeCtrl = TextEditingController(text: widget.photo.legende);
  }

  @override
  void dispose() {
    _legendeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: Image.file(
                    widget.photo.file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: InkWell(
                  onTap: widget.onDelete,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _legendeCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              hintText: 'Légende (optionnel)',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            onChanged: widget.onLegendeChanged,
          ),
        ],
      ),
    );
  }
}
