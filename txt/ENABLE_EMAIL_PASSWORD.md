# Hướng dẫn bật Email/Password Authentication

## Lỗi hiện tại:
```
Đăng nhập thất bại: [firebase_auth/operation-not-allowed]
This operation is not allowed. This may be because the given sign-in provider is disabled for this Firebase project.
```

## Nguyên nhân:
Email/Password authentication chưa được bật trong Firebase Console.

## Cách khắc phục:

### Bước 1: Truy cập Firebase Console
1. Vào [Firebase Console](https://console.firebase.google.com/)
2. Chọn project của bạn: **datbannhahang**

### Bước 2: Bật Email/Password Authentication
1. Trong menu bên trái, click **Authentication**
2. Click vào tab **Sign-in method** (hoặc **Phương thức đăng nhập**)
3. Tìm **Email/Password** trong danh sách các providers
4. Click vào **Email/Password**
5. Bật toggle **Enable** (chuyển sang trạng thái BẬT)
6. (Tùy chọn) Bật **Email link (passwordless sign-in)** nếu muốn
7. Click **Save**

### Bước 3: Kiểm tra
Sau khi bật, bạn sẽ thấy trạng thái **Enabled** màu xanh bên cạnh Email/Password.

### Bước 4: Thử lại đăng nhập
Quay lại app và thử đăng nhập lại với:
- Email: `admin@gmail.com`
- Password: `admin123456`

## Lưu ý:

- Sau khi bật Email/Password, bạn có thể đăng ký và đăng nhập bằng email/password
- Tài khoản admin sẽ được tự động tạo khi app khởi động lần đầu (sau khi Email/Password đã được bật)
- Nếu vẫn gặp lỗi, đảm bảo bạn đã click **Save** sau khi bật

## Nếu vẫn gặp lỗi:

1. Đảm bảo bạn đã bật **Email/Password** (không phải chỉ Email link)
2. Đợi 1-2 phút sau khi bật để Firebase cập nhật
3. Restart app: `flutter clean && flutter run`
4. Kiểm tra lại trong Firebase Console xem Email/Password đã được bật chưa

