import 'dart:async';
import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/restaurant.dart';
import '../../models/user.dart';
import '../../widgets/restaurant_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _searchQuery = '';
  bool _isSeeding = false;
  List<Restaurant> _cachedRestaurants = [];
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');
  AppUser? _currentUser;
  Set<String> _favoriteIds = {};
  String? _selectedLocationFilter;
  bool _filterByHighRating = false;

  @override
  void initState() {
    super.initState();
    _seedRestaurantsIfNeeded();
    _searchController.addListener(_onSearchChanged);
    _searchQueryNotifier.value = _searchQuery;
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
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer if exists
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }
    
    // Update search query immediately for instant filtering
    final currentText = _searchController.text;
    final normalizedQuery = _normalizeText(currentText);
    
    // Update state immediately to trigger UI rebuild
    if (mounted) {
      setState(() {
        _searchQuery = normalizedQuery;
      });
      // Update notifier to trigger rebuild of filtered list widget
      _searchQueryNotifier.value = normalizedQuery;
    }
  }

  // Remove Vietnamese diacritics for better search
  // Comprehensive mapping of Vietnamese characters to their non-diacritic equivalents
  String _removeVietnameseDiacritics(String str) {
    // Map Vietnamese characters to their base equivalents
    const Map<String, String> diacriticsMap = {
      // a variants
      'à': 'a', 'á': 'a', 'ạ': 'a', 'ả': 'a', 'ã': 'a',
      'À': 'A', 'Á': 'A', 'Ạ': 'A', 'Ả': 'A', 'Ã': 'A',
      // â variants
      'â': 'a', 'ầ': 'a', 'ấ': 'a', 'ậ': 'a', 'ẩ': 'a', 'ẫ': 'a',
      'Â': 'A', 'Ầ': 'A', 'Ấ': 'A', 'Ậ': 'A', 'Ẩ': 'A', 'Ẫ': 'A',
      // ă variants
      'ă': 'a', 'ằ': 'a', 'ắ': 'a', 'ặ': 'a', 'ẳ': 'a', 'ẵ': 'a',
      'Ă': 'A', 'Ằ': 'A', 'Ắ': 'A', 'Ặ': 'A', 'Ẳ': 'A', 'Ẵ': 'A',
      // e variants
      'è': 'e', 'é': 'e', 'ẹ': 'e', 'ẻ': 'e', 'ẽ': 'e',
      'È': 'E', 'É': 'E', 'Ẹ': 'E', 'Ẻ': 'E', 'Ẽ': 'E',
      // ê variants
      'ê': 'e', 'ề': 'e', 'ế': 'e', 'ệ': 'e', 'ể': 'e', 'ễ': 'e',
      'Ê': 'E', 'Ề': 'E', 'Ế': 'E', 'Ệ': 'E', 'Ể': 'E', 'Ễ': 'E',
      // i variants
      'ì': 'i', 'í': 'i', 'ị': 'i', 'ỉ': 'i', 'ĩ': 'i',
      'Ì': 'I', 'Í': 'I', 'Ị': 'I', 'Ỉ': 'I', 'Ĩ': 'I',
      // o variants
      'ò': 'o', 'ó': 'o', 'ọ': 'o', 'ỏ': 'o', 'õ': 'o',
      'Ò': 'O', 'Ó': 'O', 'Ọ': 'O', 'Ỏ': 'O', 'Õ': 'O',
      // ô variants
      'ô': 'o', 'ồ': 'o', 'ố': 'o', 'ộ': 'o', 'ổ': 'o', 'ỗ': 'o',
      'Ô': 'O', 'Ồ': 'O', 'Ố': 'O', 'Ộ': 'O', 'Ổ': 'O', 'Ỗ': 'O',
      // ơ variants
      'ơ': 'o', 'ờ': 'o', 'ớ': 'o', 'ợ': 'o', 'ở': 'o', 'ỡ': 'o',
      'Ơ': 'O', 'Ờ': 'O', 'Ớ': 'O', 'Ợ': 'O', 'Ở': 'O', 'Ỡ': 'O',
      // u variants
      'ù': 'u', 'ú': 'u', 'ụ': 'u', 'ủ': 'u', 'ũ': 'u',
      'Ù': 'U', 'Ú': 'U', 'Ụ': 'U', 'Ủ': 'U', 'Ũ': 'U',
      // ư variants
      'ư': 'u', 'ừ': 'u', 'ứ': 'u', 'ự': 'u', 'ử': 'u', 'ữ': 'u',
      'Ư': 'U', 'Ừ': 'U', 'Ứ': 'U', 'Ự': 'U', 'Ử': 'U', 'Ữ': 'U',
      // y variants
      'ỳ': 'y', 'ý': 'y', 'ỵ': 'y', 'ỷ': 'y', 'ỹ': 'y',
      'Ỳ': 'Y', 'Ý': 'Y', 'Ỵ': 'Y', 'Ỷ': 'Y', 'Ỹ': 'Y',
      // đ
      'đ': 'd', 'Đ': 'D',
    };
    
    String result = str;
    diacriticsMap.forEach((vietnamese, english) {
      result = result.replaceAll(vietnamese, english);
    });
    return result;
  }

  // Normalize text for comparison - converts to lowercase and removes diacritics
  String _normalizeText(String text) {
    if (text.isEmpty) return '';
    return _removeVietnameseDiacritics(text.toLowerCase().trim());
  }

  // Legacy method - filtering is now done in _RestaurantListWidget
  // Keeping for backward compatibility, but updated to match new requirements
  List<Restaurant> _filterRestaurants(List<Restaurant> restaurants, String query) {
    if (query.isEmpty) {
      return restaurants;
    }
    
    // Normalize the entire search query (do NOT split by spaces)
    final normalizedQuery = _normalizeText(query);
    if (normalizedQuery.isEmpty) {
      return restaurants;
    }
    
    // Strict substring match: entire query must appear as consecutive string in restaurant name only
    final filtered = restaurants.where((restaurant) {
      final normalizedName = _normalizeText(restaurant.name);
      // Check only restaurant name, not address or description
      return normalizedName.contains(normalizedQuery);
    }).toList();
    
    return filtered;
  }

  Future<void> _seedRestaurantsIfNeeded() async {
    try {
      setState(() => _isSeeding = true);
      await _firestoreService.seedRestaurants();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi đăng xuất: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách nhà hàng'),

      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, child) {
                return TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.none,
                  enableSuggestions: true,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm nhà hàng...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              if (mounted) {
                                setState(() {
                                  _searchQuery = '';
                                });
                                _searchQueryNotifier.value = '';
                              }
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                );
              },
            ),
          ),
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Đánh giá > 4⭐'),
                    selected: _filterByHighRating,
                    onSelected: (selected) {
                      setState(() {
                        _filterByHighRating = selected;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Quận 1'),
                    selected: _selectedLocationFilter == 'Quận 1',
                    onSelected: (selected) {
                      setState(() {
                        _selectedLocationFilter = selected ? 'Quận 1' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Quận 3'),
                    selected: _selectedLocationFilter == 'Quận 3',
                    onSelected: (selected) {
                      setState(() {
                        _selectedLocationFilter = selected ? 'Quận 3' : null;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: _selectedLocationFilter == null && !_filterByHighRating,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedLocationFilter = null;
                          _filterByHighRating = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Restaurant List
          Expanded(
            child: StreamBuilder<List<Restaurant>>(
              stream: _firestoreService.getRestaurants(),
              builder: (context, snapshot) {
                if (_isSeeding) {
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
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _seedRestaurantsIfNeeded,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Update cached restaurants when stream data changes
                final allRestaurants = snapshot.data ?? [];
                if (allRestaurants.isNotEmpty) {
                  _cachedRestaurants = allRestaurants;
                }

                // Use cached restaurants for filtering
                final restaurantsToFilter = _cachedRestaurants;

                if (restaurantsToFilter.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Chưa có nhà hàng nào'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _seedRestaurantsIfNeeded,
                          child: const Text('Tạo dữ liệu mẫu'),
                        ),
                      ],
                    ),
                  );
                }

                // Return a widget that will rebuild when _searchQuery changes
                // Filtering happens inside _RestaurantListWidget
                return ValueListenableBuilder<String>(
                  valueListenable: _searchQueryNotifier,
                  builder: (context, currentQuery, child) {
                    return _RestaurantListWidget(
                      restaurants: restaurantsToFilter,
                      searchQuery: currentQuery,
                      searchController: _searchController,
                      normalizeText: _normalizeText,
                      removeDiacritics: _removeVietnameseDiacritics,
                      favoriteIds: _favoriteIds,
                      onFavoriteToggle: _toggleFavorite,
                      filterByHighRating: _filterByHighRating,
                      locationFilter: _selectedLocationFilter,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Separate widget that rebuilds when searchQuery changes
class _RestaurantListWidget extends StatelessWidget {
  final List<Restaurant> restaurants;
  final String searchQuery;
  final TextEditingController searchController;
  final String Function(String) normalizeText;
  final String Function(String) removeDiacritics;
  final Set<String> favoriteIds;
  final Future<void> Function(String) onFavoriteToggle;
  final bool filterByHighRating;
  final String? locationFilter;

  const _RestaurantListWidget({
    required this.restaurants,
    required this.searchQuery,
    required this.searchController,
    required this.normalizeText,
    required this.removeDiacritics,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    this.filterByHighRating = false,
    this.locationFilter,
  });

  List<Restaurant> _filterRestaurants(List<Restaurant> restaurants, String query) {
    List<Restaurant> filtered = restaurants;

    // Apply search query filter - strict substring match on restaurant name only
    if (query.isNotEmpty) {
      // Normalize the entire search query (do NOT split by spaces)
      final normalizedQuery = normalizeText(query);
      if (normalizedQuery.isNotEmpty) {
        filtered = filtered.where((restaurant) {
          // Normalize restaurant name only (not address or description)
          final normalizedName = normalizeText(restaurant.name);
          
          // Strict substring match: entire query must appear as consecutive string in name
          // Example: "bun bo" should match "Bún Bò Huế" (normalized: "bun bo" in "bun bo hue")
          return normalizedName.contains(normalizedQuery);
        }).toList();
      }
    }

    // Apply rating filter
    if (filterByHighRating) {
      filtered = filtered.where((restaurant) => restaurant.rating > 4.0).toList();
    }

    // Apply location filter
    if (locationFilter != null) {
      filtered = filtered.where((restaurant) {
        return restaurant.address.contains(locationFilter!);
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    // Filter restaurants based on current search query
    final filteredRestaurants = _filterRestaurants(restaurants, searchQuery);

    if (filteredRestaurants.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Không tìm thấy nhà hàng với từ khóa "${searchController.text}"'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = filteredRestaurants[index];
        return RestaurantItem(
          restaurant: restaurant,
          isFavorite: favoriteIds.contains(restaurant.id),
          onFavoriteToggle: () => onFavoriteToggle(restaurant.id),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.detail,
              arguments: restaurant,
            );
          },
        );
      },
    );
  }
}
