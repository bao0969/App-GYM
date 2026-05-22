import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';

class AdminSecurityScreen extends StatefulWidget {
  const AdminSecurityScreen({super.key});

  @override
  State<AdminSecurityScreen> createState() => _AdminSecurityScreenState();
}

class _AdminSecurityScreenState extends State<AdminSecurityScreen> {
  bool _is2FaEnabled = false;
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã cập nhật cài đặt bảo mật thành công!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Bảo Mật',
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
              'ĐỔI MẬT KHẨU',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Mật Khẩu Hiện Tại',
                    hint: 'Nhập mật khẩu hiện tại',
                    controller: _oldPassCtrl,
                    isPassword: true,
                    prefix: const Icon(Icons.lock_outline_rounded, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Mật Khẩu Mới',
                    hint: 'Nhập mật khẩu mới',
                    controller: _newPassCtrl,
                    isPassword: true,
                    prefix: const Icon(Icons.vpn_key_rounded, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Xác Nhận Mật Khẩu',
                    hint: 'Nhập lại mật khẩu mới',
                    controller: _confirmPassCtrl,
                    isPassword: true,
                    prefix: const Icon(Icons.check_circle_outline_rounded, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'XÁC THỰC 2 BƯỚC (2FA)',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Bật Xác Thực 2 Bước',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Tăng cường bảo mật bằng mã OTP gửi qua Email hoặc SMS',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                value: _is2FaEnabled,
                onChanged: (val) => setState(() => _is2FaEnabled = val),
                activeThumbColor: AppColors.primary,
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.security_rounded, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Lưu Thay Đổi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
