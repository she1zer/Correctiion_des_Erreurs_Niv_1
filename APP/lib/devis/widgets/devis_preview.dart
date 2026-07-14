import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/devis_model.dart';
import '../models/produit_model.dart';
import '../providers/devis_provider.dart';
import '../utils/formatters.dart';

/// Aperçu en temps réel du devis proforma ISITEK (format images 5/6/7).
class DevisPreview extends StatelessWidget {
  final double width;

  const DevisPreview({super.key, this.width = 760});

  static const _grey = Color(0xFFD8D8D8);
  static const _red = Color(0xFFCC0000);
  static const _darkGrey = Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Consumer<DevisProvider>(
      builder: (context, provider, _) {
        final d = provider.devis;
        return Container(
          width: width,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                'assets/images/logo_isitek.png',
                height: 65,
                errorBuilder: (_, __, ___) => const Text('ISITEK',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E7D32))),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                color: _grey,
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('PROFORMA   ',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text(
                      d.numeroDevis.isEmpty ? '—' : d.numeroDevis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold, color: _red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: SizedBox()),
                  SizedBox(
                    width: 270,
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
                                  style: TextStyle(fontSize: 9),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  d.clientNom,
                                  style: const TextStyle(
                                      fontSize: 9, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        _clientTable(d),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _metaLine('DATE EMISSION: ', Formatters.dateProforma(d.date), red: true),
              _metaLine('AFFAIRE SUIVIE PAR: ', d.affaireSuiviePar),
              _metaLine('REF DEMANDE: ', d.refDemande, red: true),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                color: _grey,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 9, color: Colors.black),
                    children: [
                      const TextSpan(
                          text: 'OBJET DEMANDE: ',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: _red)),
                      TextSpan(
                          text: d.objetDemande,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _articlesTable(d),
              const SizedBox(height: 5),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('SERVICE COMMERCIAL',
                    style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 170,
                    child: Image.asset(
                      'assets/images/stamp_isitek.png',
                      errorBuilder: (_, __, ___) => const Text('ISITEK',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _darkGrey)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _termRow('Validité offre', d.validiteOffre),
                          _termRow('Delai de livraison', d.delaiLivraison),
                          _termRow('Condition de règlement', d.conditionReglementLabel),
                          _termRow('Moyen de règlement', d.moyenReglement),
                          _termRow('Libellé du chèque', d.libelleCheque),
                          _termRow('Devise', 'Franc CFA (XOF)'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Image.asset(
                'assets/images/marques_partenaires.png',
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 8),
              const Divider(color: _darkGrey, height: 1),
              const SizedBox(height: 4),
              const Text(
                'ISITEK S.A.R.L au capital de 10.000.000 F CFA - Siège social : Abidjan Cocody Angré - RCCM : CI-ABJ-2017-B-20181',
                style: TextStyle(fontSize: 7, color: _darkGrey),
                textAlign: TextAlign.center,
              ),
              const Text(
                'BICICI : CI006-01693-010577100067-64 contact@isitek.ci/ TEL: (+225) 25 20 01 19 82 / (+225) 07 59 48 21 84',
                style: TextStyle(fontSize: 7, color: _darkGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metaLine(String label, String value, {bool red = false}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 9, color: Colors.black),
        children: [
          TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
              text: value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: red ? _red : Colors.black)),
        ],
      ),
    );
  }

  Widget _clientTable(DevisModel d) {
    Widget cell(String text, {bool bold = false}) => Padding(
          padding: const EdgeInsets.all(3),
          child: Text(text,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        );

    return Table(
      border: TableBorder.all(color: _darkGrey, width: 0.5),
      columnWidths: const {
        0: FixedColumnWidth(70),
        1: FlexColumnWidth(),
      },
      children: [
        TableRow(children: [cell('Contact', bold: true), cell(d.contact, bold: true)]),
        TableRow(children: [cell('Phone', bold: true), cell(d.telephone, bold: true)]),
      ],
    );
  }

  Widget _articlesTable(DevisModel d) {
    const headers = [
      'Ref',
      'DESIGNATION',
      'Unit',
      'Qté',
      'Prix Unit\n(F CFA)',
      'REMISE',
      'Prix Tot. HT\n(F CFA)',
    ];
    const flexes = [1, 4, 1, 1, 2, 1, 2];

    return Table(
      border: TableBorder.all(color: _darkGrey, width: 0.5),
      columnWidths: {
        for (var i = 0; i < flexes.length; i++) i: FlexColumnWidth(flexes[i].toDouble()),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: const BoxDecoration(color: _grey),
          children: headers
              .map((h) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(h,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic)),
                  ))
              .toList(),
        ),
        if (d.listeProduits.isEmpty)
          TableRow(
            children: List.generate(
                7,
                (_) => const Padding(
                      padding: EdgeInsets.all(4),
                      child: Text(''),
                    )),
          )
        else
          ...d.listeProduits.map((p) => _productRow(p)),
        _finRow('TOTAL HT BRUT', Formatters.montant(d.totalHTBrut)),
        _finRow('TOTAL REMISE COMMERCIALE', Formatters.montant(d.totalRemise)),
        _finRow('S/TOTAL HT', Formatters.montant(d.sousTotal)),
        if (d.remiseExceptionnelleActive)
          _finRow(
            'REMISE EXCEPTIONNELLE (${d.remiseExceptionnellePct.round()}%)',
            Formatters.montant(d.remiseExceptionnelleMontant),
            grey: true,
          ),
        _finRow('TOTAL HT NET', Formatters.montant(d.totalHTNet)),
      ],
    );
  }

  TableRow _productRow(ProduitModel p) {
    Widget cell(String text, {TextAlign align = TextAlign.left}) => Padding(
          padding: const EdgeInsets.all(4),
          child: Text(text, textAlign: align, style: const TextStyle(fontSize: 8.5)),
        );

    String qte;
    if (p.quantite <= 0) {
      qte = '';
    } else if (p.quantite == p.quantite.roundToDouble()) {
      qte = p.quantite.round().toString();
    } else {
      qte = p.quantite.toString();
    }

    return TableRow(
      children: [
        cell(p.reference, align: TextAlign.center),
        cell(p.designation),
        cell(p.unite, align: TextAlign.center),
        cell(qte, align: TextAlign.center),
        cell(p.prixUnitaireHT > 0 ? Formatters.montant(p.prixUnitaireHT) : '',
            align: TextAlign.right),
        cell(p.remisePourcentage > 0 ? '${p.remisePourcentage.round()}%' : '',
            align: TextAlign.center),
        cell(p.montantHTNet > 0 ? Formatters.montant(p.montantHTNet) : '',
            align: TextAlign.right),
      ],
    );
  }

  TableRow _finRow(String label, String value, {bool grey = false}) {
    Widget empty = const Padding(padding: EdgeInsets.all(4), child: SizedBox());
    return TableRow(
      decoration: grey ? const BoxDecoration(color: _grey) : null,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        ),
        empty,
        empty,
        empty,
        empty,
        empty,
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _termRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
          ),
          Text(value,
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
