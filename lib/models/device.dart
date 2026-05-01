import 'package:cloud_firestore/cloud_firestore.dart';

class AvailabilitySlot {
  final DateTime date;
  final int startMinutes;
  final int endMinutes;

  const AvailabilitySlot({
    required this.date,
    required this.startMinutes,
    required this.endMinutes,
  });

  static AvailabilitySlot? tryFromMap(Map<String, dynamic> map) {
    DateTime? date;
    final rawDate = map['date'];

    if (rawDate is Timestamp)
      date = rawDate.toDate();
    else if (rawDate is DateTime)
      date = rawDate;
    else if (rawDate is String)
      date = DateTime.tryParse(rawDate);

    final start = (map['startMinutes'] as num?)?.toInt();
    final end = (map['endMinutes'] as num?)?.toInt();

    if (date == null || start == null || end == null) return null;

    return AvailabilitySlot(
      date: DateTime(date.year, date.month, date.day),
      startMinutes: start,
      endMinutes: end,
    );
  }

  factory AvailabilitySlot.fromMap(Map<String, dynamic> map) {
    final slot = tryFromMap(map);
    if (slot == null) {
      throw FormatException('Invalid availability slot: $map');
    }
    return slot;
  }

  Map<String, dynamic> toMap() => {
    'date': Timestamp.fromDate(date),
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };

  String _fmtTime(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  String get labelNl =>
      '${_fmtDate(date)} · ${_fmtTime(startMinutes)} - ${_fmtTime(endMinutes)}';
}

class Device {
  final String id;
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final double pricePerDay;
  final bool isAvailable;
  final String ownerId;
  final String ownerName;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final List<AvailabilitySlot> availabilitySlots;

  Device({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.pricePerDay,
    required this.isAvailable,
    required this.ownerId,
    required this.ownerName,
    required this.lat,
    required this.lng,
    this.rating = 0,
    this.reviewCount = 0,
    this.availabilitySlots = const [],
  });

  factory Device.fromMap(Map<String, dynamic> map, String id) {
    return Device(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      availabilitySlots: ((map['availabilitySlots'] as List?) ?? const [])
          .map(
            (e) => AvailabilitySlot.tryFromMap(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .whereType<AvailabilitySlot>()
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'category': category,
    'imageUrl': imageUrl,
    'pricePerDay': pricePerDay,
    'isAvailable': isAvailable,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'lat': lat,
    'lng': lng,
    'rating': rating,
    'reviewCount': reviewCount,
    'availabilitySlots': availabilitySlots.map((s) => s.toMap()).toList(),
  };
}
