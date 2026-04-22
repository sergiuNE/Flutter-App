import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/map_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final name = data['name'] ?? 'Gebruiker';
        final email = data['email'] ?? '';
        final city = data['city'] ?? '';
        final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
        final locationLat = (data['locationLat'] as num?)?.toDouble();
        final locationLng = (data['locationLng'] as num?)?.toDouble();
        final radiusKm = (data['searchRadiusKm'] as num?)?.toDouble() ?? 15.0;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          appBar: AppBar(
            title: const Text('Profiel'),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1C1C1E),
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            children: [
              // Profielkaart
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFFEEF2FF),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 13,
                            ),
                          ),
                          if (city.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  city,
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (locationLat != null && locationLng != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.radar_outlined,
                                  size: 13,
                                  color: Color(0xFF8E8E93),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Bereik: ${radiusKm.toStringAsFixed(0)} km',
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Mijn toestellen sectie
              _Sectie(
                title: 'Mijn toestellen',
                children: [
                  _Rij(
                    icon: Icons.devices_other_outlined,
                    label: 'Mijn aanbod',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _MijnAanbodScreen(uid: uid),
                      ),
                    ),
                  ),
                  _Rij(
                    icon: Icons.calendar_today_outlined,
                    label: 'Mijn reserveringen',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _MijnReserveringenScreen(uid: uid),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Account sectie
              _Sectie(
                title: 'Account',
                children: [
                  _Rij(
                    icon: Icons.map_outlined,
                    label: 'Map & bereik',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapSettingsScreen(
                          uid: uid,
                          initialLat: locationLat,
                          initialLng: locationLng,
                          initialRadiusKm: radiusKm,
                        ),
                      ),
                    ),
                  ),
                  _Rij(
                    icon: Icons.logout,
                    label: 'Afmelden',
                    color: const Color(0xFFFF3B30),
                    onTap: () async {
                      await AuthService().logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (_) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Mijn aanbod ──────────────────────────────────────────────
class _MijnAanbodScreen extends StatelessWidget {
  final String uid;
  const _MijnAanbodScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Mijn aanbod'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('devices')
            .where('ownerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Je hebt nog geen toestellen aangeboden.',
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final isAvailable = d['isAvailable'] as bool? ?? true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          d['imageUrl'] != null &&
                              (d['imageUrl'] as String).isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                d['imageUrl'],
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(
                              Icons.devices_other,
                              color: Color(0xFF4F46E5),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '€${(d['pricePerDay'] ?? 0).toStringAsFixed(0)}/dag · ${d['category'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isAvailable ? 'Live' : 'Inactief',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isAvailable
                              ? const Color(0xFF065F46)
                              : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Verwijder knop
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Verwijderen?'),
                            content: const Text(
                              'Wil je dit toestel verwijderen?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuleer'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Verwijder',
                                  style: TextStyle(color: Color(0xFFFF3B30)),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('devices')
                              .doc(docs[i].id)
                              .delete();
                        }
                      },
                      child: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Color(0xFFFF3B30),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Mijn reserveringen ──────────────────────────────────────
class _MijnReserveringenScreen extends StatelessWidget {
  final String uid;
  const _MijnReserveringenScreen({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Mijn reserveringen'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('renterId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Je hebt nog geen reserveringen.',
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final status = d['status'] ?? 'pending';
              Color bgColor;
              Color txtColor;
              String label;
              switch (status) {
                case 'active':
                  bgColor = const Color(0xFFD1FAE5);
                  txtColor = const Color(0xFF065F46);
                  label = 'Actief';
                case 'pending':
                  bgColor = const Color(0xFFFEF3C7);
                  txtColor = const Color(0xFF92400E);
                  label = 'Aanvraag';
                default:
                  bgColor = const Color(0xFFF0F0F0);
                  txtColor = const Color(0xFF8E8E93);
                  label = 'Afgelopen';
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.devices_other,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['deviceName'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '€${(d['pricePerDay'] ?? 0).toStringAsFixed(0)}/dag',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                          if ((d['slotLabel'] as String?)?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 2),
                            Text(
                              d['slotLabel'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF4F46E5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              color: txtColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (status == 'pending' || status == 'active') ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Niet meer huren?'),
                                  content: const Text(
                                    'Wil je deze reservering annuleren?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Nee'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Ja, annuleren',
                                        style: TextStyle(
                                          color: Color(0xFFFF3B30),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await FirebaseFirestore.instance
                                    .collection('reservations')
                                    .doc(docs[i].id)
                                    .update({'status': 'cancelled'});
                              }
                            },
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────
class _Sectie extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Sectie({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8E8E93),
              letterSpacing: .6,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Rij extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Rij({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF1C1C1E);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 15, color: c)),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
