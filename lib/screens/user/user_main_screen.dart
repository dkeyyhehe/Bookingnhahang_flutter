import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../saved/saved_restaurants_screen.dart';
import '../profile/profile_screen.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'user_intro_screen.dart';
import 'notification_screen.dart';

class UserMainScreen extends StatefulWidget {
  const UserMainScreen({super.key});

  @override
  State<UserMainScreen> createState() => _UserMainScreenState();
}

class _UserMainScreenState extends State<UserMainScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserId;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _screens = [
      UserIntroScreen(
        onNavigateToRestaurants: () {
          setState(() {
            _selectedIndex = 2; // Navigate to Restaurants tab (updated index)
          });
        },
      ),
      const NotificationScreen(),
      const HomeScreen(),
      const SavedRestaurantsScreen(),
      const ProfileScreen(),
    ];
  }

  Future<void> _loadCurrentUser() async {
    try {
      final appUser = await _authService.getCurrentAppUser();
      if (appUser != null && mounted) {
        setState(() {
          _currentUserId = appUser.uid;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildNotificationIcon() {
    if (_currentUserId == null) {
      return Icon(Icons.notifications_outlined);
    }

    return StreamBuilder<int>(
      stream: _firestoreService.getUnreadNotificationCount(_currentUserId!),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        final hasUnread = unreadCount > 0;

        return Stack(
          children: [
            Icon(
              _selectedIndex == 1
                  ? Icons.notifications
                  : Icons.notifications_outlined,
            ),
            if (hasUnread)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: _currentUserId != null
                ? _buildNotificationIcon()
                : Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Nhà hàng',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Đã lưu',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

