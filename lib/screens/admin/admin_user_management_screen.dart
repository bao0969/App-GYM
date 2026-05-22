import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDialog(
          context: context,
          builder: (ctx) => const _CreateUserDialog(),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo Tài Khoản Mới',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
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

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController(text: 'Admin Thứ Hai');
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController(text: 'admin123');
  final _phoneCtrl = TextEditingController(text: '0999888777');
  UserRole _selectedRole = UserRole.admin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = 'admin2@gymsync.com';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    setState(() {
      _selectedRole = role;
      if (role == UserRole.admin) {
        _nameCtrl.text = 'Admin Thứ Hai';
        _emailCtrl.text = 'admin2@gymsync.com';
        _passCtrl.text = 'admin123';
        _phoneCtrl.text = '0999888777';
      } else if (role == UserRole.staff) {
        _nameCtrl.text = 'Nhân Viên Mới';
        _emailCtrl.text = 'staff_${DateTime.now().millisecondsSinceEpoch % 1000}@gymsync.com';
        _passCtrl.text = 'staff123';
        _phoneCtrl.text = '0901234567';
      } else if (role == UserRole.trainer) {
        _nameCtrl.text = 'PT Hữu Cảnh';
        _emailCtrl.text = 'trainer_${DateTime.now().millisecondsSinceEpoch % 1000}@gymsync.com';
        _passCtrl.text = 'trainer123';
        _phoneCtrl.text = '0902345678';
      } else {
        _nameCtrl.text = 'Hội Viên Mới';
        _emailCtrl.text = 'member_${DateTime.now().millisecondsSinceEpoch % 1000}@gymsync.com';
        _passCtrl.text = 'member123';
        _phoneCtrl.text = '0903456789';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tạo Tài Khoản Mới',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Đăng ký gián tiếp để giữ phiên đăng nhập hiện tại.',
            style: TextStyle(color: AppColors.textHint, fontSize: 11),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn Vai Trò',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: UserRole.values.map((role) {
                    final isSelected = _selectedRole == role;
                    Color roleColor = AppColors.primary;
                    if (role == UserRole.staff) roleColor = AppColors.accent;
                    if (role == UserRole.trainer) roleColor = AppColors.success;
                    if (role == UserRole.member) roleColor = AppColors.textHint;

                    return InkWell(
                      onTap: () => _onRoleChanged(role),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? roleColor.withValues(alpha: 0.15) : AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? roleColor : Colors.white.withValues(alpha: 0.05),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            role.roleLabel,
                            style: TextStyle(
                              color: isSelected ? roleColor : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Họ và Tên'),
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('Tên hiển thị'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Địa chỉ Email'),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('VD: admin2@gymsync.com'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                    if (!v.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Mật khẩu'),
                TextFormField(
                  controller: _passCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('Tối thiểu 6 ký tự'),
                  validator: (v) => v == null || v.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                ),
                const SizedBox(height: 12),
                _buildFieldLabel('Số điện thoại'),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: _buildInputDecoration('Số liên hệ'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập số điện thoại' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text(
                  'Tạo Tài Khoản',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.card,
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameCtrl.text;
      final email = _emailCtrl.text;
      final password = _passCtrl.text;
      final phone = _phoneCtrl.text;
      final role = _selectedRole;

      final tempAppName = 'TempRegisterApp_${DateTime.now().millisecondsSinceEpoch}';
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: tempAppName,
        options: Firebase.app().options,
      );

      final authInstance = FirebaseAuth.instanceFor(app: tempApp);
      UserCredential cred = await authInstance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (cred.user != null) {
        final uid = cred.user!.uid;

        final userModel = UserModel(
          uid: uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          role: role,
          createdAt: DateTime.now(),
        );

        final firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(uid).set(userModel.toJson());

        if (role == UserRole.member) {
          await firestore.collection('members').add({
            'userId': uid,
            'name': name.trim(),
            'email': email.trim(),
            'phone': phone.trim(),
            'status': 'active',
            'qrCode': uid,
            'joinDate': Timestamp.now(),
            'packageName': 'Gói Cơ Bản',
            'packageExpiry': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
          });
        } else if (role == UserRole.trainer) {
          await firestore.collection('trainers').add({
            'userId': uid,
            'name': name.trim(),
            'email': email.trim(),
            'phone': phone.trim(),
            'specialization': 'Thể hình tổng quát',
            'experience': 1,
            'rating': 5.0,
            'isAvailable': true,
            'joinDate': Timestamp.now(),
            'bio': 'Huấn luyện viên tại GymSync.',
            'certifications': ['ACE Personal Trainer'],
            'clients': 0,
            'sessions': 0,
          });
        }

        await tempApp.delete();

        if (!mounted) return;
        Navigator.pop(context);

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Tạo Thành Công',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đã tạo thành công tài khoản ${role.roleLabel} mới!',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoText('Email:', email),
                        _buildInfoText('Mật khẩu:', password),
                        _buildInfoText('Vai trò:', role.roleLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn có thể dùng tài khoản này đăng nhập kiểm tra các luồng nghiệp vụ tương ứng ngay.',
                    style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Xong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildInfoText(String label, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(color: AppColors.textHint, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: val,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
