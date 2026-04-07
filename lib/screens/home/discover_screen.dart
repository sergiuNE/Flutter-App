import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/device.dart';
import '../../widgets/device_card.dart';
import '../dashboard/dashboard_screen.dart';
import '../device/device_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../device/add_device_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.white,
          title: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid ?? '')
                .get(),
            builder: (context, snap) {
              final data = snap.data?.data() as Map<String, dynamic>? ?? {};
              final city = (data['city'] as String?)?.trim();
              final cityLabel = (city == null || city.isEmpty)
                  ? 'Jouw stad'
                  : city;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cityLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4F46E5),
                    ),
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
              );
            },
          ),
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

            if (devices.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Geen toestellen gevonden',
                    style: TextStyle(color: Color(0xFF8E8E93)),
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
