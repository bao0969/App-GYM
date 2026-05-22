import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/booking_model.dart';
import '../../core/models/member_model.dart';
import '../../core/models/trainer_model.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/trainer/trainer_banner_carousel.dart';
import '../admin/admin_class_schedule_screen.dart';
import 'trainer_workout_program_screen.dart';

class TrainerDashboardScreen extends StatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  State<TrainerDashboardScreen> createState() => _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends State<TrainerDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _TrainerHome(),
      const _TrainerStudents(),
      const TrainerWorkoutProgramScreen(),
      const _TrainerProfile(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Trang Chu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Hoc Vien',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              label: 'Chuong Trinh',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Ho So',
            ),
          ],
        ),
      ),
    );
  }
}

class _TrainerHome extends StatelessWidget {
  const _TrainerHome();

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final user = context.read<AuthProvider>().user;

    return SafeArea(
      child: FutureBuilder<TrainerModel?>(
        future: db.getTrainerByUserId(user?.uid ?? ''),
        builder: (context, trainerSnapshot) {
          if (trainerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          final trainer = trainerSnapshot.data;
          if (trainer == null) {
            return const Center(
              child: Text(
                'Chua tim thay thong tin PT',
                style: TextStyle(color: AppColors.textHint),
              ),
            );
          }

          return StreamBuilder<List<MemberModel>>(
            stream: db.streamTrainerMembers(trainer.id),
            builder: (context, memberSnapshot) {
              final members = memberSnapshot.data ?? [];
              return StreamBuilder<List<BookingModel>>(
                stream: db.streamTrainerBookings(trainer.id),
                builder: (context, bookingSnapshot) {
                  final bookings = bookingSnapshot.data ?? [];
                  final now = DateTime.now();
                  final todayBookings = bookings.where((booking) {
                    return booking.startTime.year == now.year &&
                        booking.startTime.month == now.month &&
                        booking.startTime.day == now.day &&
                        booking.status != BookingStatus.cancelled;
                  }).toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Xin Chao',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (b) =>
                                      AppColors.blueGradient.createShader(b),
                                  child: const Text(
                                    'PT Dashboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.blueGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  user?.name.isNotEmpty == true
                                      ? user!.name[0].toUpperCase()
                                      : 'T',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const TrainerBannerCarousel(),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                label: 'Hoc Vien',
                                value: '${members.length}',
                                icon: Icons.people_rounded,
                                gradient: AppColors.blueGradient,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StatBox(
                                label: 'Buoi Hom Nay',
                                value: '${todayBookings.length}',
                                icon: Icons.fitness_center_rounded,
                                gradient: AppColors.orangeGradient,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                label: 'Rating',
                                value: '${trainer.rating.toStringAsFixed(1)}*',
                                icon: Icons.star_rounded,
                                gradient: AppColors.greenGradient,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _StatBox(
                                label: 'Kinh Nghiem',
                                value: '${trainer.experience} nam',
                                icon: Icons.workspace_premium_rounded,
                                gradient: AppColors.purpleGradient,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Lich Hom Nay',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminClassScheduleScreen(),
                                  ),
                                );
                              },
                              child: const Text('Xem Lop Hoc Nhom'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (todayBookings.isEmpty)
                          const Text(
                            'Chua co lich PT hom nay',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ...todayBookings.map(
                          (booking) => _TrainerScheduleCard(booking: booking),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TrainerScheduleCard extends StatelessWidget {
  final BookingModel booking;

  const _TrainerScheduleCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  booking.startTime.hour.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  ':${booking.startTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.memberName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  booking.notes.isNotEmpty ? booking.notes : 'Buoi PT 1 kem 1',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Xem',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Gradient gradient;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerStudents extends StatelessWidget {
  const _TrainerStudents();

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final user = context.read<AuthProvider>().user;

    return SafeArea(
      child: FutureBuilder<TrainerModel?>(
        future: db.getTrainerByUserId(user?.uid ?? ''),
        builder: (context, trainerSnapshot) {
          if (trainerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          final trainer = trainerSnapshot.data;
          if (trainer == null) {
            return const Center(
              child: Text(
                'Chua tim thay thong tin PT',
                style: TextStyle(color: AppColors.textHint),
              ),
            );
          }

          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hoc Vien Cua Toi',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<MemberModel>>(
                  stream: db.streamTrainerMembers(trainer.id),
                  builder: (context, snapshot) {
                    final members = snapshot.data ?? [];
                    if (members.isEmpty) {
                      return const Center(
                        child: Text(
                          'Chua co hoc vien chon ban',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: members.length,
                      itemBuilder: (_, i) {
                        final member = members[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  gradient: AppColors.blueGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    member.name.isNotEmpty
                                        ? member.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      member.phone,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textHint,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrainerProfile extends StatelessWidget {
  const _TrainerProfile();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppColors.blueGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'T',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'Huấn Luyện Viên',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'Huấn Luyện Viên',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().signOut();
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text(
                  'Đăng Xuất',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
