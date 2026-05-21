import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/checkin_model.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/staff/staff_banner_carousel.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final staffName = auth.user?.name ?? 'Nhân Viên';

    final pages = [
      _StaffHome(staffName: staffName),
      const _StaffCheckIn(),
      const _StaffMembersList(),
      _StaffProfile(staffName: staffName),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: AppColors.warning,
          unselectedItemColor: AppColors.textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Trang Chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              label: 'Check-in',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded),
              label: 'Hội Viên',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Hồ Sơ',
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tab Home ────────────────────────────────────────────────────────────────

class _StaffHome extends StatelessWidget {
  final String staffName;
  const _StaffHome({required this.staffName});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService();
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xin Chào 👋',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [AppColors.warning, Color(0xFFFFAD00)],
                            ).createShader(b),
                            child: Text(
                              staffName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.warning, Color(0xFFFFAD00)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.badge_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Banner Carousel
                  const StaffBannerCarousel(),

                  // Stats cards
                  FutureBuilder<Map<String, dynamic>>(
                    future: db.getDashboardStats(),
                    builder: (context, snapshot) {
                      final stats = snapshot.data ?? {};
                      final todayCI = stats['todayCheckIns'] ?? 0;
                      final total = stats['totalMembers'] ?? 0;
                      final active = stats['activeMembers'] ?? 0;
                      final expired = stats['expiredMembers'] ?? 0;
                      return GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _StatCard(
                            label: 'Check-in Hôm Nay',
                            value: '$todayCI',
                            icon: Icons.how_to_reg_rounded,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD740), Color(0xFFFFAD00)],
                            ),
                          ),
                          _StatCard(
                            label: 'Tổng Hội Viên',
                            value: '$total',
                            icon: Icons.people_rounded,
                            gradient: AppColors.blueGradient,
                          ),
                          _StatCard(
                            label: 'Đang Hoạt Động',
                            value: '$active',
                            icon: Icons.verified_rounded,
                            gradient: AppColors.greenGradient,
                          ),
                          _StatCard(
                            label: 'Hết Hạn',
                            value: '$expired',
                            icon: Icons.warning_rounded,
                            gradient: AppColors.purpleGradient,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Check-in Gần Đây',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: StreamBuilder<List<CheckInModel>>(
              stream: db.streamTodayCheckIns(),
              builder: (context, snapshot) {
                final checkIns = snapshot.data ?? [];
                if (checkIns.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.history_rounded,
                              color: AppColors.textHint,
                              size: 56,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Chưa có check-in hôm nay',
                              style: TextStyle(color: AppColors.textHint),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _CheckInTile(checkIn: checkIns[i]),
                    childCount: checkIns.length,
                  ),
                );
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Gradient gradient;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckInTile extends StatelessWidget {
  final CheckInModel checkIn;
  const _CheckInTile({required this.checkIn});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkIn.memberName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      checkIn.method == CheckInMethod.qr
                          ? Icons.qr_code_rounded
                          : Icons.touch_app_rounded,
                      color: AppColors.textHint,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      checkIn.method == CheckInMethod.qr
                          ? 'QR Code'
                          : 'Thủ công',
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
          Text(
            DateFormat('HH:mm').format(checkIn.timestamp),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Check-in ─────────────────────────────────────────────────────────────

class _StaffCheckIn extends StatefulWidget {
  const _StaffCheckIn();

  @override
  State<_StaffCheckIn> createState() => _StaffCheckInState();
}

class _StaffCheckInState extends State<_StaffCheckIn> {
  final FirestoreService _db = FirestoreService();
  final _qrCtrl = TextEditingController();
  MemberModel? _foundMember;
  String? _message;
  bool _isSuccess = false;
  bool _isLoading = false;
  bool _confirmed = false;

  @override
  void dispose() {
    _qrCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchMember() async {
    final code = _qrCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isLoading = true;
      _foundMember = null;
      _message = null;
      _confirmed = false;
    });

    // Tìm bằng qrCode trước
    var member = await _db.getMemberByQR(code);

    // Nếu không thấy, thử tìm bằng userId
    member ??= await _db.getMemberByUserId(code);

    if (member == null) {
      setState(() {
        _message = 'Không tìm thấy hội viên với mã: $code';
        _isSuccess = false;
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _foundMember = member;
      _isLoading = false;
      _message = null;
    });
  }

  Future<void> _confirmCheckIn() async {
    if (_foundMember == null) return;

    // Kiểm tra gói tập hết hạn
    if (!_foundMember!.isActive) {
      setState(() {
        _message =
            '❌ Gói tập của ${_foundMember!.name} đã hết hạn! Vui lòng gia hạn trước khi check-in.';
        _isSuccess = false;
      });
      return;
    }

    // Kiểm tra check-in trùng ngày
    final alreadyCheckedIn = await _db.hasCheckedInToday(_foundMember!.id);
    if (alreadyCheckedIn && mounted) {
      final forceProceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Check-in Trùng Ngày',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            '${_foundMember!.name} đã check-in hôm nay rồi.\nBạn có muốn ghi nhận thêm lần check-in này không?',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Huỷ',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Vẫn Check-in',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (forceProceed != true) {
        setState(() => _isLoading = false);
        return;
      }
    }

    // Cảnh báo gần hết hạn
    String? expiryWarning;
    if (_foundMember!.packageExpiry != null &&
        _foundMember!.daysRemaining <= 7) {
      expiryWarning =
          '⚠️ Gói tập còn ${_foundMember!.daysRemaining} ngày – nhắc gia hạn!';
    }

    setState(() => _isLoading = true);
    await _db.addCheckIn(
      CheckInModel(
        id: '',
        memberId: _foundMember!.id,
        memberName: _foundMember!.name,
        timestamp: DateTime.now(),
        method: CheckInMethod.manual,
        isSuccess: true,
      ),
    );
    setState(() {
      _message =
          expiryWarning ?? '✅ Check-in thành công cho ${_foundMember!.name}!';
      _isSuccess = expiryWarning == null;
      _isLoading = false;
      _confirmed = true;
      _qrCtrl.clear();
    });
  }

  void _reset() {
    setState(() {
      _foundMember = null;
      _message = null;
      _confirmed = false;
      _qrCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Check-in Hội Viên',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Nhập mã QR hoặc ID hội viên để check-in',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // QR placeholder area
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.warning,
                    size: 56,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Vùng Quét QR Code',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '(Tích hợp camera scanner)',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Manual input
            const Text(
              'Nhập Mã Thủ Công',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qrCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nhập mã QR hoặc ID hội viên...',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: const Icon(
                        Icons.qr_code_rounded,
                        color: AppColors.textHint,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _searchMember(),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _searchMember,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.warning, Color(0xFFFFAD00)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Member info card
            if (_foundMember != null && !_confirmed)
              _MemberInfoCard(
                member: _foundMember!,
                onConfirm: _confirmCheckIn,
                onCancel: _reset,
                isLoading: _isLoading,
              ),

            // Result message
            if (_message != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isSuccess
                        ? AppColors.success.withValues(alpha: 0.4)
                        : AppColors.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_rounded,
                      color: _isSuccess ? AppColors.success : AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _isSuccess
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_confirmed)
                      GestureDetector(
                        onTap: _reset,
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.textHint,
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 28),
            const Text(
              'Lịch Sử Check-in Hôm Nay',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<CheckInModel>>(
              stream: _db.streamTodayCheckIns(),
              builder: (context, snapshot) {
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Chưa có check-in hôm nay',
                        style: TextStyle(color: AppColors.textHint),
                      ),
                    ),
                  );
                }
                return Column(
                  children: list
                      .take(10)
                      .map((ci) => _CheckInTile(checkIn: ci))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberInfoCard extends StatelessWidget {
  final MemberModel member;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool isLoading;

  const _MemberInfoCard({
    required this.member,
    required this.onConfirm,
    required this.onCancel,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = member.isActive;
    final expiry = member.packageExpiry;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.error.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isActive
                      ? AppColors.greenGradient
                      : AppColors.purpleGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.phone,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isActive ? 'Còn Hạn' : 'Hết Hạn',
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.card_membership_rounded,
            label: 'Gói Tập',
            value: member.packageName ?? 'Chưa đăng ký',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Ngày Hết Hạn',
            value: expiry != null
                ? DateFormat('dd/MM/yyyy').format(expiry)
                : 'Không xác định',
            valueColor: isActive ? AppColors.success : AppColors.error,
          ),
          if (isActive && expiry != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.timer_rounded,
              label: 'Còn Lại',
              value: '${member.daysRemaining} ngày',
              valueColor: member.daysRemaining <= 7
                  ? AppColors.warning
                  : AppColors.success,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textHint),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Huỷ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: isLoading || !isActive ? null : onConfirm,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.how_to_reg_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                  label: Text(
                    isActive ? 'Xác Nhận Check-in' : 'Không Thể Check-in',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? AppColors.success
                        : AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textHint, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tab Members ──────────────────────────────────────────────────────────────

class _StaffMembersList extends StatefulWidget {
  const _StaffMembersList();

  @override
  State<_StaffMembersList> createState() => _StaffMembersListState();
}

class _StaffMembersListState extends State<_StaffMembersList> {
  final FirestoreService _db = FirestoreService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  // 0 = tất cả, 1 = active, 2 = expired
  int _filterIndex = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danh Sách Hội Viên',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                // Search
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, số điện thoại...',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.textHint,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                Row(
                  children: [
                    _FilterChip(
                      label: 'Tất Cả',
                      selected: _filterIndex == 0,
                      onTap: () => setState(() => _filterIndex = 0),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Đang Hoạt Động',
                      selected: _filterIndex == 1,
                      color: AppColors.success,
                      onTap: () => setState(() => _filterIndex = 1),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Hết Hạn',
                      selected: _filterIndex == 2,
                      color: AppColors.error,
                      onTap: () => setState(() => _filterIndex = 2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MemberModel>>(
              stream: _db.streamMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.warning),
                  );
                }
                var members = snapshot.data ?? [];

                // Apply filter
                if (_filterIndex == 1) {
                  members = members.where((m) => m.isActive).toList();
                } else if (_filterIndex == 2) {
                  members = members
                      .where((m) => m.currentStatus == 'expired' || !m.isActive)
                      .toList();
                }

                // Apply search
                if (_searchQuery.isNotEmpty) {
                  members = members
                      .where(
                        (m) =>
                            m.name.toLowerCase().contains(_searchQuery) ||
                            m.phone.contains(_searchQuery) ||
                            m.email.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                }

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          color: AppColors.textHint,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tìm thấy hội viên',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: members.length,
                  itemBuilder: (_, i) => _MemberListTile(member: members[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.warning;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.2) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c : AppColors.textHint,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MemberListTile extends StatelessWidget {
  final MemberModel member;
  const _MemberListTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final isActive = member.isActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              gradient: isActive
                  ? AppColors.greenGradient
                  : AppColors.purpleGradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (member.packageName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    member.packageName!,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Expired',
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (member.packageExpiry != null) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yy').format(member.packageExpiry!),
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Tab Profile ──────────────────────────────────────────────────────────────

class _StaffProfile extends StatelessWidget {
  final String staffName;
  const _StaffProfile({required this.staffName});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD740), Color(0xFFFFAD00)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warning.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        staffName.isNotEmpty ? staffName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    staffName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Nhân Viên',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Info section
            _SectionHeader(title: 'Thông Tin Cá Nhân'),
            const SizedBox(height: 10),
            _ProfileTile(
              icon: Icons.person_rounded,
              label: 'Họ Tên',
              value: staffName,
            ),
            _ProfileTile(
              icon: Icons.email_rounded,
              label: 'Email',
              value: user?.email ?? '',
            ),
            _ProfileTile(
              icon: Icons.phone_rounded,
              label: 'Số Điện Thoại',
              value: user?.phone ?? '',
            ),
            const SizedBox(height: 20),

            _SectionHeader(title: 'Hoạt Động'),
            const SizedBox(height: 10),
            StreamBuilder<List<CheckInModel>>(
              stream: FirestoreService().streamTodayCheckIns(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return _ProfileTile(
                  icon: Icons.how_to_reg_rounded,
                  label: 'Check-in Hôm Nay',
                  value: '$count lượt',
                  valueColor: AppColors.warning,
                );
              },
            ),
            const SizedBox(height: 28),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text(
                        'Đăng Xuất',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      content: const Text(
                        'Bạn có chắc muốn đăng xuất không?',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Huỷ'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Đăng Xuất',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await auth.signOut();
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text(
                  'Đăng Xuất',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
