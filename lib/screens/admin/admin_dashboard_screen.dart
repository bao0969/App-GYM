import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/admin/admin_check_in_widget.dart';
import '../../widgets/admin/gym_banner_carousel.dart';
import '../admin/admin_members_screen.dart';
import '../admin/admin_trainers_screen.dart';
import '../admin/admin_packages_screen.dart';
import '../admin/admin_revenue_screen.dart';
import '../admin/admin_settings_screen.dart';
import '../admin/admin_renewal_screen.dart';
import '../admin/admin_expiry_alerts_screen.dart';
import '../admin/admin_equipment_screen.dart';
import '../admin/admin_notifications_screen.dart';
import '../admin/admin_class_schedule_screen.dart';
import '../admin/admin_qr_generator_screen.dart';
import '../admin/admin_booking_screen.dart';
import '../admin/admin_coupons_screen.dart';
import '../admin/admin_pos_screen.dart';
import '../admin/admin_inventory_screen.dart';
import '../admin/admin_lockers_screen.dart';
import '../admin/admin_inbody_screen.dart';
import '../admin/admin_support_tickets_screen.dart';
import '../admin/admin_user_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  final FirestoreService _db = FirestoreService();
  Map<String, dynamic> _stats = {};
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _db.getDashboardStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardHome(
        stats: _stats,
        loading: _loadingStats,
        onRefresh: _loadStats,
      ),
      const AdminMembersScreen(),
      const AdminTrainersScreen(),
      const AdminPackagesScreen(),
      const AdminRevenueScreen(),
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
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Tổng Quan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Hội Viên',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_rounded),
              label: 'HLV',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_membership_rounded),
              label: 'Gói Tập',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Doanh Thu',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool loading;
  final VoidCallback onRefresh;

  const _DashboardHome({
    required this.stats,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
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
                              'Xin chào, ${user?.name.split(' ').last ?? 'Admin'} 👋',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ShaderMask(
                              shaderCallback: (b) =>
                                  AppColors.primaryGradient.createShader(b),
                              child: const Text(
                                'GymSync Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminSettingsScreen(),
                            ),
                          ),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Banner Carousel
                    const GymBannerCarousel(),

                    // Check-in Component
                    const AdminCheckInWidget(),

                    // Today summary card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1A28), Color(0xFF141420)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _QuickStat(
                              label: 'Check-in Hôm Nay',
                              value: loading
                                  ? '...'
                                  : '${stats['todayCheckIns'] ?? 0}',
                              icon: Icons.qr_code_scanner_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          Expanded(
                            child: _QuickStat(
                              label: 'HV Mới Tháng Này',
                              value: loading
                                  ? '...'
                                  : '${stats['newMembersThisMonth'] ?? 0}',
                              icon: Icons.person_add_rounded,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Tổng Quan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            // Stats grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate([
                  StatCard(
                    title: 'Tổng Hội Viên',
                    value: loading ? '...' : '${stats['totalMembers'] ?? 0}',
                    icon: Icons.people_rounded,
                    gradient: AppColors.orangeGradient,
                    subtitle: 'Đã đăng ký',
                  ),
                  StatCard(
                    title: 'Đang Hoạt Động',
                    value: loading ? '...' : '${stats['activeMembers'] ?? 0}',
                    icon: Icons.verified_user_rounded,
                    gradient: AppColors.greenGradient,
                    subtitle: 'Còn hạn gói',
                  ),
                  StatCard(
                    title: 'Huấn Luyện Viên',
                    value: loading ? '...' : '${stats['totalTrainers'] ?? 0}',
                    icon: Icons.sports_rounded,
                    gradient: AppColors.blueGradient,
                    subtitle: 'PT đang làm việc',
                  ),
                  StatCard(
                    title: 'Hết Hạn',
                    value: loading ? '...' : '${stats['expiredMembers'] ?? 0}',
                    icon: Icons.warning_rounded,
                    gradient: AppColors.purpleGradient,
                    subtitle: 'Cần gia hạn',
                  ),
                ]),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.0,
                ),
              ),
            ),
            // Revenue mini chart
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _RevenueChart(),
              ),
            ),
            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thao Tác Nhanh',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _QuickAction(
                          label: 'Gia Hạn',
                          icon: Icons.card_membership_rounded,
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminRenewalScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Hết Hạn',
                          icon: Icons.warning_rounded,
                          color: AppColors.warning,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminExpiryAlertsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Thiết Bị',
                          icon: Icons.fitness_center_rounded,
                          color: AppColors.accent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminEquipmentScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Lịch Đặt',
                          icon: Icons.calendar_today_rounded,
                          color: AppColors.success,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminBookingScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QuickAction(
                          label: 'Thông Báo',
                          icon: Icons.campaign_rounded,
                          color: AppColors.error,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminNotificationsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Lớp Nhóm',
                          icon: Icons.groups_rounded,
                          color: AppColors.trainerColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminClassScheduleScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Tạo QR',
                          icon: Icons.qr_code_2_rounded,
                          color: AppColors.staffColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminQrGeneratorScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Inbody',
                          icon: Icons.monitor_heart_rounded,
                          color: AppColors.memberColor,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminInbodyScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Hàng quick action mới: POS / Voucher / Kho / Tủ đồ
                    Row(
                      children: [
                        _QuickAction(
                          label: 'POS',
                          icon: Icons.point_of_sale_rounded,
                          color: AppColors.success,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminPosScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Voucher',
                          icon: Icons.local_offer_rounded,
                          color: AppColors.warning,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminCouponsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Kho Hàng',
                          icon: Icons.inventory_2_rounded,
                          color: AppColors.accent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminInventoryScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Tủ Đồ',
                          icon: Icons.lock_rounded,
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminLockersScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _QuickAction(
                          label: 'Báo Lỗi & Duyệt',
                          icon: Icons.rate_review_rounded,
                          color: AppColors.primary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminSupportTicketsScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          label: 'Phân Quyền',
                          icon: Icons.people_outline_rounded,
                          color: AppColors.accent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminUserManagementScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sample data for demo
    final List<BarChartGroupData> barGroups = List.generate(7, (i) {
      final values = [3.5, 5.2, 4.1, 6.8, 5.5, 7.2, 4.9];
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: values[i],
            gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primaryLight],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 28,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Doanh Thu Tuần Này',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '7 ngày',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '37.2M VNĐ tổng cộng',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt()],
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    tooltipBorder: const BorderSide(color: Colors.transparent),
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)}M',
                        const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
