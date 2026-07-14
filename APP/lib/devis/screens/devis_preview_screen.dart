import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/devis_model.dart';
import '../providers/devis_provider.dart';
import '../services/devis_api_service.dart';
import '../services/pdf_service.dart';
import '../../screens/admin/affaire_detail_screen.dart';
import '../../services/api_service.dart';
import '../utils/app_theme.dart';

/// Aperçu PDF natif (ProformaPdfGenerator) — identique au modèle HTML / az.jpeg.
class DevisPreviewScreen extends StatefulWidget {
  const DevisPreviewScreen({super.key});

  @override
  State<DevisPreviewScreen> createState() => _DevisPreviewScreenState();
}

class _DevisPreviewScreenState extends State<DevisPreviewScreen> {
  String? _error;

  Future<Uint8List> _buildPdf(DevisProvider provider) async {
    return PdfService.genererPdf(provider.devis);
  }

  @override
  Widget build(BuildContext context) {
    final devis = context.watch<DevisProvider>().devis;
    final provider = context.read<DevisProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Text(
          devis.numeroDevis.isEmpty
              ? 'Aperçu proforma'
              : 'PROFORMA ${devis.numeroDevis}',
        ),
      ),
      body: Column(
        children: [
          if (_error != null)
            Material(
              color: Colors.orange.shade100,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(_error!, style: const TextStyle(fontSize: 12)),
              ),
            ),
          Expanded(
            child: PdfPreview(
              build: (_) async {
                try {
                  final bytes = await _buildPdf(provider);
                  if (mounted) setState(() => _error = null);
                  return bytes;
                } catch (e) {
                  if (mounted) {
                    setState(() => _error = 'Génération PDF : $e');
                  }
                  rethrow;
                }
              },
              allowPrinting: false,
              allowSharing: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              maxPageWidth: 700,
              pdfFileName:
                  'ISITEK_Proforma_${devis.numeroDevis.isEmpty ? "draft" : devis.numeroDevis}.pdf',
              loadingWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.isitekNavy),
                    SizedBox(height: 16),
                    Text('Génération du PDF...',
                        style: TextStyle(
                            color: AppColors.isitekNavy, fontWeight: FontWeight.bold)),
                  ],
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
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _enregistrerServeur(context),
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Enregistrer sur ISITEK Connect'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.isitekNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (ApiService.instance.currentUser?.canCreateAffaireEffective == true) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _createAffaire(context),
                  icon: const Icon(Icons.folder_copy_outlined),
                  label: const Text('Créer dossier d\'affaire'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.isitekGreen,
                    side: const BorderSide(color: AppColors.isitekGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _actionBtn(
                    icon: Icons.table_chart_outlined,
                    label: 'Excel',
                    onPressed: () => _exporterExcel(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionBtn(
                    icon: Icons.print_outlined,
                    label: 'Imprimer',
                    onPressed: () => _imprimer(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => _exporterPdf(context),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                    label: const Text('Exporter PDF'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.isitekGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.isitekGreen,
        side: const BorderSide(color: AppColors.isitekGreen),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _createAffaire(BuildContext context) async {
    final provider = context.read<DevisProvider>();
    _showLoading(context);
    try {
      int? devisId = provider.savedDevisId;
      if (devisId == null) {
        final saved = await DevisApiService.instance.saveDevis(provider.toApiPayload());
        devisId = saved['id'] as int;
        provider.setSavedDevisId(devisId);
      } else {
        await DevisApiService.instance.updateDevis(devisId, provider.toApiPayload());
      }
      final affaire = await DevisApiService.instance.createAffaireFromDevis(devisId);
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Affaire ${affaire['numero_affaire']} créée'),
            backgroundColor: AppColors.isitekGreen,
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AffaireDetailScreen(affaireId: affaire['id'])),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      _showError(context, e);
    }
  }

  Future<void> _enregistrerServeur(BuildContext context) async {
    final provider = context.read<DevisProvider>();
    if (provider.devis.numeroDevis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un numéro de devis.')),
      );
      return;
    }
    _showLoading(context);
    try {
      Map<String, dynamic> saved;
      if (provider.savedDevisId != null) {
        saved = await DevisApiService.instance.updateDevis(
          provider.savedDevisId!,
          provider.toApiPayload(),
        );
      } else {
        saved = await DevisApiService.instance.saveDevis(provider.toApiPayload());
        provider.setSavedDevisId(saved['id'] as int);
      }
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Devis ${saved['numero_devis']} enregistré (${saved['total_ht_net']} F CFA HT)'),
            backgroundColor: AppColors.isitekGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      _showError(context, e);
    }
  }

  Future<void> _exporterExcel(BuildContext context) async {
    final provider = context.read<DevisProvider>();
    _showLoading(context);
    try {
      final bytes = await DevisApiService.instance.renderExcel(provider.toRenderPayload());
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        final dir = await getTemporaryDirectory();
        final name =
            'ISITEK_Proforma_${provider.devis.numeroDevis.isEmpty ? "draft" : provider.devis.numeroDevis}.xlsx';
        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([XFile(file.path)], subject: name);
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      _showError(context, e);
    }
  }

  Future<void> _exporterPdf(BuildContext context) async {
    final provider = context.read<DevisProvider>();
    _showLoading(context);
    try {
      final bytes = await _buildPdf(provider);
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        await Printing.sharePdf(
          bytes: bytes,
          filename:
              'devis_${provider.devis.numeroDevis.isEmpty ? "ISITEK" : provider.devis.numeroDevis}.pdf',
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      _showError(context, e);
    }
  }

  Future<void> _imprimer(BuildContext context) async {
    final provider = context.read<DevisProvider>();
    _showLoading(context);
    try {
      final bytes = await _buildPdf(provider);
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        await Printing.layoutPdf(onLayout: (format) async => bytes);
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
        content: Text('Erreur : $e'),
        backgroundColor: AppColors.danger,
      ),
    );
  }
}
