import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart' show IsitekColors;
import '../providers/devis_provider.dart';
import '../services/devis_api_service.dart';
import '../../services/gmail_service.dart';
import '../../services/easy_ai_service.dart';
import '../widgets/product_search_sheet.dart';
import 'devis_email_detail_screen.dart';
import 'devis_form_screen.dart';

class DevisEmailInboxScreen extends StatefulWidget {
  const DevisEmailInboxScreen({super.key});

  @override
  State<DevisEmailInboxScreen> createState() => _DevisEmailInboxScreenState();
}

class _DevisEmailInboxScreenState extends State<DevisEmailInboxScreen> {
  List<dynamic> _emails = [];
  bool _loading = false;
  String? _gmailError;
  String? _imapError;
  bool _gmailMode = false;
  bool _gmailConnected = false;
  String? _gmailAccount;
  final _manualController = TextEditingController();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _gmailConnected = GmailService.instance.isSignedIn;
    _gmailAccount = GmailService.instance.account?.email;
    if (_gmailConnected) {
      _gmailMode = true;
      _loadEmails();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  Future<void> _connectGmail() async {
    setState(() { _loading = true; _gmailError = null; });
    try {
      final ok = await GmailService.instance.signIn();
      if (!mounted) return;
      if (ok) {
        setState(() {
          _gmailMode = true;
          _gmailConnected = true;
          _gmailAccount = GmailService.instance.account?.email;
          _gmailError = null;
        });
        await _loadEmails();
      } else {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connexion Gmail annulée')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _gmailError = e.toString();
          _gmailConnected = false;
          _gmailMode = false;
        });
      }
    }
  }

  Future<void> _disconnectGmail() async {
    await GmailService.instance.signOut();
    setState(() {
      _gmailMode = false;
      _gmailConnected = false;
      _gmailAccount = null;
      _emails = [];
      _gmailError = null;
      _imapError = null;
      _loading = false;
    });
  }

  Future<void> _loadEmails() async {
    setState(() { _loading = true; });
    try {
      if (_gmailMode && _gmailConnected) {
        setState(() => _gmailError = null);
        final gmailEmails = await GmailService.instance.fetchInbox(maxResults: 20);
        if (mounted) {
          setState(() {
            _emails = gmailEmails.map((e) => e.toMap()).toList();
            _loading = false;
          });
        }
      } else {
        setState(() => _imapError = null);
        final data = await DevisApiService.instance.fetchEmails();
        if (mounted) {
          setState(() {
            _emails = data;
            _loading = false;
            if (data.isEmpty) _imapError = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_gmailMode && _gmailConnected) {
            _gmailError = GmailService.friendlyApiError(e);
          } else {
            _imapError = e.toString();
          }
          _loading = false;
          _emails = [];
        });
      }
    }
  }

  Future<Map<String, dynamic>> _analyzeContent({
    String? messageId,
    required String rawText,
    String? subject,
    String? fromAddress,
  }) async {
    try {
      final easyResult = await EasyAiService.instance.analyzeEmail(
        body: rawText,
        subject: subject ?? '',
        fromAddress: fromAddress ?? '',
      );
      if ((easyResult['references'] as List?)?.isNotEmpty == true) {
        final refs = (easyResult['references'] as List).cast<String>();
        final suggested = <String, String>{};
        for (final ref in refs.take(5)) {
          try {
            final search = await DevisApiService.instance.searchReference(ref);
            final results = search['results'] as List? ?? [];
            if (results.isNotEmpty) {
              suggested[ref] = (results.first['title'] ?? results.first['snippet'] ?? '').toString();
            }
          } catch (_) {}
        }
        return {
          'references': refs,
          'client_nom': easyResult['client_nom'],
          'contact': easyResult['contact'],
          'client_da': easyResult['client_da'],
          'suggested_designations': suggested,
          'used_easy': easyResult['used_isi'] == true,
        };
      }
    } catch (_) {}

    return DevisApiService.instance.analyzeEmail(
      messageId: _gmailMode ? null : messageId,
      rawText: rawText,
      subject: subject,
      fromAddress: fromAddress,
    );
  }

  void _showLoader() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator(color: IsitekColors.green)),
      ),
    );
  }

  Future<void> _hideLoader() async {
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> _analyzeAndCreate({
    String? messageId,
    String? rawText,
    String? subject,
    String? fromAddress,
    String? fullBody,
    bool popDetailScreen = false,
  }) async {
    if (_processing) return;
    _processing = true;
    _showLoader();
    try {
      final text = fullBody ?? rawText ?? '';
      final analysis = await _analyzeContent(
        messageId: messageId,
        rawText: text,
        subject: subject,
        fromAddress: fromAddress,
      );
      final numero = await DevisApiService.instance.nextDevisNumber();
      await _hideLoader();
      if (!mounted) return;

      final refs = (analysis['references'] as List<dynamic>? ?? []).cast<String>();
      if (refs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune référence produit détectée dans ce message.')),
        );
        return;
      }

      final suggestions = (analysis['suggested_designations'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString()));

      final provider = context.read<DevisProvider>();
      provider.loadFromAnalysis(
        references: refs,
        clientNom: analysis['client_nom'] as String?,
        contact: analysis['contact'] as String?,
        refDemande: analysis['client_da'] as String?,
        suggestedDesignations: suggestions,
        numeroDevis: numero,
      );

      final usedEasy = analysis['used_easy'] == true || analysis['used_isi'] == true;
      if (popDetailScreen && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        await Future<void>.delayed(Duration.zero);
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(usedEasy
              ? 'Devis préparé par Easy (${refs.length} référence(s))'
              : 'Devis préparé (${refs.length} référence(s))'),
          backgroundColor: IsitekColors.green,
        ),
      );

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: provider,
            child: const DevisFormScreen(),
          ),
        ),
      );
    } catch (e) {
      await _hideLoader();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      _processing = false;
    }
  }

  void _openEmailDetail(Map<String, dynamic> email) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => DevisEmailDetailScreen(
          email: email,
          onAnalyze: () => _analyzeAndCreate(
            messageId: email['message_id'] as String?,
            subject: email['subject'] as String?,
            fromAddress: email['from_address'] as String?,
            fullBody: email['body'] as String?,
            rawText: email['preview'] as String?,
            popDetailScreen: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadEmails,
      color: IsitekColors.green,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildGmailCard()),
          SliverToBoxAdapter(child: _buildManualSection()),
          SliverToBoxAdapter(child: _buildInboxHeader()),
          if (_imapError != null && !_gmailConnected)
            SliverToBoxAdapter(child: _buildImapError()),
          if (_loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator(color: IsitekColors.green)),
            )
          else if (_emails.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyInbox(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildEmailTile(_emails[index]),
                  childCount: _emails.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGmailCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _gmailConnected ? IsitekColors.greenSoft : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _gmailConnected ? IsitekColors.green.withOpacity(0.3) : Colors.blue.shade100,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _gmailConnected ? Icons.mark_email_read : Icons.mail_lock_outlined,
                  color: _gmailConnected ? IsitekColors.green : Colors.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _gmailConnected
                        ? 'Gmail connecté : $_gmailAccount'
                        : 'Connecter Gmail (isitek.sarl@gmail.com)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _gmailConnected
                  ? 'Les emails sont lus directement depuis votre boîte Gmail.'
                  : 'OAuth Google (projet appisitek) — ajoutez isitek.sarl@gmail.com comme utilisateur test.',
              style: const TextStyle(fontSize: 11, color: IsitekColors.textSoft),
            ),
            if (_gmailError != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  _gmailError!,
                  style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!_gmailConnected)
                  FilledButton.icon(
                    onPressed: _loading ? null : _connectGmail,
                    icon: const Icon(Icons.login, size: 18),
                    label: const Text('Connexion Google'),
                    style: FilledButton.styleFrom(
                      backgroundColor: IsitekColors.green,
                      foregroundColor: Colors.white,
                    ),
                  )
                else ...[
                  OutlinedButton.icon(
                    onPressed: _loadEmails,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Actualiser'),
                  ),
                  TextButton(
                    onPressed: _disconnectGmail,
                    child: const Text('Déconnexion'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coller un email ou une demande client',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Collez ici le texte du mail avec les références produits...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _analyzeAndCreate(rawText: _manualController.text),
              icon: const Icon(Icons.search),
              label: const Text('Analyser et créer le devis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: IsitekColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.mail_outline, color: IsitekColors.green, size: 20),
          const SizedBox(width: 8),
          const Text('Boîte mail ISITEK', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            tooltip: 'Charger emails IMAP (serveur)',
            onPressed: _gmailConnected
                ? _loadEmails
                : () async {
                    setState(() => _gmailMode = false);
                    await _loadEmails();
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  Widget _buildImapError() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Boîte IMAP non configurée', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_imapError!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            const Text(
              'Connectez Gmail ci-dessus, ou configurez IMAP dans le .env de l\'API, '
              'ou utilisez le collage manuel.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyInbox() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            _gmailConnected ? 'Boîte Gmail vide ou en attente' : 'Connectez Gmail pour lire vos emails',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _gmailConnected && _gmailError != null
                ? 'Appuyez sur Actualiser après activation de l\'API Gmail.'
                : 'Ou collez un email manuellement en haut de l\'écran.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTile(Map<String, dynamic> email) {
    final refs = (email['references'] as List<dynamic>? ?? []);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        title: Text(
          email['subject'] ?? '(Sans objet)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('De : ${email['from_address']}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              email['preview'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            if (refs.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: refs.take(5).map((r) => Chip(
                  label: Text(r.toString(), style: const TextStyle(fontSize: 10)),
                  backgroundColor: IsitekColors.greenSoft,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: IsitekColors.green),
        onTap: () => _openEmailDetail(email),
      ),
    );
  }
}

class DevisReferenceSearchScreen extends StatefulWidget {
  const DevisReferenceSearchScreen({super.key});

  @override
  State<DevisReferenceSearchScreen> createState() => _DevisReferenceSearchScreenState();
}

class _DevisReferenceSearchScreenState extends State<DevisReferenceSearchScreen> {
  final _controller = TextEditingController();
  Map<String, dynamic>? _result;
  bool _loading = false;

  Future<void> _search() async {
    final ref = _controller.text.trim();
    if (ref.isEmpty) return;
    setState(() { _loading = true; _result = null; });
    try {
      final data = await DevisApiService.instance.searchReference(ref);
      if (mounted) setState(() { _result = data; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recherche impossible : $e'),
            duration: const Duration(seconds: 5),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final ok = await openExternalUrl(url);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir le navigateur')),
      );
    }
  }

  void _applyResult(Map<String, dynamic> r) {
    if (_result == null) return;
    final ref = _result!['reference'] as String;
    final provider = context.read<DevisProvider>();
    provider.ajouterProduit();
    final last = provider.produits.last;
    provider.applySearchResult(last.id, r, fallbackReference: ref);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Référence $ref ajoutée au devis')),
    );
  }

  Future<void> _addToDevis() async {
    if (_result == null) return;
    final results = _result!['results'] as List<dynamic>? ?? [];
    if (results.isNotEmpty) {
      _applyResult(results.first as Map<String, dynamic>);
      return;
    }
    final ref = _result!['reference'] as String;
    final provider = context.read<DevisProvider>();
    provider.ajouterProduit();
    final last = provider.produits.last;
    provider.updateReference(last.id, ref);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Référence $ref ajoutée — complétez le prix manuellement')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _result?['results'] as List<dynamic>? ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rechercher une référence produit sur le web',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Ex: SEC0010, LC1D09, 6ES7...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: IsitekColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Chercher'),
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Résultats pour ${_result!['reference']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openUrl(_result!['search_url']),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Google'),
                ),
                TextButton.icon(
                  onPressed: () => _openUrl(_result!['shopping_url'] ?? _result!['search_url']),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                  label: const Text('Shopping'),
                ),
                TextButton.icon(
                  onPressed: _addToDevis,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Ajouter au devis'),
                ),
              ],
            ),
            ...results.map((r) {
              final item = r as Map<String, dynamic>;
              final price = (item['price'] as num?)?.toDouble();
              final priceLabel = item['price_label'] as String? ?? '';
              final merchant = item['merchant'] as String? ?? '';
              return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(item['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((item['snippet'] as String?)?.isNotEmpty == true)
                      Text(item['snippet'], style: const TextStyle(fontSize: 11)),
                    if (price != null && price > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          priceLabel.isNotEmpty ? priceLabel : '${price.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: IsitekColors.greenDark, fontSize: 12),
                        ),
                      ),
                    if (merchant.isNotEmpty)
                      Text(merchant, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.link, color: IsitekColors.green),
                      onPressed: () => _openUrl(item['url']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: IsitekColors.green),
                      onPressed: () => _applyResult(item),
                    ),
                  ],
                ),
                onTap: () => _applyResult(item),
              ),
            );
            }),
            if (results.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 40, color: Colors.grey),
                    const SizedBox(height: 10),
                    const Text(
                      'Aucun résultat automatique pour cette référence.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Appuyez sur Google Shopping pour comparer les prix dans votre navigateur, '
                      'ou ajoutez SERP_API_KEY dans le .env de l\'API pour la recherche avec prix.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _openUrl(_result!['shopping_url'] ?? _result!['search_url']),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Ouvrir Google Shopping'),
                      style: FilledButton.styleFrom(backgroundColor: IsitekColors.green),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
