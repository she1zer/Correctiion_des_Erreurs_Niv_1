import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/devis_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Formulaire d'en-tête du devis proforma ISITEK.
class DevisHeaderForm extends StatefulWidget {
  const DevisHeaderForm({super.key});

  @override
  State<DevisHeaderForm> createState() => _DevisHeaderFormState();
}

class _DevisHeaderFormState extends State<DevisHeaderForm> {
  late TextEditingController _numeroCtrl;
  late TextEditingController _suiviCtrl;
  late TextEditingController _refCtrl;
  late TextEditingController _attCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _objCtrl;

  @override
  void initState() {
    super.initState();
    final devis = context.read<DevisProvider>().devis;
    _numeroCtrl = TextEditingController(text: devis.numeroDevis);
    _suiviCtrl = TextEditingController(text: devis.affaireSuiviePar);
    _refCtrl = TextEditingController(text: devis.refDemande);
    _attCtrl = TextEditingController(text: devis.clientNom);
    _contactCtrl = TextEditingController(text: devis.contact);
    _telCtrl = TextEditingController(text: devis.telephone);
    _objCtrl = TextEditingController(text: devis.objetDemande);
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _suiviCtrl.dispose();
    _refCtrl.dispose();
    _attCtrl.dispose();
    _contactCtrl.dispose();
    _telCtrl.dispose();
    _objCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DevisProvider>();
    final devis = context.watch<DevisProvider>().devis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Document'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _numeroCtrl,
                        decoration: const InputDecoration(
                          labelText: 'N° Proforma',
                          hintText: '26FP1153',
                          prefixIcon: Icon(Icons.tag),
                        ),
                        onChanged: provider.updateNumeroDevis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _choisirDate(context, provider, devis.date),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date d\'émission',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(Formatters.dateProforma(devis.date)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _suiviCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Affaire suivie par',
                          hintText: 'Amadou OUATTARA',
                        ),
                        onChanged: provider.updateAffaireSuiviePar,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _refCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Réf. demande',
                          hintText: 'N/A',
                        ),
                        onChanged: provider.updateRefDemande,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _SectionTitle(title: 'Client'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Center(
                    child: Column(
                      children: [
                        const Text(
                          'À l\'attention de :',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _attCtrl,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'Société / Client',
                            hintText: 'ACIA',
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          onChanged: provider.updateClientNom,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 100,
                            padding: const EdgeInsets.all(12),
                            color: AppColors.background,
                            child: const Text(
                              'Contact',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextFormField(
                                controller: _contactCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Jolanta ANDRASIK',
                                  border: InputBorder.none,
                                ),
                                onChanged: provider.updateContact,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 1),
                      Row(
                        children: [
                          Container(
                            width: 100,
                            padding: const EdgeInsets.all(12),
                            color: AppColors.background,
                            child: const Text(
                              'Phone',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: TextFormField(
                                controller: _telCtrl,
                                decoration: const InputDecoration(
                                  hintText: '+33 1 55 30 54 88',
                                  border: InputBorder.none,
                                ),
                                onChanged: provider.updateTelephone,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _objCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Objet de la demande',
                    hintText: 'FOURNITURE SWITCH HDMI/USP LOT 5',
                    prefixIcon: Icon(Icons.subject_outlined),
                  ),
                  onChanged: provider.updateObjetDemande,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _choisirDate(
      BuildContext context, DevisProvider provider, DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) provider.updateDate(picked);
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}
