import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../main.dart' show IsitekColors;
import '../widgets/product_search_sheet.dart';

/// Affichage complet d'un email (HTML, images) avant analyse devis.
class DevisEmailDetailScreen extends StatelessWidget {
  final Map<String, dynamic> email;
  final Future<void> Function() onAnalyze;

  const DevisEmailDetailScreen({
    super.key,
    required this.email,
    required this.onAnalyze,
  });

  String get _subject => email['subject'] as String? ?? '(Sans objet)';
  String get _from => email['from_address'] as String? ?? '';
  String get _fromName => email['from_name'] as String? ?? '';
  String get _date => email['date'] as String? ?? '';
  String get _plainBody => email['body'] as String? ?? email['preview'] as String? ?? '';
  String? get _htmlBody {
    final html = email['html_body'] as String?;
    if (html != null && html.trim().isNotEmpty) return html;
    return null;
  }

  List<String> get _refs =>
      (email['references'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

  @override
  Widget build(BuildContext context) {
    final html = _htmlBody;
    return Scaffold(
      backgroundColor: IsitekColors.bg,
      appBar: AppBar(
        title: Text(
          _subject,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(),
                  const SizedBox(height: 16),
                  if (_refs.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _refs
                          .take(12)
                          .map((r) => Chip(
                                label: Text(r, style: const TextStyle(fontSize: 11)),
                                backgroundColor: IsitekColors.greenSoft,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: html != null
                          ? Html(
                              data: html,
                              shrinkWrap: true,
                              style: {
                                'body': Style(
                                  margin: Margins.zero,
                                  fontSize: FontSize(14),
                                  lineHeight: LineHeight(1.45),
                                ),
                                'img': Style(
                                  width: Width.auto(),
                                ),
                              },
                              onLinkTap: (url, _, __) {
                                if (url != null) openExternalUrl(url);
                              },
                            )
                          : SelectableText(
                              _plainBody.isEmpty ? 'Contenu vide' : _plainBody,
                              style: const TextStyle(fontSize: 14, height: 1.45),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => onAnalyze(),
                  icon: const Icon(Icons.request_quote_outlined),
                  label: const Text('Analyser et créer le devis'),
                  style: FilledButton.styleFrom(
                    backgroundColor: IsitekColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IsitekColors.greenSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_fromName.isNotEmpty)
            Text(_fromName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(_from, style: const TextStyle(fontSize: 13, color: IsitekColors.textSoft)),
          if (_date.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(_date, style: const TextStyle(fontSize: 12, color: IsitekColors.textSoft)),
          ],
        ],
      ),
    );
  }
}
