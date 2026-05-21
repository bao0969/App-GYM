// Tính năng mới: Quản lý voucher / mã giảm giá
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/coupon_model.dart';
import '../../core/services/firestore_service.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen> {
  final _db = FirestoreService();
  String _filter = 'all'; // all | active | expired | used_up

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Quản Lý Voucher',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormSheet(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo Mới',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _filterChip('all', 'Tất cả'),
                _filterChip('active', 'Còn hiệu lực'),
                _filterChip('expired', 'Hết hạn'),
                _filterChip('used_up', 'Hết lượt'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CouponModel>>(
              stream: _db.streamCoupons(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                var coupons = snap.data ?? [];
                coupons = _applyFilter(coupons);

                if (coupons.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có voucher nào',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: coupons.length,
                  itemBuilder: (_, i) => _CouponCard(
                    coupon: coupons[i],
                    onEdit: () => _showFormSheet(existing: coupons[i]),
                    onDelete: () => _confirmDelete(coupons[i]),
                    onToggle: () => _db.updateCoupon(coupons[i].id, {
                      'isActive': !coupons[i].isActive,
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filter = value),
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
    );
  }

  List<CouponModel> _applyFilter(List<CouponModel> all) {
    final now = DateTime.now();
    switch (_filter) {
      case 'active':
        return all.where((c) => c.isValid).toList();
      case 'expired':
        return all.where((c) => now.isAfter(c.endDate)).toList();
      case 'used_up':
        return all
            .where(
              (c) => c.totalQuantity != -1 && c.usedCount >= c.totalQuantity,
            )
            .toList();
      default:
        return all;
    }
  }

  void _confirmDelete(CouponModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Xoá voucher?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Bạn có chắc muốn xoá voucher "${c.code}"?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Huỷ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.deleteCoupon(c.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xoá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFormSheet({CouponModel? existing}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _CouponForm(
          existing: existing,
          onSubmit: (coupon) async {
            if (existing == null) {
              await _db.addCoupon(coupon);
            } else {
              await _db.updateCoupon(existing.id, coupon.toJson());
            }
          },
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _CouponCard({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final isValid = coupon.isValid;
    final accentColor = isValid ? AppColors.success : AppColors.textHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid
              ? AppColors.primary.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isValid
                    ? [
                        AppColors.primary.withValues(alpha: 0.18),
                        AppColors.primary.withValues(alpha: 0.05),
                      ]
                    : [
                        Colors.grey.withValues(alpha: 0.15),
                        Colors.grey.withValues(alpha: 0.05),
                      ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Icon discount
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      coupon.valueLabel,
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
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
                        coupon.code,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        coupon.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: coupon.isActive,
                  onChanged: (_) => onToggle(),
                  activeThumbColor: AppColors.success,
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Đơn tối thiểu',
                        value: coupon.minOrderAmount > 0
                            ? '${(coupon.minOrderAmount / 1000).toInt()}K'
                            : 'Không',
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'Đã dùng',
                        value: coupon.totalQuantity == -1
                            ? '${coupon.usedCount} / ∞'
                            : '${coupon.usedCount} / ${coupon.totalQuantity}',
                        icon: Icons.confirmation_number_outlined,
                      ),
                    ),
                    Expanded(
                      child: _Stat(
                        label: 'HSD',
                        value: dateFmt.format(coupon.endDate),
                        icon: Icons.event_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Sửa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Xoá'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _Stat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.textHint),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.textHint, fontSize: 10),
        ),
      ],
    );
  }
}

class _CouponForm extends StatefulWidget {
  final CouponModel? existing;
  final Future<void> Function(CouponModel) onSubmit;

  const _CouponForm({this.existing, required this.onSubmit});

  @override
  State<_CouponForm> createState() => _CouponFormState();
}

class _CouponFormState extends State<_CouponForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _valueCtrl;
  late TextEditingController _maxDiscountCtrl;
  late TextEditingController _minOrderCtrl;
  late TextEditingController _quantityCtrl;
  late CouponType _type;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _codeCtrl = TextEditingController(text: c?.code ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _valueCtrl = TextEditingController(text: c?.value.toString() ?? '');
    _maxDiscountCtrl = TextEditingController(
      text: c?.maxDiscount?.toString() ?? '',
    );
    _minOrderCtrl = TextEditingController(
      text: c?.minOrderAmount.toString() ?? '0',
    );
    _quantityCtrl = TextEditingController(
      text: c?.totalQuantity.toString() ?? '-1',
    );
    _type = c?.type ?? CouponType.percent;
    _startDate = c?.startDate ?? DateTime.now();
    _endDate = c?.endDate ?? DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _minOrderCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final coupon = CouponModel(
      id: widget.existing?.id ?? '',
      code: _codeCtrl.text.toUpperCase().trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      value: double.tryParse(_valueCtrl.text) ?? 0,
      maxDiscount: _maxDiscountCtrl.text.isEmpty
          ? null
          : double.tryParse(_maxDiscountCtrl.text),
      minOrderAmount: double.tryParse(_minOrderCtrl.text) ?? 0,
      totalQuantity: int.tryParse(_quantityCtrl.text) ?? -1,
      usedCount: widget.existing?.usedCount ?? 0,
      startDate: _startDate,
      endDate: _endDate,
      isActive: widget.existing?.isActive ?? true,
    );

    await widget.onSubmit(coupon);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing == null ? 'Tạo Voucher Mới' : 'Sửa Voucher',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _field(
                _codeCtrl,
                'Mã code (VD: SUMMER10)',
                upperCase: true,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nhập mã code' : null,
              ),
              _field(
                _descCtrl,
                'Mô tả',
                validator: (v) => v == null || v.isEmpty ? 'Nhập mô tả' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Loại giảm',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('% Phần trăm'),
                      selected: _type == CouponType.percent,
                      onSelected: (_) =>
                          setState(() => _type = CouponType.percent),
                      backgroundColor: AppColors.surfaceLight,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _type == CouponType.percent
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('VNĐ Cố định'),
                      selected: _type == CouponType.fixed,
                      onSelected: (_) =>
                          setState(() => _type = CouponType.fixed),
                      backgroundColor: AppColors.surfaceLight,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _type == CouponType.fixed
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                _valueCtrl,
                _type == CouponType.percent ? 'Giá trị (%)' : 'Giá trị (VNĐ)',
                keyboardType: TextInputType.number,
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Nhập giá trị'
                    : null,
              ),
              if (_type == CouponType.percent)
                _field(
                  _maxDiscountCtrl,
                  'Trần giảm tối đa (VNĐ, có thể bỏ trống)',
                  keyboardType: TextInputType.number,
                ),
              _field(
                _minOrderCtrl,
                'Đơn tối thiểu (VNĐ, 0 = không yêu cầu)',
                keyboardType: TextInputType.number,
              ),
              _field(
                _quantityCtrl,
                'Số lượng phát hành (-1 = không giới hạn)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _datePicker(
                      'Ngày bắt đầu',
                      _startDate,
                      (d) => setState(() => _startDate = d),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _datePicker(
                      'Ngày kết thúc',
                      _endDate,
                      (d) => setState(() => _endDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Lưu Voucher',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    bool upperCase = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        textCapitalization: upperCase
            ? TextCapitalization.characters
            : TextCapitalization.none,
        style: const TextStyle(color: AppColors.textPrimary),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _datePicker(
    String label,
    DateTime value,
    ValueChanged<DateTime> onChange,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primary,
                surface: AppColors.surface,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) onChange(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textHint, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(value),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
