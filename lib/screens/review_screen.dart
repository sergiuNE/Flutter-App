import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;
  const ReviewScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _stars = 0;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  Future<void> _submitReview() async {
    if (_stars == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geef minstens 1 ster.'),
          backgroundColor: Color(0xFFFF3B30),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Anoniem';

      await FirebaseFirestore.instance
          .collection('devices')
          .doc(widget.deviceId)
          .collection('reviews')
          .doc(uid)
          .set({
            'stars': _stars,
            'title': _titleCtrl.text.trim(),
            'description': _descCtrl.text.trim(),
            'userId': uid,
            'userName': userName,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await _updateDeviceRating();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beoordeling opgeslagen!'),
            backgroundColor: Color(0xFF34C759),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _updateDeviceRating() async {
    final deviceRef = FirebaseFirestore.instance
        .collection('devices')
        .doc(widget.deviceId);

    final reviewsSnap = await deviceRef.collection('reviews').get();

    if (reviewsSnap.docs.isEmpty) {
      await deviceRef.update({'rating': 0.0, 'reviewCount': 0});
      return;
    }

    final total = reviewsSnap.docs
        .map((d) => (d.data()['stars'] as num?)?.toDouble() ?? 0.0)
        .fold<double>(0.0, (a, b) => a + b);

    final avg = total / reviewsSnap.docs.length;

    await deviceRef.update({
      'rating': double.parse(avg.toStringAsFixed(1)),
      'reviewCount': reviewsSnap.docs.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Beoordelingen'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            widget.deviceName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Deel je ervaring met dit toestel.',
            style: TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jouw score',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => GestureDetector(
                      onTap: () => setState(() => _stars = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 36,
                          color: i < _stars
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFD1D1D6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Titel (optioneel)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    hintText: 'bv. Werkte perfect',
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Beschrijving (optioneel)'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Vertel meer over je ervaring...',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _submitReview,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Beoordeling plaatsen'),
          ),

          const SizedBox(height: 32),
          const Text(
            'Alle beoordelingen',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('devices')
                .doc(widget.deviceId)
                .collection('reviews')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return const Text(
                  'Nog geen beoordelingen.',
                  style: TextStyle(color: Color(0xFF8E8E93)),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final isOwn = d['userId'] == uid;

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
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: const Color(0xFFEEF2FF),
                              child: Text(
                                (d['userName'] as String? ?? '?').isNotEmpty
                                    ? (d['userName'] as String)[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d['userName'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (i) => Icon(
                                  i < (d['stars'] as int? ?? 0)
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 14,
                                  color: i < (d['stars'] as int? ?? 0)
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFFD1D1D6),
                                ),
                              ),
                            ),
                            if (isOwn) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Review verwijderen?'),
                                      content: const Text(
                                        'Wil je zeker je review verwijderen?',
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
                                            'Ja',
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
                                        .collection('devices')
                                        .doc(widget.deviceId)
                                        .collection('reviews')
                                        .doc(doc.id)
                                        .delete();
                                    await _updateDeviceRating();
                                  }
                                },
                                child: const Icon(
                                  Icons.delete_outline,
                                  size: 16,
                                  color: Color(0xFFFF3B30),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if ((d['title'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 6),
                          Text(
                            d['title'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if ((d['description'] as String?)?.isNotEmpty ==
                            true) ...[
                          const SizedBox(height: 4),
                          Text(
                            d['description'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3C3C43),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
