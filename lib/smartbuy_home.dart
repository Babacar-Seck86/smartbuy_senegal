import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'smartbuy_product_stores.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String _selectedCategory = 'Tout';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _showSuggestions = false;
  String _prenom = '';
  final String _localisation = 'Dakar, Sénégal';

  AnimationController? _headerController;
  AnimationController? _pulseController;
  Animation<double>? _headerAnim;
  Animation<double>? _pulseAnim;

  // Compte à rebours offres flash
  int _flashSeconds = 3600;
  Timer? _flashTimer;

  final List<String> _categories = ['Tout', 'Alimentaire', 'Hygiène', 'Boissons', 'Maison', 'Électronique'];

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pulseController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _headerAnim = CurvedAnimation(parent: _headerController!, curve: Curves.easeOut);
    _pulseAnim  = CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut);
    _headerController!.forward();
    _searchController.addListener(() {
      final q = _searchController.text.trim().toLowerCase();
      setState(() { _searchQuery = q; _showSuggestions = q.isNotEmpty; });
    });
    _loadUserData();
    _flashTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _flashSeconds > 0) setState(() => _flashSeconds--);
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final nom = (doc.data()?['nom'] ?? '').toString().trim();
        if (nom.isNotEmpty) setState(() => _prenom = nom.split(' ').first);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerController?.dispose();
    _pulseController?.dispose();
    _flashTimer?.cancel();
    super.dispose();
  }

  String get _flashTime {
    final h = _flashSeconds ~/ 3600;
    final m = (_flashSeconds % 3600) ~/ 60;
    final s = _flashSeconds % 60;
    return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  Stream<QuerySnapshot> _buildStream() {
    final ref = FirebaseFirestore.instance.collection('Produits');
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
    final greeting = _prenom.isNotEmpty ? 'Bonjour, $_prenom 👋' : 'Bonjour 👋';
    final anim = _headerAnim ?? const AlwaysStoppedAnimation(1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      body: GestureDetector(
        onTap: () => setState(() => _showSuggestions = false),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ══ HEADER ══
              FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, -0.08), end: Offset.zero).animate(anim),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D2B1E), Color(0xFF1A3C2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(greeting, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.location_on_rounded, color: Color(0xFF8BC34A), size: 13),
                                const SizedBox(width: 3),
                                Text(_localisation, style: const TextStyle(color: Color(0xFF8BC34A), fontSize: 12)),
                              ]),
                            ]),
                            Stack(children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF2E5E3E),
                                radius: 22,
                                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                              ),
                              Positioned(right: 2, top: 2,
                                child: Container(width: 8, height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFF8BC34A), shape: BoxShape.circle)),
                              ),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Recherche
                        Column(children: [
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
                                    ? IconButton(icon: const Icon(Icons.close, color: Color(0xFFAAAAAA), size: 18),
                                        onPressed: () { _searchController.clear(); setState(() { _searchQuery = ''; _showSuggestions = false; }); })
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
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
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)]),
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
                        ]),
                        const SizedBox(height: 18),

                        // Catégories pills
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

              // ══ PRODUITS (scroll horizontal - inchangé) ══
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(
                    _selectedCategory == 'Tout' ? 'Tendances du jour' : _selectedCategory,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                  const Text('Voir tout', style: TextStyle(fontSize: 13, color: Color(0xFF2E7D32))),
                ]),
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

              const SizedBox(height: 28),

              // ══ OFFRES FLASH ══
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6F00), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFFFF6F00).withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: Row(children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 4),
                        Text('Offres Flash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                      const SizedBox(height: 4),
                      const Text('Jusqu\'à -25% sur\nles produits du jour', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                    ]),
                    const Spacer(),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      const Text('Se termine dans', style: TextStyle(color: Colors.white60, fontSize: 10)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Text(_flashTime,
                          style: const TextStyle(color: Color(0xFFFF6F00), fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'monospace')),
                      ),
                    ]),
                  ]),
                ),
              ),

              const SizedBox(height: 28),

              // ══ PARTENAIRES ANIMÉS ══
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('Nos partenaires', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                ]),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 70,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _PartnerCard(name: 'Auchan',    emoji: '🛒', color: const Color(0xFFE53935), url: 'https://www.auchan.sn'),
                    _PartnerCard(name: 'Jumia',     emoji: '📦', color: const Color(0xFFE65100), url: 'https://www.jumia.sn'),
                    _PartnerCard(name: 'Casino',    emoji: '🏪', color: const Color(0xFF1565C0), url: 'https://maps.google.com/?q=Casino+Supermarché+Dakar'),
                    _PartnerCard(name: 'Exclusive', emoji: '✨', color: const Color(0xFF6A1B9A), url: 'https://maps.google.com/?q=Exclusive+Almadies+Dakar'),
                    _PartnerCard(name: 'Score',     emoji: '🏬', color: const Color(0xFF00695C), url: 'https://maps.google.com/?q=Score+Dakar'),
                    _PartnerCard(name: 'Sandaga',   emoji: '🏛', color: const Color(0xFF558B2F), url: 'https://maps.google.com/?q=Marché+Sandaga+Dakar'),
                    _PartnerCard(name: 'Carrefour', emoji: '🛍', color: const Color(0xFF1A237E), url: 'https://maps.google.com/?q=Carrefour+Dakar'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ══ CONSEILS & ASTUCES ══
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('Conseils malins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                ]),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 120,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _TipCard(emoji: '💡', title: 'Comparez avant d\'acheter', subtitle: 'Jusqu\'à 30% d\'économie\npar semaine', color: Color(0xFF1A3C2E)),
                    _TipCard(emoji: '📍', title: 'Commerce le plus proche', subtitle: 'Trouvez où acheter\nen moins de 2 min', color: Color(0xFF1565C0)),
                    _TipCard(emoji: '⭐', title: 'Produits les mieux notés', subtitle: 'Choix validés par\nla communauté', color: Color(0xFF6A1B9A)),
                    _TipCard(emoji: '🔔', title: 'Alertes de prix', subtitle: 'Soyez notifié quand\nun prix baisse', color: Color(0xFFBF360C)),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ══ COMMERCES PROCHES ══
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFF2E7D32), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('Près de vous', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _ShopNearby(name: 'Auchan Dakar',       distance: '1.2 km', status: 'Ouvert', rating: 4.5, badge: 'Partenaire', url: 'https://www.auchan.sn'),
                  const SizedBox(height: 10),
                  _ShopNearby(name: 'Marché Sandaga',     distance: '2.0 km', status: 'Ouvert', rating: 4.0, badge: null,          url: 'https://maps.google.com/?q=Marché+Sandaga+Dakar'),
                  const SizedBox(height: 10),
                  _ShopNearby(name: 'Casino Supermarché', distance: '3.1 km', status: 'Fermé',  rating: 3.5, badge: 'Partenaire', url: 'https://maps.google.com/?q=Casino+Supermarché+Dakar'),
                  const SizedBox(height: 10),
                  _ShopNearby(name: 'Jumia Dakar',        distance: '3.8 km', status: 'En ligne', rating: 4.3, badge: 'En ligne', url: 'https://www.jumia.sn'),
                ]),
              ),

              const SizedBox(height: 32),

              // ══ FOOTER BLANC ══
              const _Footer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Carte produit scroll horizontal (INCHANGÉE) ──
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
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
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
              Row(children: [
                ...List.generate(5, (i) => Icon(i < ((d['note'] ?? 4) as num).floor() ? Icons.star : Icons.star_border, size: 13, color: const Color(0xFFFFC107))),
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
                width: double.infinity, height: 36,
                child: ElevatedButton(
                  onPressed: () { _removeOverlay(); widget.onTap(); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3C2E), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, padding: EdgeInsets.zero),
                  child: const Text('Voir où acheter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() { _overlayEntry?.remove(); _overlayEntry = null; }
  Widget _miniPlaceholder() => Container(width: 48, height: 48,
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(10)),
      child: const Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 22));

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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          ]),
        ),
      ),
    );
  }

  Widget _cardPlaceholder() => Container(height: 125, color: const Color(0xFFE8F5E9),
      child: const Center(child: Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 36)));
}

