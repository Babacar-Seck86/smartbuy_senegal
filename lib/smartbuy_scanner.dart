import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ─────────────────────────────────────────────
// ÉCRAN SCANNER (caméra réelle + lecture Firestore)
// ─────────────────────────────────────────────
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Scanner un produit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Zone de scan
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Viewfinder (aperçu statique, la vraie caméra s'ouvre au clic)
                          GestureDetector(
                            onTap: () => _openCameraScanner(context),
                            child: Container(
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
                                      width: 160,
                                      height: 2,
                                      color: const Color(0xFF2E7D32),
                                    ),
                                  ),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(height: 10),
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Color(0xFF666666),
                                        size: 28,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Touchez pour ouvrir la caméra',
                                        style: TextStyle(
                                          color: Color(0xFF888888),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Boutons Scanner / Recherche manuelle
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openCameraScanner(context),
                                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                                  label: const Text('Scanner le code-barres'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openManualSearch(context),
                                  icon: const Icon(Icons.search, size: 18),
                                  label: const Text('Rechercher'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2E7D32),
                                    side: const BorderSide(color: Color(0xFF2E7D32)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Produits disponibles (lus depuis Firestore, plus de données fictives)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Produits disponibles',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 10),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('Produits')
                                .limit(8)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                                  ),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    'Aucun produit enregistré pour le moment',
                                    style: TextStyle(color: Color(0xFF888888)),
                                  ),
                                );
                              }
                              return Column(
                                children: snapshot.data!.docs.map((doc) {
                                  final d = doc.data() as Map<String, dynamic>;
                                  return _RecentScanItem(
                                    name: d['nom'] ?? '',
                                    price: '${d['prixMin'] ?? '0'} F',
                                    shops: '${d['nbCommerces'] ?? '0'} commerces',
                                    imageUrl: d['image'] ?? '',
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ResultsScreen(
                                          productId: doc.id,
                                          productData: d,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
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

  // ── Ouvre la vraie caméra pour scanner un code-barres ──
  Future<void> _openCameraScanner(BuildContext context) async {
    final String? code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _BarcodeScannerPage()),
    );

    if (code == null || !context.mounted) return;

    // Cherche le produit dans Firestore par champ 'codeBarre'
    final query = await FirebaseFirestore.instance
        .collection('Produits')
        .where('codeBarre', isEqualTo: code)
        .limit(1)
        .get();

    if (!context.mounted) return;

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            productId: doc.id,
            productData: doc.data(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucun produit trouvé pour le code $code'),
          backgroundColor: const Color(0xFFB00020),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ── Recherche manuelle par nom si le produit n'a pas de code-barres scanné ──
  Future<void> _openManualSearch(BuildContext context) async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rechercher un produit',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nom du produit...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                filled: true,
                fillColor: const Color(0xFFF5F7F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => _searchAndNavigate(context, value),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => _searchAndNavigate(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Rechercher'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchAndNavigate(BuildContext context, String value) async {
    final q = value.trim().toLowerCase();
    if (q.isEmpty) return;

    final snap = await FirebaseFirestore.instance.collection('Produits').get();
    final match = snap.docs.where((d) =>
        ((d.data())['nom'] ?? '').toString().toLowerCase().contains(q));

    if (!context.mounted) return;
    Navigator.pop(context); // ferme le bottom sheet

    if (match.isNotEmpty) {
      final doc = match.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(productId: doc.id, productData: doc.data()),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucun produit trouvé pour "$value"'),
          backgroundColor: const Color(0xFFB00020),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
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

// ─────────────────────────────────────────────
// PAGE CAMÉRA RÉELLE (mobile_scanner)
// ─────────────────────────────────────────────
class _BarcodeScannerPage extends StatefulWidget {
  const _BarcodeScannerPage();

  @override
  State<_BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<_BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final value = barcodes.first.rawValue;
    if (value == null) return;
    _handled = true;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scanner le code-barres', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Cadre visuel de visée
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2E7D32), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            bottom: 40, left: 0, right: 0,
            child: Text(
              'Centrez le code-barres dans le cadre',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PAGE DE RÉSULTATS (COMPARAISON RÉELLE depuis Firestore)
// ─────────────────────────────────────────────
class ResultsScreen extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ResultsScreen({
    super.key,
    required this.productId,
    required this.productData,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int _sortIndex = 0; // 0=Prix, 1=Distance, 2=Avis

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                      child: Text(
                        'Comparaison',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Produits')
                    .doc(widget.productId)
                    .collection('commerces')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
                  }

                  final commerceDocs = snapshot.data?.docs ?? [];
                  final results = commerceDocs.map((d) {
                    final m = d.data() as Map<String, dynamic>;
                    return {
                      'name': m['nom'] ?? m['Nom'] ?? '',
                      'price': (m['prix'] is num) ? (m['prix'] as num).toInt() : 0,
                      'distanceLabel': m['distance'] ?? m['Distance'] ?? '',
                      'rating': (m['avis'] is num) ? (m['avis'] as num).round() : 0,
                      'stock': m['stock'] ?? 'En stock',
                    };
                  }).toList();

                  final sorted = List<Map<String, dynamic>>.from(results);
                  if (_sortIndex == 0) {
                    sorted.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int));
                  } else if (_sortIndex == 2) {
                    sorted.sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));
                  }
                  // distance reste dans l'ordre Firestore car stockée en texte (ex: "1.2 km")

                  final prixMin = sorted.isNotEmpty
                      ? sorted.map((e) => e['price'] as int).reduce((a, b) => a < b ? a : b)
                      : (widget.productData['prixMin'] ?? 0);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Carte produit résumé (vraies données du produit scanné)
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
                                child: (widget.productData['image'] ?? '').isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          widget.productData['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                              Icons.shopping_bag, color: Color(0xFF2E7D32)),
                                        ),
                                      )
                                    : const Icon(Icons.shopping_bag, color: Color(0xFF2E7D32)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.productData['nom'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      'Trouvé dans ${sorted.length} commerce${sorted.length > 1 ? 's' : ''}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Meilleur prix : $prixMin F',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        if (sorted.isNotEmpty) ...[
                          // Filtres de tri
                          Row(
                            children: [
                              _SortChip(label: 'Prix', isSelected: _sortIndex == 0,
                                  onTap: () => setState(() => _sortIndex = 0)),
                              const SizedBox(width: 8),
                              _SortChip(label: 'Distance', isSelected: _sortIndex == 1,
                                  onTap: () => setState(() => _sortIndex = 1)),
                              const SizedBox(width: 8),
                              _SortChip(label: 'Avis ★', isSelected: _sortIndex == 2,
                                  onTap: () => setState(() => _sortIndex = 2)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Liste des commerces réels
                          ...sorted.asMap().entries.map((entry) {
                            final i = entry.key;
                            final shop = entry.value;
                            return _ShopResultItem(
                              rank: i + 1,
                              name: shop['name'],
                              price: shop['price'],
                              distanceLabel: shop['distanceLabel'],
                              rating: shop['rating'],
                              stock: shop['stock'],
                              isBest: i == 0,
                            );
                          }),
                        ] else
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(Icons.store_outlined, size: 48, color: Color(0xFFBBBBBB)),
                                SizedBox(height: 12),
                                Text(
                                  'Aucun commerce enregistré pour ce produit',
                                  style: TextStyle(color: Color(0xFF888888)),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(1),
    );
  }
}

// ─── Widgets Helper ─────────────────────────
class _RecentScanItem extends StatelessWidget {
  final String name, price, shops, imageUrl;
  final VoidCallback onTap;
  const _RecentScanItem({
    required this.name,
    required this.price,
    required this.shops,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 44, height: 44, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _placeholder(),
                    )
                  : _placeholder(),
            ),
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
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF888888)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 44, height: 44,
    color: const Color(0xFFE8F5E9),
    child: const Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 20),
  );
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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF555555),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ShopResultItem extends StatelessWidget {
  final int rank;
  final String name;
  final int price;
  final String distanceLabel;
  final int rating;
  final String stock;
  final bool isBest;

  const _ShopResultItem({
    required this.rank,
    required this.name,
    required this.price,
    required this.distanceLabel,
    required this.rating,
    required this.stock,
    required this.isBest,
  });

  Color get _dotColor {
    if (isBest) return const Color(0xFF2E7D32);
    const palette = [Color(0xFFF57C00), Color(0xFF1565C0), Color(0xFF6A1B9A), Color(0xFF757575)];
    return palette[(rank - 1) % palette.length];
  }

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
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
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
                    if (distanceLabel.isNotEmpty)
                      Text('$distanceLabel · ', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                    ...List.generate(
                      rating.clamp(0, 5),
                      (_) => const Icon(Icons.star, size: 11, color: Color(0xFFFFC107)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(stock,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stock.toLowerCase() == 'en stock'
                          ? const Color(0xFF2E7D32)
                          : stock.toLowerCase() == 'rupture de stock'
                              ? const Color(0xFFB00020)
                              : const Color(0xFFFF8F00),
                    )),
              ],
            ),
          ),
          Text(
            '$price F',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isBest ? const Color(0xFF2E7D32) : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Nav partagé ──────────────────────
BottomNavigationBar _buildBottomNav(int currentIndex) {
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: const Color(0xFF2E7D32),
    unselectedItemColor: const Color(0xFF999999),
    selectedLabelStyle: const TextStyle(fontSize: 11),
    unselectedLabelStyle: const TextStyle(fontSize: 11),
    currentIndex: currentIndex,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
      BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_outlined), activeIcon: Icon(Icons.qr_code_scanner), label: 'Scanner'),
      BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Carte'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
    ],
  );
}