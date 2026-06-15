import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'smartbuy_product_stores.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  String _selectedCategory = 'Tout';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _categories = ['Tout', 'Alimentaire', 'Hygiène', 'Boissons', 'Maison'];
  bool _showSuggestions = false;
  late AnimationController _bannerController;
  late Animation<double> _bannerAnimation;

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _bannerAnimation = CurvedAnimation(parent: _bannerController, curve: Curves.easeOut);
    _bannerController.forward();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      setState(() { _searchQuery = q; _showSuggestions = q.isNotEmpty; });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _buildStream() {
    var ref = FirebaseFirestore.instance.collection('Produits');
    if (_selectedCategory != 'Tout') return ref.where('Catégories', isEqualTo: _selectedCategory).snapshots();
    return ref.snapshots();
  }

  List<QueryDocumentSnapshot> _filterDocs(List<QueryDocumentSnapshot> docs) {
    if (_searchQuery.isEmpty) return docs;
    return docs.where((d) => ((d.data() as Map)['nom'] ?? '').toString().toLowerCase().contains(_searchQuery)).toList();
  }

  void _showProductSheet(Map<String, dynamic> data, String productId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductBottomSheet(data: data, productId: productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: GestureDetector(
        onTap: () => setState(() => _showSuggestions = false),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _bannerAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(_bannerAnimation),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A3C2E),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(36), bottomRight: Radius.circular(36)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                              Text('Bonjour, Fatou 👋', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text('Dakar, Plateau', style: TextStyle(color: Color(0xFF8BC34A), fontSize: 13)),
                            ]),
                            CircleAvatar(
                              backgroundColor: const Color(0xFF2E5E3E),
                              radius: 22,
                              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Barre de recherche ──
                        Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onTap: () { if (_searchController.text.isNotEmpty) setState(() => _showSuggestions = true); },
                                decoration: InputDecoration(
                                  hintText: 'Rechercher un produit...',
                                  hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2E7D32)),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.close, color: Color(0xFFAAAAAA), size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() { _searchQuery = ''; _showSuggestions = false; });
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),

                            // ── Suggestions ──
                            if (_showSuggestions && _searchQuery.isNotEmpty)
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('Produits').snapshots(),
                                builder: (context, snap) {
                                  if (!snap.hasData) return const SizedBox();
                                  final results = snap.data!.docs
                                      .where((d) => ((d.data() as Map)['nom'] ?? '').toString().toLowerCase().contains(_searchQuery))
                                      .take(5).toList();
                                  if (results.isEmpty) return const SizedBox();
                                  return Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
                                    ),
                                    child: Column(
                                      children: results.map((doc) {
                                        final d = doc.data() as Map<String, dynamic>;
                                        return ListTile(
                                          dense: true,
                                          leading: const Icon(Icons.search, color: Color(0xFF2E7D32), size: 18),
                                          title: Text(d['nom'] ?? '', style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
                                          trailing: Text('${d['prixMin'] ?? ''} F', style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                                          onTap: () {
                                            _searchController.text = d['nom'] ?? '';
                                            setState(() { _searchQuery = (d['nom'] ?? '').toLowerCase(); _showSuggestions = false; });
                                            _showProductSheet(d, doc.id);
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Catégories ──
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
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: selected ? const Color(0xFF8BC34A) : const Color(0xFF2E5E3E),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: selected ? [BoxShadow(color: const Color(0xFF8BC34A).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))] : [],
                                  ),
                                  child: Text(cat, style: TextStyle(
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
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Tendances du jour', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                    Text('Voir tout', style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              StreamBuilder<QuerySnapshot>(
                stream: _buildStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: Color(0xFF2E7D32))));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Aucun produit trouvé', style: TextStyle(color: Color(0xFF888888)))));
                  }
                  final docs = _filterDocs(snapshot.data!.docs);
                  if (docs.isEmpty) {
                    return const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('Aucun résultat', style: TextStyle(color: Color(0xFF888888)))));
                  }
                  return SizedBox(
                    height: 240,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        return _HoverProductCard(
                          data: data,
                          onTap: () => _showProductSheet(data, docs[i].id),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Près de vous', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
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
      ),
    );
  }
}

// ── Carte produit avec hover ──
class _HoverProductCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _HoverProductCard({required this.data, required this.onTap});

  @override
  State<_HoverProductCard> createState() => _HoverProductCardState();
}

class _HoverProductCardState extends State<_HoverProductCard> {
  bool _hovered = false;
  OverlayEntry? _overlayEntry;

