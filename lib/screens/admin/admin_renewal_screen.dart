// Tính năng 1: Gia hạn gói tập cho hội viên (Admin/Staff)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/member_model.dart';
import '../../core/models/package_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/notification_service.dart';

class AdminRenewalScreen extends StatefulWidget {
  final String? initialMemberId;
  const AdminRenewalScreen({super.key, this.initialMemberId});

  @override
  State<AdminRenewalScreen> createState() => _AdminRenewalScreenState();
}

class _AdminRenewalScreenState extends State<AdminRenewalScreen> {
  final _db = FirestoreService();
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Gia Hạn Gói Tập',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Tìm hội viên...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<MemberModel>>(
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
                      m.phone.contains(_query),
                )
                .toList();
          } else {
            // Sort: Priority: expiring_soon > expired > active > paused
            members.sort((a, b) {
              int priority(MemberModel m) {
                switch (m.currentStatus) {
                  case 'expiring_soon': return 0;
                  case 'expired': return 1;
                  case 'active': return 2;
                  default: return 3;
                }
              }
              return priority(a).compareTo(priority(b));
            });
          }

          if (widget.initialMemberId != null) {
            members.sort((a, b) {
              if (a.id == widget.initialMemberId) return -1;
              if (b.id == widget.initialMemberId) return 1;
              return 0;
            });
          }
          if (members.isEmpty) {
            return const Center(
              child: Text(
                'Không tìm thấy hội viên',
                style: TextStyle(color: AppColors.textHint),
              ),
            );
          }
          return Column(
            children: [
              if (widget.initialMemberId != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      const Text('Hội viên đã được chọn sẵn ở đầu danh sách.', style: TextStyle(color: AppColors.primary, fontSize: 12)),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (_, i) =>
                      _MemberRenewalCard(member: members[i], db: _db),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MemberRenewalCard extends StatelessWidget {
  final MemberModel member;
  final FirestoreService db;

  const _MemberRenewalCard({required this.member, required this.db});

  Color get _statusColor {
    final s = member.currentStatus;
    if (s == 'active' || s == 'expiring_soon') {
      return member.daysRemaining <= 7
          ? AppColors.warning
          : AppColors.success;
    } else if (s == 'expired') {
      return AppColors.error;
    } else {
      return AppColors.textHint;
    }
  }

  String get _statusText {
    final s = member.currentStatus;
    if (s == 'active' || s == 'expiring_soon') {
      return member.daysRemaining <= 7
          ? 'Sắp hết hạn (${member.daysRemaining} ngày)'
          : 'Còn ${member.daysRemaining} ngày';
    }
    return member.statusLabel;
  }

  void _showRenewalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => RenewalBottomSheet(member: member, db: db),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.packageName ?? 'Chưa có gói',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showRenewalDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Gia Hạn'),
          ),
        ],
      ),
    );
  }
}

class RenewalBottomSheet extends StatefulWidget {
  final MemberModel member;
  final FirestoreService db;

  const RenewalBottomSheet({super.key, required this.member, required this.db});

  @override
  State<RenewalBottomSheet> createState() => _RenewalBottomSheetState();
}

