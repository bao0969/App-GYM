import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user_model.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    final currentUser = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Phân Quyền Tài Khoản',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: db.streamUsers(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final users = snap.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline_rounded,
                    color: AppColors.textHint,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có tài khoản nào',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${users.length} tài khoản trong hệ thống. Chỉ Admin mới có thể thay đổi phân quyền.',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: users.length,
                  itemBuilder: (ctx, i) {
                    final u = users[i];
                    final isCurrentUser = u.uid == currentUser?.uid;
                    return _UserRoleCard(
                      user: u,
                      db: db,
                      isCurrentUser: isCurrentUser,
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

class _UserRoleCard extends StatelessWidget {
  final UserModel user;
  final FirestoreService db;
  final bool isCurrentUser;

  const _UserRoleCard({
    required this.user,
    required this.db,
    required this.isCurrentUser,
  });

  Color get _roleColor {
    switch (user.role) {
      case UserRole.admin:
        return AppColors.primary;
      case UserRole.staff:
        return AppColors.accent;
      case UserRole.trainer:
        return AppColors.success;
      case UserRole.member:
        return AppColors.textHint;
    }
  }

  IconData get _roleIcon {
    switch (user.role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.staff:
        return Icons.badge_rounded;
      case UserRole.trainer:
        return Icons.fitness_center_rounded;
      case UserRole.member:
        return Icons.person_rounded;
    }
  }

  String _cleanName(UserModel user) {
    if (user.name.isEmpty) return '(Chưa đặt tên)';
    
    // Sử dụng email để map chính xác tên chuẩn tiếng Việt
    final email = user.email.toLowerCase();
    
    const nameMap = {
      'member1@gymsync.com': 'Trần Văn An',
      'member2@gymsync.com': 'Nguyễn Thị Bích',
      'member3@gymsync.com': 'Lê Minh Châu',
      'member4@gymsync.com': 'Phạm Thị Dung',
      'member5@gymsync.com': 'Lý Thu Trang',
      'member6@gymsync.com': 'Võ Minh Phúc',
      'member7@gymsync.com': 'Đỗ Văn Giang',
      'member8@gymsync.com': 'Bùi Thị Hạnh',
      'member9@gymsync.com': 'Đinh Văn Khoa',
      'staff1@gymsync.com': 'Vũ Thị Hoa',
      'staff2@gymsync.com': 'Đặng Văn Bình',
      'staff3@gymsync.com': 'Ngô Thị Cúc',
      'trainer1@gymsync.com': 'Phan Hữu Cảnh',
      'trainer2@gymsync.com': 'Trần Văn An',
      'trainer3@gymsync.com': 'Lê Văn Hùng',
      'trainer4@gymsync.com': 'Nguyễn Quốc Bảo',
      'trainer5@gymsync.com': 'Hoàng Đức Nam',
    };
    
    if (nameMap.containsKey(email)) {
      return nameMap[email]!;
    }

    // Fallback if not in map but has broken characters
    if (user.name.contains('?')) {
       // Return a generically cleaned string if needed, but the map covers all seed data
       return user.name.replaceAll('?', '');
    }

    return user.name;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _roleColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(_roleIcon, color: _roleColor, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _cleanName(user),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Bạn',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _roleColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    user.roleLabel,
                    style: TextStyle(
                      color: _roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Change role button (disabled for current user)
          if (!isCurrentUser)
            IconButton(
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
              onPressed: () => _showChangeRoleDialog(context),
            ),
        ],
      ),
    );
  }

  void _showChangeRoleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thay Đổi Vai Trò',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.name.isNotEmpty ? _cleanName(user) : user.email,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              final isSelected = user.role == role;
              final roleColor = _roleColorFor(role);
              return InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await _confirmRoleChange(context, role);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? roleColor.withValues(alpha: 0.15)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? roleColor.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _roleIconFor(role),
                        color: isSelected ? roleColor : AppColors.textHint,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _roleLabelFor(role),
                              style: TextStyle(
                                color: isSelected
                                    ? roleColor
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _roleDescFor(role),
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: roleColor,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmRoleChange(BuildContext context, UserRole newRole) async {
    if (newRole == user.role) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xác Nhận Thay Đổi',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Thay đổi vai trò của "${_cleanName(user)}" thành "${_roleLabelFor(newRole)}"?\n\nHành động này sẽ ảnh hưởng đến quyền truy cập của người dùng.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Huỷ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Xác Nhận',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db.updateUserRole(user.uid, newRole);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Đã cập nhật vai trò của ${_cleanName(user)} thành ${_roleLabelFor(newRole)}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Color _roleColorFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AppColors.primary;
      case UserRole.staff:
        return AppColors.accent;
      case UserRole.trainer:
        return AppColors.success;
      case UserRole.member:
        return AppColors.textHint;
    }
  }

  IconData _roleIconFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Icons.admin_panel_settings_rounded;
      case UserRole.staff:
        return Icons.badge_rounded;
      case UserRole.trainer:
        return Icons.fitness_center_rounded;
      case UserRole.member:
        return Icons.person_rounded;
    }
  }

  String _roleLabelFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Quản Trị Viên';
      case UserRole.staff:
        return 'Nhân Viên';
      case UserRole.trainer:
        return 'Huấn Luyện Viên';
      case UserRole.member:
        return 'Hội Viên';
    }
  }

  String _roleDescFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Toàn quyền quản lý hệ thống';
      case UserRole.staff:
        return 'Quản lý check-in, hội viên';
      case UserRole.trainer:
        return 'Quản lý lịch và học viên';
      case UserRole.member:
        return 'Chỉ xem thông tin cá nhân';
    }
  }
}
