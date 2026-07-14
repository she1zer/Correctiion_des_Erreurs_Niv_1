import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/number_parser.dart';

enum CalculatorApplyTarget { quantite, prixUnitaire, remise, none }

/// Calculatrice + assistant devis (Qté × PU, remise %, total net).
class DevisCalculatorSheet extends StatefulWidget {
  final double? initialQuantite;
  final double? initialPrix;
  final double? initialRemise;
  final void Function(CalculatorApplyTarget target, double value)? onApply;

  const DevisCalculatorSheet({
    super.key,
    this.initialQuantite,
    this.initialPrix,
    this.initialRemise,
    this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    double? quantite,
    double? prix,
    double? remise,
    void Function(CalculatorApplyTarget target, double value)? onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DevisCalculatorSheet(
          initialQuantite: quantite,
          initialPrix: prix,
          initialRemise: remise,
          onApply: onApply,
        ),
      ),
    );
  }

  @override
  State<DevisCalculatorSheet> createState() => _DevisCalculatorSheetState();
}

class _DevisCalculatorSheetState extends State<DevisCalculatorSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _display = '0';
  String _expression = '';

  late TextEditingController _qtyCtrl;
  late TextEditingController _puCtrl;
  late TextEditingController _remCtrl;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _qtyCtrl = TextEditingController(
      text: widget.initialQuantite != null && widget.initialQuantite! > 0
          ? _fmt(widget.initialQuantite!)
          : '',
    );
    _puCtrl = TextEditingController(
      text: widget.initialPrix != null && widget.initialPrix! > 0
          ? _fmt(widget.initialPrix!)
          : '',
    );
    _remCtrl = TextEditingController(
      text: widget.initialRemise != null && widget.initialRemise! > 0
          ? _fmt(widget.initialRemise!)
          : '',
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _qtyCtrl.dispose();
    _puCtrl.dispose();
    _remCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _tap(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0';
        _expression = '';
        return;
      }
      if (key == '⌫') {
        if (_display.length <= 1) {
          _display = '0';
        } else {
          _display = _display.substring(0, _display.length - 1);
        }
        return;
      }
      if (key == '=') {
        _evaluate();
        return;
      }
      if (['+', '-', '×', '÷'].contains(key)) {
        if (_expression.isNotEmpty && !['+', '-', '×', '÷'].contains(_display)) {
          _evaluate(silent: true);
        }
        _expression = '$_display $key';
        _display = '0';
        return;
      }
      if (key == '.') {
        if (!_display.contains('.')) _display = _display == '0' ? '0.' : '$_display.';
        return;
      }
      if (_display == '0') {
        _display = key;
      } else {
        _display += key;
      }
    });
  }

  void _evaluate({bool silent = false}) {
    if (_expression.isEmpty) return;
    final parts = _expression.split(' ');
    if (parts.length != 2) return;
    final a = double.tryParse(parts[0]) ?? 0;
    final op = parts[1];
    final b = double.tryParse(_display) ?? 0;
    double? result;
    switch (op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '×':
        result = a * b;
        break;
      case '÷':
        result = b == 0 ? null : a / b;
        break;
    }
    if (result == null) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Division par zéro impossible')),
        );
      }
      return;
    }
    setState(() {
      _display = _fmtResult(result!);
      if (!silent) _expression = '';
    });
  }

  String _fmtResult(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(2);
  }

  double get _qty => NumberParser.parse(_qtyCtrl.text) ?? 0;
  double get _pu => NumberParser.parse(_puCtrl.text) ?? 0;
  double get _rem => NumberParser.parse(_remCtrl.text) ?? 0;
  double get _brut => _qty * _pu;
  double get _remiseVal => _brut * (_rem / 100);
  double get _net => _brut - _remiseVal;

  void _apply(CalculatorApplyTarget target, double value) {
    widget.onApply?.call(target, value);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Valeur appliquée : ${Formatters.montant(value)}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Calculatrice devis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            TabBar(
              controller: _tabs,
              labelColor: AppColors.isitekGreen,
              tabs: const [
                Tab(text: 'Calculatrice'),
                Tab(text: 'Ligne devis'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildCalcPad(),
                  _buildDevisHelper(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalcPad() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.isitekNavy,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_expression.isNotEmpty)
                  Text(_expression, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                Text(
                  _display,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _calcGrid()),
          if (widget.onApply != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _apply(CalculatorApplyTarget.quantite, double.tryParse(_display) ?? 0),
                    child: const Text('→ Qté'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _apply(CalculatorApplyTarget.prixUnitaire, double.tryParse(_display) ?? 0),
                    child: const Text('→ PU'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _apply(CalculatorApplyTarget.remise, double.tryParse(_display) ?? 0),
                    child: const Text('→ Remise %'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _calcGrid() {
    const rows = [
      ['C', '⌫', '÷', '×'],
      ['7', '8', '9', '-'],
      ['4', '5', '6', '+'],
      ['1', '2', '3', '='],
      ['0', '.'],
    ];
    return Column(
      children: rows.map((row) {
        return Expanded(
          child: Row(
            children: [
              for (var i = 0; i < row.length; i++)
                Expanded(
                  flex: row[i] == '0' ? 2 : 1,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _calcKey(row[i]),
                  ),
                ),
              if (row.length < 4)
                for (var i = row.length; i < 4; i++)
                  const Expanded(child: SizedBox()),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _calcKey(String k) {
    final isOp = ['+', '-', '×', '÷', '='].contains(k);
    final isAction = ['C', '⌫'].contains(k);
    return FilledButton(
      onPressed: () => _tap(k),
      style: FilledButton.styleFrom(
        backgroundColor: isAction
            ? Colors.orange.shade100
            : isOp
                ? AppColors.isitekGreen
                : Colors.grey.shade100,
        foregroundColor: isAction
            ? Colors.orange.shade900
            : isOp
                ? Colors.white
                : AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Text(k, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDevisHelper() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _numField(_qtyCtrl, 'Quantité'),
          const SizedBox(height: 10),
          _numField(_puCtrl, 'Prix unitaire HT (FCFA)'),
          const SizedBox(height: 10),
          _numField(_remCtrl, 'Remise (%)'),
          const SizedBox(height: 16),
          _resultTile('Montant brut (Qté × PU)', _brut),
          _resultTile('Remise ligne', _remiseVal),
          _resultTile('Montant HT Net', _net, highlight: true),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _qty > 0 && _net > 0
                    ? () {
                        _puCtrl.text = _fmt(_net / _qty);
                        setState(() {});
                      }
                    : null,
                child: const Text('PU = Net ÷ Qté'),
              ),
              OutlinedButton(
                onPressed: _pu > 0 && _net > 0
                    ? () {
                        _qtyCtrl.text = _fmt(_net / _pu);
                        setState(() {});
                      }
                    : null,
                child: const Text('Qté = Net ÷ PU'),
              ),
              OutlinedButton(
                onPressed: _brut > 0 && _net >= 0
                    ? () {
                        final pct = ((_brut - _net) / _brut) * 100;
                        _remCtrl.text = _fmt(pct);
                        setState(() {});
                      }
                    : null,
                child: const Text('Remise % depuis Net'),
              ),
            ],
          ),
          if (widget.onApply != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.onApply == null
                  ? null
                  : () {
                      widget.onApply!(CalculatorApplyTarget.quantite, _qty);
                      widget.onApply!(CalculatorApplyTarget.prixUnitaire, _pu);
                      widget.onApply!(CalculatorApplyTarget.remise, _rem);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Qté, PU et remise appliqués à la ligne')),
                      );
                    },
              icon: const Icon(Icons.check),
              label: const Text('Appliquer Qté, PU et Remise à la ligne'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.isitekGreen,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\s.,]+'))],
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _resultTile(String label, double value, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: highlight ? AppColors.isitekGreen.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? AppColors.isitekGreen : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: highlight ? FontWeight.bold : FontWeight.w500)),
          Text(
            Formatters.montantCFA(value),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.isitekGreenDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
