import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/checkin_model.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';
import '../../screens/admin/admin_renewal_screen.dart';

class AdminCheckInWidget extends StatefulWidget {
  const AdminCheckInWidget({super.key});

  @override
  State<AdminCheckInWidget> createState() => _AdminCheckInWidgetState();
}

class _AdminCheckInWidgetState extends State<AdminCheckInWidget>
    with SingleTickerProviderStateMixin {
  final FirestoreService _db = FirestoreService();
  final _qrCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  MemberModel? _foundMember;
  String? _message;
  bool _isSuccess = false;
  bool _isLoading = false;
  bool _confirmed = false;
  bool _isExpanded = false; // Compact by default

  List<MemberModel> _allMembers = [];
  List<MemberModel> _suggestions = [];
  List<CheckInModel> _todayCheckIns = [];
  bool _loadingMembers = true;

  late AnimationController _animCtrl;
  late Animation<double> _chevronAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _chevronAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final members = await _db.getMembers();
    final checkins = await _db.getTodayCheckIns();
    if (mounted) {
      setState(() {
        _allMembers = members;
        _todayCheckIns = checkins;
        _loadingMembers = false;
      });
    }
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded) {
      _animCtrl.forward();
    } else {
      _animCtrl.reverse();
    }
  }

  void _filterSuggestions(String q) {
    if (q.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _suggestions = _allMembers
          .where(
            (m) =>
                m.name.toLowerCase().contains(lower) ||
                m.phone.contains(lower) ||
                m.qrCode.toLowerCase().contains(lower),
          )
          .take(5)
          .toList();
    });
  }

  @override
  void dispose() {
    _qrCtrl.dispose();
    _focusNode.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchMember(String code) async {
    if (code.isEmpty) return;
    setState(() {
      _isLoading = true;
      _foundMember = null;
      _message = null;
      _confirmed = false;
      _suggestions = [];
    });

    var member = await _db.getMemberByQR(code);
    member ??= await _db.getMemberByUserId(code);

    if (member == null) {
      final lower = code.toLowerCase();
      member = _allMembers
          .where((m) => m.name.toLowerCase().contains(lower))
          .firstOrNull;
    }

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
      _qrCtrl.text = code;
    });
  }

  Future<void> _selectMemberDirectly(MemberModel m) async {
    setState(() {
      _foundMember = m;
      _message = null;
      _confirmed = false;
      _suggestions = [];
      _qrCtrl.text = m.qrCode;
    });
  }

  Future<void> _confirmCheckIn() async {
    if (_foundMember == null) return;

    if (_foundMember!.currentStatus == 'pending') {
      setState(() {
        _message =
            '❌ TÀI KHOẢN CHỜ THANH TOÁN! Yêu cầu thu tiền trước khi check-in.';
        _isSuccess = false;
      });
      return;
    }

    if (!_foundMember!.isActive) {
      setState(() {
        _message =
            '❌ Gói tập của ${_foundMember!.name} đã hết hạn! Vui lòng gia hạn trước khi check-in.';
        _isSuccess = false;
      });
      return;
    }

    if ((_foundMember!.packageName?.toLowerCase().contains('buổi') == true ||
            _foundMember!.packageName?.toLowerCase().contains('session') ==
                true) &&
        _foundMember!.sessionsRemaining <= 0) {
      setState(() {
        _message =
            '❌ Đã hết số lượt tập (0 buổi)! Vui lòng gia hạn để tiếp tục.';
        _isSuccess = false;
      });
      return;
    }

    final alreadyCheckedIn = await _db.hasCheckedInToday(_foundMember!.id);
    if (alreadyCheckedIn && mounted) {
      final forceProceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
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
            '${_foundMember!.name} đã check-in hôm nay rồi.\nBạn có muốn ghi nhận thêm không?',
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

    String? expiryWarning;
    if (_foundMember!.packageExpiry != null &&
        _foundMember!.daysRemaining <= 7) {
      expiryWarning =
          '⚠️ Gói tập còn ${_foundMember!.daysRemaining} ngày – nhắc gia hạn!';
    }

    setState(() => _isLoading = true);
    final ci = CheckInModel(
      id: '',
      memberId: _foundMember!.id,
      memberName: _foundMember!.name,
      timestamp: DateTime.now(),
      method: CheckInMethod.qr,
      isSuccess: true,
    );
    await _db.addCheckIn(ci);

    setState(() {
      _message =
          expiryWarning ?? '✅ Check-in thành công cho ${_foundMember!.name}!';
      _isSuccess = expiryWarning == null;
      _isLoading = false;
      _confirmed = true;
      _todayCheckIns.insert(0, ci);
      _qrCtrl.clear();
      _focusNode.requestFocus();
      // Auto-expand to show history after check-in
      if (!_isExpanded) {
        _isExpanded = true;
        _animCtrl.forward();
      }
    });
  }

  void _reset() {
    setState(() {
      _foundMember = null;
      _message = null;
      _confirmed = false;
      _suggestions = [];
      _qrCtrl.clear();
      _focusNode.requestFocus();
    });
  }

  Future<void> _openCameraScanner() async {
    final MobileScannerController cameraController = MobileScannerController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quét QR Bằng Camera',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty &&
                        barcodes.first.rawValue != null) {
                      final String code = barcodes.first.rawValue!;
                      cameraController.stop();
                      Navigator.pop(context);
                      _searchMember(code);
                    }
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Hướng camera vào mã QR trên ứng dụng của Hội viên',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );

    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Compact Header (always visible) ────────────────────────────
          _buildHeader(),

          // ─── Search / Scan (always visible) ──────────────────────────────
          _buildSearchBar(),

          // ─── Suggestions (visible when typing) ────────────────────────────
          if (_suggestions.isNotEmpty) _buildSuggestions(),

          // ─── Found member card ─────────────────────────────────────────────
          if (_foundMember != null && !_confirmed) _buildMemberCard(),

          // ─── Status message ────────────────────────────────────────────────
          if (_message != null) _buildStatusMessage(),

          // ─── Expandable: Today's check-in list ────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded ? _buildTodayList() : const SizedBox.shrink(),
          ),

          // Bottom padding
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: _toggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.07),
          borderRadius: BorderRadius.vertical(
            top: const Radius.circular(20),
            bottom: _isExpanded || _foundMember != null || _message != null
                ? Radius.zero
                : const Radius.circular(0),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.accent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Title + subtitle
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Check-in Hội Viên',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Quét thẻ QR hoặc tìm kiếm tên hội viên',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // Today badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _loadingMembers
                        ? '...'
                        : '${_todayCheckIns.length} hôm nay',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Chevron toggle
            RotationTransition(
              turns: _chevronAnim,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textHint,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _qrCtrl,
              focusNode: _focusNode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              onChanged: (val) => _filterSuggestions(val.trim()),
              decoration: InputDecoration(
                hintText: 'Quét QR bằng súng hoặc gõ tên / SĐT / mã...',
                hintStyle: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: (val) => _searchMember(val.trim()),
            ),
          ),
          const SizedBox(width: 8),
          // Camera button
          _IconBtn(
            icon: Icons.camera_alt_rounded,
            color: AppColors.accent,
            bgColor: AppColors.surfaceLight,
            borderColor: AppColors.accent.withValues(alpha: 0.3),
            onTap: _isLoading ? null : _openCameraScanner,
          ),
          const SizedBox(width: 6),
          // Send/Search button
          _IconBtn(
            icon: Icons.send_rounded,
            color: Colors.white,
            bgColor: AppColors.accent,
            isLoading: _isLoading,
            onTap: _isLoading ? null : () => _searchMember(_qrCtrl.text.trim()),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: _suggestions
            .map(
              (m) => InkWell(
                onTap: () => _selectMemberDirectly(m),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor:
                            m.isActive ? AppColors.success : AppColors.error,
                        child: Text(
                          m.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
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
                            ),
                            Text(
                              m.phone,
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: m.isActive
                              ? AppColors.success.withValues(alpha: 0.12)
                              : AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          m.isActive ? 'Hợp lệ' : 'Hết hạn',
                          style: TextStyle(
                            color:
                                m.isActive ? AppColors.success : AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMemberCard() {
    final m = _foundMember!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: m.isActive
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.error.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: m.isActive ? AppColors.success : AppColors.error,
              radius: 20,
              child: Text(
                m.name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
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
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    m.isActive
                        ? '${m.packageName ?? "Chưa có gói"} · Còn ${m.daysRemaining} ngày'
                        : 'Gói đã hết hạn',
                    style: TextStyle(
                      color: m.isActive
                          ? AppColors.textSecondary
                          : AppColors.error,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _reset,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Huỷ', style: TextStyle(fontSize: 11)),
            ),
            const SizedBox(width: 6),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _confirmCheckIn,
              icon: _isLoading
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 15),
              label: const Text(
                'Check-in',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isSuccess
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isSuccess
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.error.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: _isSuccess ? AppColors.success : AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _message!,
                style: TextStyle(
                  color: _isSuccess ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            if (!_isSuccess && _foundMember != null)
              ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    isScrollControlled: true,
                    builder: (_) => RenewalBottomSheet(
                      member: _foundMember!,
                      db: _db,
                    ),
                  ).then((_) {
                    _searchMember(_foundMember!.qrCode);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(0, 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Gia hạn',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              )
            else if (_confirmed)
              GestureDetector(
                onTap: _reset,
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayList() {
    if (_todayCheckIns.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: AppColors.textHint.withValues(alpha: 0.5),
              size: 13,
            ),
            const SizedBox(width: 6),
            const Text(
              'Chưa có lượt check-in nào hôm nay',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Divider(
            color: Colors.white.withValues(alpha: 0.07),
            height: 1,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lịch Sử Hôm Nay',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_todayCheckIns.length} lượt',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._todayCheckIns
            .take(6)
            .map(
              (ci) => Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 7),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.success,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ci.memberName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(ci.timestamp),
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        if (_todayCheckIns.length > 6)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              '+ ${_todayCheckIns.length - 6} lượt khác hôm nay',
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
          )
        else
          const SizedBox(height: 8),
      ],
    );
  }
}

/// Small icon button helper
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    this.borderColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(11),
          border: borderColor != null
              ? Border.all(color: borderColor!)
              : null,
        ),
        child: isLoading
            ? Padding(
                padding: const EdgeInsets.all(11),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            : Icon(icon, color: color, size: 18),
      ),
    );
  }
}
