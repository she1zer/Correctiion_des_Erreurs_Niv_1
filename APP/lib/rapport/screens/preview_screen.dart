import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/rapport_data.dart';
import '../services/file_service.dart';
import '../services/pdf_report_service.dart';
import '../theme/app_theme.dart';

class PreviewScreen extends StatefulWidget {
  final RapportData data;
  final String? numeroRapport;

  const PreviewScreen({super.key, required this.data, this.numeroRapport});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  Uint8List? _pdfBytes;
  bool _generating = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final bytes = await PdfReportService.generate(widget.data);
      setState(() {
        _pdfBytes = bytes;
        _generating = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erreur lors de la génération du PDF : $e";
        _generating = false;
      });
    }
  }

  Future<void> _saveAndShare() async {
    if (_pdfBytes == null) return;
    setState(() => _saving = true);
    try {
      final file = await FileService.savePdf(_pdfBytes!, clientName: widget.data.client);
      if (!mounted) return;
      await FileService.sharePdf(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapport enregistré : ${file.path.split('/').last}'),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'enregistrement : $e"),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveOnly() async {
    if (_pdfBytes == null) return;
    setState(() => _saving = true);
    try {
      final file = await FileService.savePdf(_pdfBytes!, clientName: widget.data.client);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapport enregistré sur le téléphone'),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'enregistrement : $e"),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.numeroRapport != null
            ? 'Aperçu · ${widget.numeroRapport}'
            : 'Aperçu du rapport'),
        actions: [
          if (_pdfBytes != null)
            IconButton(
              tooltip: 'Régénérer',
              onPressed: _generate,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: _generating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primaryGreen),
                  SizedBox(height: 16),
                  Text(
                    'Génération du rapport en cours...',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13.5),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.danger, fontSize: 13.5),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _generate,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : PdfPreview(
                  build: (format) => _pdfBytes!,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  allowPrinting: true,
                  allowSharing: false,
                  scrollViewDecoration: const BoxDecoration(color: AppColors.background),
                ),
      bottomNavigationBar: _pdfBytes == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _saveOnly,
                        icon: const Icon(Icons.save_alt_outlined, size: 18),
                        label: const Text('Enregistrer'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveAndShare,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.share_outlined, size: 18),
                        label: const Text('Partager'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
