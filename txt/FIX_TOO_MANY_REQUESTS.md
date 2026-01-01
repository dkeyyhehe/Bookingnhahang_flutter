# Sửa lỗi "too-many-requests"

## Lỗi:
```
We have blocked all requests from this device due to unusual activity. Try again later.
```

## Nguyên nhân:
Firebase đã tạm khóa thiết bị do quá nhiều lần thử đăng nhập sai.

## Giải pháp:

### Cách 1: Đợi 15-30 phút
Firebase sẽ tự động mở khóa sau 15-30 phút. Đợi rồi thử lại.

### Cách 2: Sửa trong Firestore (Nhanh hơn)

Tôi thấy trong Firestore bạn có user với:
- Email: `admin@gmai.com` (thiếu chữ 'l')
- Role: `user` (cần sửa thành `admin`)

**Cách sửa:**

1. Vào Firebase Console → Firestore → Collection `users`
2. Tìm document với email `admin@gmai.com` (hoặc tạo mới với email đúng)
3. Sửa các field:
   - `email`: `admin@gmail.com` (thêm chữ 'l')
   - `role`: `admin` (thay vì `user`)
4. Click **Update**

### Cách 3: Tạo tài khoản mới với email đúng

1. Đợi 15-30 phút để Firebase mở khóa
2. Vào màn hình **Đăng ký**
3. Đăng ký với:
   - Email: `admin@gmail.com` (đúng chính tả)
   - Password: `admin123456`
   - Tên: Administrator
4. Sau khi đăng ký, vào Firestore và sửa `role` thành `admin`

### Cách 4: Xóa user cũ và tạo lại (trong Firebase Console)

1. Vào Firebase Console → Authentication → Users
2. Tìm user với email `admin@gmai.com` hoặc `admin@gmail.com`
3. Click vào user → Click **Delete user**
4. Đợi 15-30 phút
5. Đăng ký lại với email `admin@gmail.com` và password `admin123456`

## Lưu ý:

- Email phải chính xác: `admin@gmail.com` (không phải `admin@gmai.com`)
- Role phải là `admin` (không phải `user`)
- Sau khi sửa, đợi vài phút rồi thử đăng nhập lại

