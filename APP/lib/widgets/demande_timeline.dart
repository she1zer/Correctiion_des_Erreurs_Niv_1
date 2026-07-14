import 'package:flutter/material.dart';
import '../models/demande_steps.dart';
import '../main.dart' show IsitekColors;

class DemandeTimeline extends StatelessWidget {
  final String statut;
  final Set<int> skippedSteps;
  final int? devisMontant;
  final int? accomptePourcentage;
  final int? garantieMois;
  final DateTime? garantieDebut;
  final DateTime? garantieFin;

  const DemandeTimeline({
    super.key,
    required this.statut,
    this.skippedSteps = const {},
    this.devisMontant,
    this.accomptePourcentage,
    this.garantieMois,
    this.garantieDebut,
    this.garantieFin,
  });

  int get _currentStep => DemandeSteps.stepIndexForStatus(statut);

  String _stepLabel(DemandeStepDef step) {
    var label = step.displayLabel;
    if (step.number == 3 && devisMontant != null) {
      label += ' ($devisMontant FCFA)';
    }
    if (step.number == 5 && accomptePourcentage != null) {
      label += ' — $accomptePourcentage%';
    }
    if (step.number == 11 && garantieDebut != null && garantieFin != null) {
      final fmt = '${garantieDebut!.day}/${garantieDebut!.month}/${garantieDebut!.year}'
          ' → ${garantieFin!.day}/${garantieFin!.month}/${garantieFin!.year}';
      label += garantieMois != null ? ' ($garantieMois mois — $fmt)' : ' ($fmt)';
    }
    return label;
  }

  @override
  Widget build(BuildContext context) {
    final steps = DemandeSteps.visibleSteps(skippedSteps);
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(
            label: _stepLabel(steps[i]),
            actor: steps[i].actor,
            isActive: steps[i].number <= _currentStep,
            isCompleted: steps[i].number < _currentStep || statut == 'termine',
            isHighlight: steps[i].number == _currentStep,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final String actor;
  final bool isActive;
  final bool isCompleted;
  final bool isHighlight;
  final bool isLast;

  const _TimelineStep({
    required this.label,
    required this.actor,
    required this.isActive,
    required this.isCompleted,
    required this.isHighlight,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    // Couleur basée sur l'acteur : vert pour Isitek, bleu-vert pour client/vous
    final isIsitek = actor == 'Isitek';
    final actorColor = isIsitek ? IsitekColors.green : const Color(0xFF14B8A6); // Teal harmonieux avec le vert
    
    final stepColor = isCompleted
        ? actorColor
        : (isActive ? actorColor : Colors.grey.shade300);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isCompleted ? actorColor : (isHighlight ? actorColor.withOpacity(0.1) : Colors.white),
                  border: Border.all(color: stepColor, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : (isHighlight
                          ? Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: actorColor, shape: BoxShape.circle),
                            )
                          : null),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? actorColor : Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: (isHighlight || isCompleted) ? FontWeight.bold : FontWeight.w500,
                  color: isCompleted
                      ? IsitekColors.textSoft
                      : (isActive ? IsitekColors.textDark : Colors.grey.shade400),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
