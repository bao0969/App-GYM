import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import 'member_checkin_history_screen.dart';
import 'member_trainer_rating_screen.dart';
import 'member_stats_screen.dart';
import 'member_workout_library_screen.dart';
import 'member_nutrition_screen.dart';
import 'member_booking_screen.dart';
import '../../widgets/member/member_banner_carousel.dart';
import 'member_gamification_screen.dart';
import 'member_promos_packages_screen.dart';
import 'member_support_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkWelcomePopup();
    });
  }

  Future<void> _checkWelcomePopup() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'has_shown_welcome_popup_${user.uid}';
    final hasShown = prefs.getBool(key) ?? false;
    
    if (!hasShown) {
      if (!mounted) return;
      _showWelcomePopup(context, prefs, key);
    }
  }

  void _showWelcomePopup(BuildContext context, SharedPreferences prefs, String key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (dialogContext, anim1, anim2) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppColors.greenGradient.createShader(bounds),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ƯU ĐÃI THÀNH VIÊN MỚI! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Chào mừng bạn đến với GymSync! Chúng tôi có những phần quà đặc biệt dành riêng cho bạn:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                
                // Promo 1 Card
                _buildPromoItem(
                  dialogContext,
                  title: 'Giảm 50% Gói Hội Viên',
                  code: 'WELCOME50',
                  desc: 'Áp dụng cho lần đầu đăng ký gói tập online.',
                ),
                const SizedBox(height: 10),
                
                // Promo 2 Card
                _buildPromoItem(
                  dialogContext,
                  title: 'Tặng 7 Ngày Tập Miễn Phí',
                  code: 'FREE7D',
                  desc: 'Nhận trải nghiệm 7 ngày tập thử đầy đủ dịch vụ.',
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await prefs.setBool(key, true);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'NHẬN NGAY & BẮT ĐẦU',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          );
        },
        transitionBuilder: (dialogContext, anim1, anim2, child) {
          return ScaleTransition(
            scale: anim1,
            child: child,
          );
        },
      );
    });
  }

  Widget _buildPromoItem(BuildContext context, {
    required String title,
    required String code,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã sao chép mã $code!'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      Text(
                        code,
                        style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, color: AppColors.success, size: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final pages = [
      _MemberHome(onTabChange: (i) => setState(() => _currentIndex = i)),
      const _MemberQRScreen(),
      const MemberBookingScreen(),
      const _MemberProfileScreen(),
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
          selectedItemColor: AppColors.success,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Trang Chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_rounded),
              label: 'QR Code',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Lịch Tập',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Hồ Sơ',
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberHome extends StatelessWidget {
  final Function(int) onTabChange;
  const _MemberHome({required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final db = FirestoreService();

    return SafeArea(
      child: StreamBuilder<MemberModel?>(
        stream: db.streamMemberByUserId(user?.uid ?? ''),
        builder: (context, snapshot) {
          final member = snapshot.data;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xin Chào, ${user?.name.split(' ').last ?? 'Hội Viên'} 👋',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (b) =>
                                    AppColors.greenGradient.createShader(b),
                                child: const Text(
                                  'GymSync Member',
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
                              gradient: AppColors.greenGradient,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : 'M',
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
                      const SizedBox(height: 20),

                      // Banner Carousel
                      const MemberBannerCarousel(),

                      // Package status card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: member?.isActive == true
                              ? AppColors.greenGradient
                              : AppColors.purpleGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  member?.packageName ?? 'Chưa có gói tập',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    member?.isActive == true
                                        ? '✓ Còn Hạn'
                                        : 'Hết Hạn',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Còn Lại',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        member != null && (member.packageExpiry != null || member.sessionsRemaining > 0)
                                            ? (member.sessionsRemaining > 0 ? '${member.sessionsRemaining} buổi' : '${member.daysRemaining} ngày')
                                            : '---',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Hết Hạn',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        member?.packageExpiry != null
                                            ? DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(member!.packageExpiry!)
                                            : '---',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Tính Năng',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.15,
                        children: [
                          // GAMIFICATION - Tính năng đột phá!
                          _FeatureCard(
                            icon: Icons.emoji_events_rounded,
                            label: '🎮 Thành Tích',
                            color: const Color(0xFFFFD700), // Gold
                            onTap: () {
                              if (member != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MemberGamificationScreen(
                                      memberId: member.id,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          _FeatureCard(
                            icon: Icons.fitness_center_rounded,
                            label: 'Bài Tập',
                            color: const Color(0xFFE84E1B),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MemberWorkoutLibraryScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            icon: Icons.restaurant_rounded,
                            label: 'Dinh Dưỡng',
                            color: const Color(0xFF4CAF50),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MemberNutritionScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            icon: Icons.calendar_today_rounded,
                            label: 'Lịch Tập',
                            color: AppColors.warning,
                            onTap: () => onTabChange(2),
                          ),
                          _FeatureCard(
                            icon: Icons.history_rounded,
                            label: 'Lịch Sử',
                            color: AppColors.success,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => MemberCheckinHistoryScreen(memberId: member!.id),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            icon: Icons.bar_chart_rounded,
                            label: 'Thống Kê',
                            color: AppColors.accent,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MemberStatsScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            icon: Icons.star_rounded,
                            label: 'Đánh Giá HLV',
                            color: AppColors.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MemberTrainerRatingScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            icon: Icons.local_offer_rounded,
                            label: 'Khuyến Mãi',
                            color: AppColors.success,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MemberPromosPackagesScreen(),
                              ),
                            ),
                          ),
                          _FeatureCard(
                            icon: Icons.support_agent_rounded,
                            label: 'Hỗ Trợ 24/7',
                            color: AppColors.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MemberSupportScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _FeatureCard({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberQRScreen extends StatelessWidget {
  const _MemberQRScreen();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final db = FirestoreService();

    return SafeArea(
      child: StreamBuilder<MemberModel?>(
        stream: db.streamMemberByUserId(user?.uid ?? ''),
        builder: (context, snapshot) {
          final member = snapshot.data;
          final qrData = member?.qrCode ?? user?.uid ?? 'GYMSYNC_MEMBER';

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'QR Check-in Của Tôi',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Xuất trình mã này tại quầy để check-in',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF121212),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF121212),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          qrData,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 4,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Mã QR này được tạo riêng cho bạn. Không chia sẻ với người khác.',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ignore: unused_element
class _MemberScheduleScreen extends StatelessWidget {
  const _MemberScheduleScreen();

  final List<Map<String, dynamic>> _schedule = const [
    {
      'day': 'Thứ 2',
      'time': '06:00 - 07:30',
      'exercise': 'Ngực & Tay Sau',
      'trainer': 'PT Minh',
    },
    {
      'day': 'Thứ 3',
      'time': '07:00 - 08:30',
      'exercise': 'Lưng & Tay Trước',
      'trainer': 'PT Minh',
    },
    {
      'day': 'Thứ 4',
      'time': '06:00 - 07:00',
      'exercise': 'Cardio',
      'trainer': 'Tự luyện',
    },
    {
      'day': 'Thứ 5',
      'time': '07:00 - 08:30',
      'exercise': 'Vai & Cổ',
      'trainer': 'PT Minh',
    },
    {
      'day': 'Thứ 6',
      'time': '06:00 - 07:30',
      'exercise': 'Chân',
      'trainer': 'PT Minh',
    },
    {
      'day': 'Thứ 7',
      'time': '08:00 - 09:00',
      'exercise': 'Core & Stretch',
      'trainer': 'Tự luyện',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lịch Tập Tuần Này',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final s = _schedule[i];
                final isToday = (i + 1) == today;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isToday ? AppColors.greenGradient : null,
                    color: isToday ? null : AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isToday
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.05),
                    ),
                    boxShadow: isToday
                        ? [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Column(
                          children: [
                            Text(
                              s['day'],
                              style: TextStyle(
                                color: isToday
                                    ? Colors.white
                                    : AppColors.textHint,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isToday)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 50,
                        color: (isToday ? Colors.white : Colors.white)
                            .withValues(alpha: isToday ? 0.2 : 0.08),
                        margin: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s['exercise'],
                              style: TextStyle(
                                color: isToday
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: isToday
                                      ? Colors.white70
                                      : AppColors.textHint,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  s['time'],
                                  style: TextStyle(
                                    color: isToday
                                        ? Colors.white70
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (isToday ? Colors.white : AppColors.accent)
                              .withValues(alpha: isToday ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          s['trainer'],
                          style: TextStyle(
                            color: isToday ? Colors.white : AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }, childCount: _schedule.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _MemberProfileScreen extends StatelessWidget {
  const _MemberProfileScreen();

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.greenGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : 'M',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Hội Viên',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              user?.email ?? '',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.4),
                ),
              ),
              child: const Text(
                'Hội Viên',
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 28),
            _InfoTile(
              Icons.phone_rounded,
              'Số Điện Thoại',
              user?.phone ?? 'Chưa cập nhật',
            ),
            _InfoTile(Icons.email_rounded, 'Email', user?.email ?? ''),
            _InfoTile(
              Icons.calendar_today_rounded,
              'Ngày Tham Gia',
              'Tháng 5, 2025',
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.success, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
