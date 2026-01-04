import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String? restaurantAddress;
  final String? restaurantImage;
  final DateTime bookingDate;
  final int numberOfGuests;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    this.restaurantAddress,
    this.restaurantImage,
    required this.bookingDate,
    required this.numberOfGuests,
    required this.status,
    required this.createdAt,
  });

  // Convert from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      userId: data['userId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      restaurantName: data['restaurantName'] ?? '',
      restaurantAddress: data['restaurantAddress'],
      restaurantImage: data['restaurantImage'],
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      numberOfGuests: data['numberOfGuests'] ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    final map = {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'numberOfGuests': numberOfGuests,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
    if (restaurantAddress != null) map['restaurantAddress'] = restaurantAddress!;
    if (restaurantImage != null) map['restaurantImage'] = restaurantImage!;
    return map;
  }
}

