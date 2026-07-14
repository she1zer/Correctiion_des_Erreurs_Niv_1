import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'auth_pages.dart' show AuthHomePage;

// ─────────────────────────────────────────────
// PALETTE
// ─────────────────────────────────────────────
class ISITEKColors {
  static const Color forest     = Color(0xFF1B6E2E); // deep brand green
  static const Color emerald    = Color(0xFF2EA84F); // mid green
  static const Color mint       = Color(0xFF5DD97A); // light accent
  static const Color white      = Color(0xFFFFFFFF);
  static const Color offWhite   = Color(0xFFF0FBF4);
  static const Color darkBg     = Color(0xFF0D2A15); // very dark green-black
  static const Color cardBg     = Color(0xFF122B1A);
  static const Color inputBg    = Color(0xFF1A3A22);
  static const Color border     = Color(0xFF2EA84F);
}

// ─────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _gearCtrl;
  late AnimationController _bulbCtrl;
  late AnimationController _chartCtrl;
  late AnimationController _textCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _exitCtrl;

  // Gear rotation
  late Animation<double> _gearRotation;

  // Bulb fade + scale
  late Animation<double> _bulbFade;
  late Animation<double> _bulbScale;

  // Chart bars rise
  late Animation<double> _chartProgress;

  // Text slide + fade
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _subtitleFade;

  // Glow pulse on bulb
  late Animation<double> _pulse;

  // Exit slide-up
  late Animation<Offset> _exitSlide;
  late Animation<double>  _exitFade;

  @override
  void initState() {
    super.initState();

    _gearCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _bulbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _chartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Gear spin (2.5 full turns → easeOut)
    _gearRotation = Tween<double>(begin: 0, end: 2.5 * 2 * math.pi)
        .animate(CurvedAnimation(parent: _gearCtrl, curve: Curves.easeOutCubic));

    // Bulb pop in
    _bulbFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _bulbCtrl, curve: Curves.easeIn));
    _bulbScale = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _bulbCtrl, curve: Curves.elasticOut));

    // Chart bars
    _chartProgress = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _chartCtrl, curve: Curves.easeOutCubic));

    // Text
    _textFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _subtitleFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(
          parent: _textCtrl,
          curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
        ));

    // Glow pulse
    _pulse = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // Exit
    _exitSlide = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.2))
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeInBack));
    _exitFade = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _gearCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));
    _bulbCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _chartCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    _exitCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const AuthHomePage(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: child,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _gearCtrl.dispose();
    _bulbCtrl.dispose();
    _chartCtrl.dispose();
    _textCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ISITEKColors.darkBg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_exitCtrl]),
        builder: (context, _) {
          return SlideTransition(
            position: _exitSlide,
            child: FadeTransition(
              opacity: _exitFade,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Ambient particle background
                  _ParticleField(controller: _particleCtrl),

                  // Radial glow behind logo
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Center(
                      child: Container(
                        width: 340 * _pulse.value,
                        height: 340 * _pulse.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              ISITEKColors.emerald.withValues(alpha: 0.18 * _pulse.value),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Logo + text
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ── GEAR + BULB LOGO ──
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Spinning gear
                              AnimatedBuilder(
                                animation: _gearCtrl,
                                builder: (_, __) => Transform.rotate(
                                  angle: _gearRotation.value,
                                  child: CustomPaint(
                                    size: const Size(180, 180),
                                    painter: _GearPainter(),
                                  ),
                                ),
                              ),
                              // Chart bars inside gear
                              AnimatedBuilder(
                                animation: _chartCtrl,
                                builder: (_, __) => SizedBox(
                                  width: 90,
                                  height: 90,
                                  child: CustomPaint(
                                    painter: _ChartPainter(_chartProgress.value),
                                  ),
                                ),
                              ),
                              // Bulb below gear
                              Positioned(
                                bottom: 0,
                                child: AnimatedBuilder(
                                  animation: _bulbCtrl,
                                  builder: (_, __) => FadeTransition(
                                    opacity: _bulbFade,
                                    child: Transform.scale(
                                      scale: _bulbScale.value,
                                      child: CustomPaint(
                                        size: const Size(60, 70),
                                        painter: _BulbPainter(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── ISITEK WORDMARK ──
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _textFade,
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  ISITEKColors.mint,
                                  ISITEKColors.white,
                                  ISITEKColors.emerald,
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'ISITEK',
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 10,
                                  color: Colors.white,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle
                        FadeTransition(
                          opacity: _subtitleFade,
                          child: const Text(
                            'INTÉGRATEUR DE SOLUTIONS INDUSTRIELLES',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 3.5,
                              color: ISITEKColors.mint,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom loader bar
                  Positioned(
                    bottom: 48,
                    left: 60,
                    right: 60,
                    child: AnimatedBuilder(
                      animation: _textCtrl,
                      builder: (_, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _textFade.value,
                          backgroundColor: ISITEKColors.forest.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            ISITEKColors.mint,
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CUSTOM PAINTERS
// ─────────────────────────────────────────────

/// SVG-style gear with teeth
class _GearPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final toothH = radius * 0.14;
    const teeth = 14;

    final paint = Paint()
      ..color = ISITEKColors.emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = ISITEKColors.forest
      ..style = PaintingStyle.fill;

    final path = Path();
    const step = 2 * math.pi / teeth;

    for (int i = 0; i < teeth; i++) {
      final a0 = i * step - step * 0.35;
      final a1 = i * step - step * 0.15;
      final a2 = i * step + step * 0.15;
      final a3 = i * step + step * 0.35;

      final inner = radius - toothH * 0.3;
      final outer = radius + toothH * 0.7;

      if (i == 0) {
        path.moveTo(center.dx + inner * math.cos(a0),
                    center.dy + inner * math.sin(a0));
      } else {
        path.lineTo(center.dx + inner * math.cos(a0),
                    center.dy + inner * math.sin(a0));
      }
      path.lineTo(center.dx + outer * math.cos(a1),
                  center.dy + outer * math.sin(a1));
      path.lineTo(center.dx + outer * math.cos(a2),
                  center.dy + outer * math.sin(a2));
      path.lineTo(center.dx + inner * math.cos(a3),
                  center.dy + inner * math.sin(a3));
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    // Inner ring
    canvas.drawCircle(center, radius * 0.56,
      Paint()
        ..color = ISITEKColors.darkBg
        ..style = PaintingStyle.fill);
    canvas.drawCircle(center, radius * 0.56, paint..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(_GearPainter old) => false;
}

/// Rising bar chart + arrow (inside gear)
class _ChartPainter extends CustomPainter {
  final double progress;
  _ChartPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ISITEKColors.mint
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final barHeights = [0.35, 0.55, 0.72, 0.88];
    final barW = size.width * 0.14;
    final gap = (size.width - barHeights.length * barW) / (barHeights.length + 1);

    for (int i = 0; i < barHeights.length; i++) {
      final h = size.height * barHeights[i] * progress;
      final x = gap + i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barW, h),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, paint..color = ISITEKColors.mint.withValues(alpha: 0.85 + 0.15 * i / barHeights.length));
    }

    // Trend arrow line
    if (progress > 0.5) {
      final arrowPaint = Paint()
        ..color = ISITEKColors.white
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final t = (progress - 0.5) * 2; // 0→1 in second half
      final startX = size.width * 0.05;
      final startY = size.height * 0.75;
      final endX   = size.width * 0.95;
      final endY   = size.height * 0.05;
      final curEndX = startX + (endX - startX) * t;
      final curEndY = startY + (endY - startY) * t;

      canvas.drawLine(Offset(startX, startY), Offset(curEndX, curEndY), arrowPaint);

      if (t > 0.85) {
        // Arrow head
        final angle = math.atan2(endY - startY, endX - startX);
        final aLen  = 10.0;
        canvas.drawLine(
          Offset(endX, endY),
          Offset(endX - aLen * math.cos(angle - 0.5), endY - aLen * math.sin(angle - 0.5)),
          arrowPaint..strokeWidth = 2,
        );
        canvas.drawLine(
          Offset(endX, endY),
          Offset(endX - aLen * math.cos(angle + 0.5), endY - aLen * math.sin(angle + 0.5)),
          arrowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => old.progress != progress;
}

/// Light bulb
class _BulbPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = ISITEKColors.emerald
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = ISITEKColors.mint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // Bulb globe
    final bulbRect = Rect.fromLTWH(w * 0.1, 0, w * 0.8, h * 0.62);
    canvas.drawOval(bulbRect, paint);
    canvas.drawOval(bulbRect, strokePaint);

    // Filament lines (3 stripes inside globe)
    final linePaint = Paint()
      ..color = ISITEKColors.darkBg
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final lineY = h * 0.38;
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(w * 0.28, lineY + i * 6),
        Offset(w * 0.72, lineY + i * 6),
        linePaint,
      );
    }

    // Base rectangle
    final base = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.62, w * 0.56, h * 0.24),
      const Radius.circular(3),
    );
    canvas.drawRRect(base, paint);
    canvas.drawRRect(base, strokePaint);

    // Bottom flat cap
    final cap = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.30, h * 0.87, w * 0.40, h * 0.13),
      const Radius.circular(3),
    );
    canvas.drawRRect(cap, paint);
    canvas.drawRRect(cap, strokePaint);
  }

  @override
  bool shouldRepaint(_BulbPainter old) => false;
}

/// Floating ambient particles
class _ParticleField extends StatelessWidget {
  final AnimationController controller;
  const _ParticleField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final double t;
  _ParticlePainter(this.t);

  static final List<_Particle> _particles = List.generate(28, (i) {
    final rand = math.Random(i * 13 + 7);
    return _Particle(
      x: rand.nextDouble(),
      y: rand.nextDouble(),
      r: 1.5 + rand.nextDouble() * 2.5,
      speed: 0.08 + rand.nextDouble() * 0.14,
      phase: rand.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final p in _particles) {
      final cy = (p.y - p.speed * t + p.phase) % 1.0;
      final opacity = (math.sin((cy + p.phase) * math.pi * 2) * 0.5 + 0.5) * 0.5;
      paint.color = ISITEKColors.mint.withValues(alpha: opacity.clamp(0.05, 0.45));
      canvas.drawCircle(Offset(p.x * size.width, cy * size.height), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _Particle {
  final double x, y, r, speed, phase;
  _Particle({required this.x, required this.y, required this.r,
             required this.speed, required this.phase});
}
