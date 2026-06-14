import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import '../smartbuy_onboarding.dart';

class AuthWrapper extends StatefulWidget {
  final Widget mainScreen;
  const AuthWrapper({super.key, required this.mainScreen});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _seenOnboarding;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chargement en cours
    if (_seenOnboarding == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 1ère ouverture → Onboarding
    if (!_seenOnboarding!) {
      return const OnboardingScreen();
    }

    // Déjà vu l'onboarding → vérifier connexion Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Connecté → écran principal
        if (snapshot.hasData && snapshot.data != null) {
          return widget.mainScreen;
        }
        // Non connecté → Login
        return const LoginPage();
      },
    );
  }
}