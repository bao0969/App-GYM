import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/package_model.dart';
import '../../core/models/coupon_model.dart';
import '../../core/models/order_model.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';

class MemberPromosPackagesScreen extends StatefulWidget {
  const MemberPromosPackagesScreen({super.key});

  @override
  State<MemberPromosPackagesScreen> createState() => _MemberPromosPackagesScreenState();
}

class _MemberPromosPackagesScreenState extends State<MemberPromosPackagesScreen> {
  final _db = FirestoreService();
  final _couponCtrl = TextEditingController();
  late Stream<List<PackageModel>> _packagesStream;
  
  // Timer state
  late Timer _countdownTimer;
  Duration _flashSaleTime = const Duration(hours: 3, minutes: 45, seconds: 12);
  
  // Discount states
  CouponModel? _appliedCoupon;
  bool _isStudentVerified = false;
  String? _couponError;
  bool _isValidatingCoupon = false;

  // Student upload forms
  final _schoolCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  bool _isSubmittingStudent = false;
  String? _studentVerifyStatus; // null | 'pending' | 'approved'

  @override
  void initState() {
    super.initState();
    _packagesStream = _db.streamPackages();
    _startTimer();
    _checkStudentVerification();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_flashSaleTime.inSeconds > 0) {
          _flashSaleTime = _flashSaleTime - const Duration(seconds: 1);
        } else {
          // Reset countdown to next 4 hours
          _flashSaleTime = const Duration(hours: 4);
        }
      });
    });
  }

  Future<void> _checkStudentVerification() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('student_verifications')
          .where('memberId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        setState(() {
          _studentVerifyStatus = data['status'] as String?;
          _isStudentVerified = _studentVerifyStatus == 'approved';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _couponCtrl.dispose();
    _schoolCtrl.dispose();
    _studentIdCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours : $minutes : $seconds";
  }

  Future<void> _applyCouponCode() async {
    final code = _couponCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() {
      _isValidatingCoupon = true;
      _couponError = null;
      _appliedCoupon = null;
    });

    try {
      final coupon = await _db.findCouponByCode(code);
      if (coupon == null) {
        setState(() {
          _couponError = 'Mã giảm giá không tồn tại.';
          _isValidatingCoupon = false;
        });
        return;
      }

      if (!coupon.isValid) {
        setState(() {
          _couponError = 'Mã giảm giá đã hết hạn hoặc hết lượt.';
          _isValidatingCoupon = false;
        });
        return;
      }

      setState(() {
        _appliedCoupon = coupon;
        _couponError = null;
        _isValidatingCoupon = false;
      });
    } catch (e) {
      setState(() {
        _couponError = 'Lỗi xác thực mã giảm giá.';
        _isValidatingCoupon = false;
      });
    }
  }

  Future<void> _submitStudentVerify() async {
    if (_schoolCtrl.text.trim().isEmpty || _studentIdCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin thẻ sinh viên.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmittingStudent = true);
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    try {
      // Simulate/Save in Firestore
      await FirebaseFirestore.instance.collection('student_verifications').doc(user.uid).set({
        'memberId': user.uid,
        'memberName': user.name,
        'memberEmail': user.email,
        'schoolName': _schoolCtrl.text.trim(),
        'studentId': _studentIdCtrl.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _studentVerifyStatus = 'pending';
        _isSubmittingStudent = false;
      });

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gửi thông tin xác minh thành công! Vui lòng chờ Admin duyệt.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmittingStudent = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xảy ra lỗi khi gửi xác minh. Thử lại sau.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showStudentVerificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Xác Minh Học Viên - Sinh Viên',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textHint),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.discount_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ưu đãi giảm 30% tất cả các gói tập GymSync khi xác minh thành công thẻ sinh viên còn hạn.',
                          style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _schoolCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Trường học (Đại học/Cao đẳng) *',
                    labelStyle: const TextStyle(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _studentIdCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Mã số sinh viên (MSSV) *',
                    labelStyle: const TextStyle(color: AppColors.textHint),
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ảnh chụp thẻ sinh viên *',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.textHint.withValues(alpha: 0.3), style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_rounded, color: AppColors.accent, size: 36),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhấp để chọn/chụp ảnh thẻ sinh viên',
                        style: TextStyle(color: AppColors.textHint, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Định dạng JPG, PNG (Tối đa 5MB)',
                        style: TextStyle(color: AppColors.textHint, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmittingStudent ? null : _submitStudentVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmittingStudent
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Gửi Xác Minh Ngay',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckoutBottomSheet(PackageModel pkg) {
    double originalPrice = pkg.price;
    double couponDiscount = 0;
    double studentDiscount = 0;

    // Apply student discount
    if (_isStudentVerified) {
      studentDiscount = originalPrice * 0.3; // 30% off
    }

    // Apply coupon discount
    if (_appliedCoupon != null) {
      couponDiscount = _appliedCoupon!.calculateDiscount(originalPrice, packageId: pkg.id);
    }

    double finalPrice = (originalPrice - couponDiscount - studentDiscount).clamp(0, originalPrice);
    PaymentMethod selectedMethod = PaymentMethod.transfer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setS) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Xác Nhận Đăng Ký Gói',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textHint),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pkg.description,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        pkg.durationLabel,
                        style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Phương Thức Thanh Toán',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentMethodCard(
                        onTap: () => setS(() => selectedMethod = PaymentMethod.transfer),
                        title: '💳 Chuyển Khoản',
                        subtitle: 'Quét mã VietQR',
                        isSelected: selectedMethod == PaymentMethod.transfer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPaymentMethodCard(
                        onTap: () => setS(() => selectedMethod = PaymentMethod.cash),
                        title: '💵 Tiền Mặt',
                        subtitle: 'Duyệt tại quầy lễ tân',
                        isSelected: selectedMethod == PaymentMethod.cash,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Chi Tiết Thanh Toán',
                  style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 10),
                _priceRow('Giá niêm yết', NumberFormat.simpleCurrency(locale: 'vi_VN').format(originalPrice)),
                if (studentDiscount > 0)
                  _priceRow(
                    'Ưu đãi sinh viên (30%)',
                    '- ${NumberFormat.simpleCurrency(locale: 'vi_VN').format(studentDiscount)}',
                    isDiscount: true,
                  ),
                if (couponDiscount > 0)
                  _priceRow(
                    'Mã giảm giá (${_appliedCoupon?.code})',
                    '- ${NumberFormat.simpleCurrency(locale: 'vi_VN').format(couponDiscount)}',
                    isDiscount: true,
                  ),
                const Divider(color: Colors.white12, height: 20),
                _priceRow(
                  'Tổng số tiền',
                  NumberFormat.simpleCurrency(locale: 'vi_VN').format(finalPrice),
                  isTotal: true,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx); // Close sheet
                      _executeCheckoutFlow(pkg, couponDiscount + studentDiscount, selectedMethod, finalPrice);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Xác Nhận Đăng Ký',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _executeCheckoutFlow(
    PackageModel pkg,
    double totalDiscount,
    PaymentMethod paymentMethod,
    double finalPrice,
  ) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    if (paymentMethod == PaymentMethod.transfer) {
      _showVietQRDialog(pkg, totalDiscount, finalPrice);
    } else {
      _executeCashCheckoutFlow(pkg, totalDiscount);
    }
  }


  Widget _priceRow(String label, String value, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDiscount
                  ? AppColors.error
                  : isTotal
                      ? AppColors.success
                      : AppColors.textPrimary,
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal || isDiscount ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required VoidCallback onTap,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white.withValues(alpha: 0.05),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textHint,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCashSuccessDialog(PackageModel pkg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 52),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đăng Ký Thành Công!',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Gói tập "${pkg.name}" đã được đăng ký thành công.\n\nVui lòng thanh toán tiền mặt tại quầy lễ tân để Admin duyệt kích hoạt gói tập của bạn.',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Back to dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVietQRDialog(PackageModel pkg, double totalDiscount, double finalPrice) {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final memo = 'GYMSYNC ${user.uid.substring(0, 8).toUpperCase()}';
    final qrUrl = 'https://img.vietqr.io/image/MB-012345678-compact.png?amount=${finalPrice.toInt()}&addInfo=${Uri.encodeComponent(memo)}&accountName=GYMSYNC%20MANAGEMENT';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx2, setS2) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quét QR Chuyển Khoản',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textHint),
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dùng app ngân hàng để quét mã thanh toán',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    qrUrl,
                    height: 240,
                    width: 240,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 240,
                        width: 240,
                        child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const SizedBox(
                      height: 240,
                      width: 240,
                      child: Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 64, color: AppColors.textHint),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Ngân hàng', 'MB Bank (Quân Đội)'),
                      _infoRow('Số tài khoản', '012345678'),
                      _infoRow('Chủ tài khoản', 'GYMSYNC MANAGEMENT'),
                      _infoRow('Số tiền', NumberFormat.simpleCurrency(locale: 'vi_VN').format(finalPrice)),
                      _infoRow('Nội dung', memo, isHighlight: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogCtx); // close dialog
                  _executeTransferCheckoutFlow(pkg, totalDiscount, memo);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Tôi Đã Chuyển Khoản',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.accent : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeTransferCheckoutFlow(PackageModel pkg, double totalDiscount, String memo) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    try {
      // Create Order in pending state
      await _db.createOnlinePackageOrder(
        memberId: user.uid,
        package: pkg,
        couponCode: _appliedCoupon?.code,
        discountAmount: totalDiscount,
        paymentMethod: PaymentMethod.transfer,
        paymentNote: 'Chuyển khoản VietQR: $memo',
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        _showTransferSuccessDialog(pkg);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showTransferSuccessDialog(PackageModel pkg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 52),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gửi Yêu Cầu Thành Công!',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Yêu cầu thanh toán chuyển khoản cho gói "${pkg.name}" đã được ghi nhận.\n\nAdmin sẽ xác minh tài khoản và kích hoạt gói tập cho bạn trong thời gian sớm nhất!',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Back to dashboard
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeCashCheckoutFlow(PackageModel pkg, double totalDiscount) async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );

    try {
      // Create Order in pending state
      await _db.createOnlinePackageOrder(
        memberId: user.uid,
        package: pkg,
        couponCode: _appliedCoupon?.code,
        discountAmount: totalDiscount,
        paymentMethod: PaymentMethod.cash,
        paymentNote: 'Thanh toán tiền mặt gói ${pkg.name}',
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        _showCashSuccessDialog(pkg);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thanh toán thất bại: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Khuyến Mãi & Gói Tập',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Flash sale Countdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE84E1B), Color(0xFFFF6B35), Color(0xFFFF8C61)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.flash_on_rounded, color: Colors.yellow, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'FLASH SALE GIỜ VÀNG',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Gói Platinum 6 Tháng',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Giảm ngay 40% trọn gói.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'KẾT THÚC SAU',
                          style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(_flashSaleTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            final flashPkg = PackageModel(
                              id: 'flash_sale_platinum',
                              name: 'Gói Flash Sale Platinum 6T',
                              description: 'Gói tập Gym, Yoga cao cấp 6 tháng',
                              durationDays: 180,
                              price: 899000,
                              originalPrice: 1500000,
                              features: ['Tập 24/7 toàn hệ thống', 'Đo inbody miễn phí', 'Tủ đồ thông minh'],
                            );
                            _showCheckoutBottomSheet(flashPkg);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Đăng Ký',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Coupon application section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mã Giảm Giá & Voucher',
                      style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _couponCtrl,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Nhập mã (Ví dụ: WELCOME50)',
                              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                              filled: true,
                              fillColor: AppColors.surfaceLight,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _isValidatingCoupon ? null : _applyCouponCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: _isValidatingCoupon
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Áp Dụng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                      ],
                    ),
                    if (_couponError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _couponError!,
                        style: const TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (_appliedCoupon != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Đã áp dụng mã ${_appliedCoupon!.code}: ${_appliedCoupon!.description}',
                              style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),

          // Student verification section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.school_rounded, color: AppColors.accent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chương Trình Ưu Đãi Sinh Viên',
                            style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isStudentVerified
                                ? '✓ Tài khoản của bạn đã được duyệt giảm giá 30%'
                                : _studentVerifyStatus == 'pending'
                                    ? 'Đang chờ Admin duyệt thẻ sinh viên'
                                    : 'Giảm 30% khi xác minh thẻ sinh viên',
                            style: TextStyle(
                              color: _isStudentVerified
                                  ? AppColors.success
                                  : _studentVerifyStatus == 'pending'
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: _isStudentVerified || _studentVerifyStatus == 'pending' ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isStudentVerified && _studentVerifyStatus != 'pending')
                      ElevatedButton(
                        onPressed: _showStudentVerificationSheet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Xác Minh',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      )
                    else if (_studentVerifyStatus == 'pending')
                      const Icon(Icons.hourglass_empty_rounded, color: AppColors.warning, size: 20),
                  ],
                ),
              ),
            ),
          ),

          // Packages Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text(
                'Lựa Chọn Gói Tập Phù Hợp',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          // Packages List
          StreamBuilder<List<PackageModel>>(
            stream: _packagesStream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: AppColors.accent))),
                );
              }

              final pkgs = snap.data?.where((p) => p.isActive).toList() ?? [];

              if (pkgs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('Không có gói tập nào khả dụng.', style: TextStyle(color: AppColors.textHint)))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final p = pkgs[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    p.durationLabel,
                                    style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.description,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            ...p.features.map(
                              (feat) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 14),
                                    const SizedBox(width: 8),
                                    Text(
                                      feat,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white10, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('GIÁ ĐĂNG KÝ', style: TextStyle(color: AppColors.textHint, fontSize: 9, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      NumberFormat.simpleCurrency(locale: 'vi_VN').format(p.price),
                                      style: const TextStyle(color: AppColors.success, fontSize: 18, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () => _showCheckoutBottomSheet(p),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.accent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                  child: const Text('Mua Ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: pkgs.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
