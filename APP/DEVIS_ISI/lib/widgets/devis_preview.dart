import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/devis_model.dart';
import '../models/produit_model.dart';
import '../providers/devis_provider.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

/// Aperçu en temps réel du devis, reproduisant fidèlement la mise en
/// page du modèle papier ISITEK : logo, "Notre Proforma N°", blocs
/// "Nos références" / "Vos références", informations du devis,
/// tableau détaillé, totaux et conditions de règlement.
///
/// Ce widget est purement visuel (lecture seule) ; toute modification
/// se fait via les formulaires dédiés et se reflète ici instantanément
/// grâce au [DevisProvider].
class DevisPreview extends StatelessWidget {
  /// Largeur fixe simulant une feuille A4, utilisée notamment pour le
  /// rendu dans un conteneur scrollable horizontalement sur mobile.
  final double width;

  const DevisPreview({super.key, this.width = 760});

  @override
  Widget build(BuildContext context) {
    return Consumer<DevisProvider>(
      builder: (context, provider, _) {
        final devis = provider.devis;
        return Container(
          width: width,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(devis),
              const SizedBox(height: 22),
              _buildReferences(devis),
              const SizedBox(height: 18),
              _buildInfosDevis(devis),
              const SizedBox(height: 20),
              const Text(
                'Détail de votre devis',
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 10),
              _buildTable(devis.listeProduits),
              const SizedBox(height: 22),
              _buildTotalsAndConditions(devis),
              const SizedBox(height: 36),
              _buildSignature(),
              const SizedBox(height: 30),
              const Divider(color: Color(0xFFBFC8C5)),
              const SizedBox(height: 8),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(DevisModel devis) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/logo_isitek.png',
          height: 70,
          errorBuilder: (_, __, ___) => Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.isitekGreen),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text('ISITEK',
                style: TextStyle(color: AppColors.isitekGreen, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 20),
        const Expanded(
          child: Text(
            'NOTRE PROFORMA N°',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.isitekGreen),
          ),
        ),
        Text(
          devis.numeroDevis.isEmpty ? '—' : devis.numeroDevis,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.isitekRed),
        ),
      ],
    );
  }

  Widget _buildReferences(DevisModel devis) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _RefBlock(
            title: 'Nos références',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ISITEK SARL', style: TextStyle(fontSize: 12.5)),
                Text('ETUDE.ING.REALISAT.FORMAT.EXPERTISE', style: TextStyle(fontSize: 12.5)),
                Text('2520011982', style: TextStyle(fontSize: 12.5)),
                Text('contact@isitek.ci', style: TextStyle(fontSize: 12.5)),
                Text('1736067S', style: TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: _RefBlock(
            title: 'Vos références',
            minHeight: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(devis.clientNom,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('N°CC : ${devis.clientNumeroCC}', style: const TextStyle(fontSize: 12.5)),
                const SizedBox(height: 6),
                Text('DA : ${devis.clientDA}', style: const TextStyle(fontSize: 12.5)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfosDevis(DevisModel devis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Informations sur le devis',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.9)),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text('N° du devis : ${devis.numeroDevis}',
                    style: const TextStyle(fontSize: 12.5)),
              ),
              Expanded(
                flex: 3,
                child: Text('Date : ${Formatters.dateCourte(devis.date)}',
                    style: const TextStyle(fontSize: 12.5)),
              ),
              Expanded(
                flex: 3,
                child: Text('Contact : ${devis.contact}',
                    style: const TextStyle(fontSize: 12.5)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<ProduitModel> produits) {
    const headers = ['Référence', 'Désignation', 'QTE', 'P.U.H.T.', 'Remise', 'Mont HT NET'];
    const flexes = [2, 4, 1, 2, 1, 2];

    Widget cell(String text, int flex,
        {bool bold = false, TextAlign align = TextAlign.left}) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Text(
            text,
            textAlign: align,
            style: TextStyle(
              fontSize: 12,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.9)),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFEFF3F1),
            child: Row(
              children: List.generate(headers.length, (i) => cell(headers[i], flexes[i], bold: true)),
            ),
          ),
          if (produits.isEmpty)
            Container(
              decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFD9DEDC)))),
              child: Row(
                children: List.generate(headers.length, (i) => cell('', flexes[i])),
              ),
            )
          else
            ...produits.map((p) {
              return Container(
                decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFD9DEDC)))),
                child: Row(
                  children: [
                    cell(p.reference, flexes[0]),
                    cell(p.designation, flexes[1]),
                    cell(_fmtQte(p.quantite), flexes[2], align: TextAlign.center),
                    cell(Formatters.montant(p.prixUnitaireHT), flexes[3], align: TextAlign.right),
                    cell(Formatters.pourcentage(p.remisePourcentage), flexes[4], align: TextAlign.center),
                    cell(Formatters.montant(p.montantHTNet), flexes[5], align: TextAlign.right, bold: true),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _fmtQte(double q) {
    if (q == q.roundToDouble()) return q.round().toString();
    return q.toString();
  }

  Widget _buildTotalsAndConditions(DevisModel devis) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(flex: 5, child: SizedBox()),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTotalsBlock(devis),
              const SizedBox(height: 14),
              _buildConditionsBlock(devis),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsBlock(DevisModel devis) {
    Widget ligne(String label, String valeur, {bool isLast = false}) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: isLast
                ? BorderSide.none
                : const BorderSide(color: Color(0xFFD9DEDC)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            Text(valeur, style: const TextStyle(fontSize: 12.5)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.9)),
      child: Column(
        children: [
          ligne('Total HT Brut:', Formatters.montant(devis.totalHTBrut)),
          ligne('Total Remise:', Formatters.montant(devis.totalRemise)),
          ligne('Total HT NET:', Formatters.montant(devis.totalHTNet), isLast: true),
        ],
      ),
    );
  }

  Widget _buildConditionsBlock(DevisModel devis) {
    Widget ligne(String label, String valeur, {Color? color}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.isitekNavy)),
            ),
            Expanded(
              child: Text(valeur,
                  style: TextStyle(fontSize: 12.5, color: color ?? Colors.black)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ligne('Validité offre :', devis.validiteOffre),
        ligne('Delai de livraison :', devis.delaiLivraison),
        ligne(
          'Condition de règlement :',
          '${Formatters.pourcentage(devis.acomptePourcentage)} CMDE',
          color: AppColors.isitekRed,
        ),
        ligne('Moyen de règlement :', devis.moyenReglement),
        ligne('Libellé du chèque :', devis.libelleCheque),
      ],
    );
  }

  Widget _buildSignature() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SERVICE COMMERCIAL',
          style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
        ),
        const SizedBox(height: 30),
        const Text('ISITEK SARL',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const Text('COTE D\'IVOIRE / ABIDJAN',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const Text('CI-ABJ-2017-B-21181 / 1736067S / RSI',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const Text('BICICI 010S77100067-64',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const Text('(+225) 20 01 19 82 / (+225) 09 48 21 84',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildFooter() {
    return const Column(
      children: [
        Text(
          'ISITEK SARL au capital de 10 000 000 F CFA - RCCM: CI-ABJ-2017-B-21181 N° CC: 1736067S',
          style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        Text(
          'Compte Bancaire: BICICI 010577100067 - Siège: Cocody Angré Chateau - '
          'TEL: +225 25 20 01 19 82/+225 07 97 38 50 35/+225 05 66 66 01 98',
          style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        Text(
          'Email: contact@isitek.ci/ isitek.sarl@gmail.com',
          style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RefBlock extends StatelessWidget {
  final String title;
  final Widget child;
  final double? minHeight;

  const _RefBlock({required this.title, required this.child, this.minHeight});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minHeight ?? 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 0.9)),
          child: child,
        ),
      ],
    );
  }
}
