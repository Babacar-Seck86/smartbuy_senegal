import 'package:flutter/material.dart';
import 'smartbuy_main_nav.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Achetez malin, payez moins',
      'desc': 'Scannez n\'importe quel produit et comparez instantanément les prix dans tous les commerces près de chez vous.',
    },
    {
      'title': 'Trouvez les meilleures offres',
      'desc': 'Accédez aux prix en temps réel dans les marchés, supermarchés et boutiques de votre quartier.',
    },
    {
      'title': 'Économisez chaque jour',
      'desc': 'Suivez vos économies et découvrez les tendances du jour pour toujours payer le meilleur prix.',
    },
  ];

  void _goToApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: const Color(0xFF1A3C2E),
            height: MediaQuery.of(context).size.height * 0.55,
            width: double.infinity,
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Text('SmartBuy',
                    style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                const Text('Sénégal',
                    style: TextStyle(color: Color(0xFF8BC34A), fontSize: 16, letterSpacing: 2)),
                const SizedBox(height: 40),
                SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 60,
                        child: Container(
                          width: 80, height: 80,
                          decoration: const BoxDecoration(color: Color(0xFF2E5E3E), shape: BoxShape.circle),
                        ),
                      ),
                      Container(
                        width: 60, height: 60,
                        decoration: const BoxDecoration(color: Color(0xFF3D7A50), shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_pages[_currentPage]['title']!,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 16),
                          Text(_pages[_currentPage]['desc']!,
                              style: const TextStyle(fontSize: 15, color: Color(0xFF666666), height: 1.5)),
                          const SizedBox(height: 30),
                          Row(
                            children: List.generate(3, (i) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: i == _currentPage ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _currentPage ? const Color(0xFF2E7D32) : const Color(0xFFCCCCCC),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_currentPage < 2) {
                                  setState(() => _currentPage++);
                                } else {
                                  _goToApp();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: Text(
                                _currentPage < 2 ? 'Suivant' : 'Commencer',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: _goToApp,
                              child: const Text('J\'ai déjà un compte',
                                  style: TextStyle(color: Color(0xFF555555), fontSize: 14)),
                            ),
                          ),
                        ],
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