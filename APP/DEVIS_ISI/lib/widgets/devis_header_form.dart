import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/devis_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Formulaire de saisie des informations d'en-tête du devis :
/// numéro de devis, date, contact client, ainsi que les références
/// client (nom, N°CC, DA).
class DevisHeaderForm extends StatefulWidget {
  const DevisHeaderForm({super.key});

  @override
  State<DevisHeaderForm> createState() => _DevisHeaderFormState();
}

class _DevisHeaderFormState extends State<DevisHeaderForm> {
  late TextEditingController _numeroCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _clientNomCtrl;
  late TextEditingController _clientCCCtrl;
  late TextEditingController _clientDACtrl;

  @override
  void initState() {
    super.initState();
    final devis = context.read<DevisProvider>().devis;
    _numeroCtrl = TextEditingController(text: devis.numeroDevis);
    _contactCtrl = TextEditingController(text: devis.contact);
    _clientNomCtrl = TextEditingController(text: devis.clientNom);
    _clientCCCtrl = TextEditingController(text: devis.clientNumeroCC);
    _clientDACtrl = TextEditingController(text: devis.clientDA);
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _contactCtrl.dispose();
    _clientNomCtrl.dispose();
    _clientCCCtrl.dispose();
    _clientDACtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DevisProvider>();
    final devis = context.watch<DevisProvider>().devis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Informations sur le devis'),
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
                          labelText: 'N° du devis',
                          hintText: '26FP1073',
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
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(Formatters.dateCourte(devis.date)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _contactCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact client',
                    hintText: 'Ex: OUATTARA',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  onChanged: provider.updateContact,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _SectionTitle(title: 'Vos références (client)'),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                TextFormField(
                  controller: _clientNomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom du client',
                    hintText: 'COTE D\'IVOIRE TERMINAL',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                  onChanged: provider.updateClientNom,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _clientCCCtrl,
                        decoration: const InputDecoration(
                          labelText: 'N° CC',
                        ),
                        onChanged: provider.updateClientNumeroCC,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _clientDACtrl,
                        decoration: const InputDecoration(
                          labelText: 'DA',
                          hintText: '12062026',
                        ),
                        onChanged: provider.updateClientDA,
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

  Future<void> _choisirDate(
      BuildContext context, DevisProvider provider, DateTime initial) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      provider.updateDate(picked);
    }
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
