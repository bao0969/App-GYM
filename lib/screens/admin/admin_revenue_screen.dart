import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
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
  bool _exporting = false;

  final List<Map<String, dynamic>> _monthly = [
    {'month': 'T1', 'revenue': 32.5, 'cost': 19.5},
    {'month': 'T2', 'revenue': 28.0, 'cost': 16.8},
    {'month': 'T3', 'revenue': 41.2, 'cost': 24.7},
    {'month': 'T4', 'revenue': 38.7, 'cost': 23.2},
    {'month': 'T5', 'revenue': 45.1, 'cost': 27.1},
    {'month': 'T6', 'revenue': 52.3, 'cost': 31.4},
    {'month': 'T7', 'revenue': 48.9, 'cost': 29.3},
    {'month': 'T8', 'revenue': 56.4, 'cost': 33.8},
    {'month': 'T9', 'revenue': 43.2, 'cost': 25.9},
    {'month': 'T10', 'revenue': 61.7, 'cost': 37.0},
    {'month': 'T11', 'revenue': 58.9, 'cost': 35.3},
    {'month': 'T12', 'revenue': 72.1, 'cost': 43.3},
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  double get _total => _monthly.fold(0, (s, d) => s + (d['revenue'] as double));
  double get _totalCost =>
      _monthly.fold(0, (s, d) => s + (d['cost'] as double));
  double get _totalProfit => _total - _totalCost;

  // ─── Excel Export ───────────────────────────────────────────────────────────
  Future<void> _exportExcel() async {
    setState(() => _exporting = true);
    try {
      final excel = Excel.createExcel();

      // Remove default Sheet1
      excel.delete('Sheet1');

      _buildSheet1Overview(excel);
      _buildSheet2Monthly(excel);
      _buildSheet3Packages(excel);
      _buildSheet4KPI(excel);

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Failed to encode Excel');

      final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      
      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.document.createElement('a') as html.AnchorElement
          ..href = url
          ..style.display = 'none'
          ..download = 'GymSync_BaoCaoTaiChinh_$now.xlsx';
        html.document.body?.children.add(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã tải xuống báo cáo Excel!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else if (Platform.isWindows) {
        final downloadsPath = '${Platform.environment['USERPROFILE']}\\Downloads';
        final file = File('$downloadsPath\\GymSync_BaoCaoTaiChinh_$now.xlsx');
        await file.writeAsBytes(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã lưu báo cáo Excel vào mục Downloads!'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/GymSync_BaoCaoTaiChinh_$now.xlsx');
        await file.writeAsBytes(bytes);

        if (mounted) {
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(file.path)],
              text: '📊 Báo Cáo Tài Chính GymSync - $now',
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vui lòng khởi động lại app hoàn toàn (Stop & Start) để cập nhật tính năng xuất file. Lỗi: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _buildSheet1Overview(Excel excel) {
    final sheet = excel['Tổng Quan'];

    // Header style
    final headerStyle = CellStyle(
      bold: true,
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#FF6B35'),
      horizontalAlign: HorizontalAlign.Center,
    );
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 22,
      fontColorHex: ExcelColor.fromHexString('#FF6B35'),
    );
    final labelStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#888888'),
    );
    final valueStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#1A1A2E'),
    );
    final greenStyle = CellStyle(
      bold: true,
      fontSize: 16,
      fontColorHex: ExcelColor.fromHexString('#00C853'),
    );
    final subStyle = CellStyle(
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#AAAAAA'),
      italic: true,
    );

    // Row 1: Title
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('🏋️ GymSync — Báo Cáo Tài Chính');
    titleCell.cellStyle = titleStyle;

    // Row 2: Period
    final periodCell = sheet.cell(CellIndex.indexByString('A2'));
    periodCell.value = TextCellValue(
        'Kỳ Báo Cáo: Năm ${DateTime.now().year}   |   Ngày Xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}');
    periodCell.cellStyle = subStyle;

    // Row 4: Section header
    final secCell = sheet.cell(CellIndex.indexByString('A4'));
    secCell.value = TextCellValue('CHỈ SỐ TỔNG QUAN');
    secCell.cellStyle = headerStyle;
    sheet.merge(CellIndex.indexByString('A4'), CellIndex.indexByString('D4'));

    // Row 5–8: KPIs
    final kpis = [
      ['Tổng Doanh Thu', '${_total.toStringAsFixed(1)}M VNĐ'],
      ['Tổng Chi Phí (Ước Tính)', '${_totalCost.toStringAsFixed(1)}M VNĐ'],
      ['Lợi Nhuận Gộp', '${_totalProfit.toStringAsFixed(1)}M VNĐ'],
      ['Tỷ Suất Lợi Nhuận', '${(_totalProfit / _total * 100).toStringAsFixed(1)}%'],
      ['Tăng Trưởng YoY', '+18%'],
      ['Tháng Doanh Thu Cao Nhất', 'T12: 72.1M VNĐ'],
      ['Trung Bình / Tháng', '${(_total / 12).toStringAsFixed(1)}M VNĐ'],
    ];

    for (int i = 0; i < kpis.length; i++) {
      final labelCell = sheet.cell(CellIndex.indexByString('A${5 + i}'));
      labelCell.value = TextCellValue(kpis[i][0]);
      labelCell.cellStyle = labelStyle;

      final valCell = sheet.cell(CellIndex.indexByString('C${5 + i}'));
      valCell.value = TextCellValue(kpis[i][1]);
      valCell.cellStyle = i == 2 ? greenStyle : valueStyle;
    }

    // Row 13: Footer
    final footerCell = sheet.cell(CellIndex.indexByString('A14'));
    footerCell.value = TextCellValue(
        'Báo cáo được tạo tự động bởi GymSync Admin App. Dữ liệu chi phí là ước tính.');
    footerCell.cellStyle = subStyle;

    // Column widths
    sheet.setColumnWidth(0, 35);
    sheet.setColumnWidth(1, 5);
    sheet.setColumnWidth(2, 25);
    sheet.setColumnWidth(3, 15);
  }

  void _buildSheet2Monthly(Excel excel) {
    final sheet = excel['Doanh Thu Tháng'];

    final headerStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#FF6B35'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final evenRowStyle = CellStyle(
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#FFF8F5'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final oddRowStyle = CellStyle(
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final textStyleEven = CellStyle(
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#FFF8F5'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final textStyleOdd = CellStyle(
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#FFFFFF'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );
    final greenStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#00C853'),
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );
    final redStyle = CellStyle(
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#D50000'),
      bold: true,
      horizontalAlign: HorizontalAlign.Right,
      verticalAlign: VerticalAlign.Center,
    );

    // Title
    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('DOANH THU THEO THÁNG — NĂM ${DateTime.now().year}');
    titleCell.cellStyle = CellStyle(
        bold: true, fontSize: 14, fontColorHex: ExcelColor.fromHexString('#FF6B35'),
        horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);
    sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('G1'));

    // Header row
    final headers = [
      'Tháng', 'Doanh Thu (Triệu VNĐ)', 'Chi Phí (Triệu VNĐ)', 'Lợi Nhuận (Triệu VNĐ)',
      'Tỷ Suất LN (%)', 'So Tháng Trước', 'Đánh Giá'
    ];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 2));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (int i = 0; i < _monthly.length; i++) {
      final d = _monthly[i];
      final rev = d['revenue'] as double;
      final cost = d['cost'] as double;
      final profit = rev - cost;
      final margin = profit / rev * 100;
      final prevRev = i > 0 ? _monthly[i - 1]['revenue'] as double : rev;
      final growth = i > 0 ? ((rev - prevRev) / prevRev * 100) : 0.0;
      final isEven = i % 2 == 0;
      final baseStyle = isEven ? evenRowStyle : oddRowStyle;
      final textStyle = isEven ? textStyleEven : textStyleOdd;

      final rowData = [
        d['month'] as String,
        rev.toStringAsFixed(1),
        cost.toStringAsFixed(1),
        profit.toStringAsFixed(1),
        '${margin.toStringAsFixed(1)}%',
        i == 0 ? '-' : '${growth >= 0 ? "+" : ""}${growth.toStringAsFixed(1)}%',
        profit >= 15 ? '✅ Tốt' : profit >= 10 ? '⚠️ Bình thường' : '❌ Cần cải thiện',
      ];

      for (int c = 0; c < rowData.length; c++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3 + i));
        cell.value = TextCellValue(rowData[c]);
        
        if (c == 0 || c == 6) {
          cell.cellStyle = textStyle; // Text columns
        } else if (c == 5 && i > 0) {
          cell.cellStyle = growth >= 0 ? greenStyle : redStyle;
        } else {
          cell.cellStyle = baseStyle; // Number columns
        }
      }
    }

    // Total row
    final totalRow = 3 + _monthly.length;
    final totalData = [
      'TỔNG CỘNG',
      _total.toStringAsFixed(1),
      _totalCost.toStringAsFixed(1),
      _totalProfit.toStringAsFixed(1),
      '${(_totalProfit / _total * 100).toStringAsFixed(1)}%',
      '+18% YoY',
      '',
    ];
    final totalStyle = CellStyle(
      bold: true, fontSize: 12,
      backgroundColorHex: ExcelColor.fromHexString('#FF6B35'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );
    for (int c = 0; c < totalData.length; c++) {
      final cell =
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: totalRow));
      cell.value = TextCellValue(totalData[c]);
      cell.cellStyle = totalStyle;
    }

    // Column widths
    sheet.setColumnWidth(0, 12);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 18);
    sheet.setColumnWidth(6, 22);
  }

  void _buildSheet3Packages(Excel excel) {
    final sheet = excel['Phân Tích Gói Tập'];

    final headerStyle = CellStyle(
      bold: true, fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#FF6B35'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('PHÂN TÍCH DOANH THU THEO GÓI TẬP');
    titleCell.cellStyle = CellStyle(
        bold: true, fontSize: 13, fontColorHex: ExcelColor.fromHexString('#FF6B35'));

    final headers = [
      'Gói Tập', 'Tỷ Lệ (%)','Doanh Thu (M)', 'Số HV Ước Tính', 'Doanh Thu/HV (K)'
    ];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 2));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }

    final packages = [
      {'name': 'Gói 1 Tháng', 'pct': 0.25, 'members': 45},
      {'name': 'Gói 3 Tháng', 'pct': 0.30, 'members': 38},
      {'name': 'Gói 6 Tháng', 'pct': 0.28, 'members': 28},
      {'name': 'Gói 1 Năm', 'pct': 0.17, 'members': 15},
    ];
    final rowColors = [
      '#FFF3EE', '#FFF8F5', '#FFF3EE', '#FFF8F5',
    ];

    for (int i = 0; i < packages.length; i++) {
      final p = packages[i];
      final pct = p['pct'] as double;
      final members = p['members'] as int;
      final rev = _total * pct;
      final revPerMember = members > 0 ? (rev / members * 1000) : 0;

      final rowStyle = CellStyle(
        fontSize: 11,
        backgroundColorHex: ExcelColor.fromHexString(rowColors[i]),
      );

      final rowData = [
        p['name'] as String,
        '${(pct * 100).toStringAsFixed(0)}%',
        rev.toStringAsFixed(1),
        '$members người',
        '${revPerMember.toStringAsFixed(0)}K',
      ];
      for (int c = 0; c < rowData.length; c++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3 + i));
        cell.value = TextCellValue(rowData[c]);
        cell.cellStyle = rowStyle;
      }
    }

    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 20);
  }

  void _buildSheet4KPI(Excel excel) {
    final sheet = excel['KPI Dashboard'];

    final headerStyle = CellStyle(
      bold: true, fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#FF6B35'),
    );
    final titleStyle = CellStyle(
      bold: true, fontSize: 13,
      fontColorHex: ExcelColor.fromHexString('#FF6B35'),
    );

    final titleCell = sheet.cell(CellIndex.indexByString('A1'));
    titleCell.value = TextCellValue('KPI DASHBOARD — GYMSYNC');
    titleCell.cellStyle = titleStyle;

    final headers = ['Chỉ Số KPI', 'Giá Trị', 'Mục Tiêu', 'Trạng Thái'];
    for (int c = 0; c < headers.length; c++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 2));
      cell.value = TextCellValue(headers[c]);
      cell.cellStyle = headerStyle;
    }

    final kpis = [
      ['Tổng Hội Viên Hoạt Động', '126 người', '150 người', '⚠️ 84%'],
      ['Tỷ Lệ Gia Hạn (Retention)', '72%', '80%', '⚠️ Cần cải thiện'],
      ['Doanh Thu Trung Bình/HV', '${(_total / 126 * 1000).toStringAsFixed(0)}K/tháng', '5,000K/tháng', '✅ Đạt'],
      ['Churn Rate (Tỷ Lệ Rời Bỏ)', '28%', '<20%', '❌ Cao'],
      ['NPS (Điểm Hài Lòng)', '7.2/10', '8.5/10', '⚠️ Cần cải thiện'],
      ['Check-in TB / Ngày', '45 lượt', '60 lượt', '⚠️ 75%'],
      ['Lợi Nhuận Gộp TB / Tháng', '${(_totalProfit / 12).toStringAsFixed(1)}M', '20M', '✅ Đạt'],
      ['Tỷ Suất Lợi Nhuận', '${(_totalProfit / _total * 100).toStringAsFixed(1)}%', '40%', '✅ Vượt mục tiêu'],
      ['Công Suất Phòng Tập', '68%', '85%', '⚠️ Cần cải thiện'],
      ['PT Sessions / Tháng', '320 buổi', '400 buổi', '⚠️ 80%'],
    ];

    final rowColors = ['#FFF8F5', '#FFFFFF'];
    for (int i = 0; i < kpis.length; i++) {
      final rowStyle = CellStyle(
        fontSize: 11,
        backgroundColorHex: ExcelColor.fromHexString(rowColors[i % 2]),
      );
      for (int c = 0; c < kpis[i].length; c++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3 + i));
        cell.value = TextCellValue(kpis[i][c]);
        cell.cellStyle = rowStyle;
      }
    }

    sheet.setColumnWidth(0, 35);
    sheet.setColumnWidth(1, 22);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 22);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
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
                // Summary card
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
                                  color: Colors.white70, fontSize: 13),
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.trending_up_rounded,
                                          color: Colors.white, size: 13),
                                      SizedBox(width: 4),
                                      Text(
                                        '+18% YoY',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'LN: ${_totalProfit.toStringAsFixed(1)}M',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
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
                // Tabs
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
                      fontSize: 11,
                    ),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Biểu Đồ'),
                      Tab(text: 'Phân Tích'),
                      Tab(text: 'Lịch Sử'),
                      Tab(text: 'Báo Cáo'),
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
                _ReportTab(
                  monthly: _monthly,
                  total: _total,
                  totalCost: _totalCost,
                  totalProfit: _totalProfit,
                  exporting: _exporting,
                  onExport: _exportExcel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Bar Chart ─────────────────────────────────────────────────────────
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
                    tooltipBorder:
                        const BorderSide(color: Colors.transparent),
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

// ─── Tab 2: Analysis ──────────────────────────────────────────────────────────
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
                            onTouch(
                                resp!.touchedSection!.touchedSectionIndex);
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
                          title:
                              '${((d['pct'] as double) * 100).toInt()}%',
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
                const Row(
                  children: [
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

// ─── Tab 3: Renewal History ───────────────────────────────────────────────────
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
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05)),
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

// ─── Tab 4: Report & Development Plan ────────────────────────────────────────
class _ReportTab extends StatelessWidget {
  final List<Map<String, dynamic>> monthly;
  final double total;
  final double totalCost;
  final double totalProfit;
  final bool exporting;
  final VoidCallback onExport;

  const _ReportTab({
    required this.monthly,
    required this.total,
    required this.totalCost,
    required this.totalProfit,
    required this.exporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Export Section ───────────────────────────────────────────────
          const Text(
            'Xuất Báo Cáo',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Report preview
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.table_chart_rounded,
                        color: AppColors.success,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Báo Cáo Tài Chính Excel',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'GymSync_BaoCaoTaiChinh_${DateFormat('yyyyMM').format(DateTime.now())}.xlsx',
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Sheet list
                const Text(
                  'Nội dung file Excel:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...[
                  ('Sheet 1', 'Tổng Quan', 'KPI tổng hợp toàn năm', AppColors.primary),
                  ('Sheet 2', 'Doanh Thu Tháng', 'Bảng 12 tháng có lợi nhuận & tăng trưởng', AppColors.success),
                  ('Sheet 3', 'Phân Tích Gói', 'Breakdown theo từng loại gói tập', AppColors.accent),
                  ('Sheet 4', 'KPI Dashboard', 'Các chỉ số hoạt động quan trọng', AppColors.warning),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: item.$4.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.$1,
                            style: TextStyle(
                              color: item.$4,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.$2,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              item.$3,
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Export button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: exporting ? null : onExport,
                    icon: exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      exporting ? 'Đang xuất...' : '📊 Xuất Excel Ngay',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Development Plan ─────────────────────────────────────────────
          Row(
            children: [
              const Text(
                'Kế Hoạch Phát Triển',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Roadmap',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Lộ trình phát triển GymSync theo từng giai đoạn',
            style: TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const SizedBox(height: 14),

          // Phase cards
          ..._phases.map(
            (phase) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PhaseCard(phase: phase),
            ),
          ),

          const SizedBox(height: 8),

          // Vision note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.accent.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Text('🎯', style: TextStyle(fontSize: 22)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tầm Nhìn 2027',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Trở thành chuỗi phòng gym công nghệ hàng đầu với 10+ chi nhánh, nền tảng app quản lý thống nhất và doanh thu 5 tỷ VNĐ/năm.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
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

// ─── Phase Data ───────────────────────────────────────────────────────────────
class _Phase {
  final String phase;
  final String title;
  final String period;
  final String status;
  final String emoji;
  final Color color;
  final double progress;
  final List<String> targets;
  final List<String> actions;

  const _Phase({
    required this.phase,
    required this.title,
    required this.period,
    required this.status,
    required this.emoji,
    required this.color,
    required this.progress,
    required this.targets,
    required this.actions,
  });
}

const _phases = [
  _Phase(
    phase: 'Phase 1',
    title: 'Foundation — Nền Tảng',
    period: 'Q1 2025',
    status: 'Hoàn Thành',
    emoji: '✅',
    color: AppColors.success,
    progress: 1.0,
    targets: [
      '🎯 100 hội viên đăng ký',
      '💰 Break-even (hòa vốn)',
      '📱 App quản lý v1.0',
      '⭐ NPS ≥ 7.0',
    ],
    actions: [
      'Ra mắt phòng gym & tuyển dụng PT',
      'Triển khai hệ thống GymSync',
      'Chiến dịch marketing đầu tiên',
    ],
  ),
  _Phase(
    phase: 'Phase 2',
    title: 'Growth — Tăng Trưởng',
    period: 'Q2 – Q3 2025',
    status: 'Đang Thực Hiện',
    emoji: '🔄',
    color: AppColors.primary,
    progress: 0.65,
    targets: [
      '🎯 300 hội viên hoạt động',
      '💰 Doanh thu 50M/tháng',
      '🏢 Mở thêm 1 chi nhánh',
      '📊 Triển khai POS & Inventory',
    ],
    actions: [
      'Mở rộng đội ngũ PT (thêm 3 HLV)',
      'Ra mắt chương trình referral',
      'Tích hợp thanh toán online',
    ],
  ),
  _Phase(
    phase: 'Phase 3',
    title: 'Scale — Mở Rộng',
    period: 'Q4 2025 – Q1 2026',
    status: 'Kế Hoạch',
    emoji: '📋',
    color: AppColors.accent,
    progress: 0.0,
    targets: [
      '🎯 500 hội viên',
      '💰 Doanh thu 100M/tháng',
      '🏢 3 chi nhánh',
      '📲 App member v2.0',
    ],
    actions: [
      'Nâng cấp cơ sở vật chất',
      'Ra mắt app member đầy đủ tính năng',
      'Hệ thống loyalty & gamification',
    ],
  ),
  _Phase(
    phase: 'Phase 4',
    title: 'Franchise — Nhượng Quyền',
    period: '2026 – 2027',
    status: 'Tầm Nhìn',
    emoji: '🚀',
    color: AppColors.warning,
    progress: 0.0,
    targets: [
      '🎯 5+ chi nhánh Franchise',
      '💰 Doanh thu 500M/tháng',
      '🤝 B2B Corporate wellness',
      '🌏 Xuất khẩu sang thị trường ĐNA',
    ],
    actions: [
      'Phát triển franchise model',
      'Hệ thống quản lý multi-branch',
      'Đầu tư vào R&D công nghệ',
    ],
  ),
];

class _PhaseCard extends StatefulWidget {
  final _Phase phase;
  const _PhaseCard({required this.phase});

  @override
  State<_PhaseCard> createState() => _PhaseCardState();
}

class _PhaseCardState extends State<_PhaseCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.phase;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: p.color.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(p.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: p.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.phase,
                              style: TextStyle(
                                color: p.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.period,
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: p.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    p.status,
                    style: TextStyle(
                      color: p.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tiến độ',
                      style: const TextStyle(
                          color: AppColors.textHint, fontSize: 11),
                    ),
                    Text(
                      '${(p.progress * 100).toInt()}%',
                      style: TextStyle(
                        color: p.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: p.progress,
                    backgroundColor: p.color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(p.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),

            // Expanded content
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        Divider(
                            color: Colors.white.withValues(alpha: 0.07),
                            height: 1),
                        const SizedBox(height: 12),
                        Text(
                          'Mục tiêu:',
                          style: TextStyle(
                            color: p.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...p.targets.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              t,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Hành động:',
                          style: TextStyle(
                            color: p.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...p.actions.map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.arrow_right_rounded,
                                    color: p.color, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    a,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // Tap to expand hint
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  _expanded ? 'Thu gọn' : 'Xem chi tiết',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