  void _showOverlay(BuildContext context) {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final d = widget.data;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx - 20,
        top: offset.dy - 180,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 210,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (d['image'] ?? '').isNotEmpty
                        ? Image.network(d['image'], width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _miniPlaceholder())
                        : _miniPlaceholder(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(d['nom'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    Text('${d['prixMin'] ?? '0'} F', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  ])),
                ]),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                const SizedBox(height: 10),
                if ((d['description'] ?? '').isNotEmpty) ...[
                  const Text('Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 3),
                  Text(d['description'], style: const TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                ],
                if ((d['bienfaits'] ?? '').isNotEmpty) ...[
                  const Text('Bienfaits', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 3),
                  Text(d['bienfaits'], style: const TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                ],
                Row(children: [
                  ...List.generate(5, (i) => Icon(
                    i < ((d['note'] ?? 4) as num).floor() ? Icons.star : Icons.star_border,
                    size: 13, color: const Color(0xFFFFC107),
                  )),
                  const SizedBox(width: 6),
                  Text('${d['avis'] ?? '0'} avis', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(Icons.store_outlined, size: 13, color: Color(0xFF888888)),
                  const SizedBox(width: 4),
                  Text('${d['nbCommerces'] ?? '0'} commerces', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: () { _removeOverlay(); widget.onTap(); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A3C2E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0, padding: EdgeInsets.zero,
                    ),
                    child: const Text('Voir où acheter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() { _overlayEntry?.remove(); _overlayEntry = null; }

  Widget _miniPlaceholder() => Container(
    width: 48, height: 48,
    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 22),
  );

  @override
  void dispose() { _removeOverlay(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) { setState(() => _hovered = true); _showOverlay(context); },
      onExit: (_) { setState(() => _hovered = false); _removeOverlay(); },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 165,
          transform: _hovered ? (Matrix4.identity()..scale(1.04)) : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(
              color: _hovered ? const Color(0xFF2E7D32).withOpacity(0.2) : Colors.black.withOpacity(0.06),
              blurRadius: _hovered ? 20 : 10, offset: const Offset(0, 4),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                child: (d['image'] ?? '').isNotEmpty
                    ? Image.network(d['image'], height: 125, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _cardPlaceholder())
                    : _cardPlaceholder(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if ((d['Catégories'] ?? '').isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
                      child: Text(d['Catégories'], style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 6),
                  Text(d['nom'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 4),
                  Text('${d['prixMin'] ?? '0'} F', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                  Text('${d['nbCommerces'] ?? '0'} commerces', style: const TextStyle(fontSize: 11, color: Color(0xFF999999))),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardPlaceholder() => Container(
    height: 125, color: const Color(0xFFE8F5E9),
    child: const Center(child: Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 36)),
  );
}

// ── Bottom Sheet ──
class _ProductBottomSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final String productId;
  const _ProductBottomSheet({required this.data, required this.productId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: (data['image'] ?? '').isNotEmpty
                    ? Image.network(data['image'], width: 72, height: 72, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if ((data['Catégories'] ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
                    child: Text(data['Catégories'], style: const TextStyle(fontSize: 10, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  ),
                const SizedBox(height: 6),
                Text(data['nom'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 4),
                Text('${data['prixMin'] ?? '0'} F', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                Text('· ${data['nbCommerces'] ?? '0'} commerces', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
              ])),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          if ((data['description'] ?? '').isNotEmpty) ...[
            _sectionTitle('Description'),
            const SizedBox(height: 6),
            Text(data['description'], style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5)),
            const SizedBox(height: 14),
          ] else ...[
            _sectionTitle('Description'),
            const SizedBox(height: 6),
            const Text('Produit disponible dans plusieurs commerces à Dakar.',
                style: TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5)),
            const SizedBox(height: 14),
          ],
          if ((data['bienfaits'] ?? '').isNotEmpty) ...[
            _sectionTitle('Bienfaits'),
            const SizedBox(height: 6),
            Text(data['bienfaits'], style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5)),
            const SizedBox(height: 14),
          ],
          _sectionTitle('Avis clients'),
          const SizedBox(height: 8),
          Row(children: [
            ...List.generate(5, (i) => Icon(
              i < ((data['note'] ?? 4) as num).floor() ? Icons.star : Icons.star_border,
              size: 18, color: const Color(0xFFFFC107),
            )),
            const SizedBox(width: 8),
            Text('${data['note'] ?? '4'}/5', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
            const SizedBox(width: 6),
            Text('(${data['avis'] ?? '0'} avis)', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductStoresPage(
                      productId: productId,
                      productData: data,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.location_on_outlined, size: 18),
              label: const Text('Voir où acheter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3C2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
    child: const Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 30),
  );

  Widget _sectionTitle(String title) =>
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)));
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(width: 46, height: 46,
            decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.store, color: Color(0xFF2E7D32), size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A1A))),
          Text(distance, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
        ])),
        Row(children: List.generate(5, (i) => Icon(
          i < rating.floor() ? Icons.star : Icons.star_border,
          size: 14, color: const Color(0xFFFFC107),
        ))),
      ]),
    );
  }
}