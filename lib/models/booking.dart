import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final DateTime bookingDate;
  final int numberOfGuests;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
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
      bookingDate: (data['bookingDate'] as Timestamp).toDate(),
      numberOfGuests: data['numberOfGuests'] ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'numberOfGuests': numberOfGuests,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

