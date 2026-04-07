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
    };
  }
}
