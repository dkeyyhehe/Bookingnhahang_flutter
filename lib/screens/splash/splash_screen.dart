import 'package:flutter/material.dart';
import 'dart:async';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/seed_admin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();
  final SeedAdminService _seedAdminService = SeedAdminService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Tự động tạo admin account nếu chưa có
    try {
      await _seedAdminService.createDefaultAdmin();
    } catch (e) {
      // Ignore errors, admin might already exist
      debugPrint('Seed admin: ${e.toString()}');
    }

    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = await _authService.getCurrentAppUser();
    
    if (!mounted) return;

    if (user != null) {
      // User is logged in, navigate based on role
      if (user.isAdmin) {
        Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } else {
      // User is not logged in
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Food Booking',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
