import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String role; // 'admin' or 'user'
  final String? avatarUrl;
  final List<String> favoriteRestaurantIds;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    List<String>? favoriteRestaurantIds,
  }) : favoriteRestaurantIds = favoriteRestaurantIds ?? [];

  // Convert from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'user',
      avatarUrl: data['avatarUrl'],
      favoriteRestaurantIds: List<String>.from(data['favoriteRestaurantIds'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'favoriteRestaurantIds': favoriteRestaurantIds,
    };
  }

  bool get isAdmin => role == 'admin';

  // Create a copy with updated favoriteRestaurantIds
  AppUser copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? avatarUrl,
    List<String>? favoriteRestaurantIds,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      favoriteRestaurantIds: favoriteRestaurantIds ?? this.favoriteRestaurantIds,
    );
  }
}

