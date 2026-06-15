import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductStoresPage extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ProductStoresPage({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: CustomScrollView(
        slivers: [
          // ── App Bar avec image produit ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1A3C2E),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if ((productData['image'] ?? '').isNotEmpty)
                    Image.network(
                      productData['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A3C2E)),
                    )
                  else
                    Container(color: const Color(0xFF1A3C2E)),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC1A3C2E)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((productData['Catégories'] ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8BC34A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              productData['Catégories'],
                              style: const TextStyle(fontSize: 10, color: Color(0xFF1A3C2E), fontWeight: FontWeight.w700),
                            ),
                          ),
                        const SizedBox(height: 6),
                        Text(
                          productData['nom'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'À partir de ${productData['prixMin'] ?? '0'} F',
                          style: const TextStyle(color: Color(0xFF8BC34A), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Contenu ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((productData['description'] ?? '').isNotEmpty) ...[
                    const _SectionTitle(title: 'Description'),
                    const SizedBox(height: 8),
                    Text(
                      productData['description'],
                      style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if ((productData['bienfaits'] ?? '').isNotEmpty) ...[
                    const _SectionTitle(title: 'Bienfaits'),
                    const SizedBox(height: 8),
                    Text(
                      productData['bienfaits'],
                      style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const _SectionTitle(title: 'Disponible dans ces commerces'),
                  const SizedBox(height: 4),
                  const Text(
                    'Prix et stock en temps réel',
                    style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),

          // ── Liste des commerces ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Produits')
                .doc(productId)
                .collection('commerces')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverToBoxAdapter(child: _EmptyStores());
              }

              final docs = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final store = docs[i].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: _StoreCard(store: store),
                    );
                  },
                  childCount: docs.length,
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

// ── Carte commerce ──
class _StoreCard extends StatefulWidget {
  final Map<String, dynamic> store;
  const _StoreCard({required this.store});

  @override
  State<_StoreCard> createState() => _StoreCardState();
}

class _StoreCardState extends State<_StoreCard> {
  bool _loadingItinerary = false;

  Color _stockColor(String stock) {
    switch (stock.toLowerCase()) {
      case 'en stock': return const Color(0xFF2E7D32);
      case 'stock limité': return const Color(0xFFFF8F00);
      case 'rupture de stock': return const Color(0xFFB00020);
      default: return const Color(0xFF888888);
    }
  }

  IconData _stockIcon(String stock) {
    switch (stock.toLowerCase()) {
      case 'en stock': return Icons.check_circle_outline;
      case 'stock limité': return Icons.warning_amber_outlined;
      case 'rupture de stock': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  /// Demande la permission GPS, récupère la position, puis ouvre Google Maps
  Future<void> _openItinerary() async {
    setState(() => _loadingItinerary = true);

    try {
      // 1. Vérifier si le service GPS est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Le GPS est désactivé. Activez-le dans vos paramètres.');
        return;
      }

      // 2. Vérifier / demander la permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permission de localisation refusée.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Permission refusée définitivement. Allez dans les paramètres de l\'app.');
        return;
      }

      // 3. Récupérer la position actuelle
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // 4. Récupérer les coordonnées du commerce depuis Firestore
      final storeLat = widget.store['lat'];
      final storeLng = widget.store['lng'];

      if (storeLat == null || storeLng == null) {
        // Pas de coordonnées → recherche par nom dans Google Maps
        final storeName = Uri.encodeComponent(widget.store['nom'] ?? '');
        final url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
          '&origin=${position.latitude},${position.longitude}'
          '&destination=$storeName'
          '&travelmode=driving',
        );
        await _launch(url);
        return;
      }

      // 5. Ouvrir Google Maps avec l'itinéraire exact
      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${position.latitude},${position.longitude}'
        '&destination=$storeLat,$storeLng'
        '&travelmode=driving',
      );
      await _launch(url);
    } catch (e) {
      _showError('Impossible d\'obtenir votre position. Réessayez.');
    } finally {
      if (mounted) setState(() => _loadingItinerary = false);
    }
  }

  Future<void> _launch(Uri url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showError('Impossible d\'ouvrir Google Maps.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB00020),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final stock = store['stock'] ?? 'En stock';
    final stockColor = _stockColor(stock);
    final avis = (store['avis'] ?? 0.0) as num;
    final nbAvis = store['nbAvis'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_mall_directory_rounded, color: Color(0xFF2E7D32), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store['nom'] ?? '',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                    ),
                    if ((store['adresse'] ?? '').isNotEmpty)
                      Text(
                        store['adresse'],
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${store['prix'] ?? '0'} F',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                  ),
                  const Text('par unité', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),

          // ── Stock + avis ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_stockIcon(stock), size: 13, color: stockColor),
                    const SizedBox(width: 4),
                    Text(stock, style: TextStyle(fontSize: 11, color: stockColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  ...List.generate(5, (i) => Icon(
                    i < avis.floor()
                        ? Icons.star
                        : (i < avis ? Icons.star_half : Icons.star_border),
                    size: 14, color: const Color(0xFFFFC107),
                  )),
                  const SizedBox(width: 4),
                  Text('$avis ($nbAvis)', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                ],
              ),
            ],
          ),

          // ── Distance ──
          if ((store['distance'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF888888)),
                const SizedBox(width: 4),
                Text(
                  '${store['distance']} km',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ── Bouton Itinéraire ──
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _loadingItinerary ? null : _openItinerary,
              icon: _loadingItinerary
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF1A3C2E),
                      ),
                    )
                  : const Icon(Icons.directions_outlined, size: 16),
              label: Text(
                _loadingItinerary ? 'Localisation...' : "Obtenir l'itinéraire",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1A3C2E),
                side: const BorderSide(color: Color(0xFF1A3C2E), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── État vide ──
class _EmptyStores extends StatelessWidget {
  const _EmptyStores();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
              child: const Icon(Icons.store_outlined, color: Color(0xFF2E7D32), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucun commerce enregistré',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ce produit n\'est pas encore disponible dans nos commerces partenaires.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF888888), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Titre de section ──
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3, height: 16,
          decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
      ],
    );
  }
}