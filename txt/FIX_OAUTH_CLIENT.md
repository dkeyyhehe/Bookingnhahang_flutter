# Fix: oauth_client vẫn rỗng sau khi thêm SHA-1

## Vấn đề:
File `google-services.json` vẫn có `"oauth_client": []` mặc dù đã thêm SHA-1 vào Firebase Console.

## Nguyên nhân:
Firebase chưa tự động tạo OAuth client ID. Cần enable Google Sign-In method trong Firebase Authentication.

## Cách khắc phục:

### Bước 1: Enable Google Sign-In trong Firebase Authentication

1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project: **datbannhahang**
3. Vào **Authentication** (trong menu bên trái)
4. Click tab **Sign-in method**
5. Tìm **Google** trong danh sách providers
6. Click vào **Google**
7. Bật **Enable** toggle
8. Chọn **Project support email** (email của bạn)
9. Click **Save**

### Bước 2: Đợi vài phút

Sau khi enable Google Sign-In, Firebase sẽ tự động tạo OAuth client ID. Đợi 2-3 phút.

### Bước 3: Tải lại google-services.json

1. Vào **Project Settings** (⚙️)
2. Tìm app Android: **baitap (android)**
3. Click nút **"google-services.json"** để tải lại
4. Thay thế file trong `android/app/google-services.json`

### Bước 4: Kiểm tra

Mở file `google-services.json` và kiểm tra:

**Đúng (có dữ liệu):**
```json
"oauth_client": [
  {
    "client_id": "509711775144-xxxxx.apps.googleusercontent.com",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.baitap",
      "certificate_hash": "7c:1e:bc:87:8e:1f:ae:7b:f2:61:bd:56:40:03:f3:c0:d5:4d:ac:76"
    }
  }
]
```

**Sai (vẫn rỗng):**
```json
"oauth_client": []
```

### Bước 5: Restart app

```bash
flutter clean
flutter run
```

## Lưu ý:

- Nếu sau khi enable Google Sign-In mà vẫn không có OAuth client, có thể cần đợi thêm 5-10 phút
- Đảm bảo SHA-1 fingerprint đã được thêm đúng trong Firebase Console
- Package name phải khớp: `com.example.baitap`

