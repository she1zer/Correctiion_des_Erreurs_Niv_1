import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/devis_model.dart';
import '../providers/devis_provider.dart';
import '../services/pdf_service.dart';
import '../utils/app_theme.dart';
import '../widgets/devis_preview.dart';

/// Écran d'aperçu en temps réel du devis avant export.
///
/// Affiche une reproduction fidèle du document final et propose les
/// actions d'export PDF, d'impression et de partage. Utilise le
/// package `printing` qui gère nativement l'aperçu d'impression, le
/// partage et l'enregistrement du PDF généré par [PdfService].
class DevisPreviewScreen extends StatelessWidget {
  const DevisPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final devis = context.watch<DevisProvider>().devis;

    return Scaffold(
      backgroundColor: const Color(0xFFE7EAE8),
      appBar: AppBar(
        title: const Text('Aperçu du devis'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final previewWidth = maxWidth < 780 ? maxWidth : 760.0;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DevisPreview(width: previewWidth),
                    );
                  },
                ),
              ),
            ),
          ),
          _buildActionBar(context, devis),
        ],
      ),
    );
  }

  Widget _buildActionBar(BuildContext context, DevisModel devis) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _imprimer(context),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Imprimer'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _partager(context),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Partager'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => _exporterPdf(context),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Exporter PDF'),
                style: FilledButton.styleFrom(backgroundColor: AppColors.isitekGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exporterPdf(BuildContext context) async {
    final provider = context.read<DevisProvider>();
    _showLoading(context);
    try {
      final bytes = await PdfService.genererPdf(provider.devis);
      if (context.mounted) Navigator.of(context).pop(); // ferme le loader
      if (context.mounted) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'devis_${provider.devis.numeroDevis.isEmpty ? "ISITEK" : provider.devis.numeroDevis}.pdf',
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      _showError(context, e);
    }
  }

  Future<void> _imprimer(BuildContext context) async {
    final provider = context.read<DevisProvider>();
    try {
      final bytes = await PdfService.genererPdf(provider.devis);
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      if (context.mounted) _showError(context, e);
    }
  }

  Future<void> _partager(BuildContext context) async {
    final provider = context.read<DevisProvider>();
    _showLoading(context);
    try {
      final bytes = await PdfService.genererPdf(provider.devis);
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'devis_${provider.devis.numeroDevis.isEmpty ? "ISITEK" : provider.devis.numeroDevis}.pdf',
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      _showError(context, e);
    }
  }

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur lors de la génération du PDF : $e'),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}
