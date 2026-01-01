# Sửa lỗi đăng nhập Admin

## Lỗi: invalid-credential

Lỗi này xảy ra khi tài khoản admin chưa được tạo hoặc password sai.

## Giải pháp nhanh nhất:

### Cách 1: Đăng ký tài khoản admin thủ công

1. Trong app, click **"Đăng ký"** (Register)
2. Điền thông tin:
   - **Họ và tên:** Administrator (hoặc tên bất kỳ)
   - **Email:** `admin@gmail.com`
   - **Password:** `admin123456`
   - **Xác nhận mật khẩu:** `admin123456`
3. Click **"Đăng ký"**

Sau khi đăng ký, bạn sẽ tự động là admin (vì code check email `admin@gmail.com`) và được chuyển đến Admin Dashboard.

### Cách 2: Để app tự tạo (sau khi restart)

1. **Đảm bảo Email/Password đã được bật** trong Firebase Console
2. **Đóng app hoàn toàn** (không chỉ minimize)
3. **Mở lại app**
4. App sẽ tự động tạo admin account khi khởi động
5. Đợi 2-3 giây rồi thử đăng nhập

### Cách 3: Tạo admin trong Firebase Console (nếu cần)

1. Vào Firebase Console → Authentication → Users
2. Click **Add user**
3. Email: `admin@gmail.com`
4. Password: `admin123456`
5. Click **Add user**
6. Vào Firestore → Collection `users`
7. Tìm document với email `admin@gmail.com` (hoặc tạo mới với uid từ Auth)
8. Set field `role` = `'admin'`

## Thông tin đăng nhập Admin:

- **Email:** `admin@gmail.com`
- **Password:** `admin123456`

## Lưu ý:

- Nếu bạn đã đăng ký với email khác và muốn set làm admin, có thể sửa role trong Firestore
- Sau khi đăng nhập thành công, bạn sẽ thấy Admin Dashboard thay vì Home screen

