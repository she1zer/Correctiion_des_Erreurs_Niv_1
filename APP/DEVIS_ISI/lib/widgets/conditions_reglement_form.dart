import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/devis_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Widget permettant de définir les conditions de règlement du devis,
/// en particulier le pourcentage d'acompte à la commande (30%, 40%,
/// 50% ou valeur personnalisée), ainsi que les autres informations
/// commerciales (validité, délai, moyen de règlement, libellé chèque).
class ConditionsReglementForm extends StatefulWidget {
  const ConditionsReglementForm({super.key});

  @override
  State<ConditionsReglementForm> createState() =>
      _ConditionsReglementFormState();
}

class _ConditionsReglementFormState extends State<ConditionsReglementForm> {
  static const List<double> _presets = [30, 40, 50];
  late TextEditingController _validiteCtrl;
  late TextEditingController _delaiCtrl;
  late TextEditingController _moyenCtrl;
  late TextEditingController _libelleCtrl;
  late TextEditingController _acompteCustomCtrl;

  @override
  void initState() {
    super.initState();
    final devis = context.read<DevisProvider>().devis;
    _validiteCtrl = TextEditingController(text: devis.validiteOffre);
    _delaiCtrl = TextEditingController(text: devis.delaiLivraison);
    _moyenCtrl = TextEditingController(text: devis.moyenReglement);
    _libelleCtrl = TextEditingController(text: devis.libelleCheque);
    _acompteCustomCtrl = TextEditingController(
      text: _presets.contains(devis.acomptePourcentage)
          ? ''
          : devis.acomptePourcentage.round().toString(),
    );
  }

  @override
  void dispose() {
    _validiteCtrl.dispose();
    _delaiCtrl.dispose();
    _moyenCtrl.dispose();
    _libelleCtrl.dispose();
    _acompteCustomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DevisProvider>();
    final devis = context.watch<DevisProvider>().devis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conditions de règlement',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pourcentage d\'acompte à la commande',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ..._presets.map((p) {
                      final selected = devis.acomptePourcentage == p;
                      return ChoiceChip(
                        label: Text('${p.round()} %'),
                        selected: selected,
                        selectedColor: AppColors.isitekGreen,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          provider.updateAcomptePourcentage(p);
                          setState(() => _acompteCustomCtrl.clear());
                        },
                      );
                    }),
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _acompteCustomCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Autre %',
                          isDense: true,
                        ),
                        onChanged: (v) {
                          final value = double.tryParse(v);
                          if (value != null && value >= 0 && value <= 100) {
                            provider.updateAcomptePourcentage(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.isitekRed.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.isitekRed.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${Formatters.pourcentage(devis.acomptePourcentage)} CMDE',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: AppColors.isitekRed),
                      ),
                      Text(
                        'Acompte : ${Formatters.montantCFA(devis.montantAcompte)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.isitekRed),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _validiteCtrl,
                        decoration: const InputDecoration(labelText: 'Validité offre'),
                        onChanged: provider.updateValiditeOffre,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _delaiCtrl,
                        decoration: const InputDecoration(labelText: 'Délai de livraison'),
                        onChanged: provider.updateDelaiLivraison,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _moyenCtrl,
                        decoration: const InputDecoration(labelText: 'Moyen de règlement'),
                        onChanged: provider.updateMoyenReglement,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _libelleCtrl,
                        decoration: const InputDecoration(labelText: 'Libellé du chèque'),
                        onChanged: provider.updateLibelleCheque,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
