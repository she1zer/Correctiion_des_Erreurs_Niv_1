// lib/screens/form_screen.dart
import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/section_card.dart';
import '../widgets/article_card.dart';
import '../widgets/style_panel.dart';
import 'preview_screen.dart';

class FormScreen extends StatefulWidget {
  final DevisData devis;
  const FormScreen({super.key, required this.devis});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  late DevisData _d;

  // Controllers document
  late TextEditingController _numCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _suiviCtrl;
  late TextEditingController _refCtrl;
  late TextEditingController _vldCtrl;
  late TextEditingController _dlvCtrl;

  // Controllers client
  late TextEditingController _attCtrl;
  late TextEditingController _contCtrl;
  late TextEditingController _telCtrl;
  late TextEditingController _objCtrl;

  // Article controllers map
  final Map<String, Map<String, TextEditingController>> _artCtrl = {};

  @override
  void initState() {
    super.initState();
    _d = widget.devis;
    _numCtrl   = TextEditingController(text: _d.num);
    _dateCtrl  = TextEditingController(text: _d.date);
    _suiviCtrl = TextEditingController(text: _d.suivi);
    _refCtrl   = TextEditingController(text: _d.ref);
    _vldCtrl   = TextEditingController(text: _d.vld);
    _dlvCtrl   = TextEditingController(text: _d.dlv);
    _attCtrl   = TextEditingController(text: _d.att);
    _contCtrl  = TextEditingController(text: _d.cont);
    _telCtrl   = TextEditingController(text: _d.tel);
    _objCtrl   = TextEditingController(text: _d.obj);
    _initArticleControllers();
  }

  void _initArticleControllers() {
    for (final l in _d.lignes) {
      _artCtrl[l.id] = {
        'item':        TextEditingController(text: l.item),
        'description': TextEditingController(text: l.description),
        'unite':       TextEditingController(text: l.unite),
        'qte':         TextEditingController(text: l.qte > 0 ? l.qte.toString() : ''),
        'prixUnit':    TextEditingController(text: l.prixUnit > 0 ? l.prixUnit.toString() : ''),
        'remise':      TextEditingController(text: l.remise > 0 ? l.remise.toString() : ''),
      };
    }
  }

  void _syncFromControllers() {
    _d = DevisData(
      num:    _numCtrl.text,
      date:   _dateCtrl.text,
      suivi:  _suiviCtrl.text,
      ref:    _refCtrl.text,
      att:    _attCtrl.text,
      cont:   _contCtrl.text,
      tel:    _telCtrl.text,
      obj:    _objCtrl.text,
      vld:    _vldCtrl.text,
      dlv:    _dlvCtrl.text,
      rxOn:   _d.rxOn,
      rxPct:  _d.rxPct,
      lignes: _d.lignes.map((l) {
        final c = _artCtrl[l.id]!;
        return LigneArticle(
          id:          l.id,
          item:        c['item']!.text,
          description: c['description']!.text,
          unite:       c['unite']!.text,
          qte:         double.tryParse(c['qte']!.text) ?? 0,
          prixUnit:    double.tryParse(c['prixUnit']!.text) ?? 0,
          remise:      double.tryParse(c['remise']!.text) ?? 0,
        );
      }).toList(),
      style:  _d.style,
    );
  }

  void _addLigne() {
    setState(() {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      _d.lignes.add(LigneArticle(id: id, unite: 'U'));
      _artCtrl[id] = {
        'item':        TextEditingController(),
        'description': TextEditingController(),
        'unite':       TextEditingController(text: 'U'),
        'qte':         TextEditingController(),
        'prixUnit':    TextEditingController(),
        'remise':      TextEditingController(),
      };
    });
  }

  void _removeLigne(String id) {
    setState(() {
      _d.lignes.removeWhere((l) => l.id == id);
      _artCtrl[id]?.forEach((_, c) => c.dispose());
      _artCtrl.remove(id);
    });
  }

  @override
  void dispose() {
    _numCtrl.dispose(); _dateCtrl.dispose(); _suiviCtrl.dispose();
    _refCtrl.dispose(); _vldCtrl.dispose(); _dlvCtrl.dispose();
    _attCtrl.dispose(); _contCtrl.dispose(); _telCtrl.dispose();
    _objCtrl.dispose();
    _artCtrl.forEach((_, m) => m.forEach((_, c) => c.dispose()));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(
                'ISITEK — Devis Proforma',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _goPreview,
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('Voir Devis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── DOCUMENT ──
          SectionCard(
            icon: Icons.description,
            title: 'Document',
            child: Column(
              children: [
                _row2(
                  _field('N° Proforma', _numCtrl),
                  _field('Date d\'émission', _dateCtrl, hint: 'jj/mm/aaaa'),
                ),
                const SizedBox(height: 10),
                _row2(
                  _field('Affaire suivie par', _suiviCtrl),
                  _field('Réf demande', _refCtrl),
                ),
                const SizedBox(height: 10),
                _row2(
                  _field('Validité offre', _vldCtrl, hint: '1 mois'),
                  _field('Délai de livraison', _dlvCtrl, hint: '1 semaine'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── CLIENT ──
          SectionCard(
            icon: Icons.person,
            title: 'Client',
            child: Column(
              children: [
                _field('À l\'attention de (Société)', _attCtrl),
                const SizedBox(height: 10),
                _row2(
                  _field('Contact', _contCtrl),
                  _field('Téléphone', _telCtrl),
                ),
                const SizedBox(height: 10),
                _field('Objet de la demande', _objCtrl),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── ARTICLES ──
          SectionCard(
            icon: Icons.inventory_2,
            title: 'Articles',
            child: Column(
              children: [
                ..._d.lignes.asMap().entries.map((e) => ArticleCard(
                      index: e.key + 1,
                      ligne: e.value,
                      controllers: _artCtrl[e.value.id]!,
                      canRemove: _d.lignes.length > 1,
                      onRemove: () => _removeLigne(e.value.id),
                      onChanged: () => setState(() {}),
                    )),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addLigne,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un article'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E40AF),
                    side: const BorderSide(
                        color: Color(0xFF3B82F6), style: BorderStyle.solid),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── REMISE EXCEPTIONNELLE ──
          SectionCard(
            icon: Icons.percent,
            title: 'Remise Exceptionnelle',
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Activer la remise exceptionnelle',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Ajoute une ligne dans le devis',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: _d.rxOn,
                  activeColor: const Color(0xFF1E3A8A),
                  onChanged: (v) => setState(() => _d.rxOn = v),
                ),
                if (_d.rxOn) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Pourcentage :',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: _d.rxPct.toStringAsFixed(0),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            suffixText: '%',
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          onChanged: (v) =>
                              setState(() => _d.rxPct = double.tryParse(v) ?? 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── STYLE ──
          SectionCard(
            icon: Icons.format_paint,
            title: 'Style du Devis — Gras & Majuscules',
            child: StylePanel(
              style: _d.style,
              onChanged: (s) => setState(() => _d.style = s),
            ),
          ),
          const SizedBox(height: 24),

          // ── CTA ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _goPreview,
              icon: const Icon(Icons.picture_as_pdf, size: 22),
              label: const Text(
                'Générer le Devis',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _goPreview() {
    _syncFromControllers();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(devis: _d),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }

  Widget _row2(Widget a, Widget b) {
    return Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ],
    );
  }
}
