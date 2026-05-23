import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';
import '../admin/admin_member_detail_screen.dart';
import '../admin/admin_renewal_screen.dart';
import '../admin/admin_booking_screen.dart';

class AdminMembersScreen extends StatefulWidget {
  const AdminMembersScreen({super.key});
  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirestoreService();
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _statusFilter = 'all';
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      final filters = ['all', 'active', 'expired', 'paused'];
      setState(() => _statusFilter = filters[_tabCtrl.index]);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quản Lý Hội Viên',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      StreamBuilder<List<MemberModel>>(
                        stream: _db.streamMembers(),
                        builder: (_, snap) {
                          final total = snap.data?.length ?? 0;
                          final active =
                              snap.data?.where((m) => m.isActive).length ?? 0;
                          return Text(
                            '$total hội viên • $active đang hoạt động',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _IconBtn(
                      icon: Icons.card_membership_rounded,
                      color: AppColors.warning,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminRenewalScreen(),
                        ),
                      ),
                      tooltip: 'Gia hạn',
                    ),
                    const SizedBox(width: 8),
                    _IconBtn(
                      icon: Icons.person_add_rounded,
                      color: AppColors.primary,
                      onTap: () => _showAddDialog(context),
                      tooltip: 'Thêm hội viên',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Search ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SĐT, email...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppColors.textHint,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Tabs ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
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
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                tabs: const [
                  Tab(text: 'Tất Cả'),
                  Tab(text: 'Hoạt Động'),
                  Tab(text: 'Hết Hạn'),
                  Tab(text: 'Tạm Dừng'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── List ─────────────────────────────────────────────────────────
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
                            m.phone.contains(_query) ||
                            m.email.toLowerCase().contains(_query),
                      )
                      .toList();
                }
                if (_statusFilter != 'all') {
                  members = members.where((m) {
                    switch (_statusFilter) {
                      case 'active':
                        return m.isActive;
                      case 'expired':
                        return m.currentStatus == 'expired';
                      case 'paused':
                        return m.status == MemberStatus.paused;
                      default:
                        return true;
                    }
                  }).toList();
                }

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          color: AppColors.textHint,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không có hội viên nào',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  itemCount: members.length,
                  itemBuilder: (_, i) =>
                      _MemberCard(member: members[i], db: _db),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thêm Hội Viên Mới',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textHint),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ValidatedField(
                  hint: 'Họ và Tên *',
                  ctrl: nameCtrl,
                  icon: Icons.person_outline,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    if (v.trim().length < 2) {
                      return 'Họ tên phải từ 2 ký tự';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _ValidatedField(
                  hint: 'Email',
                  ctrl: emailCtrl,
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final emailRegex = RegExp(
                        r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(v.trim())) {
                        return 'Email không hợp lệ';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _ValidatedField(
                  hint: 'Số Điện Thoại',
                  ctrl: phoneCtrl,
                  icon: Icons.phone_outlined,
                  type: TextInputType.phone,
                  validator: (v) {
                    if (v != null && v.isNotEmpty) {
                      final phoneRegex = RegExp(r'^(0|\+84)[0-9]{8,10}$');
                      if (!phoneRegex.hasMatch(v.trim())) {
                        return 'SĐT không hợp lệ (bắt đầu bằng 0 hoặc +84)';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                _Field('Địa Chỉ', addressCtrl, Icons.location_on_outlined),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setS(() => isLoading = true);
                            await _db.addMember({
                              'userId': '',
                              'name': nameCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'address': addressCtrl.text.trim(),
                              'status': MemberStatus.pending.name,
                              'qrCode':
                                  'MBR${DateTime.now().millisecondsSinceEpoch}',
                              'joinDate': Timestamp.now(),
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.person_add_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                    label: const Text(
                      'Thêm Hội Viên',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType type;

  const _Field(
    this.hint,
    this.ctrl,
    this.icon, [
    // ignore: unused_element_parameter
    this.type = TextInputType.text,
  ]);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ValidatedField extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType type;
  final String? Function(String?)? validator;

  const _ValidatedField({
    required this.hint,
    required this.ctrl,
    required this.icon,
    this.type = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberModel member;
  final FirestoreService db;

  const _MemberCard({required this.member, required this.db});

  Color get _statusColor {
    final s = member.currentStatus;
    if (s == 'active' || s == 'expiring_soon') {
      return member.daysRemaining <= 7 ? AppColors.warning : AppColors.success;
    } else if (s == 'expired') {
      return AppColors.error;
    } else {
      return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminMemberDetailScreen(member: member),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _statusColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
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
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.phone.isNotEmpty ? member.phone : member.email,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: _statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member.statusLabel,
                              style: TextStyle(
                                color: _statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (member.packageName != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.packageName!,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                      if ((member.packageExpiry != null || member.sessionsRemaining > 0) &&
                          member.status == MemberStatus.active) ...[
                        const SizedBox(width: 6),
                        Text(
                          member.sessionsRemaining > 0 ? '${member.sessionsRemaining}b' : '${member.daysRemaining}d',
                          style: TextStyle(
                            color: _statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: AppColors.surface,
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'detail',
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Chi Tiết',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'renew',
                  child: Row(
                    children: [
                      Icon(
                        Icons.card_membership_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Gia Hạn',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'schedule_pt',
                  child: Row(
                    children: [
                      Icon(
                        Icons.sports_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sắp Lịch PT',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'pause',
                  child: Row(
                    children: [
                      Icon(
                        Icons.pause_circle_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tạm Dừng / Kích Hoạt',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_rounded,
                        color: AppColors.error,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text('Xóa', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
              onSelected: (val) async {
                switch (val) {
                  case 'detail':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminMemberDetailScreen(member: member),
                      ),
                    );
                    break;
                  case 'renew':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminRenewalScreen(initialMemberId: member.id),
                      ),
                    );
                    break;
                  case 'schedule_pt':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminPTBookingFlow(initialMember: member),
                      ),
                    );
                    break;
                  case 'pause':
                    if (member.status == MemberStatus.paused) {
                      await db.updateMember(member.id, {'status': MemberStatus.active.name});
                    } else {
                      int days = 7;
                      final result = await showDialog<int>(
                        context: context,
                        builder: (ctx) => StatefulBuilder(
                          builder: (ctx2, setS) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Text('Tạm Dừng Gói Tập', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Tạm dừng gói cho ${member.name}.\nHạn gói sẽ được cộng thêm số ngày pause.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(onPressed: () => setS(() => days = (days - 1).clamp(1, 90)), icon: const Icon(Icons.remove_circle_rounded, color: AppColors.primary, size: 28)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(12)),
                                      child: Text('$days ngày', style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(onPressed: () => setS(() => days = (days + 1).clamp(1, 90)), icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28)),
                                  ],
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ', style: TextStyle(color: AppColors.textSecondary))),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, days),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                child: const Text('Xác Nhận', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (result != null) {
                        await db.pauseMember(member.id, result);
                      }
                    }
                    break;
                  case 'delete':
                    // Cảnh báo khi hội viên còn gói tập active
                    final hasActivePackage =
                        member.status == MemberStatus.active &&
                        member.packageExpiry != null &&
                        member.packageExpiry!.isAfter(DateTime.now());

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              hasActivePackage
                                  ? Icons.warning_rounded
                                  : Icons.delete_rounded,
                              color: AppColors.error,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Xác nhận xóa',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Xóa hội viên "${member.name}"?',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (hasActivePackage) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColors.warning,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Hội viên đang có gói "${member.packageName}" còn ${member.daysRemaining} ngày. Dữ liệu sẽ bị mất vĩnh viễn!',
                                        style: const TextStyle(
                                          color: AppColors.warning,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'Hủy',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Xóa',
                              style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) await db.deleteMember(member.id);
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
