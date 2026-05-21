import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/trainer_model.dart';
import '../../core/services/firestore_service.dart';

class AdminTrainersScreen extends StatefulWidget {
  const AdminTrainersScreen({super.key});
  @override
  State<AdminTrainersScreen> createState() => _AdminTrainersScreenState();
}

class _AdminTrainersScreenState extends State<AdminTrainersScreen> {
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
    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Huấn Luyện Viên',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      StreamBuilder<List<TrainerModel>>(
                        stream: _db.streamTrainers(),
                        builder: (_, snap) {
                          final total = snap.data?.length ?? 0;
                          final avail =
                              snap.data?.where((t) => t.isAvailable).length ??
                              0;
                          return Text(
                            '$total HLV • $avail đang nhận học viên',
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
                  onTap: () => _showAddDialog(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.person_add_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Search ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, chuyên môn...',
                hintStyle: const TextStyle(color: AppColors.textHint),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.textHint,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<TrainerModel>>(
              stream: _db.streamTrainers(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }
                var trainers = snap.data ?? [];
                if (_query.isNotEmpty) {
                  trainers = trainers
                      .where(
                        (t) =>
                            t.name.toLowerCase().contains(_query) ||
                            t.specialization.toLowerCase().contains(_query),
                      )
                      .toList();
                }

                if (trainers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.sports_outlined,
                          color: AppColors.textHint,
                          size: 56,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có huấn luyện viên',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _showAddDialog(context),
                          child: const Text(
                            'Thêm ngay',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  itemCount: trainers.length,
                  itemBuilder: (_, i) =>
                      _TrainerCard(trainer: trainers[i], db: _db),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    int experience = 1;

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
                    const Text(
                      'Thêm Huấn Luyện Viên',
                      style: TextStyle(
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
                _tf('Họ và Tên *', nameCtrl, Icons.person_outline),
                const SizedBox(height: 10),
                _tf(
                  'Email',
                  emailCtrl,
                  Icons.email_outlined,
                  type: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                _tf(
                  'Điện Thoại',
                  phoneCtrl,
                  Icons.phone_outlined,
                  type: TextInputType.phone,
                ),
                const SizedBox(height: 10),
                _tf('Chuyên Môn', specCtrl, Icons.fitness_center_rounded),
                const SizedBox(height: 10),
                _tf('Giới Thiệu', bioCtrl, Icons.info_outline),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Kinh nghiệm:',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setS(
                        () => experience = (experience - 1).clamp(0, 30),
                      ),
                      icon: const Icon(
                        Icons.remove_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      '$experience năm',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setS(
                        () => experience = (experience + 1).clamp(0, 30),
                      ),
                      icon: const Icon(
                        Icons.add_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      await _db.addTrainer({
                        'userId': '',
                        'name': nameCtrl.text.trim(),
                        'email': emailCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'specialization': specCtrl.text.isEmpty
                            ? 'General Fitness'
                            : specCtrl.text.trim(),
                        'bio': bioCtrl.text.trim(),
                        'studentIds': [],
                        'rating': 0.0,
                        'experience': experience,
                        'isAvailable': true,
                        'joinDate': Timestamp.now(),
                        'certifications': [],
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.sports_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text(
                      'Thêm HLV',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
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

  Widget _tf(
    String hint,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint),
        prefixIcon: Icon(icon, color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _TrainerCard extends StatelessWidget {
  final TrainerModel trainer;
  final FirestoreService db;

  const _TrainerCard({required this.trainer, required this.db});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.blueGradient,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    trainer.name.isNotEmpty
                        ? trainer.name[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            trainer.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: trainer.isAvailable
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            trainer.isAvailable ? 'Nhận HV' : 'Đầy',
                            style: TextStyle(
                              color: trainer.isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      trainer.specialization,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.warning,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          trainer.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.people_rounded,
                          color: AppColors.textHint,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${trainer.totalStudents} học viên',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.textHint,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${trainer.experience} năm',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (trainer.bio != null && trainer.bio!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trainer.bio!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await db.updateTrainer(trainer.id, {
                      'isAvailable': !trainer.isAvailable,
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: trainer.isAvailable
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  icon: Icon(
                    trainer.isAvailable
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 16,
                    color: trainer.isAvailable
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  label: Text(
                    trainer.isAvailable ? 'Tạm Dừng' : 'Mở Lại',
                    style: TextStyle(
                      color: trainer.isAvailable
                          ? AppColors.warning
                          : AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: const Text(
                        'Xác nhận xóa',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      content: Text(
                        'Xóa HLV "${trainer.name}"?',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Xóa',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) await db.deleteTrainer(trainer.id);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
                label: const Text(
                  'Xóa',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
