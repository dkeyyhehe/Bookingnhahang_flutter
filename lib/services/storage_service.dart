import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image to Firebase Storage
  /// Returns download URL
  Future<String> uploadImage(File imageFile, String folder) async {
    try {
      final fileName = path.basename(imageFile.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '$timestamp$fileName';
      
      final ref = _storage.ref().child('$folder/$uniqueFileName');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Lỗi upload ảnh: ${e.toString()}');
    }
  }

  /// Delete image from Firebase Storage by URL
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.startsWith('http')) {
        return; // Not a Firebase Storage URL, skip deletion
      }

      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Ignore errors if image doesn't exist
      debugPrint('Lỗi xóa ảnh: ${e.toString()}');
    }
  }
}

