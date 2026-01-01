# Cách sửa lỗi Google Sign-In

## Bạn đã thêm SHA-1 vào Firebase Console ✅

Nhưng file `google-services.json` hiện tại vẫn chưa có cấu hình OAuth client.

## Các bước tiếp theo:

### Bước 1: Tải lại google-services.json từ Firebase Console

1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project: **datbannhahang**
3. Vào **Project Settings** (⚙️)
4. Tìm app Android: **baitap (android)**
5. Click nút **"google-services.json"** (có icon download 📥)
6. File sẽ được tải về

### Bước 2: Thay thế file cũ

1. Copy file `google-services.json` vừa tải về
2. Paste vào thư mục: `android/app/google-services.json` (thay thế file cũ)

### Bước 3: Khởi động lại app

```bash
flutter clean
flutter run
```

## Kiểm tra:

Sau khi thay file, mở `android/app/google-services.json` và kiểm tra phần `oauth_client`:

**Trước (sai):**
```json
"oauth_client": []
```

**Sau (đúng):**
```json
"oauth_client": [
  {
    "client_id": "...",
    "client_type": 1,
    "android_info": {
      "package_name": "com.example.baitap",
      "certificate_hash": "7c:1e:bc:87:8e:1f:ae:7b:f2:61:bd:56:40:03:f3:c0:d5:4d:ac:76"
    }
  }
]
```

Nếu `oauth_client` không còn rỗng nữa, nghĩa là đã đúng! 🎉

