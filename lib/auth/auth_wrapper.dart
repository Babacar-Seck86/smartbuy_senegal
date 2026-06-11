
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';

class AuthWrapper extends StatelessWidget {
  final Widget mainScreen;
  const AuthWrapper({super.key, required this.mainScreen});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Connecté → écran principal
        if (snapshot.hasData && snapshot.data != null) {
          return mainScreen;
        }

        // Non connecté ou en attente → page de connexion
        return const LoginPage();
      },
    );
  }
}