import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'register_page.dart';
import 'forgot_password_page.dart';

class _SlideData {
  final IconData icon;
  final Color iconBg;
  final String titre;
  final String sousTitre;
  const _SlideData({
    required this.icon,
    required this.iconBg,
    required this.titre,
    required this.sousTitre,
  });
}

const _slides = [
  _SlideData(
    icon: Icons.qr_code_scanner_rounded,
    iconBg: Color(0xFF1B5E20),
    titre: 'Scannez. Comparez.',
    sousTitre: 'Un simple scan pour connaître\nle meilleur prix en ville.',
  ),
  _SlideData(
    icon: Icons.savings_rounded,
    iconBg: Color(0xFF2E7D32),
    titre: 'Économisez chaque jour',
    sousTitre: 'Des centaines de FCFA économisés\nà chaque course.',
  ),
  _SlideData(
    icon: Icons.store_mall_directory_rounded,
    iconBg: Color(0xFF388E3C),
    titre: 'Tous les commerces',
    sousTitre: 'Marchés, supermarchés, boutiques —\ntout en un seul endroit.',
  ),
  _SlideData(
    icon: Icons.verified_rounded,
    iconBg: Color(0xFF43A047),
    titre: 'Faites confiance à SmartBuy',
    sousTitre: 'Prix vérifiés en temps réel\npar notre communauté.',
  ),
];

const _partenaires = [
  {'logo': 'assets/logos/auchan.png', 'nom': 'Auchan'},
  {'logo': 'assets/logos/casino.png', 'nom': 'Casino'},
  {'logo': 'assets/logos/exclusive.png', 'nom': 'Exclusive'},
  {'logo': 'assets/logos/jumia.png', 'nom': 'Jumia'},
  {'logo': 'assets/logos/supermarket.png', 'nom': 'Super Market'},
  {'logo': 'assets/logos/score.png', 'nom': 'Score'},
  {'logo': 'assets/logos/carrefour.png', 'nom': 'Carrefour'},
];

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pageController = PageController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  int _currentSlide = 0;
  Timer? _carouselTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_currentSlide + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _pageController.dispose();
    _carouselTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'Aucun compte trouvé avec cet email.';
          break;
        case 'wrong-password':
          message = 'Mot de passe incorrect.';
          break;
        case 'invalid-credential':
          message = 'Email ou mot de passe incorrect.';
          break;
        case 'invalid-email':
          message = 'Email invalide.';
          break;
        default:
          message = 'Erreur de connexion. Réessayez.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(message),
            ]),
            backgroundColor: const Color(0xFFB00020),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F0F),
      body: Stack(
        children: [
          Positioned(
            top: -50, right: -50,
            child: _decoCircle(200, const Color(0xFF1E6B3C), 0.2),
          ),
          Positioned(
            bottom: 100, left: -60,
            child: _decoCircle(180, const Color(0xFF2E7D32), 0.1),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ── Logo ──────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(11),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2E7D32).withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.shopping_bag_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SmartBuy',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                )),
                            Text('SÉNÉGAL',
                                style: TextStyle(
                                  color: Color(0xFF66BB6A),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3,
                                )),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Carousel ──────────────────────────────
                    SizedBox(
                      height: 190,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _slides.length,
                        onPageChanged: (i) =>
                            setState(() => _currentSlide = i),
                        itemBuilder: (context, index) {
                          final s = _slides[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [s.iconBg, s.iconBg.withOpacity(0.75)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: s.iconBg.withOpacity(0.4),
                                    blurRadius: 18,
                                    offset: const Offset(0, 7),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    right: -15, top: -15,
                                    child: Container(
                                      width: 100, height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.07),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(22),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 48, height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(13),
                                          ),
                                          child: Icon(s.icon,
                                              color: Colors.white, size: 26),
                                        ),
                                        const SizedBox(height: 14),
                                        Text(s.titre,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            )),
                                        const SizedBox(height: 5),
                                        Text(s.sousTitre,
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                              fontSize: 12,
                                              height: 1.5,
                                            )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Points indicateurs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _currentSlide ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == _currentSlide
                                ? const Color(0xFF66BB6A)
                                : Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // ── Formulaire centré et limité en largeur ─
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 28,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Bon retour 👋',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0A1F0F),
                                    )),
                                const SizedBox(height: 3),
                                Text('Connectez-vous à votre compte',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500)),
                                const SizedBox(height: 22),

                                _buildLabel('Email'),
                                _buildTextField(
                                  controller: _emailController,
                                  hint: 'votre@email.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),

                                _buildLabel('Mot de passe'),
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  obscure: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade400,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ForgotPasswordPage()),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Mot de passe oublié ?',
                                      style: TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 18),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _seConnecter,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B5E20),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20, height: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5),
                                          )
                                        : const Text('Se connecter',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Lien inscription
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Pas encore de compte ? ',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterPage()),
                          ),
                          child: const Text('S\'inscrire',
                              style: TextStyle(
                                color: Color(0xFF66BB6A),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Section Partenaires (fixe, hover = agrandit) ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3, height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF66BB6A),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Partenaires officiels',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 64,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: _partenaires.length,
                              itemBuilder: (context, index) {
                                final p = _partenaires[index];
                                return _PartnerBadge(
                                  logo: p['logo'] as String,
                                  nom: p['nom'] as String,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _decoCircle(double size, Color color, double opacity) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: 0.3,
          )),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E8E0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

// ── Widget badge partenaire avec hover ────────────────────────
class _PartnerBadge extends StatefulWidget {
  final String logo;
  final String nom;
  const _PartnerBadge({required this.logo, required this.nom});

  @override
  State<_PartnerBadge> createState() => _PartnerBadgeState();
}

class _PartnerBadgeState extends State<_PartnerBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        transform: _hovered
            ? (Matrix4.identity()..scale(1.08))
            : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: _hovered
              ? Colors.white.withOpacity(0.15)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _hovered
                ? const Color(0xFF66BB6A)
                : Colors.white.withOpacity(0.1),
            width: _hovered ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(3),
              child: Image.asset(widget.logo, fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            Text(
              widget.nom,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}