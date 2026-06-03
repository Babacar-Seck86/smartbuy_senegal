import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Row(
              children: [
                Text('Bonjour, Fatou ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                Text('👋', style: TextStyle(fontSize: 18)),
              ],
            ),
            Text('Dakar, Plateau',
                style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFFF0F0F0),
              radius: 20,
              child: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1A1A), size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit...',
                  hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Color(0xFFAAAAAA)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Catégories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 10),
            Row(
              children: [
                _CategoryChip(label: 'Tout', isSelected: true),
                const SizedBox(width: 8),
                _CategoryChip(label: 'Alimentaire', isSelected: false),
                const SizedBox(width: 8),
                _CategoryChip(label: 'Hygiène', isSelected: false),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Tendances du jour',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _ProductCard(name: 'Riz Parfumé 5kg', price: '2 800 F', shops: '12 commerces', emoji: '🍚')),
                const SizedBox(width: 12),
                Expanded(child: _ProductCard(name: 'Huile Végétale 1L', price: '1 150 F', shops: '8 commerces', emoji: '🛢️')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Près de vous',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 12),
            _ShopNearby(name: 'Auchan Dakar', distance: '1.2 km · Ouvert', rating: 4.5),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _CategoryChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF2E7D32) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFFDDDDDD)),
      ),
      child: Text(label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF555555),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          )),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name, price, shops, emoji;
  const _ProductCard({required this.name, required this.price, required this.shops, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text(price, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
          Text(shops, style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
        ],
      ),
    );
  }
}

class _ShopNearby extends StatelessWidget {
  final String name, distance;
  final double rating;
  const _ShopNearby({required this.name, required this.distance, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.store, color: Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A1A))),
                Text(distance, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (i) => Icon(
              i < rating.floor() ? Icons.star : Icons.star_border,
              size: 14, color: const Color(0xFFFFC107),
            )),
          ),
        ],
      ),
    );
  }
}