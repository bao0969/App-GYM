import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/booking_model.dart';
import '../../core/services/firestore_service.dart';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final _db = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Quản Lý Lịch Đặt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        leading: const BackButton(color: Colors.white),
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _db.streamAdminBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Lỗi: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                'Không có lịch đặt nào.',
                style: TextStyle(color: AppColors.textHint),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final b = bookings[index];
              return _AdminBookingCard(
                booking: b,
                onStatusChange: (status) async {
                  await _db.updateBookingStatus(b.id, status);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật trạng thái lịch đặt'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  final BookingModel booking;
  final Function(BookingStatus) onStatusChange;

  const _AdminBookingCard({
    required this.booking,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final isPT = booking.type == BookingType.pt;
    final dateStr = DateFormat('dd/MM/yyyy').format(booking.startTime);
    final timeStr =
        '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}';

    Color statusColor;
    String statusText;
    switch (booking.status) {
      case BookingStatus.pending:
        statusColor = AppColors.warning;
        statusText = 'Chờ duyệt';
        break;
      case BookingStatus.confirmed:
        statusColor = AppColors.success;
        statusText = 'Đã duyệt';
        break;
      case BookingStatus.cancelled:
        statusColor = AppColors.error;
        statusText = 'Đã huỷ';
        break;
      case BookingStatus.completed:
        statusColor = AppColors.primary;
        statusText = 'Hoàn thành';
        break;
      case BookingStatus.noShow:
        statusColor = AppColors.error;
        statusText = 'Không đến';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.memberName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPT
                ? 'Loại: Tập cùng PT ${booking.trainerName}'
                : 'Loại: Lớp ${booking.className ?? "Nhóm"}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.access_time,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (booking.status == BookingStatus.pending) ...[
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onStatusChange(BookingStatus.cancelled),
                  child: const Text(
                    'Từ chối',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => onStatusChange(BookingStatus.confirmed),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                  child: const Text(
                    'Duyệt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ] else if (booking.status == BookingStatus.confirmed) ...[
            const Divider(color: Colors.white10, height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => onStatusChange(BookingStatus.completed),
                child: const Text(
                  'Đánh dấu Hoàn Thành',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
