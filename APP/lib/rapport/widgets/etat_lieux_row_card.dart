import 'package:flutter/material.dart';
import '../models/etat_lieux_row.dart';
import '../theme/app_theme.dart';

/// Carte représentant une ligne éditable du tableau "État des lieux" :
/// Secteur/Zone, État des lieux, Actions correctives + bouton suppression.
class EtatLieuxRowCard extends StatefulWidget {
  final EtatLieuxRow row;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onChanged;
  final bool canDelete;

  const EtatLieuxRowCard({
    super.key,
    required this.row,
    required this.index,
    required this.onDelete,
    required this.onChanged,
    required this.canDelete,
  });

  @override
  State<EtatLieuxRowCard> createState() => _EtatLieuxRowCardState();
}

class _EtatLieuxRowCardState extends State<EtatLieuxRowCard> {
  late TextEditingController _secteurCtrl;
  late TextEditingController _etatCtrl;
  late TextEditingController _actionsCtrl;

  @override
  void initState() {
    super.initState();
    _secteurCtrl = TextEditingController(text: widget.row.secteurZone);
    _etatCtrl = TextEditingController(text: widget.row.etatDesLieux);
    _actionsCtrl = TextEditingController(text: widget.row.actionsCorrectives);
  }

  @override
  void dispose() {
    _secteurCtrl.dispose();
    _etatCtrl.dispose();
    _actionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${widget.index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ligne',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
              ),
              if (widget.canDelete)
                InkWell(
                  onTap: widget.onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 19, color: AppColors.danger),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _secteurCtrl,
            decoration: const InputDecoration(
              labelText: 'Secteur / Zone',
              hintText: 'Ex: TGBT, Local technique...',
              isDense: true,
            ),
            onChanged: (v) {
              widget.row.secteurZone = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _etatCtrl,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              labelText: 'État des lieux',
              hintText: 'Observations, constatations, anomalies relevées...',
              isDense: true,
            ),
            onChanged: (v) {
              widget.row.etatDesLieux = v;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _actionsCtrl,
            maxLines: 3,
            minLines: 2,
            decoration: const InputDecoration(
              labelText: 'Actions correctives',
              hintText: 'Solutions techniques recommandées...',
              isDense: true,
            ),
            onChanged: (v) {
              widget.row.actionsCorrectives = v;
              widget.onChanged();
            },
          ),
        ],
      ),
    );
  }
}
