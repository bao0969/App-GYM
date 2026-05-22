import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/seed_service.dart';

class AdminBackupScreen extends StatefulWidget {
  const AdminBackupScreen({super.key});

  @override
  State<AdminBackupScreen> createState() => _AdminBackupScreenState();
}

class _AdminBackupScreenState extends State<AdminBackupScreen> {
  bool _isResetting = false;
  bool _isBackingUp = false;

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);
    // Simulate backup delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isBackingUp = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sao lưu dữ liệu thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleResetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Khôi Phục Dữ Liệu Gốc',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Hành động này sẽ XÓA SẠCH toàn bộ dữ liệu hiện tại và khôi phục lại dữ liệu mẫu ban đầu (Sửa lỗi font chữ). Bạn có chắc chắn muốn tiếp tục?',
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: AppColors.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Xác Nhận Khôi Phục',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isResetting = true);
      try {
        final seedService = SeedService();
        await seedService.forceReseedAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã khôi phục dữ liệu gốc thành công!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Có lỗi xảy ra khi khôi phục dữ liệu'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isResetting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Sao Lưu & Khôi Phục',
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
            // Backup Section
            _buildSectionCard(
              title: 'Sao Lưu Dữ Liệu',
              description:
                  'Tạo bản sao an toàn cho toàn bộ dữ liệu hội viên, HLV, thiết bị và cấu hình hệ thống trên Cloud Storage.',
              icon: Icons.cloud_upload_rounded,
              color: AppColors.info,
              buttonLabel: 'Tạo Bản Sao Lưu Mới',
              buttonIcon: Icons.backup_rounded,
              isLoading: _isBackingUp,
              onPressed: _handleBackup,
            ),
            const SizedBox(height: 24),
            
            // Auto Backup Setting
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Tự Động Sao Lưu',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Sao lưu định kỳ vào 02:00 sáng mỗi ngày',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                value: true,
                onChanged: (val) {},
                activeThumbColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),

            // Danger Zone
            const Text(
              'KHU VỰC NGUY HIỂM',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            _buildSectionCard(
              title: 'Khôi Phục Dữ Liệu Gốc (Sửa Lỗi Font)',
              description:
                  'Hành động này sẽ xóa toàn bộ dữ liệu hiện tại và tạo lại dữ liệu mẫu ban đầu. Thường dùng để sửa lỗi font chữ khi dữ liệu bị lỗi hiển thị.',
              icon: Icons.restore_rounded,
              color: AppColors.error,
              buttonLabel: 'Khôi Phục & Reset',
              buttonIcon: Icons.warning_amber_rounded,
              isLoading: _isResetting,
              onPressed: _handleResetData,
              isDanger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String buttonLabel,
    required IconData buttonIcon,
    required bool isLoading,
    required VoidCallback onPressed,
    bool isDanger = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDanger ? AppColors.error.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDanger ? AppColors.error : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDanger ? AppColors.error : color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isLoading
                  ? const SizedBox.shrink()
                  : Icon(buttonIcon, color: Colors.white, size: 18),
              label: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      buttonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
