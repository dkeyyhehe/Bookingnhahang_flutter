import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/restaurant.dart';
import '../models/booking.dart';
import '../models/review.dart';
import '../models/notification.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== USER OPERATIONS ==========

  // Create user document
  Future<void> createUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
    } catch (e) {
      throw Exception('Lỗi tạo người dùng: ${e.toString()}');
    }
  }

  // Get user by ID
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin người dùng: ${e.toString()}');
    }
  }

  // Update user role (for admin)
  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      throw Exception('Lỗi cập nhật quyền: ${e.toString()}');
    }
  }

  // Update user name
  Future<void> updateUserName(String uid, String name) async {
    try {
      await _firestore.collection('users').doc(uid).update({'name': name});
    } catch (e) {
      throw Exception('Lỗi cập nhật tên: ${e.toString()}');
    }
  }

  // Toggle favorite restaurant
  // CASE 1: Adding to Favorites - Check if restaurant exists in Firestore, if not create it, then add to user's favorites
  // CASE 2: Removing from Favorites - Just remove from user's favorites, don't delete restaurant document
  Future<void> toggleFavoriteRestaurant(String uid, Restaurant restaurant) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        throw Exception('Người dùng không tồn tại');
      }

      final data = userDoc.data()!;
      final favorites = List<String>.from(data['favoriteRestaurantIds'] ?? []);
      final restaurantId = restaurant.id;
      final isCurrentlyFavorite = favorites.contains(restaurantId);

      if (isCurrentlyFavorite) {
        // CASE 2: Removing from Favorites (Turn OFF)
        // Unlink User: Remove the restaurantId from user's favoriteRestaurantIds array
        await _firestore.collection('users').doc(uid).update({
          'favoriteRestaurantIds': FieldValue.arrayRemove([restaurantId]),
        });
      } else {
        // CASE 1: Adding to Favorites (Turn ON)
        // Check & Sync: Check if restaurant exists in Firestore restaurants collection
        final restaurantDoc = await _firestore.collection('restaurants').doc(restaurantId).get();
        
        if (!restaurantDoc.exists) {
          // If NO: Create/Save the full restaurant document to Firestore restaurants collection
          await _firestore.collection('restaurants').doc(restaurantId).set(
            restaurant.toFirestore(),
          );
        }
        // If YES: Do nothing to the restaurant doc (keep existing data)
        
        // Link User: Add the restaurantId to user's favoriteRestaurantIds array
        await _firestore.collection('users').doc(uid).update({
          'favoriteRestaurantIds': FieldValue.arrayUnion([restaurantId]),
        });
      }
    } catch (e) {
      throw Exception('Lỗi cập nhật yêu thích: ${e.toString()}');
    }
  }

  // Get favorite restaurants
  Future<List<Restaurant>> getFavoriteRestaurants(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        return [];
      }

      final data = userDoc.data()!;
      final favoriteIds = List<String>.from(data['favoriteRestaurantIds'] ?? []);

      if (favoriteIds.isEmpty) {
        return [];
      }

      // Get all restaurants that are in favorites
      final restaurantsSnapshot = await _firestore
          .collection('restaurants')
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .get();

      return restaurantsSnapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách yêu thích: ${e.toString()}');
    }
  }

  // Stream favorite restaurants
  Stream<List<Restaurant>> getFavoriteRestaurantsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .asyncMap((userDoc) async {
      if (!userDoc.exists) {
        return <Restaurant>[];
      }

      final data = userDoc.data()!;
      final favoriteIds = List<String>.from(data['favoriteRestaurantIds'] ?? []);

      if (favoriteIds.isEmpty) {
        return <Restaurant>[];
      }

      // Get all restaurants that are in favorites
      final restaurantsSnapshot = await _firestore
          .collection('restaurants')
          .where(FieldPath.documentId, whereIn: favoriteIds)
          .get();

      return restaurantsSnapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  // Get all users (for admin operations)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách người dùng: ${e.toString()}');
    }
  }

  // ========== RESTAURANT OPERATIONS ==========

  // Get all restaurants
  Stream<List<Restaurant>> getRestaurants() {
    return _firestore
        .collection('restaurants')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Restaurant.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Get all restaurants as Future (for one-time fetch)
  Future<List<Restaurant>> getAllRestaurants() async {
    try {
      final snapshot = await _firestore.collection('restaurants').get();
      return snapshot.docs
          .map((doc) => Restaurant.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Lỗi lấy danh sách nhà hàng: ${e.toString()}');
    }
  }

  // Get restaurant by ID
  Future<Restaurant?> getRestaurant(String id) async {
    try {
      final doc = await _firestore.collection('restaurants').doc(id).get();
      if (doc.exists) {
        return Restaurant.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi lấy thông tin nhà hàng: ${e.toString()}');
    }
  }

  // Create restaurant
  Future<String> createRestaurant(Restaurant restaurant) async {
    try {
      final docRef = await _firestore
          .collection('restaurants')
          .add(restaurant.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi tạo nhà hàng: ${e.toString()}');
    }
  }

  // Update restaurant
  Future<void> updateRestaurant(String id, Restaurant restaurant) async {
    try {
      await _firestore
          .collection('restaurants')
          .doc(id)
          .update(restaurant.toFirestore());
    } catch (e) {
      throw Exception('Lỗi cập nhật nhà hàng: ${e.toString()}');
    }
  }

  // Delete restaurant
  Future<void> deleteRestaurant(String id) async {
    try {
      await _firestore.collection('restaurants').doc(id).delete();
    } catch (e) {
      throw Exception('Lỗi xóa nhà hàng: ${e.toString()}');
    }
  }

  // Seed restaurants (call this once to add dummy data)
  Future<void> seedRestaurants() async {
    try {
      final restaurantsRef = _firestore.collection('restaurants');
      
      // Check if restaurants already exist
      final snapshot = await restaurantsRef.limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return; // Already seeded
      }

      final restaurants = [
        {
          'name': 'Nhà hàng A',
          'address': '123 Nguyễn Trãi, Quận 1, TP.HCM',
          'description': 'Nhà hàng sang trọng với không gian ấm cúng, phục vụ các món ăn Á-Âu đặc sắc.',
          'imageUrl': 'assets/images/restaurant.jpg',
          'rating': 4.5,
        },
        {
          'name': 'Nhà hàng B',
          'address': '45 Lê Lợi, Quận 3, TP.HCM',
          'description': 'Nhà hàng hiện đại với view đẹp, menu đa dạng và chất lượng phục vụ tốt.',
          'imageUrl': 'assets/images/restaurant.jpg',
          'rating': 4.2,
        },
        {
          'name': 'Nhà hàng C',
          'address': '789 Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
          'description': 'Không gian rộng rãi, phù hợp cho các buổi tiệc và họp mặt gia đình.',
          'imageUrl': 'assets/images/restaurant.jpg',
          'rating': 4.7,
        },
        {
          'name': 'Nhà hàng D',
          'address': '321 Võ Văn Tần, Quận 3, TP.HCM',
          'description': 'Nhà hàng ẩm thực Việt Nam truyền thống với hương vị đậm đà.',
          'imageUrl': 'assets/images/restaurant.jpg',
          'rating': 4.3,
        },
        {
          'name': 'Nhà hàng E',
          'address': '567 Nguyễn Huệ, Quận 1, TP.HCM',
          'description': 'Nhà hàng cao cấp với view sông đẹp, menu quốc tế phong phú.',
          'imageUrl': 'assets/images/restaurant.jpg',
          'rating': 4.8,
        },
      ];

      for (var restaurant in restaurants) {
        await restaurantsRef.add(restaurant);
      }
    } catch (e) {
      throw Exception('Lỗi seed dữ liệu: ${e.toString()}');
    }
  }

  // ========== BOOKING OPERATIONS ==========

  // Create booking
  Future<String> createBooking(Booking booking) async {
    try {
      final docRef = await _firestore
          .collection('bookings')
          .add(booking.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi tạo đặt bàn: ${e.toString()}');
    }
  }

  // Get bookings by user ID
  Stream<List<Booking>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => Booking.fromFirestore(doc))
              .toList();
          // Sort by createdAt descending in memory
          bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return bookings;
        });
  }

  // Get all bookings (for admin)
  Stream<List<Booking>> getAllBookings() {
    return _firestore
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Booking.fromFirestore(doc))
            .toList());
  }

  // Update booking status
  Future<void> updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore
          .collection('bookings')
          .doc(bookingId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Lỗi cập nhật trạng thái đặt bàn: ${e.toString()}');
    }
  }

  // ========== REVIEW OPERATIONS ==========

  // Create review and update restaurant rating
  Future<String> createReview(Review review) async {
    try {
      // Add review
      final docRef = await _firestore
          .collection('reviews')
          .add(review.toFirestore());
      
      // Calculate new average rating for the restaurant
      await _updateRestaurantRating(review.restaurantId);
      
      return docRef.id;
    } catch (e) {
      throw Exception('Lỗi tạo đánh giá: ${e.toString()}');
    }
  }

  // Get reviews for a restaurant
  Stream<List<Review>> getRestaurantReviews(String restaurantId) {
    return _firestore
        .collection('reviews')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
          final reviews = snapshot.docs
              .map((doc) => Review.fromFirestore(doc))
              .toList();
          // Sort by timestamp descending in memory
          reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return reviews;
        });
  }

  // Update restaurant rating based on all reviews
  Future<void> _updateRestaurantRating(String restaurantId) async {
    try {
      // Get all reviews for this restaurant
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        // No reviews, set rating to 0
        await _firestore.collection('restaurants').doc(restaurantId).update({
          'rating': 0.0,
        });
        return;
      }

      // Calculate average rating
      double totalRating = 0;
      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();
        totalRating += (data['rating'] ?? 0).toDouble();
      }
      final averageRating = totalRating / reviewsSnapshot.docs.length;

      // Update restaurant rating
      await _firestore.collection('restaurants').doc(restaurantId).update({
        'rating': averageRating,
      });
    } catch (e) {
      throw Exception('Lỗi cập nhật đánh giá nhà hàng: ${e.toString()}');
    }
  }

  // Check if user has already reviewed this restaurant
  Future<bool> hasUserReviewed(String userId, String restaurantId) async {
    try {
      // Use limit(1) to minimize data transfer - only check if exists
      final snapshot = await _firestore
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .where('restaurantId', isEqualTo: restaurantId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // Return false on error to allow user to try
      return false;
    }
  }

  // ========== NOTIFICATION OPERATIONS ==========

  // Get notifications for a user (ordered by timestamp descending)
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => AppNotification.fromFirestore(doc))
              .toList();
          // Sort by timestamp descending in memory to avoid requiring composite index
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return notifications;
        });
  }

  // Get unread notification count for a user
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Lỗi đánh dấu thông báo đã đọc: ${e.toString()}');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Lỗi đánh dấu tất cả thông báo đã đọc: ${e.toString()}');
    }
  }
}

