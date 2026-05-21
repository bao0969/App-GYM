// Tính năng 9: Quản lý lớp học nhóm (Group Classes)
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/trainer_model.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AdminClassScheduleScreen extends StatefulWidget {
  const AdminClassScheduleScreen({super.key});

  @override
  State<AdminClassScheduleScreen> createState() =>
      _AdminClassScheduleScreenState();
}

class _AdminClassScheduleScreenState extends State<AdminClassScheduleScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _db = FirestoreService();

  Stream<QuerySnapshot> get _stream => _firestore
      .collection('group_classes')
      .orderBy('scheduledAt', descending: false)
      .snapshots();

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateClassSheet(db: _db),
    );
  }

  void _deleteAllClasses() async {
    final snap = await _firestore.collection('group_classes').get();
    for (var doc in snap.docs) {
      await doc.reference.delete();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa toàn bộ lớp học')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final isTrainer = user?.role.name == 'trainer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Lớp Học Nhóm',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: isTrainer ? [] : [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
            onPressed: _deleteAllClasses,
            tooltip: 'Xóa toàn bộ lớp học (Sửa lỗi dữ liệu)',
          ),
        ],
      ),
      floatingActionButton: isTrainer ? null : FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo Lớp',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.accent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có lớp học nhóm',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return _ClassCard(
                id: docs[i].id,
                data: data,
                currentUserId: context.read<AuthProvider>().user?.uid ?? '',
              );
            },
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final String id, currentUserId;
  final Map<String, dynamic> data;

  const _ClassCard({
    required this.id,
    required this.data,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final ts = data['scheduledAt'] as Timestamp?;
    final date = ts?.toDate() ?? DateTime.now();
    final enrolled = List<String>.from(data['enrolledIds'] ?? []);
    final maxSlots = data['maxSlots'] ?? 20;
    final isFull = enrolled.length >= maxSlots;
    final isEnrolled = enrolled.contains(currentUserId);
    final isPast = date.isBefore(DateTime.now());

    final typeColors = {
      'yoga': AppColors.success,
      'zumba': AppColors.warning,
      'boxing': AppColors.error,
      'cardio': AppColors.accent,
      'pilates': AppColors.primary,
    };
    final type = (data['type'] ?? 'cardio').toLowerCase();
    final color = typeColors[type] ?? AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_classIcon(type), color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Lớp học',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'HLV: ${data['trainerName'] ?? 'Chưa gán'}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textHint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Đã Qua',
                      style: TextStyle(
                        color: AppColors.textHint,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _DetailChip(
                      Icons.calendar_today_rounded,
                      DateFormat('dd/MM/yyyy').format(date),
                      color,
                    ),
                    const SizedBox(width: 8),
                    _DetailChip(
                      Icons.access_time_rounded,
                      DateFormat('HH:mm').format(date),
                      color,
                    ),
                    const SizedBox(width: 8),
                    _DetailChip(
                      Icons.timer_rounded,
                      '${data['durationMin'] ?? 60} phút',
                      color,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Slots progress
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${enrolled.length}/$maxSlots chỗ',
                                style: TextStyle(
                                  color: isFull
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isFull ? 'Đầy' : 'Còn chỗ',
                                style: TextStyle(
                                  color: isFull
                                      ? AppColors.error
                                      : AppColors.success,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: enrolled.length / maxSlots,
                              backgroundColor: color.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isFull ? AppColors.error : color,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isPast) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isFull && !isEnrolled
                          ? null
                          : () => _toggleEnroll(context, enrolled),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isEnrolled
                            ? AppColors.error.withValues(alpha: 0.15)
                            : isFull
                            ? AppColors.surfaceLight
                            : color,
                        foregroundColor: isEnrolled
                            ? AppColors.error
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        elevation: 0,
                      ),
                      child: Text(
                        isEnrolled
                            ? 'Hủy Đăng Ký'
                            : isFull
                            ? 'Đã Đầy'
                            : 'Đăng Ký Tham Gia',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleEnroll(
    BuildContext context,
    List<String> enrolled,
  ) async {
    final ref = FirebaseFirestore.instance.collection('group_classes').doc(id);
    if (enrolled.contains(currentUserId)) {
      await ref.update({
        'enrolledIds': FieldValue.arrayRemove([currentUserId]),
      });
    } else {
      await ref.update({
        'enrolledIds': FieldValue.arrayUnion([currentUserId]),
      });
    }
  }

  IconData _classIcon(String type) {
    switch (type) {
      case 'yoga':
        return Icons.self_improvement_rounded;
      case 'zumba':
        return Icons.music_note_rounded;
      case 'boxing':
        return Icons.sports_mma_rounded;
      case 'cardio':
        return Icons.directions_run_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateClassSheet extends StatefulWidget {
  final FirestoreService db;
  const _CreateClassSheet({required this.db});

  @override
  State<_CreateClassSheet> createState() => _CreateClassSheetState();
}

class _CreateClassSheetState extends State<_CreateClassSheet> {
  final _nameCtrl = TextEditingController();
  String _type = 'cardio';
  TrainerModel? _selectedTrainer;
  List<TrainerModel> _trainers = [];
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  int _duration = 60;
  int _maxSlots = 20;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrainers();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTrainers() async {
    final trainers = await widget.db.getTrainers();
    setState(() => _trainers = trainers);
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (_, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
      builder: (_, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('group_classes').add({
        'name': _nameCtrl.text.trim(),
        'type': _type,
        'trainerId': _selectedTrainer?.userId ?? '',
        'trainerName': _selectedTrainer?.name ?? 'Chưa gán',
        'scheduledAt': Timestamp.fromDate(_scheduledAt),
        'durationMin': _duration,
        'maxSlots': _maxSlots,
        'enrolledIds': [],
        'createdAt': Timestamp.now(),
        'isActive': true,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = [
      ('cardio', 'Cardio'),
      ('yoga', 'Yoga'),
      ('zumba', 'Zumba'),
      ('boxing', 'Boxing'),
      ('pilates', 'Pilates'),
    ];

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tạo Lớp Học Nhóm',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Tên Lớp',
                labelStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Type
            const Text(
              'Loại Lớp',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: types.map((t) {
                final isSelected = _type == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _type = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.2)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent
                            : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      t.$2,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            // Trainer
            DropdownButtonFormField<TrainerModel>(
              initialValue: _selectedTrainer,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Huấn Luyện Viên',
                labelStyle: const TextStyle(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _trainers
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedTrainer = v),
            ),
            const SizedBox(height: 14),
            // Date time
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: AppColors.textHint,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(_scheduledAt),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.edit_rounded,
                      color: AppColors.accent,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thời Lượng (phút)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(
                              () => _duration = (_duration - 15).clamp(15, 180),
                            ),
                            icon: const Icon(
                              Icons.remove_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          Text(
                            '$_duration',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(
                              () => _duration = (_duration + 15).clamp(15, 180),
                            ),
                            icon: const Icon(
                              Icons.add_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Số Chỗ Tối Đa',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(
                              () => _maxSlots = (_maxSlots - 5).clamp(5, 100),
                            ),
                            icon: const Icon(
                              Icons.remove_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                          Text(
                            '$_maxSlots',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(
                              () => _maxSlots = (_maxSlots + 5).clamp(5, 100),
                            ),
                            icon: const Icon(
                              Icons.add_rounded,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
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
                        'Tạo Lớp Học',
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
      ),
    );
  }
}
