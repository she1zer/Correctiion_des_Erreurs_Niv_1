import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'admin/admin_navigator.dart';
import 'technicien/technicien_screens.dart';
import '../navigation/root_navigator.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _pwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.instance.login(
        _emailController.text.trim(),
        _pwController.text,
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
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Center(
                child: Image.asset(
                  'assets/images/logo_isitek.jpg',
                  height: 110,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.lock_person_rounded, size: 70, color: Colors.green);
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('Connexion', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Text('Connectez-vous à votre espace ISITEK Pro.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pwController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('SE CONNECTER', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupPage())),
                  child: const Text('Pas encore de compte ? Créer un compte'),
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
      ),
    );
  }
}

class AdminEmployeeLoginPage extends StatefulWidget {
  const AdminEmployeeLoginPage({super.key});

  @override
  State<AdminEmployeeLoginPage> createState() => _AdminEmployeeLoginPageState();
}

class _AdminEmployeeLoginPageState extends State<AdminEmployeeLoginPage> with TickerProviderStateMixin {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _posteController = TextEditingController();
  final _emailController = TextEditingController();
  final _pwController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  bool _isSignup = false;
  final String _selectedRole = 'technicien';

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
    _nomController.dispose();
    _prenomController.dispose();
    _phoneController.dispose();
    _posteController.dispose();
    _emailController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _pwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.instance.login(
        _emailController.text.trim(),
        _pwController.text,
      );
      if (!mounted) return;
      if (user.role == 'admin' || user.role == 'technicien') {
        final destination = user.role == 'admin' ? const AdminRootNavigator() : const TechRootNavigator();
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accès réservé aux administrateurs et employés.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signup() async {
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _posteController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _pwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ApiService.instance.register(
        email: _emailController.text.trim(),
        password: _pwController.text,
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _phoneController.text.trim(),
        poste: _posteController.text.trim(),
        role: _selectedRole,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte employé créé avec succès !')));
      setState(() => _isSignup = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType? keyboardType,
    String? helperText,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Color(0xFF0E2913),
          fontSize: 15.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
          helperText: helperText,
          helperMaxLines: 2,
          helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          prefixIcon: Icon(icon, color: const Color(0xFF0B5E26)),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        ),
      ),
    );
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B5E26), Color(0xFF1B8A3A), Color(0xFF2EAD4E)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
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
                      ),
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
                            Container(
                              width: 100,
                              height: 100,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0B5E26).withValues(alpha: 0.35),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logo_isitek.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.admin_panel_settings,
                                      color: Color(0xFF0B5E26),
                                      size: 60,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _isSignup ? 'Créer un compte employé' : 'Connexion Admin/Employé',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isSignup 
                                  ? 'Rejoignez l\'équipe ISITEK'
                                  : 'Connectez-vous à votre espace professionnel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 34),
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
                                  if (_isSignup) ...[
                                    _buildTextField(
                                      label: 'Prénom',
                                      icon: Icons.person_outline_rounded,
                                      controller: _prenomController,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Nom',
                                      icon: Icons.badge_outlined,
                                      controller: _nomController,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Numéro de téléphone',
                                      icon: Icons.phone_android,
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      helperText: 'Doit être enregistré par l\'administrateur ISITEK',
                                    ),
                                    const SizedBox(height: 16),
                                    _buildTextField(
                                      label: 'Rôle dans l\'entreprise',
                                      icon: Icons.work_outline_rounded,
                                      controller: _posteController,
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  _buildTextField(
                                    label: 'Adresse e-mail',
                                    icon: Icons.email_outlined,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    label: 'Mot de passe',
                                    icon: Icons.lock_outline_rounded,
                                    controller: _pwController,
                                    obscure: _obscure,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: Colors.grey.shade500,
                                      ),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: _isLoading
                                        ? Container(
                                            height: 54,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [Color(0xFF0B5E26), Color(0xFF2EAD4E)],
                                              ),
                                              borderRadius: BorderRadius.circular(28),
                                            ),
                                            child: const Center(
                                              child: SizedBox(
                                                width: 26,
                                                height: 26,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.6,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            height: 54,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [Color(0xFF0B5E26), Color(0xFF2EAD4E)],
                                              ),
                                              borderRadius: BorderRadius.circular(28),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF0B5E26).withValues(alpha: 0.45),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: _isSignup ? _signup : _login,
                                                borderRadius: BorderRadius.circular(28),
                                                child: Center(
                                                  child: Text(
                                                    _isSignup ? 'Créer mon compte' : 'Se connecter',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.3,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 26),
                            GestureDetector(
                              onTap: () => setState(() => _isSignup = !_isSignup),
                              child: RichText(
                                text: TextSpan(
                                  text: _isSignup 
                                      ? 'Vous avez déjà un compte ? ' 
                                      : 'Vous n\'avez pas de compte ? ',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 13.5,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _isSignup ? 'Connectez-vous' : 'Inscrivez-vous',
                                      style: const TextStyle(
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
        ],
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Future<void> _signup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _pwController.text.isEmpty ||
        _confirmPwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir tous les champs.')));
      return;
    }
    if (_pwController.text != _confirmPwController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les mots de passe ne correspondent pas.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final parts = _nameController.text.trim().split(' ');
      final prenom = parts.first;
      final nom = parts.length > 1 ? parts.sublist(1).join(' ') : parts.first;
      await ApiService.instance.register(
        email: _emailController.text.trim(),
        password: _pwController.text,
        nom: nom,
        prenom: prenom,
        telephone: _phoneController.text.trim(),
        role: 'client',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte créé avec succès !')));
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
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
          child: Column(
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo_isitek.jpg',
                  height: 100,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person_outline, size: 70, color: Colors.green);
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  prefixIcon: const Icon(Icons.phone_android),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pwController,
                obscureText: _obscurePw,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePw ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePw = !_obscurePw),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPwController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock_person),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('CRÉER MON COMPTE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminEmployeeLoginPage()),
                  );
                },
                child: Container(width: 30, height: 30, color: Colors.transparent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
