class AvailabilitySlot {
  final int weekday;
  final int startMinutes;
  final int endMinutes;

  const AvailabilitySlot({
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
  });

  factory AvailabilitySlot.fromMap(Map<String, dynamic> map) {
    return AvailabilitySlot(
      weekday: (map['weekday'] as num?)?.toInt() ?? 1,
      startMinutes: (map['startMinutes'] as num?)?.toInt() ?? 0,
      endMinutes: (map['endMinutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'weekday': weekday,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };

  static const _days = <int, String>{
    1: 'Maandag',
    2: 'Dinsdag',
    3: 'Woensdag',
    4: 'Donderdag',
    5: 'Vrijdag',
    6: 'Zaterdag',
    7: 'Zondag',
  };

  String get dayLabelNl => _days[weekday] ?? 'Onbekend';

  String _fmt(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get timeRangeLabel => '${_fmt(startMinutes)} - ${_fmt(endMinutes)}';
  String get labelNl => '$dayLabelNl · $timeRangeLabel';
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
            (e) =>
                AvailabilitySlot.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
}
