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
      title: 'SmartBuy Senegal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D52)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/':        (_) => const SmartBuyOnboarding(),
        '/scanner': (_) => const SmartBuyScanner(),
        '/map':     (_) => const SmartBuyProductMap(),
      },
    );
  }
}
