// Màn hình tạo mã QR cho hội viên - Admin dùng để in thẻ cho khách
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';

class AdminQrGeneratorScreen extends StatefulWidget {
  const AdminQrGeneratorScreen({super.key});

  @override
  State<AdminQrGeneratorScreen> createState() => _AdminQrGeneratorScreenState();
}

class _AdminQrGeneratorScreenState extends State<AdminQrGeneratorScreen> {
  final FirestoreService _db = FirestoreService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<MemberModel> _allMembers = [];
  List<MemberModel> _filtered = [];
  MemberModel? _selected;
  bool _loading = true;

  // Breakpoint để chuyển giữa mobile và desktop layout
  static const double _mobileBreakpoint = 720;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await _db.getMembers();
    if (mounted) {
      setState(() {
        _allMembers = members;
        _filtered = members;
        _loading = false;
      });
    }
  }

  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = _allMembers
          .where(
            (m) =>
                m.name.toLowerCase().contains(lower) ||
                m.phone.contains(lower) ||
                m.qrCode.toLowerCase().contains(lower),
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < _mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          isMobile && _selected != null
              ? 'Mã QR - ${_selected!.name}'
              : 'Tạo Mã QR Hội Viên',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: isMobile && _selected != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selected = null),
              )
            : null,
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  // Mobile: hiển thị danh sách hoặc QR (1 màn 1 lúc)
  Widget _buildMobileLayout() {
    if (_selected != null) {
      return _QrDisplayPanel(member: _selected!);
    }
    return _buildMemberList(isMobile: true);
  }

  // Desktop: hiển thị danh sách + QR cạnh nhau
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
            ),
            child: _buildMemberList(isMobile: false),
          ),
        ),
        Expanded(
          child: _selected == null
              ? _buildEmptyState()
              : _QrDisplayPanel(member: _selected!),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: AppColors.primary,
              size: 52,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chọn hội viên để\nhiển thị mã QR',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberList({required bool isMobile}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filter,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên, SĐT, mã QR...',
              hintStyle: const TextStyle(
                color: AppColors.textHint,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
              filled: true,
              fillColor: AppColors.surfaceLight,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _filtered.isEmpty
              ? const Center(
                  child: Text(
                    'Không tìm thấy hội viên',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                )
              : ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final m = _filtered[i];
                    final isSelected = _selected?.id == m.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = m),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected && !isMobile
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected && !isMobile
                                ? AppColors.primary.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: m.isActive
                                  ? AppColors.success
                                  : AppColors.error,
                              radius: 18,
                              child: Text(
                                m.name.isNotEmpty
                                    ? m.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.name,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    m.qrCode,
                                    style: const TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: m.isActive
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                m.isActive ? 'Hợp lệ' : 'Hết hạn',
                                style: TextStyle(
                                  color: m.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isMobile) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textHint,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _QrDisplayPanel extends StatelessWidget {
  final MemberModel member;
  const _QrDisplayPanel({required this.member});

  @override
  Widget build(BuildContext context) {
    final qrData = member.qrCode;
    final width = MediaQuery.of(context).size.width;
    // Card width thích ứng theo màn hình, max 340
    final cardWidth = width < 380 ? width - 40 : 340.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: width < 600 ? 16 : 40,
        vertical: width < 600 ? 20 : 40,
      ),
      child: Center(
        child: Column(
          children: [
            // Card preview
            Container(
              width: cardWidth,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A1A28), Color(0xFF141420)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Gym logo / name
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.primaryGradient.createShader(b),
                    child: const Text(
                      'GymSync',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'THẺ HỘI VIÊN',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Member info
                  Text(
                    member.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.packageName ?? 'Chưa có gói tập',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Mã: $qrData',
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: member.isActive
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: member.isActive
                            ? AppColors.success.withValues(alpha: 0.4)
                            : AppColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          member.isActive
                              ? Icons.verified_rounded
                              : Icons.warning_rounded,
                          color: member.isActive
                              ? AppColors.success
                              : AppColors.error,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          member.isActive
                              ? 'Còn ${member.daysRemaining} ngày'
                              : 'Đã hết hạn',
                          style: TextStyle(
                            color: member.isActive
                                ? AppColors.success
                                : AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '💡 Hướng dẫn: Đưa thẻ này cho hội viên để dùng khi check-in.\nDùng máy quét mã vạch USB để quét tại quầy lễ tân.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tính năng in thẻ: Dùng Ctrl+P trên trình duyệt để in màn hình này',
                        ),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  },
                  icon: const Icon(Icons.print_rounded, size: 16),
                  label: const Text('In Thẻ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Mã QR của ${member.name}: $qrData'),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Sao Chép Mã'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
