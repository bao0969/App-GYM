import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Báo Cáo Tổng Hợp',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'XUẤT BÁO CÁO DOANH THU',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              context,
              title: 'Báo Cáo Theo Tháng',
              description: 'Doanh thu từ các gói tập và POS',
              icon: Icons.calendar_month_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              context,
              title: 'Báo Cáo Theo Quý',
              description: 'Tổng hợp 3 tháng gần nhất',
              icon: Icons.pie_chart_rounded,
              color: AppColors.accent,
            ),
            const SizedBox(height: 32),
            const Text(
              'BÁO CÁO HOẠT ĐỘNG',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildReportCard(
              context,
              title: 'Lượt Check-in Hội Viên',
              description: 'Thống kê mật độ hội viên theo giờ',
              icon: Icons.qr_code_scanner_rounded,
              color: AppColors.success,
            ),
            const SizedBox(height: 12),
            _buildReportCard(
              context,
              title: 'Đánh Giá Huấn Luyện Viên',
              description: 'Tổng hợp rating trung bình',
              icon: Icons.star_rounded,
              color: AppColors.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang tạo và tải xuống báo cáo PDF...'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            icon: const Icon(Icons.download_rounded, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
