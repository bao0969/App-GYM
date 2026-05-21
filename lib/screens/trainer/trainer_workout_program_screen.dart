// Tính năng 6: Trainer tạo chương trình tập cho học viên
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class TrainerWorkoutProgramScreen extends StatefulWidget {
  const TrainerWorkoutProgramScreen({super.key});

  @override
  State<TrainerWorkoutProgramScreen> createState() =>
      _TrainerWorkoutProgramScreenState();
}

class _TrainerWorkoutProgramScreenState
    extends State<TrainerWorkoutProgramScreen> {
  final _db = FirestoreService();

  Stream<QuerySnapshot> _streamPrograms(String trainerId) {
    return FirebaseFirestore.instance
        .collection('workout_programs')
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Chương Trình Tập',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, user?.uid ?? ''),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tạo Chương Trình',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _streamPrograms(user?.uid ?? ''),
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
                      Icons.fitness_center_rounded,
                      color: AppColors.accent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chưa có chương trình tập',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nhấn + để tạo chương trình mới',
                    style: TextStyle(color: AppColors.textHint, fontSize: 12),
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
              return _ProgramCard(
                id: docs[i].id,
                data: data,
                onDelete: () async {
                  await FirebaseFirestore.instance
                      .collection('workout_programs')
                      .doc(docs[i].id)
                      .delete();
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, String trainerId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateProgramSheet(trainerId: trainerId, db: _db),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _ProgramCard({
    required this.id,
    required this.data,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final exercises = List<Map<String, dynamic>>.from(
      (data['exercises'] as List?)?.map(
            (e) => Map<String, dynamic>.from(e as Map),
          ) ??
          [],
    );
    final createdAt = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'Chương trình',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Học viên: ${data['memberName'] ?? 'Chưa gán'} • ${DateFormat('dd/MM/yyyy').format(createdAt)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data['durationWeeks'] ?? 4} tuần',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Exercises
          if (exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: exercises.take(3).map((ex) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ex['name'] ?? '',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Text(
                          '${ex['sets'] ?? 3}x${ex['reps'] ?? 12}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          if (exercises.length > 3)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '+ ${exercises.length - 3} bài tập khác',
                style: const TextStyle(color: AppColors.textHint, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreateProgramSheet extends StatefulWidget {
  final String trainerId;
  final FirestoreService db;

  const _CreateProgramSheet({required this.trainerId, required this.db});

  @override
  State<_CreateProgramSheet> createState() => _CreateProgramSheetState();
}

class _CreateProgramSheetState extends State<_CreateProgramSheet> {
  final _nameCtrl = TextEditingController();
  int _weeks = 4;
  MemberModel? _selectedMember;
  List<MemberModel> _members = [];
  final List<Map<String, dynamic>> _exercises = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _exercises.addAll([
      {'name': 'Bench Press', 'sets': 4, 'reps': 10},
      {'name': 'Squat', 'sets': 4, 'reps': 12},
      {'name': 'Deadlift', 'sets': 3, 'reps': 8},
    ]);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final members = await widget.db.getMembers();
    setState(() => _members = members);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('workout_programs').add({
        'name': _nameCtrl.text.trim(),
        'trainerId': widget.trainerId,
        'memberId': _selectedMember?.id ?? '',
        'memberName': _selectedMember?.name ?? 'Chưa gán',
        'durationWeeks': _weeks,
        'exercises': _exercises,
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
              'Tạo Chương Trình Tập',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            // Tên chương trình
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Tên Chương Trình',
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
            // Chọn học viên
            const Text(
              'Học Viên',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MemberModel>(
              initialValue: _selectedMember,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              hint: const Text(
                'Chọn học viên',
                style: TextStyle(color: AppColors.textHint),
              ),
              items: _members
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedMember = v),
            ),
            const SizedBox(height: 14),
            // Số tuần
            Row(
              children: [
                const Text(
                  'Thời Gian:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () =>
                      setState(() => _weeks = (_weeks - 1).clamp(1, 52)),
                  icon: const Icon(
                    Icons.remove_circle_outline_rounded,
                    color: AppColors.accent,
                  ),
                ),
                Text(
                  '$_weeks tuần',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      setState(() => _weeks = (_weeks + 1).clamp(1, 52)),
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Danh sách bài tập
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bài Tập',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(
                    () => _exercises.add({
                      'name': 'Bài tập mới',
                      'sets': 3,
                      'reps': 12,
                    }),
                  ),
                  icon: const Icon(
                    Icons.add_rounded,
                    color: AppColors.accent,
                    size: 16,
                  ),
                  label: const Text(
                    'Thêm',
                    style: TextStyle(color: AppColors.accent, fontSize: 12),
                  ),
                ),
              ],
            ),
            ..._exercises.asMap().entries.map((entry) {
              final i = entry.key;
              final ex = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        ex['name'] as String,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '${ex['sets']}x${ex['reps']}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _exercises.removeAt(i)),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.error,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
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
                        'Tạo Chương Trình',
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
