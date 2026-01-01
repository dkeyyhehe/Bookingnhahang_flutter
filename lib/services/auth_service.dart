import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import '../models/user.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<AppUser?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        return await _firestoreService.getUser(credential.user!.uid);
      }
      return null;
    } catch (e) {
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }

  // Register with email and password
  Future<AppUser?> registerWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final appUser = AppUser(
          uid: credential.user!.uid,
          email: email,
          name: name,
          role: email == 'admin@gmail.com' ? 'admin' : 'user',
        );

        await _firestoreService.createUser(appUser);
        return appUser;
      }
      return null;
    } catch (e) {
      throw Exception('Đăng ký thất bại: ${e.toString()}');
    }
  }

  // Sign in with Google
  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final user = userCredential.user!;
        
        // Check if user exists in Firestore
        var appUser = await _firestoreService.getUser(user.uid);
        
        if (appUser == null) {
          // Create new user document
          appUser = AppUser(
            uid: user.uid,
            email: user.email ?? '',
            name: user.displayName ?? 'User',
            role: user.email == 'admin@gmail.com' ? 'admin' : 'user',
            avatarUrl: user.photoURL,
          );
          await _firestoreService.createUser(appUser);
        }
        
        return appUser;
      }
      return null;
    } on PlatformException catch (e) {
      // Handle specific Google Sign-In errors
      if (e.code == 'sign_in_failed' && e.message?.contains('10') == true) {
        throw Exception(
          'Lỗi cấu hình Google Sign-In. Vui lòng:\n'
          '1. Lấy SHA-1 fingerprint bằng lệnh: keytool -list -v -keystore "%USERPROFILE%\\.android\\debug.keystore" -alias androiddebugkey -storepass android -keypass android\n'
          '2. Thêm SHA-1 vào Firebase Console > Project Settings > Your Apps > Android App\n'
          '3. Tải lại google-services.json và đặt vào android/app/\n'
          '4. Khởi động lại ứng dụng',
        );
      }
      throw Exception('Đăng nhập Google thất bại: ${e.message ?? e.toString()}');
    } catch (e) {
      throw Exception('Đăng nhập Google thất bại: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Đăng xuất thất bại: ${e.toString()}');
    }
  }

  // Get current app user
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;
    return await _firestoreService.getUser(user.uid);
  }
}

