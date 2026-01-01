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
    // Cancel previous timer
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    
    // Update search query immediately for instant filtering
    final currentText = _searchController.text;
    final normalizedQuery = _removeVietnameseDiacritics(
      currentText.toLowerCase().trim(),
    );
    
    if (mounted && _searchQuery != normalizedQuery) {
      setState(() {
        _searchQuery = normalizedQuery;
      });
      // Update notifier to trigger rebuild of filtered list
      _searchQueryNotifier.value = normalizedQuery;
    }
  }

  // Remove Vietnamese diacritics for better search
  String _removeVietnameseDiacritics(String str) {
    const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const english = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeiiiiioooooooooooooooouuuuuuuuuuyyyyyyd';
    
    String result = str;
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], english[i]);
      result = result.replaceAll(vietnamese[i].toUpperCase(), english[i].toUpperCase());
    }
    return result;
  }

  // Normalize text for comparison
  String _normalizeText(String text) {
    return _removeVietnameseDiacritics(text.toLowerCase());
  }

  List<Restaurant> _filterRestaurants(List<Restaurant> restaurants, String query) {
    if (query.isEmpty) {
      return restaurants;
    }
    
    final normalizedQuery = _normalizeText(query);
    if (normalizedQuery.isEmpty) {
      return restaurants;
    }
    
    final filtered = restaurants.where((restaurant) {
      final normalizedName = _normalizeText(restaurant.name);
      final normalizedAddress = _normalizeText(restaurant.address);
      final normalizedDescription = _normalizeText(restaurant.description);
      
      final matches = normalizedName.contains(normalizedQuery) ||
          normalizedAddress.contains(normalizedQuery) ||
          normalizedDescription.contains(normalizedQuery);
      
      return matches;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Hồ sơ',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
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

    // Apply search query filter
    if (query.isNotEmpty) {
      final normalizedQuery = normalizeText(query);
      if (normalizedQuery.isNotEmpty) {
        filtered = filtered.where((restaurant) {
          final normalizedName = normalizeText(restaurant.name);
          final normalizedAddress = normalizeText(restaurant.address);
          final normalizedDescription = normalizeText(restaurant.description);
          
          return normalizedName.contains(normalizedQuery) ||
              normalizedAddress.contains(normalizedQuery) ||
              normalizedDescription.contains(normalizedQuery);
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
