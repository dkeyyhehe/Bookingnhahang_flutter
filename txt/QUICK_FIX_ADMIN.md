# Sửa nhanh tài khoản Admin trong Firestore

## Vấn đề hiện tại:

Trong Firestore, user có:
- Email: `admin@gmai.com` ❌ (thiếu chữ 'l')
- Role: `user` ❌ (cần là `admin`)

## Cách sửa nhanh:

### Bước 1: Sửa trong Firestore

1. Vào Firebase Console → Firestore → Collection `users`
2. Tìm document với email `admin@gmai.com` (hoặc bất kỳ email nào bạn muốn set làm admin)
3. Click vào document đó
4. Sửa các field:
   - **email**: Đổi thành `admin@gmail.com` (nếu muốn dùng email này)
   - **role**: Đổi từ `user` thành `admin`
5. Click **Update**

### Bước 2: Tạo tài khoản mới trong Firebase Auth (nếu cần)

Nếu bạn muốn tạo tài khoản mới với email đúng:

1. Vào Firebase Console → Authentication → Users
2. Click **Add user**
3. Email: `admin@gmail.com`
4. Password: `admin123456`
5. Click **Add user**
6. Copy **User UID**
7. Vào Firestore → Collection `users`
8. Tạo document mới với:
   - Document ID: Paste User UID vừa copy
   - Fields:
     - `email`: `admin@gmail.com`
     - `name`: `Administrator`
     - `role`: `admin`
     - `avatarUrl`: `null` (hoặc để trống)

### Bước 3: Đăng nhập

Sau khi sửa xong:
1. Đợi 15-30 phút (nếu bị block do too-many-requests)
2. Hoặc thử đăng nhập ngay với:
   - Email: `admin@gmail.com`
   - Password: `admin123456`

## Lưu ý:

- Email phải chính xác: `admin@gmail.com` (có chữ 'l')
- Role phải là `admin` (không phải `user`)
- Nếu vẫn bị block, đợi thêm thời gian hoặc thử từ thiết bị/network khác

