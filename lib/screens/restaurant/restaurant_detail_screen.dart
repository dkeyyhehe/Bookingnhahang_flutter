import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../models/restaurant.dart';
import '../../models/review.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user.dart';
import '../../widgets/review_item.dart';

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key});

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  AppUser? _currentUser;
  bool _isFavorite = false;
  bool _isLoading = false;
  bool _hasReviewed = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndFavoriteStatus();
  }

  Future<void> _loadUserAndFavoriteStatus() async {
    try {
      final appUser = await _authService.getCurrentAppUser();
      if (appUser != null && mounted) {
        final restaurant = ModalRoute.of(context)!.settings.arguments as Restaurant;
        final hasReviewed = await _firestoreService.hasUserReviewed(
          appUser.uid,
          restaurant.id,
        );
        setState(() {
          _currentUser = appUser;
          _isFavorite = appUser.favoriteRestaurantIds.contains(restaurant.id);
          _hasReviewed = hasReviewed;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUser == null) return;

    final restaurant = ModalRoute.of(context)!.settings.arguments as Restaurant;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.toggleFavoriteRestaurant(
        _currentUser!.uid,
        restaurant.id,
      );
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
          _isLoading = false;
        });
        await _loadUserAndFavoriteStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = ModalRoute.of(context)!.settings.arguments as Restaurant;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                      ),
                onPressed: _currentUser != null ? _toggleFavorite : null,
                tooltip: _isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: restaurant.imageUrl.startsWith('http')
                  ? Image.network(
                      restaurant.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/restaurant.jpg',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      restaurant.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.restaurant, size: 64),
                        );
                      },
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 24),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          restaurant.address,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Mô tả',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.booking,
                          arguments: restaurant,
                        );
                      },
                      icon: const Icon(Icons.table_restaurant),
                      label: const Text(
                        'Đặt bàn',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Đánh giá',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentUser != null && !_hasReviewed)
                        TextButton.icon(
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                              context,
                              AppRoutes.addReview,
                              arguments: restaurant,
                            );
                            if (result == true && mounted) {
                              // Reload to update hasReviewed status
                              await _loadUserAndFavoriteStatus();
                            }
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Viết đánh giá'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Reviews List
                  StreamBuilder<List<Review>>(
                    stream: _firestoreService.getRestaurantReviews(restaurant.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Lỗi tải đánh giá: ${snapshot.error}',
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        );
                      }

                      final reviews = snapshot.data ?? [];

                      if (reviews.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Chưa có đánh giá nào',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (_currentUser != null && !_hasReviewed) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final result = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.addReview,
                                      arguments: restaurant,
                                    );
                                    if (result == true && mounted) {
                                      await _loadUserAndFavoriteStatus();
                                    }
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Viết đánh giá đầu tiên'),
                                ),
                              ],
                            ],
                          ),
                        );
                      }

                      return Column(
                        children: [
                          // Average rating display
                          Card(
                            color: Colors.blue[50],
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 32),
                                  const SizedBox(width: 8),
                                  Text(
                                    restaurant.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '(${reviews.length} đánh giá)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Reviews list
                          ...reviews.map((review) => ReviewItem(review: review)),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
