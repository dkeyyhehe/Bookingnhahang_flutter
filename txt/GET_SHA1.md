# Hướng dẫn cấu hình Google Sign-In

## Lỗi: PlatformException(sign_in_failed, ApiException: 10)

Lỗi này xảy ra khi thiếu cấu hình OAuth Client ID trong Firebase Console.

## SHA-1 Fingerprint của bạn:

**SHA1: `7C:1E:BC:87:8E:1F:AE:7B:F2:61:BD:56:40:03:F3:C0:D5:4D:AC:76`**

## Các bước khắc phục:

### Bước 1: Lấy SHA-1 Fingerprint (Đã có sẵn ở trên)

Nếu cần lấy lại, chạy lệnh sau trong terminal:

**Windows:**
```bash
cd android
.\gradlew signingReport
```

**Hoặc dùng keytool:**
```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Bước 2: Thêm SHA-1 vào Firebase Console

1. Truy cập [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn: **datbannhahang**
3. Vào **Project Settings** (⚙️ ở góc trên bên trái)
4. Cuộn xuống phần **Your apps**
5. Tìm Android app với package name: `com.example.baitap`
6. Click **Add fingerprint** (nút bên cạnh SHA certificate fingerprints)
7. Dán SHA-1 fingerprint: `7C:1E:BC:87:8E:1F:AE:7B:F2:61:BD:56:40:03:F3:C0:D5:4D:AC:76`
8. Click **Save**

### Bước 3: Tải lại google-services.json

1. Vẫn trong Firebase Console > Project Settings
2. Trong phần Android app, click **Download google-services.json**
3. Thay thế file `android/app/google-services.json` bằng file mới tải về

### Bước 4: Khởi động lại ứng dụng

```bash
flutter clean
flutter pub get
flutter run
```

## Lưu ý:

- Nếu bạn có **release keystore**, cần thêm SHA-1 của release keystore cũng vậy
- SHA-1 fingerprint khác nhau cho debug và release builds
- Sau khi thêm SHA-1, có thể mất vài phút để Firebase cập nhật

## Kiểm tra:

Sau khi cấu hình xong, file `google-services.json` sẽ có phần `oauth_client` không còn rỗng:

```json
"oauth_client": [
  {
    "client_id": "...",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.baitap",
      "certificate_hash": "..."
    }
  }
]
```

