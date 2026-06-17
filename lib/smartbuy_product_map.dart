import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────
// Palette SmartBuy
// ─────────────────────────────────────────────
class SmartBuyColors {
  static const Color green = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFFE8F5E9);
  static const Color orange = Color(0xFFFFB800);
  static const Color lightGrey = Color(0xFFF5F7F5);
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey = Color(0xFF666666);
  static const Color red = Color(0xFFE53935);
}

// ─────────────────────────────────────────────
// Modèle partenaire
// ─────────────────────────────────────────────
class PartnerStore {
  final String name;
  final String address;
  final double rating;
  final double? lat;
  final double? lng;

  const PartnerStore({
    required this.name,
    required this.address,
    required this.rating,
    this.lat,
    this.lng,
  });

  bool get isOnline => lat == null || lng == null;
  LatLng? get latLng => isOnline ? null : LatLng(lat!, lng!);
}

// ─────────────────────────────────────────────
// Page principale
// ─────────────────────────────────────────────
class NearbyPartnersScreen extends StatefulWidget {
  const NearbyPartnersScreen({super.key});

  @override
  State<NearbyPartnersScreen> createState() => _NearbyPartnersScreenState();
}

class _NearbyPartnersScreenState extends State<NearbyPartnersScreen> {
  // ── Partenaires ──────────────────────────────────────────────────────────
  static const List<PartnerStore> _allPartners = [
    PartnerStore(
      name: "Auchan Dakar",
      address: "Sea Plaza, Corniche Ouest",
      rating: 4.5,
      lat: 14.6937,
      lng: -17.4441,
    ),
    PartnerStore(
      name: "Casino Almadies",
      address: "Route des Almadies, Dakar",
      rating: 4.3,
      lat: 14.7462,
      lng: -17.5146,
    ),
    PartnerStore(
      name: "Carrefour Grand-Yoff",
      address: "Grand-Yoff, Dakar",
      rating: 4.1,
      lat: 14.7286,
      lng: -17.4603,
    ),
    PartnerStore(
      name: "Exclusive Almadies",
      address: "Almadies, Dakar",
      rating: 4.0,
      lat: 14.7450,
      lng: -17.5120,
    ),
    PartnerStore(
      name: "Marché Sandaga",
      address: "Avenue Blaise Diagne, Plateau",
      rating: 4.2,
      lat: 14.6711,
      lng: -17.4407,
    ),
    PartnerStore(
      name: "CityDia Plateau",
      address: "Av. Léopold Sédar Senghor, Plateau",
      rating: 4.2,
      lat: 14.6731,
      lng: -17.4389,
    ),
    PartnerStore(
      name: "Boutique Walo",
      address: "Médina, Dakar",
      rating: 3.8,
      lat: 14.6842,
      lng: -17.4437,
    ),
    PartnerStore(
      name: "Jumia",
      address: "Livraison à domicile",
      rating: 4.1,
    ),
  ];

  // ── État ─────────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  Position? _userPosition;
  bool _loading = true;
  String? _errorMessage;
  PartnerStore? _selectedStore;

  static const LatLng _dakarCenter = LatLng(14.7167, -17.4677);

  List<PartnerStore> get _physicalPartners =>
      _allPartners.where((s) => !s.isOnline).toList();

