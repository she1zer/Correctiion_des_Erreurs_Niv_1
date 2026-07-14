import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../main.dart' show IsitekColors;
import '../../services/api_service.dart';
import '../services/caisse_api_service.dart';
import '../utils/caisse_formatters.dart';
import '../services/caisse_pdf_service.dart';
import '../services/excel_service.dart';
import '../services/file_service.dart';
import 'fiche_controle_form_screen.dart';
import 'livre_caisse_detail_screen.dart';

/// Hub module Caisse — fiche contrôle, livre hebdo, recherche.
class CaisseHubScreen extends StatefulWidget {
  const CaisseHubScreen({super.key});

  @override
  State<CaisseHubScreen> createState() => _CaisseHubScreenState();
}

class _CaisseHubScreenState extends State<CaisseHubScreen> with SingleTickerProviderStateMixin {
  TabController? _tabs;
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  Map<String, dynamic>? _searchResult;

  bool get _canControle =>
      ApiService.instance.currentUser?.canCaisseControleEffective ?? false;
  bool get _canLivre =>
      ApiService.instance.currentUser?.canCaisseLivreEffective ?? false;
  bool get _canAny =>
      ApiService.instance.currentUser?.canAccessCaisseEffective ?? false;

  @override
  void initState() {
    super.initState();
    _initTabs();
  }

  void _initTabs() {
    final tabCount = 1 + (_canControle ? 1 : 0) + (_canLivre ? 1 : 0);
    _tabs?.dispose();
    _tabs = TabController(length: tabCount, vsync: this);
    _tabs!.addListener(() => setState(() {}));
  }

  int get _controleTabIndex => _canControle ? 1 : -1;
  int get _livreTabIndex {
    if (!_canLivre) return -1;
    return 1 + (_canControle ? 1 : 0);
  }

  @override
  void dispose() {
    _tabs?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.length < 1) return;
    setState(() => _searching = true);
    try {
      final res = await CaisseApiService.instance.search(q);
      if (mounted) setState(() { _searchResult = res; _searching = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _searching = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Recherche : $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canAny) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Caisse ISITEK'),
          backgroundColor: IsitekColors.green,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Accès Caisse non autorisé',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Demandez à l\'administrateur d\'activer le module Caisse '
                  '(complet, fiche contrôle ou livre hebdomadaire).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tabs = <Widget>[const Tab(text: 'Accueil')];
    final views = <Widget>[_buildAccueil()];
    if (_canControle) {
      tabs.add(const Tab(text: 'Fiche contrôle'));
      views.add(const _FicheControleListTab());
    }
    if (_canLivre) {
      tabs.add(const Tab(text: 'Livre caisse'));
      views.add(const _LivreCaisseListTab());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Caisse ISITEK'),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: views,
      ),
      floatingActionButton: _tabs!.index == _controleTabIndex
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const FicheControleFormScreen(),
                ));
                setState(() {});
              },
              backgroundColor: IsitekColors.green,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle fiche'),
            )
          : _tabs!.index == _livreTabIndex
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (_) => const NouvelleSemaineLivreDialog(),
                    );
                    if (result == null || !mounted) return;
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => LivreCaisseDetailScreen(
                        annee: result['annee'] as String,
                        mois: result['mois'] as String,
                        semaine: result['semaine'] as String,
                        periodeDu: result['periodeDu'] as DateTime,
                        periodeAu: result['periodeAu'] as DateTime,
                        isNouvelle: true,
                      ),
                    ));
                    setState(() {});
                  },
                  backgroundColor: IsitekColors.green,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle semaine'),
                )
              : null,
    );
  }

  Widget _buildAccueil() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Rechercher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Année (2026), solde, nom & prénoms…',
                    isDense: true,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _searching ? null : _search,
                  style: FilledButton.styleFrom(backgroundColor: IsitekColors.green),
                  child: _searching
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Chercher'),
                ),
              ],
            ),
          ),
        ),
        if (_searchResult != null) ...[
          const SizedBox(height: 12),
          _buildSearchResults(_searchResult!),
        ],
        const SizedBox(height: 16),
        _homeCard(
          icon: Icons.fact_check_outlined,
          title: 'Fiche de contrôle caisse',
          subtitle: 'Solde théorique / réel, écarts, signatures',
          onTap: () { if (_controleTabIndex >= 0) _tabs!.animateTo(_controleTabIndex); },
          visible: _canControle,
        ),
        if (_canControle) const SizedBox(height: 12),
        _homeCard(
          icon: Icons.menu_book_outlined,
          title: 'Livre de caisse hebdomadaire',
          subtitle: 'Entrées, sorties, soldes, bénéficiaires',
          onTap: () { if (_livreTabIndex >= 0) _tabs!.animateTo(_livreTabIndex); },
          visible: _canLivre,
        ),
      ],
    );
  }

  Widget _buildSearchResults(Map<String, dynamic> res) {
    final fiches = (res['fiches_controle'] as List?) ?? [];
    final lignes = (res['livre_lignes'] as List?) ?? [];
    if (fiches.isEmpty && lignes.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun résultat')));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fiches.isNotEmpty) ...[
          Text('Fiches contrôle (${fiches.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          ...fiches.map((f) {
            final m = Map<String, dynamic>.from(f as Map);
            return ListTile(
              dense: true,
              title: Text('Semaine ${m['semaine']} — ${m['annee']}'),
              subtitle: Text('Solde réel: ${m['solde_reel'] ?? '—'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => FicheControleFormScreen(ficheId: m['id'] as int),
              )),
            );
          }),
        ],
        if (lignes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Lignes livre caisse (${lignes.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
          ...lignes.map((l) {
            final m = Map<String, dynamic>.from(l as Map);
            return ListTile(
              dense: true,
              title: Text(m['nom_prenoms']?.toString().isNotEmpty == true ? m['nom_prenoms'] : 'Sans nom'),
              subtitle: Text(
                '${m['detail_operation'] ?? ''}\nSolde: ${m['solde'] ?? '—'} · Année ${m['annee'] ?? ''}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => LivreCaisseDetailScreen(livreId: m['livre_id'] as int),
              )),
            );
          }),
        ],
      ],
    );
  }

  Widget _homeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool visible = true,
  }) {
    if (!visible) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: IsitekColors.greenSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: IsitekColors.greenDark),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _FicheControleListTab extends StatefulWidget {
  const _FicheControleListTab();
  @override
  State<_FicheControleListTab> createState() => _FicheControleListTabState();
}

