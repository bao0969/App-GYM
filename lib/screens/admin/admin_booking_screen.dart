import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/booking_model.dart';
import '../../core/models/member_model.dart';
import '../../core/models/trainer_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminPTBookingFlow()),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Sắp Lịch PT',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => _EditBookingDialog(booking: booking),
                  ),
                  child: const Text(
                    'Chỉnh sửa',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => _EditBookingDialog(booking: booking),
                  ),
                  child: const Text(
                    'Chỉnh sửa lịch',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => onStatusChange(BookingStatus.completed),
                  child: const Text(
                    'Đánh dấu Hoàn Thành',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── ADMIN PT BOOKING FLOW ──────────────────────────────────────────────────
class AdminPTBookingFlow extends StatefulWidget {
  final MemberModel? initialMember;
  const AdminPTBookingFlow({super.key, this.initialMember});

  @override
  State<AdminPTBookingFlow> createState() => AdminPTBookingFlowState();
}

class AdminPTBookingFlowState extends State<AdminPTBookingFlow> {
  final _db = FirestoreService();
  MemberModel? _selectedMember;
  TrainerModel? _selectedTrainer;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedHour = 17; // 5 PM
  bool _isLoading = false;
  String _memberSearchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialMember != null) {
      _selectedMember = widget.initialMember;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sắp Xếp Lịch PT',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Chọn Hội Viên',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.initialMember != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(
                        widget.initialMember!.name[0],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialMember!.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'SĐT: ${widget.initialMember!.phone} | Gói: ${widget.initialMember!.packageName}',
                            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm hội viên theo tên hoặc SĐT...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _memberSearchQuery = val.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<MemberModel>>(
                future: _db.getMembers(),
                builder: (ctx, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  final members = snap.data!;
                  final filtered = members.where((m) {
                    if (_selectedMember?.id == m.id) return true;
                    final nameMatch = m.name.toLowerCase().contains(_memberSearchQuery);
                    final phoneMatch = m.phone.contains(_memberSearchQuery);
                    return nameMatch || phoneMatch;
                  }).take(5).toList();

                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Không tìm thấy hội viên nào.', style: TextStyle(color: AppColors.textHint)),
                    );
                  }

                  return Column(
                    children: filtered.map((m) {
                      final isSelected = _selectedMember?.id == m.id;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(m.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('SĐT: ${m.phone} | Gói: ${m.packageName}', style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
                          trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                          onTap: () => setState(() => _selectedMember = m),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 30),
            const Text(
              '2. Chọn Huấn Luyện Viên',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<TrainerModel>>(
              future: _db.getTrainers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                final trainers = snapshot.data!;
                return SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: trainers.length,
                    itemBuilder: (ctx, i) {
                      final t = trainers[i];
                      final isSelected = _selectedTrainer?.id == t.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTrainer = t),
                        child: Container(
                          width: 110,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.2,
                                ),
                                child: Text(
                                  t.name[0],
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                t.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                t.specialization,
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              '3. Chọn Ngày Tập',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate),
                style: const TextStyle(color: Colors.white),
              ),
              trailing: const Icon(
                Icons.calendar_month,
                color: AppColors.primary,
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 30),
            const Text(
              '4. Chọn Giờ Bắt Đầu (Ca 1 tiếng)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(14, (i) {
                final hour = i + 7; // 7 AM to 8 PM
                final isSelected = _selectedHour == hour;
                return ChoiceChip(
                  label: Text(
                    '$hour:00',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onSelected: (val) => setState(() => _selectedHour = hour),
                );
              }),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _selectedMember == null || _selectedTrainer == null || _isLoading
                    ? null
                    : _submitBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Xác Nhận Sắp Lịch',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitBooking() async {
    setState(() => _isLoading = true);
    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedHour,
    );
    final endTime = startTime.add(const Duration(hours: 1));

    final booking = BookingModel(
      id: '',
      memberId: _selectedMember!.id,
      memberName: _selectedMember!.name,
      type: BookingType.pt,
      trainerId: _selectedTrainer!.id,
      trainerName: _selectedTrainer!.name,
      startTime: startTime,
      endTime: endTime,
      status: BookingStatus.confirmed,
    );

    try {
      await _db.addBooking(booking);
      await _db.assignMemberToTrainer(
        memberId: _selectedMember!.id,
        trainerId: _selectedTrainer!.id,
      );

      // Gửi thông báo đến hội viên qua NotificationService
      final notificationService = NotificationService();
      await notificationService.sendNotification(
        userId: _selectedMember!.id,
        title: 'Lịch Tập PT Mới (Đã Duyệt)',
        body: 'Admin đã sắp lịch tập cho bạn với PT ${_selectedTrainer!.name} vào ngày ${DateFormat('dd/MM/yyyy').format(startTime)} lúc ${DateFormat('HH:mm').format(startTime)}.',
        type: 'booking',
      );
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã sắp xếp lịch tập PT thành công cho ${_selectedMember!.name}!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _EditBookingDialog extends StatefulWidget {
  final BookingModel booking;
  const _EditBookingDialog({required this.booking});

  @override
  State<_EditBookingDialog> createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends State<_EditBookingDialog> {
  final _db = FirestoreService();
  TrainerModel? _selectedTrainer;
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = 17;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.booking.startTime;
    _selectedHour = widget.booking.startTime.hour;
    _loadInitialTrainer();
  }

  Future<void> _loadInitialTrainer() async {
    if (widget.booking.trainerId != null) {
      final trainers = await _db.getTrainers();
      final match = trainers.where((t) => t.id == widget.booking.trainerId).toList();
      if (match.isNotEmpty) {
        setState(() => _selectedTrainer = match.first);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Điều Chỉnh Lịch Tập PT',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textHint),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hội viên: ${widget.booking.memberName}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              '1. Chọn Huấn Luyện Viên',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<TrainerModel>>(
              future: _db.getTrainers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 90,
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }
                final trainers = snapshot.data!;
                return SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: trainers.length,
                    itemBuilder: (ctx, i) {
                      final t = trainers[i];
                      final isSelected = _selectedTrainer?.id == t.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedTrainer = t),
                        child: Container(
                          width: 85,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                child: Text(
                                  t.name[0],
                                  style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                t.name,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '2. Chọn Ngày Tập',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              tileColor: AppColors.surfaceLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              title: Text(
                DateFormat('dd/MM/yyyy').format(_selectedDate),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              trailing: const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '3. Chọn Giờ Bắt Đầu (Ca 1 tiếng)',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(14, (i) {
                final hour = i + 7;
                final isSelected = _selectedHour == hour;
                return ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(
                    '$hour:00',
                    style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 11),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceLight,
                  onSelected: (val) => setState(() => _selectedHour = hour),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _selectedTrainer == null || _isLoading ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Lưu Thay Đổi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    final newStartTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedHour,
    );
    final newEndTime = newStartTime.add(const Duration(hours: 1));

    try {
      // 1. Update Booking Document
      await FirebaseFirestore.instance.collection('bookings').doc(widget.booking.id).update({
        'trainerId': _selectedTrainer!.id,
        'trainerName': _selectedTrainer!.name,
        'startTime': Timestamp.fromDate(newStartTime),
        'endTime': Timestamp.fromDate(newEndTime),
      });

      // 2. Re-assign member if trainer changed
      if (widget.booking.trainerId != null && widget.booking.trainerId != _selectedTrainer!.id) {
        await _db.unassignMemberFromTrainer(
          memberId: widget.booking.memberId,
          trainerId: widget.booking.trainerId!,
        );
        await _db.assignMemberToTrainer(
          memberId: widget.booking.memberId,
          trainerId: _selectedTrainer!.id,
        );
      }

      // 3. Send notification to user
      final notificationService = NotificationService();
      await notificationService.sendNotification(
        userId: widget.booking.memberId,
        title: 'Lịch Tập Của Bạn Thay Đổi',
        body: 'Admin đã thay đổi lịch PT với ${_selectedTrainer!.name} sang ngày ${DateFormat('dd/MM/yyyy').format(newStartTime)} lúc ${DateFormat('HH:mm').format(newStartTime)}.',
        type: 'booking',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật lịch tập PT thành công cho ${widget.booking.memberName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