  List<PartnerStore> get _onlinePartners =>
      _allPartners.where((s) => s.isOnline).toList();

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  // ── Géolocalisation ───────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    setState(() { _loading = true; _errorMessage = null; });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { _setError("GPS désactivé."); return; }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) { _setError("Permission refusée."); return; }
      }
      if (perm == LocationPermission.deniedForever) {
        _setError("Localisation bloquée. Active-la dans les Réglages."); return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() { _userPosition = pos; _loading = false; });

      _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
    } catch (e) {
      _setError("Impossible de récupérer ta position.");
    }
  }

  void _setError(String msg) => setState(() { _loading = false; _errorMessage = msg; });

  // ── Distance Haversine ────────────────────────────────────────────────────
  double _distKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double? _distanceTo(PartnerStore s) {
    if (_userPosition == null || s.isOnline) return null;
    return _distKm(_userPosition!.latitude, _userPosition!.longitude, s.lat!, s.lng!);
  }

  PartnerStore? get _nearestStore {
    if (_userPosition == null) return null;
    return _physicalPartners.reduce((a, b) =>
        (_distanceTo(a) ?? 999) < (_distanceTo(b) ?? 999) ? a : b);
  }

  // ── Ouvrir itinéraire Google Maps ─────────────────────────────────────────
  Future<void> _openItinerary(PartnerStore store) async {
    final dest = "${store.lat},${store.lng}";
    final String url;
    if (_userPosition != null) {
      url = "https://www.google.com/maps/dir/?api=1"
          "&origin=${_userPosition!.latitude},${_userPosition!.longitude}"
          "&destination=$dest&travelmode=driving";
    } else {
      url = "https://www.google.com/maps/search/?api=1"
          "&query=${Uri.encodeComponent(store.address)}";
    }
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossible d'ouvrir Google Maps")),
        );
      }
    }
  }

  // ── Recentrer ─────────────────────────────────────────────────────────────
  void _recenter() {
    final target = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : _dakarCenter;
    _mapController.move(target, 13);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final nearest = _nearestStore;

    return Scaffold(
      body: Stack(
        children: [
          // ── Carte OpenStreetMap plein écran ───────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _dakarCenter,
              initialZoom: 12,
              onTap: (_, __) => setState(() => _selectedStore = null),
            ),
            children: [
              // Tuiles OpenStreetMap (gratuit, sans clé)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.smartbuy.senegal',
              ),

              // Cercle de position utilisateur
              if (_userPosition != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      radius: 80,
                      useRadiusInMeter: true,
                      color: SmartBuyColors.green.withOpacity(0.15),
                      borderColor: SmartBuyColors.green,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),

              // Marqueurs partenaires
              MarkerLayer(
                markers: [
                  // Position utilisateur
                  if (_userPosition != null)
                    Marker(
                      point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: SmartBuyColors.green, width: 3),
                          boxShadow: [BoxShadow(color: SmartBuyColors.green.withOpacity(0.4), blurRadius: 8)],
                        ),
                        child: const Center(
                          child: CircleAvatar(radius: 5, backgroundColor: SmartBuyColors.green),
                        ),
                      ),
                    ),

                  // Marqueurs partenaires
                  ..._physicalPartners.map((store) {
                    final isNearest = store.name == nearest?.name;
                    final isSelected = store.name == _selectedStore?.name;
                    return Marker(
                      point: store.latLng!,
                      width: isSelected ? 52 : 44,
                      height: isSelected ? 62 : 54,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedStore = store),
                        child: Column(
                          children: [
                            Container(
                              width: isSelected ? 46 : 38,
                              height: isSelected ? 46 : 38,
                              decoration: BoxDecoration(
                                color: isNearest ? SmartBuyColors.green : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isNearest ? SmartBuyColors.green : SmartBuyColors.orange,
                                  width: isSelected ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isNearest ? SmartBuyColors.green : SmartBuyColors.orange).withOpacity(0.4),
                                    blurRadius: isSelected ? 12 : 6,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.store,
                                size: isSelected ? 22 : 18,
                                color: isNearest ? Colors.white : SmartBuyColors.orange,
                              ),
                            ),
                            // Pointe du marqueur
                            Container(
                              width: 3,
                              height: isSelected ? 16 : 12,
                              decoration: BoxDecoration(
                                color: isNearest ? SmartBuyColors.green : SmartBuyColors.orange,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // ── Loader ────────────────────────────────────────────────────
          if (_loading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: SmartBuyColors.green),
                    SizedBox(height: 14),
                    Text("Localisation en cours…",
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),
            ),

          // ── Barre supérieure ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _MapBtn(icon: Icons.arrow_back_ios_new,
                      onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store_mall_directory,
                              color: SmartBuyColors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "${_physicalPartners.length} partenaires",
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: SmartBuyColors.black),
                          ),
                          const Spacer(),
                          if (_userPosition != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: SmartBuyColors.lightGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("GPS ✓",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: SmartBuyColors.green,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bannière erreur GPS ───────────────────────────────────────
          if (_errorMessage != null)
            Positioned(
              top: 90,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SmartBuyColors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: SmartBuyColors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_errorMessage!,
                        style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            ),

          // ── Boutons flottants droite ──────────────────────────────────
          Positioned(
            right: 12,
            bottom: _selectedStore != null ? 260 : 100,
            child: Column(
              children: [
                _MapBtn(
                  icon: Icons.my_location,
                  onTap: _recenter,
                  color: SmartBuyColors.green,
                  iconColor: Colors.white,
                ),
                const SizedBox(height: 10),
                _MapBtn(
                  icon: Icons.laptop_mac,
                  onTap: () => _showOnlineSheet(),
                  tooltip: "Jumia",
                ),
              ],
            ),
          ),

          // ── Fiche partenaire sélectionné ──────────────────────────────
          if (_selectedStore != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 24,
              child: _PartnerCard(
                store: _selectedStore!,
                distanceKm: _distanceTo(_selectedStore!),
                isNearest: _selectedStore!.name == nearest?.name,
                userPosition: _userPosition,
                onClose: () => setState(() => _selectedStore = null),
                onItinerary: () => _openItinerary(_selectedStore!),
              ),
            ),

          // ── Légende (quand aucune fiche ouverte) ─────────────────────
          if (_selectedStore == null)
            Positioned(
              left: 16,
              right: 70,
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _LegendItem(color: SmartBuyColors.green, label: "Le plus proche"),
                    _LegendItem(color: SmartBuyColors.orange, label: "Partenaires"),
                    _LegendItem(color: Colors.blue, label: "Ma position"),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showOnlineSheet() {
    final jumia = _onlinePartners.first;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: SmartBuyColors.lightGrey,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.laptop_mac,
                      color: SmartBuyColors.grey, size: 24)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(jumia.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text(jumia.address, style: const TextStyle(fontSize: 13, color: SmartBuyColors.grey)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: SmartBuyColors.lightGrey,
                      borderRadius: BorderRadius.circular(8)),
                  child: const Text("En ligne",
                      style: TextStyle(fontSize: 11, color: SmartBuyColors.grey,
                          fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              ...List.generate(5, (i) => Icon(
                  i < jumia.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16, color: SmartBuyColors.orange)),
              const SizedBox(width: 6),
              Text("${jumia.rating}/5",
                  style: const TextStyle(fontSize: 12, color: SmartBuyColors.grey)),
            ]),
            const SizedBox(height: 12),
            Container(width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: SmartBuyColors.lightGrey,
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.info_outline, size: 15, color: SmartBuyColors.grey),
                  SizedBox(width: 8),
                  Text("Service en ligne — pas de déplacement",
                      style: TextStyle(fontSize: 12, color: SmartBuyColors.grey)),
                ])),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Carte partenaire (bottom card)
// ─────────────────────────────────────────────
class _PartnerCard extends StatelessWidget {
  final PartnerStore store;
  final double? distanceKm;
  final bool isNearest;
  final Position? userPosition;
  final VoidCallback onClose;
  final VoidCallback onItinerary;

  const _PartnerCard({
    required this.store,
    required this.distanceKm,
    required this.isNearest,
    required this.userPosition,
    required this.onClose,
    required this.onItinerary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isNearest
            ? Border.all(color: SmartBuyColors.green, width: 1.5)
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isNearest ? SmartBuyColors.lightGreen : SmartBuyColors.lightGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.store_mall_directory,
                  color: isNearest ? SmartBuyColors.green : SmartBuyColors.grey, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(store.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.location_on, size: 13, color: SmartBuyColors.red),
                const SizedBox(width: 4),
                Expanded(child: Text(store.address,
                    style: const TextStyle(fontSize: 12, color: SmartBuyColors.grey),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, size: 20, color: SmartBuyColors.grey),
              ),
              if (distanceKm != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isNearest ? SmartBuyColors.lightGreen : SmartBuyColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${distanceKm!.toStringAsFixed(1)} km",
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isNearest ? SmartBuyColors.green : SmartBuyColors.grey),
                  ),
                ),
              ],
            ]),
          ]),

          const SizedBox(height: 12),

          Row(children: [
            ...List.generate(5, (i) => Icon(
                i < store.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                size: 16, color: SmartBuyColors.orange)),
            const SizedBox(width: 6),
            Text("${store.rating}/5",
                style: const TextStyle(fontSize: 12, color: SmartBuyColors.grey)),
            if (isNearest) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: SmartBuyColors.green,
                    borderRadius: BorderRadius.circular(4)),
                child: const Text("Le plus proche",
                    style: TextStyle(fontSize: 10, color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ]),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: onItinerary,
              icon: const Icon(Icons.directions, color: Colors.white, size: 20),
              label: const Text("Lancer l'itinéraire",
                  style: TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: SmartBuyColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Widgets helpers
// ─────────────────────────────────────────────
class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;
  final String? tooltip;

  const _MapBtn({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
    this.iconColor = SmartBuyColors.black,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11, color: SmartBuyColors.grey)),
    ]);
  }
}