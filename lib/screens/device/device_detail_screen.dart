import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/device.dart';
import '../../widgets/map_preview.dart';
import '../review_screen.dart';

class DeviceDetailScreen extends StatelessWidget {
  final Device device;
  const DeviceDetailScreen({super.key, required this.device});

  Future<AvailabilitySlot?> _pickSlot(BuildContext context) async {
    if (device.availabilitySlots.isEmpty) return null;

    final slots = [...device.availabilitySlots]
      ..sort((a, b) {
        final dayCmp = a.weekday.compareTo(b.weekday);
        if (dayCmp != 0) return dayCmp;
        return a.startMinutes.compareTo(b.startMinutes);
      });

    return showModalBottomSheet<AvailabilitySlot>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Kies een periode',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ...slots.map(
              (s) => ListTile(
                leading: const Icon(Icons.schedule_outlined),
                title: Text(s.dayLabelNl),
                subtitle: Text(s.timeRangeLabel),
                onTap: () => Navigator.pop(context, s),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reserve(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (device.availabilitySlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dit toestel heeft nog geen beschikbare periodes.'),
          backgroundColor: Color(0xFFFF3B30),
        ),
      );
      return;
    }

    final slot = await _pickSlot(context);
    if (slot == null) return;

    await FirebaseFirestore.instance.collection('reservations').add({
      'deviceId': device.id,
      'deviceName': device.name,
      'renterId': uid,
      'ownerId': device.ownerId,
      'status': 'pending',
      'pricePerDay': device.pricePerDay,
      'slotWeekday': slot.weekday,
      'slotStartMinutes': slot.startMinutes,
      'slotEndMinutes': slot.endMinutes,
      'slotLabel': slot.labelNl,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reserveringsaanvraag verstuurd (${slot.labelNl})'),
          backgroundColor: const Color(0xFF34C759),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = [...device.availabilitySlots]
      ..sort((a, b) {
        final dayCmp = a.weekday.compareTo(b.weekday);
        if (dayCmp != 0) return dayCmp;
        return a.startMinutes.compareTo(b.startMinutes);
      });

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: device.imageUrl.isNotEmpty
                  ? Image.network(device.imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: const Color(0xFFEEF2FF),
                      child: const Center(
                        child: Icon(
                          Icons.devices_other,
                          size: 64,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('devices')
                        .doc(device.id)
                        .collection('reviews')
                        .snapshots(),
                    builder: (context, snap) {
                      final docs = snap.data?.docs ?? [];

                      Widget openReviews() => GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewScreen(
                              deviceId: device.id,
                              deviceName: device.name,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Nog geen beoordelingen',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      );

                      if (docs.isEmpty) return openReviews();

                      final total = docs
                          .map(
                            (d) =>
                                ((d.data() as Map<String, dynamic>)['stars']
                                        as num?)
                                    ?.toDouble() ??
                                0.0,
                          )
                          .fold<double>(0.0, (a, b) => a + b);
                      final avg = total / docs.length;

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewScreen(
                              deviceId: device.id,
                              deviceName: device.name,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${avg.toStringAsFixed(1)} · ${docs.length} beoordelingen',
                              style: const TextStyle(
                                color: Color(0xFF4F46E5),
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFEEF2FF),
                        child: Text(
                          device.ownerName.isNotEmpty
                              ? device.ownerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.ownerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Eigenaar',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Beschrijving',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    device.description,
                    style: const TextStyle(
                      color: Color(0xFF3C3C43),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Beschikbare momenten',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  if (slots.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((slot) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            slot.labelNl,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    const Text(
                      'Nog geen verhuurmomenten ingesteld door verhuurder.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)),
                    ),
                  const SizedBox(height: 16),

                  if (device.lat != 0 && device.lng != 0) ...[
                    const Text(
                      'Locatie',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MapPreview(
                      lat: device.lat,
                      lng: device.lng,
                      label: device.name,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          device.isAvailable
                              ? Icons.check_circle_outline
                              : Icons.cancel_outlined,
                          color: device.isAvailable
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF3B30),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          device.isAvailable
                              ? 'Beschikbaar'
                              : 'Niet beschikbaar',
                          style: TextStyle(
                            color: device.isAvailable
                                ? const Color(0xFF34C759)
                                : const Color(0xFFFF3B30),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewScreen(
                          deviceId: device.id,
                          deviceName: device.name,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Beoordeel dit toestel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFF4F46E5)),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '€${device.pricePerDay.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'per dag',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      (device.isAvailable &&
                          device.availabilitySlots.isNotEmpty)
                      ? () => _reserve(context)
                      : null,
                  child: const Text('Reserveren'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