class _RenewalBottomSheetState extends State<RenewalBottomSheet> {
  PackageModel? _selectedPackage;
  bool _isLoading = false;
  List<PackageModel> _packages = [];
  String _paymentMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final pkgs = await widget.db.getPackages();
    setState(() => _packages = pkgs.where((p) => p.isActive).toList());
  }

  Future<void> _renew() async {
    if (_selectedPackage == null) return;
    setState(() => _isLoading = true);

    if (_paymentMethod == 'transfer') {
      final confirmTransfer = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 24),
              SizedBox(width: 10),
              Text(
                'Thanh Toán Chuyển Khoản',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quét mã VietQR bằng ứng dụng ngân hàng của khách để tự động điền số tiền và nội dung chuyển khoản.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // VietQR Image from free API
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(10),
                    child: Image.network(
                      'https://img.vietqr.io/image/MB-012345678-compact2.png?amount=${_selectedPackage!.price}&addInfo=Gia%20han%20goi%20tap%20cho%20${Uri.encodeComponent(widget.member.name)}&accountName=GYMSYNC%20MANAGEMENT',
                      width: 220,
                      height: 220,
                      fit: BoxFit.contain,
                      errorBuilder: (ctx, err, stack) => const SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(
                          child: Icon(Icons.qr_code_2_rounded, size: 80, color: AppColors.textHint),
                        ),
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
                      _buildBankDetailRow('Ngân hàng', 'MB Bank (Quân Đội)'),
                      const Divider(color: Colors.white10, height: 12),
                      _buildBankDetailRow('Số tài khoản', '012345678'),
                      const Divider(color: Colors.white10, height: 12),
                      _buildBankDetailRow('Chủ tài khoản', 'GYMSYNC MANAGEMENT'),
                      const Divider(color: Colors.white10, height: 12),
                      _buildBankDetailRow(
                        'Số tiền',
                        NumberFormat.simpleCurrency(locale: 'vi_VN').format(_selectedPackage!.price),
                        valueColor: AppColors.primary,
                      ),
                      const Divider(color: Colors.white10, height: 12),
                      _buildBankDetailRow('Nội dung', 'Gia han ${_selectedPackage!.name}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ Giao Dịch', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Xác Nhận Đã Nhận Tiền',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (confirmTransfer != true) {
        setState(() => _isLoading = false);
        return;
      }
    }

    final now = DateTime.now();
    // Nếu còn hạn thì cộng thêm, nếu hết hạn thì tính từ hôm nay
    final baseDate =
        widget.member.packageExpiry != null &&
            widget.member.packageExpiry!.isAfter(now)
        ? widget.member.packageExpiry!
        : now;
    final newExpiry = baseDate.add(
      Duration(days: _selectedPackage!.durationDays),
    );

    try {
      await widget.db.updateMember(widget.member.id, {
        'packageId': _selectedPackage!.id,
        'packageName': _selectedPackage!.name,
        'packageExpiry': Timestamp.fromDate(newExpiry),
        'status': MemberStatus.active.name,
        'sessionsRemaining': _selectedPackage!.sessionCount,
      });

      // Ghi lịch sử gia hạn
      await FirebaseFirestore.instance.collection('renewals').add({
        'memberId': widget.member.id,
        'memberName': widget.member.name,
        'packageId': _selectedPackage!.id,
        'packageName': _selectedPackage!.name,
        'price': _selectedPackage!.price,
        'paymentMethod': _paymentMethod,
        'renewedAt': Timestamp.now(),
        'newExpiry': Timestamp.fromDate(newExpiry),
      });

      // Ghi order cho tài chính
      await FirebaseFirestore.instance.collection('orders').add({
        'memberId': widget.member.id,
        'packageId': _selectedPackage!.id,
        'originalAmount': _selectedPackage!.price,
        'discountAmount': 0.0,
        'finalAmount': _selectedPackage!.price,
        'paymentMethod': _paymentMethod,
        'paymentNote': 'admin-renewal',
        'status': 'paid',
        'createdAt': Timestamp.now(),
        'source': 'admin_renewal',
      });

      // Send notification
      await NotificationService().sendNotification(
        userId: widget.member.userId,
        title: 'Gia Hạn Thành Công',
        body: 'Gói ${_selectedPackage!.name} đã được gia hạn thành công. Hạn mới: ${DateFormat('dd/MM/yyyy').format(newExpiry)}',
        type: 'payment',
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Gia hạn thành công cho ${widget.member.name}!\nHết hạn: ${DateFormat('dd/MM/yyyy').format(newExpiry)}',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gia Hạn: ${widget.member.name}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.member.packageExpiry != null
                ? 'Hết hạn hiện tại: ${DateFormat('dd/MM/yyyy').format(widget.member.packageExpiry!)}'
                : 'Chưa có gói tập',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chọn Gói Tập',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (_packages.isEmpty)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else
            ..._packages.map((pkg) {
              final isSelected = _selectedPackage?.id == pkg.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedPackage = pkg),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg.name,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              pkg.durationLabel,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        NumberFormat.simpleCurrency(locale: 'vi_VN').format(pkg.price),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPaymentMethodChip('cash', 'Tiền mặt', Icons.money_rounded),
                const SizedBox(width: 8),
                _buildPaymentMethodChip('transfer', 'Chuyển khoản', Icons.account_balance_rounded),
                const SizedBox(width: 8),
                _buildPaymentMethodChip('ewallet', 'Ví điện tử', Icons.account_balance_wallet_rounded),
                const SizedBox(width: 8),
                _buildPaymentMethodChip('pos', 'Quẹt thẻ', Icons.credit_card_rounded),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedPackage == null || _isLoading ? null : _renew,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.surfaceLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Xác Nhận Gia Hạn',
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
    );
  }

  Widget _buildPaymentMethodChip(String value, String label, IconData icon) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textHint, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
