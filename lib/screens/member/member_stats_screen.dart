// Tính năng 7: Thống kê cá nhân của hội viên
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class MemberStatsScreen extends StatefulWidget {
  const MemberStatsScreen({super.key});

  @override
  State<MemberStatsScreen> createState() => _MemberStatsScreenState();
}

class _MemberStatsScreenState extends State<MemberStatsScreen> {
  final _db = FirestoreService();
  MemberModel? _member;
  List<QueryDocumentSnapshot> _checkins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final member = await _db.getMemberByUserId(user.uid);
    final snap = await FirebaseFirestore.instance
        .collection('checkins')
        .where('userId', isEqualTo: user.uid)
        .orderBy('checkInTime', descending: false)
        .get();

    setState(() {
      _member = member;
      _checkins = snap.docs;
      _loading = false;
    });
  }

  // Tính số buổi tập theo từng tháng (6 tháng gần nhất)
  List<BarChartGroupData> _buildChartData() {
    final now = DateTime.now();
    final Map<int, int> monthCount = {};
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      monthCount[m.month] = 0;
    }

    for (final doc in _checkins) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['checkInTime'] as Timestamp?;
      if (ts == null) continue;
      final date = ts.toDate();
      if (date.isAfter(DateTime(now.year, now.month - 5, 1))) {
        monthCount[date.month] = (monthCount[date.month] ?? 0) + 1;
      }
    }

    return monthCount.entries.toList().asMap().entries.map((entry) {
      final i = entry.key;
      final count = entry.value.value;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            gradient: const LinearGradient(
              colors: [AppColors.success, Color(0xFF00897B)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 24,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();
  }

  List<String> _getMonthLabels() {
    final now = DateTime.now();
    return List.generate(6, (i) {
      final m = DateTime(now.year, now.month - (5 - i), 1);
      return DateFormat('MMM').format(m);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.success),
        ),
      );
    }

    final now = DateTime.now();
    final thisMonth = _checkins.where((d) {
      final ts = (d.data() as Map)['checkInTime'] as Timestamp?;
      if (ts == null) return false;
      final date = ts.toDate();
      return date.month == now.month && date.year == now.year;
    }).length;

    final thisWeek = _checkins.where((d) {
      final ts = (d.data() as Map)['checkInTime'] as Timestamp?;
      if (ts == null) return false;
      final date = ts.toDate();
      return now.difference(date).inDays <= 7;
    }).length;

    final monthLabels = _getMonthLabels();
    final chartData = _buildChartData();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Thống Kê Của Tôi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.success,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tổng quan
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Tổng Buổi Tập',
                      value: '${_checkins.length}',
                      icon: Icons.fitness_center_rounded,
                      gradient: AppColors.greenGradient,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Tháng Này',
                      value: '$thisMonth',
                      icon: Icons.calendar_month_rounded,
                      gradient: AppColors.blueGradient,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: '7 Ngày Qua',
                      value: '$thisWeek',
                      icon: Icons.today_rounded,
                      gradient: AppColors.orangeGradient,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Ngày Còn Lại',
                      value: _member?.packageExpiry != null
                          ? '${_member!.daysRemaining}'
                          : '---',
                      icon: Icons.timer_rounded,
                      gradient:
                          _member?.daysRemaining != null &&
                              _member!.daysRemaining <= 7
                          ? AppColors.purpleGradient
                          : AppColors.greenGradient,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Biểu đồ buổi tập
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buổi Tập 6 Tháng Gần Nhất',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 160,
                      child: BarChart(
                        BarChartData(
                          barGroups: chartData,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
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
                                getTitlesWidget: (v, _) => Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    monthLabels[v.toInt()],
                                    style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => AppColors.surface,
                              getTooltipItem: (g, gi, rod, ri) =>
                                  BarTooltipItem(
                                    '${rod.toY.toInt()} buổi',
                                    const TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Thông tin gói tập
              if (_member != null) ...[
                const Text(
                  'Thông Tin Gói Tập',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        'Gói Tập',
                        _member!.packageName ?? 'Chưa có gói',
                      ),
                      _InfoRow(
                        'Trạng Thái',
                        _member!.statusLabel,
                        valueColor: _member!.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      if (_member!.packageExpiry != null)
                        _InfoRow(
                          'Hết Hạn',
                          DateFormat(
                            'dd/MM/yyyy',
                          ).format(_member!.packageExpiry!),
                        ),
                      _InfoRow(
                        'Ngày Tham Gia',
                        DateFormat('dd/MM/yyyy').format(_member!.joinDate),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Gradient gradient;

  const _StatTile({
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
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;

  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
