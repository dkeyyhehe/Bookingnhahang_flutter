import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String restaurantId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final int rating; // 1-5
  final String comment;
  final DateTime timestamp;

  Review({
    required this.id,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  // Convert from Firestore document
  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

