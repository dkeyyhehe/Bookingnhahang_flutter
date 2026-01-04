class Restaurant {
  final String id;
  final String name;
  final String address;
  final String description;
  final String imageUrl;
  final double rating;
  final double? latitude;
  final double? longitude;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.imageUrl,
    required this.rating,
    this.latitude,
    this.longitude,
  });

  // Convert from Firestore document
  factory Restaurant.fromFirestore(Map<String, dynamic> data, String id) {
    return Restaurant(
      id: id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      latitude: data['latitude'] != null ? (data['latitude'] as num).toDouble() : null,
      longitude: data['longitude'] != null ? (data['longitude'] as num).toDouble() : null,
    );
  }

  // Convert from OSM JSON response
  factory Restaurant.fromOSM(Map<String, dynamic> osmData) {
    final placeId = osmData['place_id']?.toString() ?? '';
    final name = osmData['name']?.toString() ?? osmData['display_name']?.toString() ?? '';
    final displayName = osmData['display_name']?.toString() ?? '';
    final lat = double.tryParse(osmData['lat']?.toString() ?? '') ?? 0.0;
    final lon = double.tryParse(osmData['lon']?.toString() ?? '') ?? 0.0;
    
    // Generate random rating between 4.0 and 5.0
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final rating = 4.0 + (random / 100.0); // 4.0 to 5.0
    
    // Generate image URL using Lorem Picsum with place_id as seed
    final imageUrl = 'https://picsum.photos/seed/$placeId/300/200';
    
    return Restaurant(
      id: placeId,
      name: name,
      address: displayName,
      description: 'Nhà hàng tại $displayName',
      imageUrl: imageUrl,
      rating: rating,
      latitude: lat,
      longitude: lon,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final map = {
      'name': name,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
    };
    if (latitude != null) map['latitude'] = latitude!;
    if (longitude != null) map['longitude'] = longitude!;
    return map;
  }
}