// ── Carte partenaire animée ──
class _PartnerCard extends StatefulWidget {
  final String name, emoji, url;
  final Color color;
  const _PartnerCard({required this.name, required this.emoji, required this.color, required this.url});

  @override
  State<_PartnerCard> createState() => _PartnerCardState();
}

class _PartnerCardState extends State<_PartnerCard> with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
  }

  @override
  void dispose() { _ctrl?.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) async {
        setState(() => _pressed = false);
        final uri = Uri.parse(widget.url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        transform: _pressed ? (Matrix4.identity()..scale(0.95)) : Matrix4.identity(),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.color.withOpacity(0.2), width: 1.5),
          boxShadow: _pressed ? [] : [BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(widget.name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.color)),
        ]),
      ),
    );
  }
}

// ── Carte conseil ──
class _TipCard extends StatelessWidget {
  final String emoji, title, subtitle;
  final Color color;
  const _TipCard({required this.emoji, required this.title, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, height: 1.2)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white60, fontSize: 10, height: 1.3)),
      ]),
    );
  }
}

// ── Commerce proche ──
class _ShopNearby extends StatelessWidget {
  final String name, distance, status, url;
  final double rating;
  final String? badge;
  const _ShopNearby({required this.name, required this.distance, required this.status, required this.rating, required this.url, this.badge});

