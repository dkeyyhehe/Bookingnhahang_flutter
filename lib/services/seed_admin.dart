import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import '../models/user.dart';

/// Script để tạo tài khoản admin mặc định
/// Chạy function này một lần để tạo admin account
class SeedAdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Tạo tài khoản admin mặc định
  /// Email: admin@gmail.com
  /// Password: admin123456
  Future<String> createDefaultAdmin() async {
    try {
      const adminEmail = 'admin@gmail.com';
      const adminPassword = 'admin123456';
      const adminName = 'Administrator';

      // Kiểm tra xem user đã tồn tại trong Firestore chưa
      try {
        final users = await _firestoreService.getAllUsers();
        final existingAdmin = users.firstWhere(
          (u) => u.email == adminEmail && u.role == 'admin',
          orElse: () => throw Exception('Not found'),
        );
        return 'Tài khoản admin đã tồn tại!\nEmail: $adminEmail';
      } catch (e) {
        // User chưa tồn tại, tiếp tục tạo mới
      }

      // Kiểm tra xem email đã được đăng ký trong Firebase Auth chưa
      try {
        await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        // Nếu đăng nhập thành công, user đã tồn tại trong Auth
        // Kiểm tra và cập nhật role trong Firestore
        final currentUser = _auth.currentUser;
        if (currentUser != null) {
          final existingUser = await _firestoreService.getUser(currentUser.uid);
          if (existingUser != null) {
            if (existingUser.role != 'admin') {
              await _firestoreService.updateUserRole(currentUser.uid, 'admin');
              return '✅ Đã cập nhật tài khoản thành admin!\nEmail: $adminEmail\nPassword: $adminPassword';
            }
            return 'Tài khoản admin đã tồn tại!\nEmail: $adminEmail';
          } else {
            // User có trong Auth nhưng chưa có trong Firestore
            final adminUser = AppUser(
              uid: currentUser.uid,
              email: adminEmail,
              name: adminName,
              role: 'admin',
            );
            await _firestoreService.createUser(adminUser);
            await _auth.signOut(); // Đăng xuất sau khi tạo
            return '✅ Đã tạo tài khoản admin thành công!\nEmail: $adminEmail\nPassword: $adminPassword';
          }
        }
      } on FirebaseAuthException catch (e) {
        // Nếu lỗi là user-not-found, tạo user mới
        if (e.code == 'user-not-found') {
          // Tạo user mới
          final credential = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );

          if (credential.user != null) {
            // Tạo user document trong Firestore với role admin
            final adminUser = AppUser(
              uid: credential.user!.uid,
              email: adminEmail,
              name: adminName,
              role: 'admin',
            );

            await _firestoreService.createUser(adminUser);
            await _auth.signOut(); // Đăng xuất sau khi tạo
            return '✅ Đã tạo tài khoản admin thành công!\nEmail: $adminEmail\nPassword: $adminPassword';
          }
        } else if (e.code == 'wrong-password') {
          // Tài khoản đã tồn tại nhưng password sai
          // Xóa tài khoản cũ và tạo lại
          try {
            final currentUser = _auth.currentUser;
            if (currentUser != null) {
              await currentUser.delete();
            }
          } catch (_) {
            // Ignore delete errors
          }
          
          // Tạo lại với password đúng
          final credential = await _auth.createUserWithEmailAndPassword(
            email: adminEmail,
            password: adminPassword,
          );

          if (credential.user != null) {
            final adminUser = AppUser(
              uid: credential.user!.uid,
              email: adminEmail,
              name: adminName,
              role: 'admin',
            );

            await _firestoreService.createUser(adminUser);
            await _auth.signOut();
            return '✅ Đã tạo lại tài khoản admin thành công!\nEmail: $adminEmail\nPassword: $adminPassword';
          }
        } else {
          throw Exception('Lỗi: ${e.message}');
        }
      }

      throw Exception('Không thể tạo tài khoản admin');
    } catch (e) {
      throw Exception('Lỗi tạo admin: ${e.toString()}');
    }
  }

  /// Cập nhật role của user thành admin (nếu user đã tồn tại)
  Future<String> setUserAsAdmin(String email) async {
    try {
      // Lấy user từ Firestore
      final users = await _firestoreService.getAllUsers();
      final user = users.firstWhere(
        (u) => u.email == email,
        orElse: () => throw Exception('Không tìm thấy user với email: $email'),
      );

      // Cập nhật role thành admin
      await _firestoreService.updateUserRole(user.uid, 'admin');
      return '✅ Đã cập nhật $email thành admin!';
    } catch (e) {
      throw Exception('Lỗi: ${e.toString()}');
    }
  }
}

