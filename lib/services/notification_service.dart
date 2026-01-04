import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send a notification to a user
  /// 
  /// [userId] - The user ID to send the notification to
  /// [title] - The notification title
  /// [body] - The notification body/message
  /// [type] - The notification type ('success', 'error', or 'info')
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Lỗi gửi thông báo: ${e.toString()}');
    }
  }
}

