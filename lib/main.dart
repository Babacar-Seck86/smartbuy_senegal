import 'package:flutter/material.dart';

import 'smartbuy_onboarding.dart';
import 'smartbuy_scanner.dart';
import 'smartbuy_product_map.dart';

void main() {
  runApp(const SmartBuyApp());
}

class SmartBuyApp extends StatelessWidget {
  const SmartBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartBuy Sénégal',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A3C2E),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),

      // Première page affichée
      home: const OnboardingScreen(),

      // Navigation entre les pages
      routes: {
        '/scanner': (context) => const ScannerScreen(),
        '/map': (context) => const ProductDetailsScreen(),
      },
    );
  }
}
