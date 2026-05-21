// Tính năng mới: Theo dõi Inbody hội viên (thay thế "Coming soon")
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/body_metric_model.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminInbodyScreen extends StatefulWidget {
  const AdminInbodyScreen({super.key});

  @override
  State<AdminInbodyScreen> createState() => _AdminInbodyScreenState();
}

class _AdminInbodyScreenState extends State<AdminInbodyScreen> {
  final _db = FirestoreService();
  final _searchCtrl = TextEditingController();
  String _query = '';
  MemberModel? _selectedMember;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          _selectedMember != null && !isWide
              ? 'Chỉ số: ${_selectedMember!.name}'
              : 'Theo Dõi Inbody',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        leading: !isWide && _selectedMember != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedMember = null),
              )
            : null,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: _selectedMember != null && context.read<AuthProvider>().user?.role.name != 'member'
            ? [
                IconButton(
                  icon: const Icon(Icons.add_chart_rounded),
                  onPressed: _showAddMetricForm,
                  tooltip: 'Ghi nhận chỉ số mới',
                ),
              ]
            : null,
      ),
      body: isWide ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Container(color: AppColors.surface, child: _buildMemberList()),
        ),
        Container(width: 1, color: Colors.white.withValues(alpha: 0.05)),
        Expanded(
          child: _selectedMember == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monitor_heart_outlined,
                        size: 80,
                        color: AppColors.textHint,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Chọn hội viên để xem chỉ số',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : _buildMetricView(_selectedMember!),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    if (_selectedMember != null) {
      return _buildMetricView(_selectedMember!);
    }
    return _buildMemberList();
  }

  Widget _buildMemberList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tìm hội viên...',
              hintStyle: const TextStyle(color: AppColors.textHint),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textHint,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<MemberModel>>(
            stream: _db.streamMembers(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              var members = snap.data ?? [];
              if (_query.isNotEmpty) {
                members = members
                    .where(
                      (m) =>
                          m.name.toLowerCase().contains(_query) ||
                          m.phone.contains(_query),
                    )
                    .toList();
              }
              if (members.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có hội viên',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                );
              }
              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (_, i) {
                  final m = members[i];
                  final isSelected = _selectedMember?.id == m.id;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                    leading: CircleAvatar(
                      backgroundColor: m.isActive
                          ? AppColors.success
                          : AppColors.error,
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      m.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      m.packageName ?? 'Chưa có gói',
                      style: const TextStyle(color: AppColors.textHint),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textHint,
                    ),
                    onTap: () => setState(() => _selectedMember = m),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricView(MemberModel member) {
    return StreamBuilder<List<BodyMetricModel>>(
      stream: _db.streamMemberMetrics(member.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final metrics = snap.data ?? [];
        if (metrics.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.monitor_heart_outlined,
                  size: 80,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có dữ liệu inbody',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                if (context.read<AuthProvider>().user?.role.name != 'member')
                  ElevatedButton.icon(
                    onPressed: _showAddMetricForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Ghi nhận chỉ số đầu tiên'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          );
        }

        final latest = metrics.first;
        final earliest = metrics.last;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Member header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
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
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${metrics.length} lần đo • Lần gần nhất: ${DateFormat('dd/MM/yyyy').format(latest.date)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Latest metrics grid
              const Text(
                'Chỉ số mới nhất',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _MetricCard(
                    label: 'Cân nặng',
                    value: '${latest.weight?.toStringAsFixed(1) ?? '-'} kg',
                    icon: Icons.monitor_weight_outlined,
                    color: AppColors.primary,
                    delta: _delta(latest.weight, earliest.weight, 'kg'),
                    invertDelta: true,
                  ),
                  _MetricCard(
                    label: 'Mỡ cơ thể',
                    value: '${latest.bodyFat?.toStringAsFixed(1) ?? '-'}%',
                    icon: Icons.opacity_outlined,
                    color: AppColors.warning,
                    delta: _delta(latest.bodyFat, earliest.bodyFat, '%'),
                    invertDelta: true,
                  ),
                  _MetricCard(
                    label: 'BMI',
                    value: latest.bmi?.toStringAsFixed(1) ?? '-',
                    icon: Icons.straighten_outlined,
                    color: AppColors.accent,
                  ),
                  _MetricCard(
                    label: 'Chiều cao',
                    value: '${latest.height?.toStringAsFixed(0) ?? '-'} cm',
                    icon: Icons.height_rounded,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Charts
              if (metrics.length >= 2) ...[
                const Text(
                  'Diễn biến cân nặng',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildChart(
                  metrics.reversed.toList(),
                  valueGetter: (m) => m.weight,
                  color: AppColors.primary,
                  unit: 'kg',
                ),
                const SizedBox(height: 24),

                const Text(
                  'Diễn biến mỡ cơ thể',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _buildChart(
                  metrics.reversed.toList(),
                  valueGetter: (m) => m.bodyFat,
                  color: AppColors.warning,
                  unit: '%',
                ),
                const SizedBox(height: 24),
              ],

              // History
              const Text(
                'Lịch sử',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...metrics.map((m) => _HistoryTile(metric: m)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(
    List<BodyMetricModel> metrics, {
    required double? Function(BodyMetricModel) valueGetter,
    required Color color,
    required String unit,
  }) {
    final spots = <FlSpot>[];
    for (int i = 0; i < metrics.length; i++) {
      final v = valueGetter(metrics[i]);
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }
    if (spots.isEmpty) return const SizedBox();

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.2 + 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          minY: minY - padding,
          maxY: maxY + padding,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: padding,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.white.withValues(alpha: 0.05)),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  v.toStringAsFixed(1),
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
              ),
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
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= metrics.length) return const Text('');
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('M/yy').format(metrics[i].date),
                      style: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                  radius: 5,
                  color: color,
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _delta(double? current, double? earliest, String unit) {
    if (current == null || earliest == null) return null;
    final diff = current - earliest;
    if (diff.abs() < 0.05) return null;
    return '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}$unit';
  }

  void _showAddMetricForm() {
    if (_selectedMember == null) return;

    final weightCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final bodyFatCtrl = TextEditingController();
    final chestCtrl = TextEditingController();
    final waistCtrl = TextEditingController();
    final hipsCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ghi Nhận Chỉ Số',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _input(weightCtrl, 'Cân nặng (kg)')),
                  const SizedBox(width: 8),
                  Expanded(child: _input(heightCtrl, 'Cao (cm)')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _input(bodyFatCtrl, 'Mỡ (%)')),
                  const SizedBox(width: 8),
                  Expanded(child: _input(chestCtrl, 'Vòng ngực (cm)')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _input(waistCtrl, 'Vòng bụng (cm)')),
                  const SizedBox(width: 8),
                  Expanded(child: _input(hipsCtrl, 'Vòng hông (cm)')),
                ],
              ),
              _input(noteCtrl, 'Ghi chú', maxLines: 2, isDouble: false),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final metric = BodyMetricModel(
                    id: '',
                    memberId: _selectedMember!.id,
                    weight: double.tryParse(weightCtrl.text),
                    height: double.tryParse(heightCtrl.text),
                    bodyFat: double.tryParse(bodyFatCtrl.text),
                    chest: double.tryParse(chestCtrl.text),
                    waist: double.tryParse(waistCtrl.text),
                    hips: double.tryParse(hipsCtrl.text),
                    date: DateTime.now(),
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                  );
                  await _db.addBodyMetric(metric);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Lưu Chỉ Số',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    bool isDouble = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: isDouble
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          isDense: true,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? delta;
  final bool invertDelta;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.delta,
    this.invertDelta = false,
  });

  @override
  Widget build(BuildContext context) {
    Color? deltaColor;
    if (delta != null) {
      final isNegative = delta!.startsWith('-');
      // Với cân nặng và mỡ: giảm là tốt
      if (invertDelta) {
        deltaColor = isNegative ? AppColors.success : AppColors.error;
      } else {
        deltaColor = isNegative ? AppColors.error : AppColors.success;
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: deltaColor!.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    delta!,
                    style: TextStyle(
                      color: deltaColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
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

class _HistoryTile extends StatelessWidget {
  final BodyMetricModel metric;
  const _HistoryTile({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(metric.date),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 8,
                  children: [
                    if (metric.weight != null)
                      _chipText('${metric.weight!.toStringAsFixed(1)}kg'),
                    if (metric.bodyFat != null)
                      _chipText('${metric.bodyFat!.toStringAsFixed(1)}% mỡ'),
                    if (metric.bmi != null)
                      _chipText('BMI ${metric.bmi!.toStringAsFixed(1)}'),
                  ],
                ),
                if (metric.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      metric.note!,
                      style: const TextStyle(
                        color: AppColors.textHint,
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
  }

  Widget _chipText(String text) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
    );
  }
}