class _FicheControleListTabState extends State<_FicheControleListTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  final _qCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _qCtrl.dispose(); super.dispose(); }

  Future<void> _load({String? q}) async {
    setState(() => _loading = true);
    try {
      final list = await CaisseApiService.instance.listControle(q: q);
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _previewPdf(Map<String, dynamic> item) async {
    try {
      final pageId = item['page_id'] as int?;
      Map<String, dynamic>? ficheHaut;
      Map<String, dynamic>? ficheBas;
      int sections = item['sections_par_page'] as int? ?? 2;
      if (pageId != null) {
        final page = await CaisseApiService.instance.getControlePage(pageId);
        sections = page['sections_par_page'] as int? ?? 2;
        ficheHaut = page['fiche_slot_1'] as Map<String, dynamic>?;
        ficheBas = page['fiche_slot_2'] as Map<String, dynamic>?;
      } else {
        ficheHaut = await CaisseApiService.instance.getControle(item['id'] as int);
      }
      final bytes = await CaissePdfService.genererFicheControle(
        ficheHaut: ficheHaut,
        ficheBas: sections >= 2 ? ficheBas : null,
        sectionsParPage: sections,
      );
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => _PdfPreviewPage(title: 'Fiche contrôle S${ficheHaut?['semaine'] ?? item['semaine']}', bytes: bytes),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _qCtrl,
              decoration: InputDecoration(
                hintText: 'Année, solde…',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (v) => _load(q: v),
            )),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => _load(q: _qCtrl.text), child: const Text('Chercher')),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
              : _items.isEmpty
                  ? const Center(child: Text('Aucune fiche'))
                  : RefreshIndicator(
                      onRefresh: () => _load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final it = Map<String, dynamic>.from(_items[i] as Map);
                          return Card(
                            child: ListTile(
                              title: Text('Semaine ${it['semaine'] ?? '—'} · ${it['annee'] ?? ''} (§${it['slot'] ?? 1})'),
                              subtitle: Text('Solde réel: ${it['solde_reel'] ?? '—'}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (a) async {
                                  if (a == 'edit') {
                                    await Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => FicheControleFormScreen(ficheId: it['id'] as int),
                                    ));
                                    _load();
                                  } else if (a == 'pdf') {
                                    _previewPdf(it);
                                  } else if (a == 'del') {
                                    await CaisseApiService.instance.deleteControle(it['id'] as int);
                                    _load();
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Modifier')),
                                  PopupMenuItem(value: 'pdf', child: Text('Générer PDF')),
                                  PopupMenuItem(value: 'del', child: Text('Supprimer')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _LivreCaisseListTab extends StatefulWidget {
  const _LivreCaisseListTab();
  @override
  State<_LivreCaisseListTab> createState() => _LivreCaisseListTabState();
}

class _LivreCaisseListTabState extends State<_LivreCaisseListTab> {
  List<dynamic> _items = [];
  bool _loading = true;
  final _qCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _qCtrl.dispose(); super.dispose(); }

  Future<void> _load({String? q}) async {
    setState(() => _loading = true);
    try {
      final list = await CaisseApiService.instance.listLivre(q: q);
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _previewPdf(Map<String, dynamic> item) async {
    try {
      final full = await CaisseApiService.instance.getLivre(item['id'] as int);
      final bytes = await CaissePdfService.genererLivreCaisseFromApi(full);
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => _PdfPreviewPage(title: 'Livre caisse S${full['semaine']}', bytes: bytes),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _exportExcel(Map<String, dynamic> item) async {
    try {
      final full = await CaisseApiService.instance.getLivre(item['id'] as int);
      final bytes = CaisseExcelService.genererLivreCaisseFromApi(full);
      final mois = CaisseFormatters.moisLabel(full['mois']);
      final nomFichier = 'Livre_Caisse_S${full['semaine']}_${mois}_${full['annee']}.xlsx';
      final file = await CaisseFileService.sauvegarderFichier(bytes, nomFichier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel généré'),
          action: SnackBarAction(
            label: 'PARTAGER',
            onPressed: () => CaisseFileService.partagerFichier(file),
          ),
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _qCtrl,
              decoration: InputDecoration(
                hintText: 'Année, nom, solde…',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onSubmitted: (v) => _load(q: v),
            )),
            const SizedBox(width: 8),
            FilledButton(onPressed: () => _load(q: _qCtrl.text), child: const Text('Chercher')),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
              : _items.isEmpty
                  ? const Center(child: Text('Aucun livre'))
                  : RefreshIndicator(
                      onRefresh: () => _load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final it = Map<String, dynamic>.from(_items[i] as Map);
                          return Card(
                            child: ListTile(
                              title: Text('Semaine ${it['semaine'] ?? '—'} · ${it['annee'] ?? ''} / ${it['mois'] ?? ''}'),
                              subtitle: Text('Période: ${it['periode_debut'] ?? ''} → ${it['periode_fin'] ?? ''}'),
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => LivreCaisseDetailScreen(livreId: it['id'] as int),
                              )).then((_) => _load()),
                              trailing: PopupMenuButton<String>(
                                onSelected: (a) async {
                                  if (a == 'edit') {
                                    await Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => LivreCaisseDetailScreen(livreId: it['id'] as int),
                                    ));
                                    _load();
                                  } else if (a == 'pdf') {
                                    _previewPdf(it);
                                  } else if (a == 'excel') {
                                    _exportExcel(it);
                                  } else if (a == 'del') {
                                    await CaisseApiService.instance.deleteLivre(it['id'] as int);
                                    _load();
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Ouvrir')),
                                  PopupMenuItem(value: 'pdf', child: Text('Générer PDF')),
                                  PopupMenuItem(value: 'excel', child: Text('Générer Excel')),
                                  PopupMenuItem(value: 'del', child: Text('Supprimer')),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _PdfPreviewPage extends StatelessWidget {
  final String title;
  final Uint8List bytes;
  const _PdfPreviewPage({required this.title, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Printing.sharePdf(bytes: bytes, filename: '$title.pdf'),
          ),
        ],
      ),
      body: PdfPreview(build: (_) => bytes, canChangePageFormat: false, canChangeOrientation: false),
    );
  }
}
