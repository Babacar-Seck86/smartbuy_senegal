import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Tout';
  final List<String> _categories = ['Tout', 'Alimentaire', 'Hygiène', 'Boissons', 'Maison'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bannière verte arrondie ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 30),
              decoration: const BoxDecoration(
                color: Color(0xFF1A3C2E),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Bonjour, Fatou 👋',
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Dakar, Plateau',
                              style: TextStyle(color: Color(0xFF8BC34A), fontSize: 13)),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: const Color(0xFF2E5E3E),
                        radius: 22,
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit...',
                        hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF2E7D32)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Catégories DANS la bannière
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final selected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF8BC34A) : const Color(0xFF2E5E3E),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(cat,
                                style: TextStyle(
                                  color: selected ? const Color(0xFF1A3C2E) : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                                )),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(height: 24),

            // ── Tendances du jour ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Tendances du jour',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                  Text('Voir tout', style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32))),
                ],
              ),
            ),
            const SizedBox(height: 14),

            StreamBuilder<QuerySnapshot>(
              stream: _selectedCategory == 'Tout'
                  ? FirebaseFirestore.instance.collection('Produits').snapshots()
                  : FirebaseFirestore.instance
                      .collection('Produits')
                      .where('Catégories', isEqualTo: _selectedCategory)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Aucun produit trouvé',
                          style: TextStyle(color: Color(0xFF888888))),
                    ),
                  );
                }
                final docs = snapshot.data!.docs;
                return SizedBox(
                  height: 220,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _ProductCard(
                        nom: data['nom'] ?? '',
                        prix: data['prixMin']?.toString() ?? '0',
                        nbCommerces: data['nbCommerces']?.toString() ?? '0',
                        imageUrl: data['image'] ?? '',
                        categorie: data['Catégories'] ?? '',
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // ── Près de vous ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('Près de vous',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _ShopNearby(name: 'Auchan Dakar', distance: '1.2 km · Ouvert', rating: 4.5),
                  const SizedBox(height: 10),
                  _ShopNearby(name: 'Marché Sandaga', distance: '2.0 km · Ouvert', rating: 4.0),
                  const SizedBox(height: 10),
                  _ShopNearby(name: 'Casino Supermarché', distance: '3.1 km · Fermé', rating: 3.5),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Card produit arrondie avec image ──
class _ProductCard extends StatelessWidget {
  final String nom, prix, nbCommerces, imageUrl, categorie;
  const _ProductCard({
    required this.nom,
    required this.prix,
    required this.nbCommerces,
    required this.imageUrl,
    required this.categorie,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 165,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image arrondie en haut
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 115,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 115,
                      color: const Color(0xFFE8F5E9),
                      child: const Icon(Icons.image_not_supported,
                          color: Color(0xFF2E7D32), size: 36),
                    ),
                  )
                : Container(
                    height: 115,
                    color: const Color(0xFFE8F5E9),
                    child: const Center(
                      child: Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 36),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (categorie.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(categorie,
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 6),
                Text(nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text('$prix F',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                Text('$nbCommerces commerces',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Commerce proche ──
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store, color: Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A1A))),
                Text(distance,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
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