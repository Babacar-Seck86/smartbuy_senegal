import 'package:flutter/material.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  static const List<Map<String, String>> _recentScans = [
    {'name': 'Tomates en conserve', 'price': '650 F', 'shops': '5 points de vente', 'emoji': '🥫'},
    {'name': 'Savon Lux 125g', 'price': '420 F', 'shops': '9 points de vente', 'emoji': '🧴'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Scanner un produit',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 220,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ..._buildScanCorners(),
                                Positioned(
                                  child: Container(
                                    width: 160, height: 2,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 10),
                                    Icon(Icons.camera_alt_outlined, color: Color(0xFF666666), size: 28),
                                    SizedBox(height: 8),
                                    Text('Cadrez le produit ou le code-barres',
                                        style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => const ResultsScreen()));
                                  },
                                  icon: const Icon(Icons.camera_alt, size: 18),
                                  label: const Text('Prendre une photo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.photo_library, size: 18),
                                  label: const Text('Galerie'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E7D32),
                                    side: const BorderSide(color: Color(0xFF2E7D32)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Scans récents',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 10),
                          ..._recentScans.map((item) => _RecentScanItem(
                            name: item['name']!,
                            price: item['price']!,
                            shops: item['shops']!,
                            emoji: item['emoji']!,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _buildScanCorners() {
    const size = 30.0;
    const thickness = 3.0;
    const color = Color(0xFF2E7D32);
    const offset = 30.0;
    return [
      Positioned(top: offset, left: offset, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: offset, left: offset, child: Container(width: thickness, height: size, color: color)),
      Positioned(top: offset, right: offset, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: offset, right: offset, child: Container(width: thickness, height: size, color: color)),
      Positioned(bottom: offset, left: offset, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: offset, left: offset, child: Container(width: thickness, height: size, color: color)),
      Positioned(bottom: offset, right: offset, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: offset, right: offset, child: Container(width: thickness, height: size, color: color)),
    ];
  }
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _sortIndex = 0;

  final List<Map<String, dynamic>> _results = [
    {'name': 'Marché Sandaga', 'price': 2500, 'distance': 0.8, 'rating': 4, 'color': const Color(0xFFF57C00)},
    {'name': 'Casino Supermarché', 'price': 2750, 'distance': 1.4, 'rating': 4, 'color': const Color(0xFF2E7D32)},
    {'name': 'Auchan Dakar', 'price': 2800, 'distance': 1.9, 'rating': 3, 'color': const Color(0xFF1565C0)},
    {'name': 'Boutique Médina', 'price': 2900, 'distance': 2.3, 'rating': 2, 'color': const Color(0xFF757575)},
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = List<Map<String, dynamic>>.from(_results);
    if (_sortIndex == 0) sorted.sort((a, b) => a['price'] - b['price']);
    if (_sortIndex == 1) sorted.sort((a, b) => a['distance'].compareTo(b['distance']));
    if (_sortIndex == 2) sorted.sort((a, b) => b['rating'] - a['rating']);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Row(
                      children: [
                        Icon(Icons.arrow_back_ios, size: 16, color: Color(0xFF2E7D32)),
                        Text('Retour', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 14)),
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text('Comparaison',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEEEEE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('🍚', style: TextStyle(fontSize: 26), textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Riz Parfumé 5kg',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Trouvé dans 12 commerces',
                                    style: TextStyle(fontSize: 12, color: Color(0xFF888888))),
                                SizedBox(height: 4),
                                Text('Meilleur prix : 2 500 F',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _SortChip(label: 'Prix', isSelected: _sortIndex == 0, onTap: () => setState(() => _sortIndex = 0)),
                        const SizedBox(width: 8),
                        _SortChip(label: 'Distance', isSelected: _sortIndex == 1, onTap: () => setState(() => _sortIndex = 1)),
                        const SizedBox(width: 8),
                        _SortChip(label: 'Avis ★', isSelected: _sortIndex == 2, onTap: () => setState(() => _sortIndex = 2)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...sorted.asMap().entries.map((entry) {
                      final i = entry.key;
                      final shop = entry.value;
                      return _ShopResultItem(
                        rank: i + 1,
                        name: shop['name'],
                        price: shop['price'],
                        distance: shop['distance'],
                        rating: shop['rating'],
                        dotColor: shop['color'],
                        isBest: i == 0,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentScanItem extends StatelessWidget {
  final String name, price, shops, emoji;
  const _RecentScanItem({required this.name, required this.price, required this.shops, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(shops, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2E7D32))),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _SortChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1A1A1A) : const Color(0xFFDDDDDD)),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF555555),
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
      ),
    );
  }
}

class _ShopResultItem extends StatelessWidget {
  final int rank, price, rating;
  final String name;
  final double distance;
  final Color dotColor;
  final bool isBest;

  const _ShopResultItem({
    required this.rank,
    required this.name,
    required this.price,
    required this.distance,
    required this.rating,
    required this.dotColor,
    required this.isBest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBest ? const Color(0xFF2E7D32) : const Color(0xFFEEEEEE),
          width: isBest ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            child: Center(
              child: Text('$rank',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Row(
                  children: [
                    Text('${distance.toStringAsFixed(1)} km · ',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                    ...List.generate(rating,
                        (_) => const Icon(Icons.star, size: 11, color: Color(0xFFFFC107))),
                  ],
                ),
              ],
            ),
          ),
          Text('$price F',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isBest ? const Color(0xFF2E7D32) : const Color(0xFF1A1A1A),
              )),
        ],
      ),
    );
  }
}