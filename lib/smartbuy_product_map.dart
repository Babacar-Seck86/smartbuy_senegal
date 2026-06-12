import 'package:flutter/material.dart';

// Constantes partagées pour la cohérence visuelle
class SmartBuyColors {
  static const Color green = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color orange = Color(0xFFFFB800);
  static const Color lightGrey = Color(0xFFF5F7F5);
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey = Color(0xFF666666);
}

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartBuyColors.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: SmartBuyColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Analyse du Produit",
          style: TextStyle(
            color: SmartBuyColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: SmartBuyColors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Produit
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      color: SmartBuyColors.lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text("🍚", style: TextStyle(fontSize: 80)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Riz Brisé Local 25kg",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Catégorie : Alimentaire",
                    style: TextStyle(color: SmartBuyColors.grey),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "8 500 FCFA",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: SmartBuyColors.green,
                    ),
                  ),
                  const Text(
                    "Prix le plus bas détecté",
                    style: TextStyle(color: SmartBuyColors.green, fontSize: 12),
                  ),
                ],
              ),
            ),

            // 2. Section Statistiques (Inspiré des Trends du Membre 1)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem("12", "Commerces", Icons.store_mall_directory),
                  _buildStatItem("2 500 F", "Écart Max", Icons.swap_vert),
                  _buildStatItem("4.5/5", "Avis", Icons.star_rounded),
                ],
              ),
            ),

            // 3. Liste de comparaison détaillée (Inspiré des résultats du Membre 2)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Comparatif par enseigne",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRow(
                    "Auchan Dakar",
                    "8 500 F",
                    "Le moins cher",
                    true,
                  ),
                  const Divider(),
                  _buildPriceRow(
                    "CityDia Plateau",
                    "8 900 F",
                    "Bon prix",
                    false,
                  ),
                  const Divider(),
                  _buildPriceRow("Exclusive", "9 200 F", "Moyen", false),
                  const Divider(),
                  _buildPriceRow("Boutique Walo", "11 000 F", "Élevé", false),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Bouton d'action principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SmartBuyColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Ajouter à ma liste de courses",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget Helper pour les statistiques
  Widget _buildStatItem(String value, String label, IconData icon) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, color: SmartBuyColors.green, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            label,
            style: const TextStyle(color: SmartBuyColors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Widget Helper pour les lignes du tableau de prix
  Widget _buildPriceRow(String shop, String price, String tag, bool isBest) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shop, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isBest
                        ? SmartBuyColors.orange
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      color: isBest ? Colors.white : SmartBuyColors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isBest ? SmartBuyColors.green : SmartBuyColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
