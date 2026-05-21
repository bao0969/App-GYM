// Tính năng mới: Quản lý tủ đồ - Cấp/thu hồi tủ
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/locker_model.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';

class AdminLockersScreen extends StatefulWidget {
  const AdminLockersScreen({super.key});

  @override
  State<AdminLockersScreen> createState() => _AdminLockersScreenState();
}

class _AdminLockersScreenState extends State<AdminLockersScreen> {
  final _db = FirestoreService();
  String _filter = 'all';
  String? _selectedArea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Quản Lý Tủ Đồ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddLocker,
          ),
        ],
      ),
      body: StreamBuilder<List<LockerModel>>(
        stream: _db.streamLockers(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          final all = snap.data ?? [];
          final areas = all.map((l) => l.area).toSet().toList()..sort();

          // Stats
          final available = all
              .where((l) => l.status == LockerStatus.available)
              .length;
          final assigned = all
              .where((l) => l.status == LockerStatus.assigned)
              .length;
          final maintenance = all
              .where((l) => l.status == LockerStatus.maintenance)
              .length;
          final expiringSoon = all
              .where(
                (l) =>
                    l.status == LockerStatus.assigned &&
                    l.expiryDate != null &&
                    l.expiryDate!.difference(DateTime.now()).inDays <= 7 &&
                    !l.isExpired,
              )
              .length;

          // Filter
          var lockers = all;
          if (_selectedArea != null) {
            lockers = lockers.where((l) => l.area == _selectedArea).toList();
          }
          switch (_filter) {
            case 'available':
              lockers = lockers.where((l) => l.isAvailable).toList();
              break;
            case 'assigned':
              lockers = lockers
                  .where((l) => l.status == LockerStatus.assigned)
                  .toList();
              break;
            case 'expiring':
              lockers = lockers
                  .where(
                    (l) =>
                        l.status == LockerStatus.assigned &&
                        l.expiryDate != null &&
                        l.expiryDate!.difference(DateTime.now()).inDays <= 7,
                  )
                  .toList();
              break;
            case 'maintenance':
              lockers = lockers
                  .where(
                    (l) =>
                        l.status == LockerStatus.maintenance ||
                        l.status == LockerStatus.broken,
                  )
                  .toList();
              break;
          }

          return Column(
            children: [
              // Stats
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      _statBox(
                        'Tổng tủ',
                        '${all.length}',
                        AppColors.textPrimary,
                      ),
                      _statBox('Trống', '$available', AppColors.success),
                      _statBox('Đang dùng', '$assigned', AppColors.primary),
                      _statBox('Sắp hết', '$expiringSoon', AppColors.warning),
                      _statBox('Bảo trì', '$maintenance', AppColors.error),
                    ],
                  ),
                ),
              ),
              // Filter areas + status
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _areaChip(null, 'Tất cả khu'),
                          ...areas.map((a) => _areaChip(a, a)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('all', 'Tất cả'),
                          _filterChip('available', 'Trống'),
                          _filterChip('assigned', 'Đang dùng'),
                          _filterChip('expiring', 'Sắp hết hạn'),
                          _filterChip('maintenance', 'Bảo trì'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: lockers.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có tủ',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.95,
                            ),
                        itemCount: lockers.length,
                        itemBuilder: (_, i) => _LockerCard(
                          locker: lockers[i],
                          onTap: () => _showDetail(lockers[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _areaChip(String? area, String label) {
    final isSelected = _selectedArea == area;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedArea = area),
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.accent,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
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
      ),
    );
  }

  void _showDetail(LockerModel locker) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LockerDetailSheet(locker: locker, db: _db),
    );
  }

  void _showAddLocker() {
    final codeCtrl = TextEditingController();
    final areaCtrl = TextEditingController(text: 'Khu A - Nam');
    final feeCtrl = TextEditingController(text: '100000');

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
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Thêm Tủ Đồ Mới',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _input(codeCtrl, 'Mã tủ (VD: A001)'),
            _input(areaCtrl, 'Khu vực'),
            _input(
              feeCtrl,
              'Phí hàng tháng (VNĐ)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.isEmpty) return;
                await _db.addLocker(
                  LockerModel(
                    id: '',
                    code: codeCtrl.text.toUpperCase(),
                    area: areaCtrl.text,
                    monthlyFee: double.tryParse(feeCtrl.text) ?? 100000,
                  ),
                );
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Thêm Tủ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textHint),
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
}

