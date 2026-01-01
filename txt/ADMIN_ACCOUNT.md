# Tài khoản Admin mặc định

## Thông tin đăng nhập

App sẽ tự động tạo tài khoản admin khi khởi động lần đầu.

**Email:** `admin@gmail.com`  
**Password:** `admin123456`

## Cách sử dụng

1. Mở app
2. Vào màn hình **Đăng nhập**
3. Nhập:
   - Email: `admin@gmail.com`
   - Password: `admin123456`
4. Click **Đăng nhập**

Sau khi đăng nhập, bạn sẽ được chuyển đến **Admin Dashboard** thay vì Home screen.

## Tính năng Admin

- Xem tất cả bookings của mọi người dùng
- Xác nhận hoặc hủy bookings
- Xem chi tiết từng booking

## Lưu ý bảo mật

⚠️ **Quan trọng:** Đây là tài khoản admin mặc định. Trong môi trường production, bạn nên:

1. Đổi password ngay sau khi tạo
2. Xóa tài khoản admin mặc định và tạo tài khoản admin riêng
3. Sử dụng Firebase Authentication để quản lý quyền truy cập tốt hơn

## Thay đổi thông tin admin

Nếu muốn thay đổi email hoặc password của admin, bạn có thể:

1. Đăng nhập vào Firebase Console
2. Vào **Authentication** > **Users**
3. Tìm user với email `admin@gmail.com`
4. Click vào user và thay đổi thông tin

Hoặc đăng ký tài khoản mới với email khác và cập nhật role trong Firestore:
- Collection: `users`
- Document: `{uid của user}`
- Field: `role` = `'admin'`

