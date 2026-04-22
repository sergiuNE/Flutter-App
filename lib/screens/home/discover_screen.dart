import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/device.dart';
import '../../widgets/device_card.dart';
import '../dashboard/dashboard_screen.dart';
import '../device/device_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/map_settings_screen.dart';
import '../device/add_device_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  int _navIndex = 0;
  String _selectedCategory = 'Alles';
  final _categories = ['Alles', 'Tuin', 'Keuken', 'Schoonmaak', 'Gereedschap'];

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;
  bool _autoLocationTried = false;

  double? _userLat;
  double? _userLng;
  double _radiusKm = 15;
  String _cityLabel = 'Jouw stad';

  @override
  void initState() {
    super.initState();
    _listenUserSettings();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _listenUserSettings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
          final data = doc.data() ?? {};
          final city = (data['city'] as String?)?.trim();
          final lat = (data['locationLat'] as num?)?.toDouble();
          final lng = (data['locationLng'] as num?)?.toDouble();
          final radius = ((data['searchRadiusKm'] as num?)?.toDouble() ?? 15)
              .clamp(1, 50)
              .toDouble();

          if (!_autoLocationTried && (lat == null || lng == null)) {
            _autoLocationTried = true;
            _tryAutoSaveLiveLocation(uid, radius);
          }

          if (!mounted) return;
          setState(() {
            _cityLabel = (city == null || city.isEmpty) ? 'Jouw stad' : city;
            _userLat = lat;
            _userLng = lng;
            _radiusKm = radius;
          });
        });
  }

  Future<void> _tryAutoSaveLiveLocation(String uid, double radiusKm) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'locationLat': pos.latitude,
        'locationLng': pos.longitude,
        'searchRadiusKm': radiusKm,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);

    final c = 2 * math.atan2(math.sqrt(a.toDouble()), math.sqrt(1 - a));
    return 6371 * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  Future<void> _openMapSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapSettingsScreen(
          uid: uid,
          initialLat: _userLat,
          initialLng: _userLng,
          initialRadiusKm: _radiusKm,
        ),
      ),
    );
  }

  Stream<List<Device>> _deviceStream() {
    Query query = FirebaseFirestore.instance
        .collection('devices')
        .where('isAvailable', isEqualTo: true);

    if (_selectedCategory != 'Alles') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots().map(
      (snap) => snap.docs
          .map((d) => Device.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList(),
    );
  }

  Widget _buildBody() {
    switch (_navIndex) {
      case 0:
        return _buildDiscover();
      case 1:
        return const DashboardScreen(embedded: true);
      case 2:
        return const AddDeviceScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildDiscover();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFEEF2FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: Color(0xFF4F46E5)),
            label: 'Ontdekken',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF4F46E5)),
            label: 'Huren',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: Color(0xFF4F46E5)),
            label: 'Aanbieden',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF4F46E5)),
            label: 'Profiel',
          ),
        ],
      ),
    );
  }

  Widget _buildDiscover() {
    final topLabel = (_userLat != null && _userLng != null)
        ? 'Binnen ${_radiusKm.toStringAsFixed(0)} km'
        : _cityLabel;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4F46E5)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ontdekken',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1E),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _openMapSettings,
              icon: const Icon(Icons.map_outlined),
              color: const Color(0xFF4F46E5),
              tooltip: 'Map & bereik',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Zoek een toestel...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF8E8E93),
                      ),
                      hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
                      filled: true,
                      fillColor: const Color(0xFFF1F1F1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (_, i) {
                      final selected = _categories[i] == _selectedCategory;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = _categories[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF4F46E5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFE0E0E0),
                            ),
                          ),
                          child: Text(
                            _categories[i],
                            style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF8E8E93),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        StreamBuilder<List<Device>>(
          stream: _deviceStream(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            var devices = snap.data ?? [];

            if (_searchQuery.isNotEmpty) {
              devices = devices.where((d) {
                final name = d.name.toLowerCase();
                final desc = d.description.toLowerCase();
                final cat = d.category.toLowerCase();
                return name.contains(_searchQuery) ||
                    desc.contains(_searchQuery) ||
                    cat.contains(_searchQuery);
              }).toList();
            }

            if (_userLat != null && _userLng != null) {
              devices =
                  devices.where((d) {
                    if (d.lat == 0 || d.lng == 0) return false;
                    final km = _distanceKm(_userLat!, _userLng!, d.lat, d.lng);
                    return km <= _radiusKm;
                  }).toList()..sort((a, b) {
                    final da = _distanceKm(_userLat!, _userLng!, a.lat, a.lng);
                    final db = _distanceKm(_userLat!, _userLng!, b.lat, b.lng);
                    return da.compareTo(db);
                  });
            }

            if (devices.isEmpty) {
              final msg = (_userLat != null && _userLng != null)
                  ? 'Geen toestellen binnen ${_radiusKm.toStringAsFixed(0)} km'
                  : 'Geen toestellen gevonden';

              return SliverFillRemaining(
                child: Center(
                  child: Text(
                    msg,
                    style: const TextStyle(color: Color(0xFF8E8E93)),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeviceDetailScreen(device: devices[i]),
                      ),
                    ),
                    child: DeviceCard(device: devices[i]),
                  ),
                  childCount: devices.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
