import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/restaurant.dart';
import '../../models/user.dart';
import '../../widgets/restaurant_item.dart';

class SavedRestaurantsScreen extends StatefulWidget {
  const SavedRestaurantsScreen({super.key});

  @override
  State<SavedRestaurantsScreen> createState() => _SavedRestaurantsScreenState();
}

class _SavedRestaurantsScreenState extends State<SavedRestaurantsScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  AppUser? _currentUser;
  Set<String> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final appUser = await _authService.getCurrentAppUser();
      if (appUser != null && mounted) {
        setState(() {
          _currentUser = appUser;
          _favoriteIds = appUser.favoriteRestaurantIds.toSet();
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFavorite(String restaurantId) async {
    if (_currentUser == null) return;

    try {
      await _firestoreService.toggleFavoriteRestaurant(
        _currentUser!.uid,
        restaurantId,
      );
      // Update local state
      if (mounted) {
        setState(() {
          if (_favoriteIds.contains(restaurantId)) {
            _favoriteIds.remove(restaurantId);
          } else {
            _favoriteIds.add(restaurantId);
          }
        });
        // Reload user to sync
        await _loadCurrentUser();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nhà hàng đã lưu'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhà hàng đã lưu'),
      ),
      body: StreamBuilder<List<Restaurant>>(
        stream: _firestoreService.getFavoriteRestaurantsStream(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                ],
              ),
            );
          }

          final restaurants = snapshot.data ?? [];

          if (restaurants.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có nhà hàng yêu thích nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy thêm nhà hàng vào yêu thích để xem ở đây',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return RestaurantItem(
                restaurant: restaurant,
                isFavorite: _favoriteIds.contains(restaurant.id),
                onFavoriteToggle: () => _toggleFavorite(restaurant.id),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.detail,
                    arguments: restaurant,
                  ).then((_) {
                    // Reload favorites when returning from detail screen
                    _loadCurrentUser();
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}

