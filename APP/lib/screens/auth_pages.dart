import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'admin/admin_navigator.dart';
import 'technicien/technicien_screens.dart';
import '../navigation/root_navigator.dart';
import 'login_page.dart' show AdminEmployeeLoginPage;

// ============================================================================
// PALETTE DE COULEURS — inspirée du logo ISITEK
// ============================================================================
class IsitekColors {
  static const Color darkGreen = Color(0xFF0B5E26);
  static const Color green = Color(0xFF1B8A3A);
  static const Color brightGreen = Color(0xFF2EAD4E);
  static const Color lightGreen = Color(0xFFB7E8C4);
  static const Color paleGreen = Color(0xFFEAF8EE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF6FBF7);
  static const Color textDark = Color(0xFF0E2913);

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkGreen, green, brightGreen],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [darkGreen, brightGreen],
  );
}

// ============================================================================
// WIDGET PARTAGÉ : Fond animé avec particules/bulles vertes flottantes
// ============================================================================
class AnimatedBubblesBackground extends StatefulWidget {
  final int bubbleCount;
  const AnimatedBubblesBackground({super.key, this.bubbleCount = 18});

  @override
  State<AnimatedBubblesBackground> createState() =>
      _AnimatedBubblesBackgroundState();
}

class _AnimatedBubblesBackgroundState extends State<AnimatedBubblesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_BubbleData> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    for (int i = 0; i < widget.bubbleCount; i++) {
      _bubbles.add(_BubbleData(
        startX: _random.nextDouble(),
        startDelay: _random.nextDouble(),
        size: 8 + _random.nextDouble() * 34,
        speed: 0.5 + _random.nextDouble() * 1.0,
        opacity: 0.04 + _random.nextDouble() * 0.10,
        wiggle: _random.nextDouble() * 40 - 20,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: _bubbles.map((b) {
            final t = (_controller.value * b.speed + b.startDelay) % 1.0;
            final y = size.height * (1 - t) + 80;
            final x = b.startX * size.width +
                sin(t * 2 * pi) * b.wiggle;
            return Positioned(
              left: x,
              top: y - 100,
              child: Opacity(
                opacity: (sin(t * pi) * b.opacity).clamp(0.0, 1.0),
                child: Container(
                  width: b.size,
                  height: b.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: IsitekColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: IsitekColors.white.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _BubbleData {
  final double startX;
  final double startDelay;
  final double size;
  final double speed;
  final double opacity;
  final double wiggle;

  _BubbleData({
    required this.startX,
    required this.startDelay,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.wiggle,
  });
}

// ============================================================================
// WIDGET PARTAGÉ : Logo animé (pulsation + rotation légère de l'anneau)
// ============================================================================
class AnimatedLogo extends StatefulWidget {
  final double size;
  const AnimatedLogo({super.key, this.size = 140});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _entryController]),
      builder: (context, child) {
        final entry = Curves.easeOut.transform(_entryController.value);
        final pulse = 1.0 + (_pulseController.value * 0.04);
        return Transform.scale(
          scale: entry * pulse,
          child: Opacity(
            opacity: _entryController.value.clamp(0.0, 1.0),
            child: Container(
              width: widget.size,
              height: widget.size,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: IsitekColors.white,
                boxShadow: [
                  BoxShadow(
                    color: IsitekColors.darkGreen
                        .withValues(alpha: 0.35 + 0.1 * _pulseController.value),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: IsitekColors.white.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo_isitek.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Repli si l'image n'est pas trouvée
                    return const Icon(
                      Icons.eco,
                      color: IsitekColors.darkGreen,
                      size: 60,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// WIDGET PARTAGÉ : Bouton avec effet d'appui + brillance
// ============================================================================
class ShineButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool filled; // true = fond plein dégradé vert ; false = contour blanc
  final IconData? icon;

  const ShineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
    this.icon,
  });

  @override
  State<ShineButton> createState() => _ShineButtonState();
}

class _ShineButtonState extends State<ShineButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    setState(() => _scale = 0.96);
    HapticFeedback.lightImpact();
  }

  void _onTapUp(_) {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final child = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: widget.filled ? IsitekColors.buttonGradient : null,
          color: widget.filled ? null : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(28),
          border: widget.filled
              ? null
              : Border.all(color: IsitekColors.white, width: 1.6),
          boxShadow: widget.filled
              ? [
                  BoxShadow(
                    color: IsitekColors.darkGreen.withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.filled)
                AnimatedBuilder(
                  animation: _shineController,
                  builder: (context, _) {
                    return Positioned.fill(
                      child: Align(
                        alignment: Alignment(
                          -1.5 + 3.0 * _shineController.value,
                          0,
                        ),
                        child: Transform.rotate(
                          angle: 0.5,
                          child: Container(
                            width: 40,
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 19,
                      color: widget.filled
                          ? IsitekColors.white
                          : IsitekColors.white,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: IsitekColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onPressed,
      child: child,
    );
  }
}

// ============================================================================
// WIDGET PARTAGÉ : Champ de texte stylisé avec animation de focus
// ============================================================================
class IsitekTextField extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool obscure;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final Widget? suffix;

  const IsitekTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
  });

  @override
  State<IsitekTextField> createState() => _IsitekTextFieldState();
}

class _IsitekTextFieldState extends State<IsitekTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _focused
                ? IsitekColors.brightGreen.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: _focused ? 18 : 8,
            spreadRadius: _focused ? 1 : 0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _focused ? IsitekColors.brightGreen : Colors.transparent,
          width: 1.6,
        ),
      ),
      child: Focus(
        onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          style: const TextStyle(
            color: IsitekColors.textDark,
            fontSize: 15.5,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            labelStyle: TextStyle(
              color: _focused
                  ? IsitekColors.darkGreen
                  : Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: _focused
                  ? IsitekColors.darkGreen
                  : Colors.grey.shade400,
            ),
            suffixIcon: widget.suffix,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PAGE D'ACCUEIL
// ============================================================================
class AuthHomePage extends StatefulWidget {
  const AuthHomePage({super.key});

  @override
  State<AuthHomePage> createState() => _AuthHomePageState();
}

class _AuthHomePageState extends State<AuthHomePage> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<Offset> _titleSlide;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _entryController, curve: Curves.easeOutCubic));
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      body: Stack(
        children: [
          // Fond en dégradé vert
          Container(
            decoration: const BoxDecoration(gradient: IsitekColors.mainGradient),
          ),
          // Bulles flottantes animées
          const Positioned.fill(child: AnimatedBubblesBackground()),
          // Cercles décoratifs flous
          Positioned(
            top: -80,
            right: -60,
            child: _glowCircle(220, IsitekColors.white.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: _glowCircle(280, IsitekColors.brightGreen.withValues(alpha: 0.18)),
          ),
          // Contenu principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isWide ? 480 : 600),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: size.height * 0.04),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminEmployeeLoginPage()),
                          );
                        },
                        child: const AnimatedLogo(size: 150),
                      ),
                      const SizedBox(height: 28),
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _fadeIn,
                          child: Column(
                            children: [
                              const Text(
                                'ISITEK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Text(
                                  'Intégrateur de solutions industrielles',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: size.height * 0.06),
                      FadeTransition(
                        opacity: _fadeIn,
                        child: const Text(
                          'Pilotez votre performance industrielle\navec des solutions intelligentes et fiables.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),
                      // Boutons Connexion / Inscription
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Row(
                          children: [
                            Expanded(
                              child: ShineButton(
                                label: 'Connexion',
                                icon: Icons.login_rounded,
                                filled: true,
                                onPressed: () {
                                  Navigator.of(context).push(_buildRoute(
                                      const NewLoginPage(),
                                      fromRight: true));
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: ShineButton(
                                label: 'Inscrivez-vous',
                                icon: Icons.person_add_alt_1_rounded,
                                filled: false,
                                onPressed: () {
                                  Navigator.of(context).push(_buildRoute(
                                      const NewSignupPage(),
                                      fromRight: true));
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      FadeTransition(
                        opacity: _fadeIn,
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 22,
                          runSpacing: 12,
                          children: const [
                            _FeatureChip(
                                icon: Icons.precision_manufacturing_rounded,
                                label: 'Automatisation'),
                            _FeatureChip(
                                icon: Icons.insights_rounded,
                                label: 'Performance'),
                            _FeatureChip(
                                icon: Icons.verified_rounded,
                                label: 'Fiabilité'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// Transition de page personnalisée (glissement + fondu)
Route _buildRoute(Widget page, {bool fromRight = false}) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 500),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(fromRight ? 0.15 : -0.15, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

// ============================================================================
// PAGE DE CONNEXION
// ============================================================================
class NewLoginPage extends StatefulWidget {
  const NewLoginPage({super.key});

  @override
  State<NewLoginPage> createState() => _NewLoginPageState();
}

class _NewLoginPageState extends State<NewLoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await ApiService.instance.loadSession();
    final user = ApiService.instance.currentUser;
    if (user == null || !mounted) return;
    _navigateByRole(user.role);
  }

  void _navigateByRole(String role) {
    Widget destination;
    if (role == 'admin') {
      destination = const AdminRootNavigator();
    } else if (role == 'technicien') {
      destination = const TechRootNavigator();
    } else {
      destination = const RootNavigator();
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final user = await ApiService.instance.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      _navigateByRole(user.role);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: IsitekColors.mainGradient),
          ),
          const Positioned.fill(child: AnimatedBubblesBackground(bubbleCount: 12)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: slide,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            const AnimatedLogo(size: 100),
                            const SizedBox(height: 18),
                            const Text(
                              'Bon retour parmi nous',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Connectez-vous pour accéder à votre espace ISITEK',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 34),
                            // Carte du formulaire
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.97),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  IsitekTextField(
                                    label: 'Adresse e-mail',
                                    icon: Icons.email_outlined,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  IsitekTextField(
                                    label: 'Mot de passe',
                                    icon: Icons.lock_outline_rounded,
                                    controller: _passwordController,
                                    obscure: _obscurePassword,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.9,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: IsitekColors.darkGreen,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          onChanged: (v) => setState(
                                              () => _rememberMe = v ?? false),
                                        ),
                                      ),
                                      const Text(
                                        'Se souvenir de moi',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: IsitekColors.textDark,
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {},
                                        child: const Text(
                                          'Mot de passe oublié ?',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: IsitekColors.darkGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _isLoading
                                        ? Container(
                                            height: 54,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  IsitekColors.buttonGradient,
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                            ),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 26,
                                                height: 26,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.6,
                                                ),
                                              ),
                                            ),
                                          )
                                        : ShineButton(
                                            label: 'Se connecter',
                                            icon: Icons.arrow_forward_rounded,
                                            onPressed: _handleLogin,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            _OrDivider(),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SocialCircle(icon: Icons.g_mobiledata_rounded),
                                const SizedBox(width: 18),
                                _SocialCircle(icon: Icons.apple_rounded),
                                const SizedBox(width: 18),
                                _SocialCircle(icon: Icons.facebook_rounded),
                              ],
                            ),
                            const SizedBox(height: 28),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                    _buildRoute(const NewSignupPage()));
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: "Vous n'avez pas de compte ? ",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13.5,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Inscrivez-vous',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Hidden button for admin/employee access
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminEmployeeLoginPage()),
                );
              },
              child: Container(
                width: 30,
                height: 30,
                color: Colors.transparent,
                child: const Text('', style: TextStyle(color: Colors.transparent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PAGE D'INSCRIPTION
// ============================================================================
class NewSignupPage extends StatefulWidget {
  const NewSignupPage({super.key});

  @override
  State<NewSignupPage> createState() => _NewSignupPageState();
}

class _NewSignupPageState extends State<NewSignupPage> with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // Estimation simple de la force du mot de passe (0 à 1)
  double get _passwordStrength {
    final p = _passwordController.text;
    if (p.isEmpty) return 0;
    double score = 0;
    if (p.length >= 6) score += 0.25;
    if (p.length >= 10) score += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(p)) score += 0.2;
    if (RegExp(r'[0-9]').hasMatch(p)) score += 0.15;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p)) score += 0.15;
    return score.clamp(0, 1);
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (s < 0.35) return Colors.redAccent;
    if (s < 0.7) return Colors.orangeAccent;
    return IsitekColors.brightGreen;
  }

  String get _strengthLabel {
    final s = _passwordStrength;
    if (s == 0) return '';
    if (s < 0.35) return 'Faible';
    if (s < 0.7) return 'Moyen';
    return 'Solide';
  }

  void _handleSignup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas.')),
      );
      return;
    }
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Veuillez accepter les conditions d'utilisation"),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final parts = _nameController.text.trim().split(' ');
      final prenom = parts.first;
      final nom = parts.length > 1 ? parts.sublist(1).join(' ') : parts.first;
      await ApiService.instance.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        nom: nom,
        prenom: prenom,
        telephone: _phoneController.text.trim(),
        role: 'client',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé avec succès !')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _entryController, curve: Curves.easeIn);
    final slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: IsitekColors.mainGradient),
          ),
          const Positioned.fill(child: AnimatedBubblesBackground(bubbleCount: 12)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      _BackButton(onTap: () => Navigator.of(context).pop()),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: slide,
                        child: Column(
                          children: [
                            const SizedBox(height: 6),
                            const AnimatedLogo(size: 90),
                            const SizedBox(height: 16),
                            const Text(
                              'Créer un compte',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rejoignez ISITEK et boostez votre performance industrielle',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.97),
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 30,
                                    offset: const Offset(0, 14),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  IsitekTextField(
                                    label: 'Nom complet',
                                    icon: Icons.person_outline_rounded,
                                    controller: _nameController,
                                  ),
                                  const SizedBox(height: 16),
                                  IsitekTextField(
                                    label: 'Adresse e-mail',
                                    icon: Icons.email_outlined,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  IsitekTextField(
                                    label: 'Téléphone',
                                    icon: Icons.phone_android,
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),
                                  IsitekTextField(
                                    label: 'Mot de passe',
                                    icon: Icons.lock_outline_rounded,
                                    controller: _passwordController,
                                    obscure: _obscurePassword,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  // Indicateur de force du mot de passe
                                  if (_passwordController.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child:
                                                      AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    height: 6,
                                                    color: Colors.grey
                                                        .shade200,
                                                    child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child:
                                                          AnimatedFractionallySizedBox(
                                                        duration: const Duration(
                                                            milliseconds: 300),
                                                        widthFactor:
                                                            _passwordStrength,
                                                        child: Container(
                                                          color:
                                                              _strengthColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                _strengthLabel,
                                                style: TextStyle(
                                                  color: _strengthColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  IsitekTextField(
                                    label: 'Confirmer le mot de passe',
                                    icon: Icons.lock_reset_rounded,
                                    controller: _confirmController,
                                    obscure: _obscureConfirm,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscureConfirm
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: () => setState(
                                          () => _obscureConfirm = !_obscureConfirm),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Transform.scale(
                                        scale: 0.9,
                                        child: Checkbox(
                                          value: _acceptTerms,
                                          activeColor: IsitekColors.darkGreen,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5)),
                                          onChanged: (v) => setState(
                                              () => _acceptTerms = v ?? false),
                                        ),
                                      ),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              color: IsitekColors.textDark,
                                            ),
                                            children: const [
                                              TextSpan(
                                                  text: "J'accepte les "),
                                              TextSpan(
                                                text:
                                                    "conditions d'utilisation",
                                                style: TextStyle(
                                                  color:
                                                      IsitekColors.darkGreen,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              TextSpan(
                                                  text:
                                                      " et la politique de confidentialité"),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _isLoading
                                        ? Container(
                                            height: 54,
                                            decoration: BoxDecoration(
                                              gradient:
                                                  IsitekColors.buttonGradient,
                                              borderRadius:
                                                  BorderRadius.circular(28),
                                            ),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 26,
                                                height: 26,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.6,
                                                ),
                                              ),
                                            ),
                                          )
                                        : ShineButton(
                                            label: 'Créer mon compte',
                                            icon: Icons.check_circle_outline_rounded,
                                            onPressed: _handleSignup,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                    _buildRoute(const NewLoginPage()));
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Vous avez déjà un compte ? ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13.5,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'Connectez-vous',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Hidden button for admin/employee access
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminEmployeeLoginPage()),
                );
              },
              child: Container(
                width: 30,
                height: 30,
                color: Colors.transparent,
                child: const Text('', style: TextStyle(color: Colors.transparent)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PETITS WIDGETS RÉUTILISABLES
// ============================================================================
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(color: Colors.white.withValues(alpha: 0.4), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OU',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
            child: Divider(color: Colors.white.withValues(alpha: 0.4), thickness: 1)),
      ],
    );
  }
}

class _SocialCircle extends StatefulWidget {
  final IconData icon;
  const _SocialCircle({required this.icon});

  @override
  State<_SocialCircle> createState() => _SocialCircleState();
}

class _SocialCircleState extends State<_SocialCircle> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {},
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(widget.icon, color: IsitekColors.darkGreen, size: 26),
        ),
      ),
    );
  }
}
