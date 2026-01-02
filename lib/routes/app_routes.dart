import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/restaurant/restaurant_detail_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/booking/booking_success_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/saved/saved_restaurants_screen.dart';
import '../screens/review/add_review_screen.dart';
import '../screens/user/user_intro_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const detail = '/detail';
  static const booking = '/booking';
  static const success = '/success';
  static const profile = '/profile';
  static const adminDashboard = '/admin-dashboard';
  static const savedRestaurants = '/saved-restaurants';
  static const addReview = '/add-review';
  static const userIntro = '/user-intro';

  static final routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    detail: (context) => const RestaurantDetailScreen(),
    booking: (context) => const BookingScreen(),
    success: (context) => const BookingSuccessScreen(),
    profile: (context) => const ProfileScreen(),
    adminDashboard: (context) => const AdminDashboardScreen(),
    savedRestaurants: (context) => const SavedRestaurantsScreen(),
    addReview: (context) => const AddReviewScreen(),
    userIntro: (context) => const UserIntroScreen(),
  };
}
