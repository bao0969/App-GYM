import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});
  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _touchedPieIndex = -1;

  final List<Map<String, dynamic>> _monthly = [
    {'month': 'T1', 'revenue': 32.5},
    {'month': 'T2', 'revenue': 28.0},
    {'month': 'T3', 'revenue': 41.2},
    {'month': 'T4', 'revenue': 38.7},
    {'month': 'T5', 'revenue': 45.1},
    {'month': 'T6', 'revenue': 52.3},
    {'month': 'T7', 'revenue': 48.9},
    {'month': 'T8', 'revenue': 56.4},
    {'month': 'T9', 'revenue': 43.2},
    {'month': 'T10', 'revenue': 61.7},
    {'month': 'T11', 'revenue': 58.9},
    {'month': 'T12', 'revenue': 72.1},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  double get _total => _monthly.fold(0, (s, d) => s + (d['revenue'] as double));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thống Kê Doanh Thu',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng Doanh Thu 2025',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_total.toStringAsFixed(1)}M VNĐ',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '+18% so với năm ngoái',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textHint,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Biểu Đồ'),
                      Tab(text: 'Phân Tích'),
                      Tab(text: 'Lịch Sử'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _BarChartTab(monthlyData: _monthly),
                _AnalysisTab(
                  monthlyData: _monthly,
                  touchedIndex: _touchedPieIndex,
                  onTouch: (i) => setState(() => _touchedPieIndex = i),
                ),
                const _RenewalHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartTab extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;
  const _BarChartTab({required this.monthlyData});

  String get _maxLabel {
    final m = monthlyData.reduce(
      (a, b) => (a['revenue'] as double) > (b['revenue'] as double) ? a : b,
    );
    return '${m['month']}: ${(m['revenue'] as double).toStringAsFixed(1)}M';
  }

  String get _minLabel {
    final m = monthlyData.reduce(
      (a, b) => (a['revenue'] as double) < (b['revenue'] as double) ? a : b,
    );
    return '${m['month']}: ${(m['revenue'] as double).toStringAsFixed(1)}M';
  }

  double get _avg =>
      monthlyData.fold(0.0, (s, d) => s + (d['revenue'] as double)) /
      monthlyData.length;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          Container(
            height: 280,
            padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: BarChart(
              BarChartData(
                barGroups: List.generate(monthlyData.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: monthlyData[i]['revenue'] as double,
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryDark,
                            AppColors.primaryLight,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
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
                          monthlyData[v.toInt()]['month'] as String,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surface,
                    tooltipBorder: const BorderSide(color: Colors.transparent),
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, _, rod, x) => BarTooltipItem(
                      '${rod.toY.toStringAsFixed(1)}M VNĐ',
                      const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _MiniStat(
                'Tháng Cao Nhất',
                _maxLabel,
                Icons.arrow_upward_rounded,
                AppColors.success,
              ),
              _MiniStat(
                'Tháng Thấp Nhất',
                _minLabel,
                Icons.arrow_downward_rounded,
                AppColors.error,
              ),
              _MiniStat(
                'Trung Bình/Tháng',
                '${_avg.toStringAsFixed(1)}M',
                Icons.bar_chart_rounded,
                AppColors.accent,
              ),
              _MiniStat(
                'Tăng Trưởng',
                '+18%',
                Icons.trending_up_rounded,
                AppColors.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _MiniStat(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            style: const TextStyle(color: AppColors.textHint, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _AnalysisTab extends StatelessWidget {
  final List<Map<String, dynamic>> monthlyData;
  final int touchedIndex;
  final ValueChanged<int> onTouch;
  const _AnalysisTab({
    required this.monthlyData,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final total = monthlyData.fold<double>(
      0,
      (s, d) => s + (d['revenue'] as double),
    );
    final pieData = [
      {'label': 'Gói 1 tháng', 'pct': 0.25, 'color': AppColors.primary},
      {'label': 'Gói 3 tháng', 'pct': 0.30, 'color': AppColors.accent},
      {'label': 'Gói 6 tháng', 'pct': 0.28, 'color': AppColors.success},
      {'label': 'Gói 1 năm', 'pct': 0.17, 'color': AppColors.warning},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phân Bổ Theo Gói Tập',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (_, resp) {
                          if (resp?.touchedSection != null) {
                            onTouch(resp!.touchedSection!.touchedSectionIndex);
                          }
                        },
                      ),
                      sections: List.generate(pieData.length, (i) {
                        final d = pieData[i];
                        final isTouched = i == touchedIndex;
                        return PieChartSectionData(
                          value: (d['pct'] as double) * 100,
                          color: d['color'] as Color,
                          radius: isTouched ? 85 : 72,
                          title: '${((d['pct'] as double) * 100).toInt()}%',
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        );
                      }),
                      sectionsSpace: 3,
                      centerSpaceRadius: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...pieData.map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: d['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            d['label'] as String,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${((d['pct'] as double) * total).toStringAsFixed(1)}M',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi Tiết Từng Tháng',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: const [
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Tháng',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Doanh Thu',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'So Tháng Trước',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: Colors.white12),
                ...List.generate(monthlyData.length, (i) {
                  final current = monthlyData[i]['revenue'] as double;
                  final prev = i > 0
                      ? monthlyData[i - 1]['revenue'] as double
                      : current;
                  final diff = current - prev;
                  final pct = i > 0 ? (diff / prev * 100) : 0.0;
                  final isUp = diff >= 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            monthlyData[i]['month'] as String,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${current.toStringAsFixed(1)}M',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                i == 0
                                    ? Icons.remove_rounded
                                    : isUp
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: i == 0
                                    ? AppColors.textHint
                                    : isUp
                                    ? AppColors.success
                                    : AppColors.error,
                                size: 14,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                i == 0
                                    ? '-'
                                    : '${pct.abs().toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: i == 0
                                      ? AppColors.textHint
                                      : isUp
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RenewalHistoryTab extends StatelessWidget {
  const _RenewalHistoryTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('renewals')
          .orderBy('renewedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.textHint,
                  size: 56,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có lịch sử gia hạn',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final memberName = data['memberName'] ?? 'Không rõ';
            final packageName = data['packageName'] ?? 'Không rõ';
            final price = (data['price'] ?? 0).toDouble();
            final ts = data['renewedAt'] as Timestamp?;
            final date = ts?.toDate() ?? DateTime.now();
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: AppColors.greenGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.autorenew_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          memberName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          packageName,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price >= 1000000
                            ? '${(price / 1000000).toStringAsFixed(1)}M'
                            : '${(price / 1000).toInt()}K',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
