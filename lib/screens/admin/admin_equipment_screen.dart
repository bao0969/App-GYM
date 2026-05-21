// Tính năng 2: Quản lý thiết bị phòng gym
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common/custom_text_field.dart';

enum EquipmentStatus { good, maintenance, broken }

class EquipmentModel {
  final String id;
  final String name;
  final String category;
  final int quantity;
  final EquipmentStatus status;
  final DateTime? lastMaintenance;
  final String? notes;

  EquipmentModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.status,
    this.lastMaintenance,
    this.notes,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json, String id) {
    return EquipmentModel(
      id: id,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 1,
      status: EquipmentStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => EquipmentStatus.good,
      ),
      lastMaintenance: json['lastMaintenance'] is Timestamp
          ? (json['lastMaintenance'] as Timestamp).toDate()
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'quantity': quantity,
    'status': status.name,
    'lastMaintenance': lastMaintenance != null
        ? Timestamp.fromDate(lastMaintenance!)
        : null,
    'notes': notes,
    'updatedAt': Timestamp.now(),
  };

  String get statusLabel {
    switch (status) {
      case EquipmentStatus.good:
        return 'Tốt';
      case EquipmentStatus.maintenance:
        return 'Bảo Trì';
      case EquipmentStatus.broken:
        return 'Hỏng';
    }
  }

  Color get statusColor {
    switch (status) {
      case EquipmentStatus.good:
        return AppColors.success;
      case EquipmentStatus.maintenance:
        return AppColors.warning;
      case EquipmentStatus.broken:
        return AppColors.error;
    }
  }
}

class AdminEquipmentScreen extends StatefulWidget {
  const AdminEquipmentScreen({super.key});

  @override
  State<AdminEquipmentScreen> createState() => _AdminEquipmentScreenState();
}

class _AdminEquipmentScreenState extends State<AdminEquipmentScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _filterStatus = 'all';

  Stream<List<EquipmentModel>> _streamEquipment() {
    return _firestore
        .collection('equipment')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => EquipmentModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  void _showAddDialog([EquipmentModel? existing]) {
    showDialog(
      context: context,
      builder: (_) => _EquipmentDialog(
        existing: existing,
        onSave: (data) async {
          if (existing != null) {
            await _firestore
                .collection('equipment')
                .doc(existing.id)
                .update(data);
          } else {
            await _firestore.collection('equipment').add(data);
          }
        },
      ),
    );
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Xác nhận xóa',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Bạn có chắc muốn xóa thiết bị này?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textHint),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.collection('equipment').doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Quản Lý Thiết Bị',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primary),
            onPressed: () => _showAddDialog(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final f in [
                  ('all', 'Tất Cả', AppColors.textHint),
                  ('good', 'Tốt', AppColors.success),
                  ('maintenance', 'Bảo Trì', AppColors.warning),
                  ('broken', 'Hỏng', AppColors.error),
                ])
                  GestureDetector(
                    onTap: () => setState(() => _filterStatus = f.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _filterStatus == f.$1
                            ? f.$3.withValues(alpha: 0.2)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _filterStatus == f.$1
                              ? f.$3
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        f.$2,
                        style: TextStyle(
                          color: _filterStatus == f.$1
                              ? f.$3
                              : AppColors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<EquipmentModel>>(
        stream: _streamEquipment(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          var items = snap.data ?? [];
          if (_filterStatus != 'all') {
            items = items.where((e) => e.status.name == _filterStatus).toList();
          }

          // Summary row
          final total = (snap.data ?? []).length;
          final good = (snap.data ?? [])
              .where((e) => e.status == EquipmentStatus.good)
              .length;
          final broken = (snap.data ?? [])
              .where((e) => e.status == EquipmentStatus.broken)
              .length;

          return Column(
            children: [
              // Summary
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _SummaryChip('Tổng', '$total', AppColors.accent),
                    const SizedBox(width: 8),
                    _SummaryChip('Tốt', '$good', AppColors.success),
                    const SizedBox(width: 8),
                    _SummaryChip('Hỏng', '$broken', AppColors.error),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có thiết bị',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (_, i) => _EquipmentCard(
                          equipment: items[i],
                          onEdit: () => _showAddDialog(items[i]),
                          onDelete: () => _delete(items[i].id),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EquipmentCard extends StatelessWidget {
  final EquipmentModel equipment;
  final VoidCallback onEdit, onDelete;

  const _EquipmentCard({
    required this.equipment,
    required this.onEdit,
    required this.onDelete,
  });

  IconData get _categoryIcon {
    switch (equipment.category.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run_rounded;
      case 'tạ':
      case 'weights':
        return Icons.fitness_center_rounded;
      case 'máy':
      case 'machine':
        return Icons.settings_rounded;
      default:
        return Icons.sports_gymnastics_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: equipment.statusColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: equipment.statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_categoryIcon, color: equipment.statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${equipment.category} • SL: ${equipment.quantity}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (equipment.lastMaintenance != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Bảo trì: ${DateFormat('dd/MM/yyyy').format(equipment.lastMaintenance!)}',
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
                  color: equipment.statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  equipment.statusLabel,
                  style: TextStyle(
                    color: equipment.statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(
                      Icons.delete_rounded,
                      color: AppColors.error,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EquipmentDialog extends StatefulWidget {
  final EquipmentModel? existing;
  final Future<void> Function(Map<String, dynamic>) onSave;

  const _EquipmentDialog({this.existing, required this.onSave});

  @override
  State<_EquipmentDialog> createState() => _EquipmentDialogState();
}

class _EquipmentDialogState extends State<_EquipmentDialog> {
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  EquipmentStatus _status = EquipmentStatus.good;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameCtrl.text = widget.existing!.name;
      _categoryCtrl.text = widget.existing!.category;
      _qtyCtrl.text = widget.existing!.quantity.toString();
      _notesCtrl.text = widget.existing!.notes ?? '';
      _status = widget.existing!.status;
    } else {
      _qtyCtrl.text = '1';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await widget.onSave({
        'name': _nameCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'quantity': int.tryParse(_qtyCtrl.text) ?? 1,
        'status': _status.name,
        'notes': _notesCtrl.text.trim(),
        'lastMaintenance': _status == EquipmentStatus.maintenance
            ? Timestamp.now()
            : null,
        'updatedAt': Timestamp.now(),
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing != null ? 'Sửa Thiết Bị' : 'Thêm Thiết Bị',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Tên Thiết Bị',
              hint: 'VD: Máy chạy bộ',
              controller: _nameCtrl,
              prefix: const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Danh Mục',
              hint: 'VD: Cardio, Tạ, Máy...',
              controller: _categoryCtrl,
              prefix: const Icon(
                Icons.category_rounded,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Số Lượng',
              hint: '1',
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              prefix: const Icon(
                Icons.numbers_rounded,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Trạng Thái',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: EquipmentStatus.values.map((s) {
                final colors = {
                  EquipmentStatus.good: AppColors.success,
                  EquipmentStatus.maintenance: AppColors.warning,
                  EquipmentStatus.broken: AppColors.error,
                };
                final labels = {
                  EquipmentStatus.good: 'Tốt',
                  EquipmentStatus.maintenance: 'Bảo Trì',
                  EquipmentStatus.broken: 'Hỏng',
                };
                final c = colors[s]!;
                final isSelected = _status == s;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? c.withValues(alpha: 0.2)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? c : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        labels[s]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? c : AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Ghi Chú',
              hint: 'Tình trạng, vị trí...',
              controller: _notesCtrl,
              maxLines: 2,
              prefix: const Icon(
                Icons.notes_rounded,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textHint),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Lưu',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
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