class _LockerCard extends StatelessWidget {
  final LockerModel locker;
  final VoidCallback onTap;

  const _LockerCard({required this.locker, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    if (locker.status == LockerStatus.assigned) {
      if (locker.isExpired) {
        color = AppColors.error;
        icon = Icons.lock_clock_rounded;
      } else {
        color = AppColors.primary;
        icon = Icons.lock_rounded;
      }
    } else if (locker.status == LockerStatus.available) {
      color = AppColors.success;
      icon = Icons.lock_open_rounded;
    } else if (locker.status == LockerStatus.maintenance) {
      color = AppColors.warning;
      icon = Icons.build_rounded;
    } else {
      color = AppColors.error;
      icon = Icons.broken_image_rounded;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              locker.code,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              locker.statusLabel,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (locker.assignedMemberName != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  locker.assignedMemberName!,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LockerDetailSheet extends StatefulWidget {
  final LockerModel locker;
  final FirestoreService db;
  const _LockerDetailSheet({required this.locker, required this.db});

  @override
  State<_LockerDetailSheet> createState() => _LockerDetailSheetState();
}

class _LockerDetailSheetState extends State<_LockerDetailSheet> {
  @override
  Widget build(BuildContext context) {
    final l = widget.locker;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tủ ${l.code}',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      l.area,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (l.status == LockerStatus.assigned) ...[
            _detailRow('Hội viên', l.assignedMemberName ?? '-'),
            _detailRow(
              'Ngày cấp',
              l.assignedDate != null ? dateFmt.format(l.assignedDate!) : '-',
            ),
            _detailRow(
              'Hạn dùng',
              l.expiryDate != null ? dateFmt.format(l.expiryDate!) : '-',
              color: l.isExpired ? AppColors.error : AppColors.textPrimary,
            ),
            _detailRow('Phí/tháng', '${(l.monthlyFee / 1000).toInt()}K VNĐ'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await widget.db.releaseLocker(l.id);
                if (!mounted) return;
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Thu Hồi Tủ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else if (l.status == LockerStatus.available) ...[
            _detailRow(
              'Trạng thái',
              'Trống - Sẵn sàng cấp',
              color: AppColors.success,
            ),
            _detailRow('Phí/tháng', '${(l.monthlyFee / 1000).toInt()}K VNĐ'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _assignToMember(),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Cấp Tủ Cho Hội Viên'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else ...[
            _detailRow('Trạng thái', l.statusLabel, color: AppColors.warning),
            if (l.note != null) _detailRow('Ghi chú', l.note!),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await widget.db.updateLocker(l.id, {
                  'status': LockerStatus.available.name,
                  'note': null,
                });
                if (!mounted) return;
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Đánh Dấu Đã Sửa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              await widget.db.updateLocker(l.id, {
                'status': l.status == LockerStatus.maintenance
                    ? LockerStatus.available.name
                    : LockerStatus.maintenance.name,
              });
              if (!mounted) return;
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.build_rounded),
            label: Text(
              l.status == LockerStatus.maintenance
                  ? 'Bỏ trạng thái bảo trì'
                  : 'Đánh dấu Bảo Trì',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _assignToMember() async {
    final members = await widget.db.getMembers();
    final activeMembers = members.where((m) => m.isActive).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Chọn Hội Viên',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: activeMembers.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có hội viên hoạt động',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      )
                    : ListView.builder(
                        itemCount: activeMembers.length,
                        itemBuilder: (_, i) {
                          final m = activeMembers[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Text(
                                m.name.isNotEmpty
                                    ? m.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              m.name,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              m.phone,
                              style: const TextStyle(color: AppColors.textHint),
                            ),
                            onTap: () => _selectMember(m),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectMember(MemberModel m) async {
    Navigator.pop(context); // Close dialog

    final monthsCtrl = TextEditingController(text: '1');

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Cấp tủ cho ${m.name}',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: monthsCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Số tháng',
            labelStyle: TextStyle(color: AppColors.textHint),
          ),
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
              final months = int.tryParse(monthsCtrl.text) ?? 1;
              await widget.db.assignLocker(
                widget.locker.id,
                memberId: m.id,
                memberName: m.name,
                durationDays: months * 30,
              );
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context); // Close detail sheet
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Xác Nhận',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
