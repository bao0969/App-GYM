import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/package_model.dart';
import '../../core/services/firestore_service.dart';

class AdminPackagesScreen extends StatefulWidget {
  const AdminPackagesScreen({super.key});
  @override
  State<AdminPackagesScreen> createState() => _AdminPackagesScreenState();
}

class _AdminPackagesScreenState extends State<AdminPackagesScreen> {
  final _db = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Gói Tập',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      StreamBuilder<List<PackageModel>>(
                        stream: _db.streamPackages(),
                        builder: (_, snap) {
                          final pkgs = snap.data ?? [];
                          final active = pkgs.where((p) => p.isActive).length;
                          return Text(
                            '${pkgs.length} gói • $active đang bán',
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
                GestureDetector(
                  onTap: () => _showAddSheet(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.greenGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_card_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PackageModel>>(
              stream: _db.streamPackages(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                final pkgs = snap.data ?? [];
                if (pkgs.isEmpty) {
                  return _EmptyState(onAdd: () => _showAddSheet(context));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: pkgs.length,
                  itemBuilder: (_, i) => _PackageCard(
                    package: pkgs[i],
                    db: _db,
                    onEdit: () => _showEditSheet(context, pkgs[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    _showPackageSheet(context, null);
  }

  void _showEditSheet(BuildContext context, PackageModel pkg) {
    _showPackageSheet(context, pkg);
  }

  void _showPackageSheet(BuildContext context, PackageModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null ? existing.price.toInt().toString() : '',
    );
    final daysCtrl = TextEditingController(
      text: existing != null ? existing.durationDays.toString() : '',
    );
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final featureCtrl = TextEditingController();
    final features = List<String>.from(existing?.features ?? []);
    String selectedColor = existing?.color ?? 'orange';
    bool isActive = existing?.isActive ?? true;

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      existing != null ? 'Chỉnh Sửa Gói' : 'Thêm Gói Tập',
                      style: const TextStyle(
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
                _TF('Tên Gói', nameCtrl, Icons.card_membership_rounded),
                const SizedBox(height: 10),
                _TF(
                  'Giá (VNĐ)',
                  priceCtrl,
                  Icons.attach_money_rounded,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 10),
                _TF(
                  'Số Ngày',
                  daysCtrl,
                  Icons.calendar_today_rounded,
                  type: TextInputType.number,
                ),
                const SizedBox(height: 10),
                _TF('Mô Tả', descCtrl, Icons.description_rounded, maxLines: 2),
                const SizedBox(height: 14),
                // Color picker
                const Text(
                  'Màu Sắc',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final e in {
                      'orange': AppColors.orangeGradient,
                      'blue': AppColors.blueGradient,
                      'green': AppColors.greenGradient,
                      'purple': AppColors.purpleGradient,
                    }.entries)
                      GestureDetector(
                        onTap: () => setS(() => selectedColor = e.key),
                        child: Container(
                          width: 36,
                          height: 36,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            gradient: e.value,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedColor == e.key
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (existing != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.toggle_on_rounded,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Trạng Thái Hoạt Động',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Switch(
                          value: isActive,
                          onChanged: (v) => setS(() => isActive = v),
                          activeThumbColor: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Features
                const Text(
                  'Quyền Lợi',
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
                      child: _TF(
                        'Thêm quyền lợi...',
                        featureCtrl,
                        Icons.add_circle_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (featureCtrl.text.trim().isNotEmpty) {
                          setS(() {
                            features.add(featureCtrl.text.trim());
                            featureCtrl.clear();
                          });
                        }
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: features
                        .map(
                          (f) => Chip(
                            label: Text(
                              f,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: AppColors.surfaceLight,
                            deleteIcon: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.textHint,
                            ),
                            onDeleted: () => setS(() => features.remove(f)),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Validation
                      if (nameCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Vui lòng nhập tên gói tập'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                      final days = int.tryParse(daysCtrl.text.trim()) ?? 0;
                      if (price <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Giá gói phải lớn hơn 0'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      if (days <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Số ngày phải lớn hơn 0'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                        return;
                      }
                      final data = {
                        'name': nameCtrl.text.trim(),
                        'price': price,
                        'durationDays': days,
                        'description': descCtrl.text.trim(),
                        'features': features,
                        'isActive': isActive,
                        'color': selectedColor,
                      };
                      if (existing != null) {
                        await _db.updatePackage(existing.id, data);
                      } else {
                        await _db.addPackage(data);
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.save_rounded, color: Colors.white),
                    label: Text(
                      existing != null ? 'Cập Nhật' : 'Lưu Gói Tập',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: existing != null
                          ? AppColors.primary
                          : AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

class _PackageCard extends StatelessWidget {
  final PackageModel package;
  final FirestoreService db;
  final VoidCallback onEdit;
  const _PackageCard({
    required this.package,
    required this.db,
    required this.onEdit,
  });

  Gradient get _gradient {
    switch (package.color) {
      case 'blue':
        return AppColors.blueGradient;
      case 'green':
        return AppColors.greenGradient;
      case 'purple':
        return AppColors.purpleGradient;
      default:
        return AppColors.orangeGradient;
    }
  }

  bool get _isPopular =>
      package.durationDays >= 85 && package.durationDays <= 95;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: package.isActive ? 1.0 : 0.55,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: _gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              package.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              package.durationLabel,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          package.priceLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (package.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      package.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (package.features.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ...package.features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                f,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => db.updatePackage(package.id, {
                          'isActive': !package.isActive,
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                package.isActive
                                    ? Icons.toggle_on_rounded
                                    : Icons.toggle_off_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                package.isActive ? 'Đang Bán' : 'Tạm Dừng',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: onEdit,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          // Kiểm tra xem gói có hội viên đang sử dụng không
                          final memberCount = await db.getMemberCountByPackageName(package.name);
                          if (!context.mounted) return;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Icon(
                                    memberCount > 0 ? Icons.warning_rounded : Icons.delete_rounded,
                                    color: AppColors.error,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Xoà Gói Tập',
                                    style: TextStyle(color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Xoà "${package.name}"?',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (memberCount > 0) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.warning.withValues(alpha: 0.4),
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
                                              'Có $memberCount hội viên đang sử dụng gói này. Việc xóa có thể ảnh hưởng đến hộ viên!',
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
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text(
                                    'Huỷ',
                                    style: TextStyle(color: AppColors.textSecondary),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'Xoà',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await db.deletePackage(package.id);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '⭐ Phổ Biến',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_membership_rounded,
            color: AppColors.textHint,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có gói tập nào',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thêm gói tập đầu tiên để bắt đầu',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Thêm Gói Tập',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TF extends StatelessWidget {
  final String hint;
  final TextEditingController ctrl;
  final IconData icon;
  final TextInputType type;
  final int maxLines;
  const _TF(
    this.hint,
    this.ctrl,
    this.icon, {
    this.type = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
