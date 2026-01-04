import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';
import '../../models/booking.dart';

class ManageBookingsScreen extends StatelessWidget {
  const ManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();

    return StreamBuilder<List<Booking>>(
      stream: _firestoreService.getAllBookings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Lỗi: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Chưa có đặt bàn nào',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                leading: const Icon(Icons.restaurant, color: Colors.orange),
                title: Text(
                  booking.restaurantName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.bookingDate)}',
                    ),
                    Text('Số người: ${booking.numberOfGuests}'),
                  ],
                ),
                trailing: Chip(
                  label: Text(
                    _getStatusText(booking.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: _getStatusColor(booking.status),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID đặt bàn: ${booking.id}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'ID người dùng: ${booking.userId}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(booking.createdAt)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        if (booking.status == 'pending')
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    _updateBookingStatus(
                                      context,
                                      booking,
                                      'confirmed',
                                      _firestoreService,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Xác nhận'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    _updateBookingStatus(
                                      context,
                                      booking,
                                      'cancelled',
                                      _firestoreService,
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Hủy'),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Đang chờ';
      case 'confirmed':
        return 'Đã xác nhận';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateBookingStatus(
    BuildContext context,
    Booking booking,
    String newStatus,
    FirestoreService firestoreService,
  ) async {
    try {
      // Update booking status
      await firestoreService.updateBookingStatus(booking.id, newStatus);

      // Send notification to user
      final notificationService = NotificationService();
      if (newStatus == 'confirmed') {
        // Send success notification for confirmed booking
        await notificationService.sendNotification(
          userId: booking.userId,
          title: 'Đặt bàn thành công! ✅',
          body: 'Đơn đặt bàn tại ${booking.restaurantName} đã được xác nhận.',
          type: 'success',
        );
      } else if (newStatus == 'cancelled') {
        // Send error notification for cancelled booking
        await notificationService.sendNotification(
          userId: booking.userId,
          title: 'Đặt bàn bị hủy ❌',
          body: 'Rất tiếc, nhà hàng ${booking.restaurantName} không thể nhận đơn này.',
          type: 'error',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật trạng thái thành ${_getStatusText(newStatus)}'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
}


