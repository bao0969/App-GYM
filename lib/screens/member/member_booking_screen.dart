import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/booking_model.dart';
import '../../core/models/member_model.dart';
import '../../core/models/trainer_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';
import '../../providers/auth_provider.dart';

class MemberBookingScreen extends StatefulWidget {
  const MemberBookingScreen({super.key});

  @override
  State<MemberBookingScreen> createState() => _MemberBookingScreenState();
}

class _MemberBookingScreenState extends State<MemberBookingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _db = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Lịch Đặt Của Tôi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'Sắp Tới'),
            Tab(text: 'Lịch Sử'),
          ],
        ),
      ),
      body: FutureBuilder<MemberModel?>(
        future: _db.getMemberByUserId(
          context.read<AuthProvider>().user?.uid ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final member = snapshot.data;
          if (member == null) {
            return const Center(
              child: Text(
                'Không tìm thấy thông tin hội viên.',
                style: TextStyle(color: AppColors.error),
              ),
            );
          }

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _buildBookingList(member, upcoming: true),
              _buildBookingList(member, upcoming: false),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<MemberModel?>(
        future: _db.getMemberByUserId(
          context.read<AuthProvider>().user?.uid ?? '',
        ),
        builder: (context, snapshot) {
          final member = snapshot.data;
          if (member == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            onPressed: () => _showBookingOptions(context, member),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Đặt Lịch Mới',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingList(MemberModel member, {required bool upcoming}) {
    return StreamBuilder<List<BookingModel>>(
      stream: _db.streamMemberBookings(member.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi: ${snapshot.error}',
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        final allBookings = snapshot.data ?? [];
        final now = DateTime.now();

        final filtered = allBookings.where((b) {
          if (upcoming) {
            return b.startTime.isAfter(now) &&
                b.status != BookingStatus.cancelled;
          } else {
            return b.startTime.isBefore(now) ||
                b.status == BookingStatus.cancelled;
          }
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 64,
                  color: AppColors.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Không có lịch đặt nào',
                  style: TextStyle(color: AppColors.textHint, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final b = filtered[index];
            return _BookingCard(
              booking: b,
              onCancel: upcoming ? () => _cancelBooking(b) : null,
            );
          },
        );
      },
    );
  }

  void _showBookingOptions(BuildContext context, MemberModel member) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn muốn đặt lịch gì?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                _showPTBooking(context, member);
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                ),
              ),
              title: const Text(
                'Huấn Luyện Viên (PT)',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Tập luyện 1 kèm 1',
                style: TextStyle(color: AppColors.textHint),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              onTap: () {
                Navigator.pop(ctx);
                _showClassBooking(context);
              },
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.group_outlined,
                  color: AppColors.success,
                ),
              ),
              title: const Text(
                'Lớp Tập Nhóm',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Yoga, Zumba, Aerobic...',
                style: TextStyle(color: AppColors.textHint),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPTBooking(BuildContext context, MemberModel member) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _PTBookingFlow(member: member)),
    );
  }

  void _showClassBooking(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đặt lớp nhóm đang được cập nhật!'),
      ),
    );
  }

  Future<void> _cancelBooking(BookingModel booking) async {
    final now = DateTime.now();
    final isLateCancel = booking.startTime.difference(now).inHours < 12;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Huỷ Lịch', style: TextStyle(color: Colors.white)),
        content: Text(
          isLateCancel
              ? 'Bạn đang huỷ lịch quá sát giờ (dưới 12 tiếng). Việc huỷ lịch lúc này sẽ bị trừ 1 buổi tập. Bạn có chắc chắn muốn huỷ không?'
              : 'Bạn có chắc muốn huỷ lịch đặt này không?',
          style: TextStyle(
            color: isLateCancel ? AppColors.error : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Không',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Huỷ Lịch',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.cancelBooking(booking.id, isLateCancel: isLateCancel, memberId: booking.memberId);
      
      // Send notification
      await NotificationService().sendNotification(
        userId: booking.memberId,
        title: 'Huỷ Lịch Thành Công',
        body: 'Bạn đã huỷ lịch tập ngày ${DateFormat('dd/MM/yyyy').format(booking.startTime)}.${isLateCancel ? ' Bị trừ 1 buổi do huỷ sát giờ.' : ''}',
        type: 'booking',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã huỷ lịch thành công'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback? onCancel;

  const _BookingCard({required this.booking, this.onCancel});

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
        statusText = 'Đã xác nhận';
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isPT ? AppColors.primary : AppColors.success)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPT ? 'Huấn Luyện Viên' : 'Lớp Học',
                  style: TextStyle(
                    color: isPT ? AppColors.primary : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
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
                ? 'Tập cùng PT ${booking.trainerName}'
                : (booking.className ?? 'Lớp Nhóm'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
          if (onCancel != null) ...[
            const Divider(color: Colors.white10, height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  'Huỷ Lịch',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── PT BOOKING FLOW (Demo) ──────────────────────────────────────────────────
class _PTBookingFlow extends StatefulWidget {
  final MemberModel member;
  const _PTBookingFlow({required this.member});

  @override
  State<_PTBookingFlow> createState() => _PTBookingFlowState();
}

class _PTBookingFlowState extends State<_PTBookingFlow> {
  final _db = FirestoreService();
  TrainerModel? _selectedTrainer;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _selectedHour = 17; // 5 PM
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Đặt Lịch Tập PT',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.surface,
        leading: const BackButton(color: Colors.white),
      ),
      body: FutureBuilder<List<TrainerModel>>(
        future: _db.getTrainers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final trainers = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn Huấn Luyện Viên',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
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
                ),
                const SizedBox(height: 30),
                const Text(
                  'Chọn Ngày',
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
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                ),
                const SizedBox(height: 30),
                const Text(
                  'Chọn Giờ Bắt Đầu (Ca 1 tiếng)',
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
                    onPressed: _selectedTrainer == null || _isLoading
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
                            'Xác Nhận Đặt Lịch',
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
          );
        },
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
      memberId: widget.member.id,
      memberName: widget.member.name,
      type: BookingType.pt,
      trainerId: _selectedTrainer!.id,
      trainerName: _selectedTrainer!.name,
      startTime: startTime,
      endTime: endTime,
      status: BookingStatus.pending,
    );

    await _db.addBooking(booking);
    await _db.assignMemberToTrainer(
      memberId: widget.member.id,
      trainerId: _selectedTrainer!.id,
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu đặt lịch! Vui lòng chờ xác nhận.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
