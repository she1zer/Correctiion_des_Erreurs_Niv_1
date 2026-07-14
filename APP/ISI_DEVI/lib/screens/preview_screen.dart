// lib/screens/preview_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models.dart';
import '../pdf_generator.dart';

class PreviewScreen extends StatefulWidget {
  final DevisData devis;
  const PreviewScreen({super.key, required this.devis});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  bool _loading = false;

  Future<void> _sharePDF() async {
    setState(() => _loading = true);
    try {
      final bytes = await generateDevisPDF(widget.devis);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ISITEK_Proforma_${widget.devis.num}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'ISITEK Proforma ${widget.devis.num}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _printPDF() async {
    setState(() => _loading = true);
    try {
      final bytes = await generateDevisPDF(widget.devis);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'ISITEK Proforma ${widget.devis.num}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur impression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 30),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'PROFORMA ${widget.devis.num}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else ...[
            IconButton(
              onPressed: _printPDF,
              icon: const Icon(Icons.print),
              tooltip: 'Imprimer / PDF',
            ),
            IconButton(
              onPressed: _sharePDF,
              icon: const Icon(Icons.share),
              tooltip: 'Partager le PDF',
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Action bar
          Container(
            color: const Color(0xFF1E3A8A).withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _printPDF,
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('Imprimer / PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _sharePDF,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Partager PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // PDF Preview
          Expanded(
            child: PdfPreview(
              build: (_) => generateDevisPDF(widget.devis),
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
              pdfFileName: 'ISITEK_Proforma_${widget.devis.num}.pdf',
              loadingWidget: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                        color: Color(0xFF1E3A8A)),
                    SizedBox(height: 16),
                    Text('Génération du devis...',
                        style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
