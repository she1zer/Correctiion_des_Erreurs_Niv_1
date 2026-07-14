import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SignaturePad extends StatefulWidget {
  final String? initialBase64;
  final ValueChanged<String?> onChanged;

  const SignaturePad({
    super.key,
    this.initialBase64,
    required this.onChanged,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<Offset?> _points = [];

  void _clear() {
    setState(() => _points.clear());
    widget.onChanged(null);
  }

  Future<void> _export() async {
    if (_points.whereType<Offset>().isEmpty) {
      widget.onChanged(null);
      return;
    }
    final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final bytes = byteData.buffer.asUint8List();
    widget.onChanged('data:image/png;base64,${base64Encode(bytes)}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Signature responsable',
          style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: RepaintBoundary(
            key: _repaintKey,
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: GestureDetector(
                onPanUpdate: (d) {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  setState(() => _points.add(box.globalToLocal(d.globalPosition)));
                },
                onPanEnd: (_) {
                  setState(() => _points.add(null));
                  _export();
                },
                child: CustomPaint(
                  painter: _SignaturePainter(_points),
                  size: const Size(double.infinity, 100),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _clear,
          icon: const Icon(Icons.clear, size: 18),
          label: const Text('Effacer la signature'),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
