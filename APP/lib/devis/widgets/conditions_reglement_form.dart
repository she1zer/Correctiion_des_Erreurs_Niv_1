import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/devis_provider.dart';
import '../utils/app_theme.dart';

/// Conditions commerciales et remise exceptionnelle du devis proforma.
class ConditionsReglementForm extends StatefulWidget {
  const ConditionsReglementForm({super.key});

  @override
  State<ConditionsReglementForm> createState() =>
      _ConditionsReglementFormState();
}

class _ConditionsReglementFormState extends State<ConditionsReglementForm> {
  late TextEditingController _validiteCtrl;
  late TextEditingController _delaiCtrl;
  late TextEditingController _moyenCtrl;
  late TextEditingController _libelleCtrl;

  @override
  void initState() {
    super.initState();
    final devis = context.read<DevisProvider>().devis;
    _validiteCtrl = TextEditingController(text: devis.validiteOffre);
    _delaiCtrl = TextEditingController(text: devis.delaiLivraison);
    _moyenCtrl = TextEditingController(text: devis.moyenReglement);
    _libelleCtrl = TextEditingController(text: devis.libelleCheque);
  }

  @override
  void dispose() {
    _validiteCtrl.dispose();
    _delaiCtrl.dispose();
    _moyenCtrl.dispose();
    _libelleCtrl.dispose();
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
          'Service commercial',
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
                const Divider(height: 28),
                Row(
                  children: [
                    const Text(
                      'Condition de règlement:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: devis.conditionReglement,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'habituelles',
                            child: Text('Conditions habituelles'),
                          ),
                          DropdownMenuItem(
                            value: 'acompte',
                            child: Text('Acompte'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            provider.updateConditionReglement(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (devis.conditionReglement == 'acompte') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Pourcentage acompte:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: devis.acomptePourcentage.toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(suffixText: '%'),
                          onChanged: (v) => provider
                              .updateAcomptePourcentage(double.tryParse(v) ?? 40),
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 28),
                SwitchListTile(
                  title: const Text(
                    'Remise exceptionnelle',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Ajoute une ligne « REMISE EXCEPTIONNELLE » dans le devis',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: devis.remiseExceptionnelleActive,
                  activeColor: AppColors.isitekGreen,
                  onChanged: provider.updateRemiseExceptionnelleActive,
                ),
                if (devis.remiseExceptionnelleActive) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Pourcentage :',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: devis.remiseExceptionnellePct.round().toString(),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(suffixText: '%'),
                          onChanged: (v) => provider
                              .updateRemiseExceptionnellePct(double.tryParse(v) ?? 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
