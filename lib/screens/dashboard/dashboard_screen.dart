import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  final bool embedded;
  const DashboardScreen({super.key, this.embedded = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Reserveringen',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: const Color(0xFF8E8E93),
          indicatorColor: const Color(0xFF4F46E5),
          tabs: const [
            Tab(text: 'Ik huur'),
            Tab(text: 'Ik verhuur'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _Lijst(uid: uid, asRenter: true),
          _Lijst(uid: uid, asRenter: false),
        ],
      ),
    );
  }
}

class _Lijst extends StatelessWidget {
  final String uid;
  final bool asRenter;
  const _Lijst({required this.uid, required this.asRenter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reservations')
          .where(asRenter ? 'renterId' : 'ownerId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  asRenter
                      ? 'Je hebt nog niets gehuurd.'
                      : 'Nog geen aanvragen ontvangen.',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final actief = docs
            .where((d) => (d.data() as Map)['status'] == 'active')
            .length;
        final pending = docs
            .where((d) => (d.data() as Map)['status'] == 'pending')
            .length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                _Stat(label: 'Actief', value: actief.toString()),
                const SizedBox(width: 10),
                _Stat(label: 'Aanvragen', value: pending.toString()),
                const SizedBox(width: 10),
                _Stat(label: 'Totaal', value: docs.length.toString()),
              ],
            ),
            const SizedBox(height: 16),
            ...docs.map(
              (doc) => _Kaart(doc: doc, asRenter: asRenter, context: context),
            ),
          ],
        );
      },
    );
  }

  Widget _Kaart({
    required QueryDocumentSnapshot doc,
    required bool asRenter,
    required BuildContext context,
  }) {
    final d = doc.data() as Map<String, dynamic>;
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
      case 'declined':
        bgColor = const Color(0xFFFFE4E4);
        txtColor = const Color(0xFFFF3B30);
        label = 'Geweigerd';
      case 'cancelled':
        bgColor = const Color(0xFFF0F0F0);
        txtColor = const Color(0xFF8E8E93);
        label = 'Geannuleerd';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                        fontSize: 14,
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
                    if ((d['slotLabel'] as String?)?.isNotEmpty == true) ...[
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
                  if (asRenter &&
                      (status == 'pending' || status == 'active')) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Niet meer huren?'),
                            content: Text(
                              'Wil je "${d['deviceName']}" annuleren?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Nee'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Ja, annuleren',
                                  style: TextStyle(color: Color(0xFFFF3B30)),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await FirebaseFirestore.instance
                              .collection('reservations')
                              .doc(doc.id)
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

          // Verhuurder: accepteer/weiger knoppen bij pending
          if (!asRenter && status == 'pending') ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('reservations')
                          .doc(doc.id)
                          .update({'status': 'declined'});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF3B30),
                      side: const BorderSide(color: Color(0xFFFF3B30)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Weigeren',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('reservations')
                          .doc(doc.id)
                          .update({'status': 'active'});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text(
                      'Accepteren',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
            ),
          ],
        ),
      ),
    );
  }
}