  Color get _statusColor {
    if (status == 'Ouvert') return const Color(0xFF2E7D32);
    if (status == 'En ligne') return const Color(0xFF1565C0);
    return const Color(0xFFB00020);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.store_rounded, color: Color(0xFF2E7D32), size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A1A))),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF8BC34A).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(badge!, style: const TextStyle(fontSize: 9, color: Color(0xFF558B2F), fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            const SizedBox(height: 3),
            Row(children: [
              Text('$distance · ', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
              Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(status, style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.w600)),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              ...List.generate(5, (i) => Icon(i < rating.floor() ? Icons.star_rounded : Icons.star_outline_rounded, size: 12, color: const Color(0xFFFFC107))),
            ]),
            const SizedBox(height: 2),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF888888)),
          ]),
        ]),
      ),
    );
  }
}

// ── Bottom Sheet produit ──
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
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFDDDDDD), borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        ]),
        const SizedBox(height: 16),
        const Divider(color: Color(0xFFF0F0F0)),
        const SizedBox(height: 12),
        if ((data['description'] ?? '').isNotEmpty) ...[
          _sTitle('Description'),
          const SizedBox(height: 6),
          Text(data['description'], style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5)),
          const SizedBox(height: 14),
        ],
        if ((data['bienfaits'] ?? '').isNotEmpty) ...[
          _sTitle('Bienfaits'),
          const SizedBox(height: 6),
          Text(data['bienfaits'], style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.5)),
          const SizedBox(height: 14),
        ],
        _sTitle('Avis clients'),
        const SizedBox(height: 8),
        Row(children: [
          ...List.generate(5, (i) => Icon(i < ((data['note'] ?? 4) as num).floor() ? Icons.star_rounded : Icons.star_outline_rounded, size: 18, color: const Color(0xFFFFC107))),
          const SizedBox(width: 8),
          Text('${data['note'] ?? '4'}/5', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
          const SizedBox(width: 6),
          Text('(${data['avis'] ?? '0'} avis)', style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => ProductStoresPage(productId: productId, productData: data)));
            },
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: const Text('Voir où acheter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A3C2E), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _placeholder() => Container(width: 72, height: 72,
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(14)),
      child: const Icon(Icons.shopping_bag, color: Color(0xFF2E7D32), size: 30));

  Widget _sTitle(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)));
}

// ══ FOOTER BLANC ÉLÉGANT ══
class _Footer extends StatelessWidget {
  const _Footer();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAF8),
        border: Border(top: BorderSide(color: Color(0xFFE0E8E0), width: 1)),
      ),
      child: Column(children: [
        // Bandeau vert fin
        Container(height: 4,
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1A3C2E), Color(0xFF8BC34A), Color(0xFF1A3C2E)]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(children: [
            // Logo
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A3C2E), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SmartBuy', style: TextStyle(color: Color(0xFF1A3C2E), fontSize: 17, fontWeight: FontWeight.bold)),
                Text('SÉNÉGAL', style: TextStyle(color: Color(0xFF8BC34A), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2)),
              ]),
            ]),
            const SizedBox(height: 10),
            const Text(
              'Comparez les prix · Trouvez les meilleurs commerces',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE0E8E0)),
            const SizedBox(height: 16),

            // Liens 2 colonnes
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Supermarchés', style: TextStyle(color: Color(0xFF1A3C2E), fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _FLink(label: 'Auchan Dakar',    onTap: () => _open('https://www.auchan.sn')),
                _FLink(label: 'Casino',          onTap: () => _open('https://maps.google.com/?q=Casino+Supermarché+Dakar')),
                _FLink(label: 'Score',           onTap: () => _open('https://maps.google.com/?q=Score+Dakar')),
                _FLink(label: 'Carrefour',       onTap: () => _open('https://maps.google.com/?q=Carrefour+Dakar')),
              ])),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Marchés & E-com', style: TextStyle(color: Color(0xFF1A3C2E), fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _FLink(label: 'Marché Sandaga',  onTap: () => _open('https://maps.google.com/?q=Marché+Sandaga+Dakar')),
                _FLink(label: 'Jumia Sénégal',   onTap: () => _open('https://www.jumia.sn')),
                _FLink(label: 'Exclusive',        onTap: () => _open('https://maps.google.com/?q=Exclusive+Almadies+Dakar')),
              ])),
            ]),

            const SizedBox(height: 20),
            const Divider(color: Color(0xFFE0E8E0)),
            const SizedBox(height: 14),

            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('© 2025 SmartBuy Sénégal', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 10)),
              Row(children: [
                _StatPill(label: '7 partenaires', color: const Color(0xFF2E7D32)),
                const SizedBox(width: 6),
                _StatPill(label: '6 catégories', color: const Color(0xFF1565C0)),
              ]),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _FLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          const Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF8BC34A)),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
        ]),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}