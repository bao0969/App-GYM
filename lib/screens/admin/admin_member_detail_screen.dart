import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/member_model.dart';
import '../../core/models/trainer_model.dart';
import '../../core/services/firestore_service.dart';
import 'admin_renewal_screen.dart';

class AdminMemberDetailScreen extends StatefulWidget {
  final MemberModel member;

  const AdminMemberDetailScreen({super.key, required this.member});

  @override
  State<AdminMemberDetailScreen> createState() =>
      _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState extends State<AdminMemberDetailScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirestoreService();
  late TabController _tabCtrl;
  TrainerModel? _trainer;
  List<QueryDocumentSnapshot> _checkins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (widget.member.trainerId != null &&
          widget.member.trainerId!.isNotEmpty) {
        final trainers = await _db.getTrainers();
        _trainer = trainers
            .where((t) => t.id == widget.member.trainerId)
            .firstOrNull;
      }

      final snap = await FirebaseFirestore.instance
          .collection('checkins')
          .where('memberId', isEqualTo: widget.member.id)
          .get();

      final docs = snap.docs;
      docs.sort((a, b) {
        final ta = (a.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final tb = (b.data()['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return tb.compareTo(ta);
      });

      if (mounted) {
        setState(() {
          _checkins = docs.take(30).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Color get _statusColor {
    final s = widget.member.currentStatus;
    if (s == 'active' || s == 'expiring_soon') {
      return widget.member.daysRemaining <= 7
          ? AppColors.warning
          : AppColors.success;
    } else if (s == 'expired') {
      return AppColors.error;
    } else {
      return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, _) => [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.surface,
            iconTheme: const IconThemeData(color: AppColors.textPrimary),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.card_membership_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminRenewalScreen()),
                ),
                tooltip: 'Gia Hạn',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _statusColor.withValues(alpha: 0.3),
                      AppColors.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: _statusColor, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        m.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            m.statusLabel,
                            style: TextStyle(
                              color: _statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (m.packageName != null) ...[
                            const Text(
                              ' • ',
                              style: TextStyle(color: AppColors.textHint),
                            ),
                            Text(
                              m.packageName!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              tabs: const [
                Tab(text: 'Thông Tin'),
                Tab(text: 'Check-in'),
                Tab(text: 'Gói Tập'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _InfoTab(member: m, trainer: _trainer),
                  _CheckinTab(checkins: _checkins),
                  _PackageTab(member: m),
                ],
              ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final MemberModel member;
  final TrainerModel? trainer;

  const _InfoTab({required this.member, this.trainer});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị Mã QR
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: member.qrCode,
                    version: QrVersions.auto,
                    size: 160.0,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    member.qrCode,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dùng mã này để in thẻ Check-in',
                    style: TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          _Section('Thông Tin Cá Nhân', [
            _Row(Icons.person_rounded, 'Họ Tên', member.name),
            _Row(Icons.phone_rounded, 'Điện Thoại', member.phone),
            _Row(Icons.email_rounded, 'Email', member.email),
            if (member.address != null && member.address!.isNotEmpty)
              _Row(Icons.location_on_rounded, 'Địa Chỉ', member.address!),
            _Row(
              Icons.calendar_today_rounded,
              'Ngày Tham Gia',
              DateFormat('dd/MM/yyyy').format(member.joinDate),
            ),
          ]),
          const SizedBox(height: 20),
          _Section('Huấn Luyện Viên', [
            if (trainer != null) ...[
              _Row(Icons.sports_rounded, 'Tên HLV', trainer!.name),
              _Row(Icons.star_rounded, 'Chuyên Môn', trainer!.specialization),
              _Row(Icons.phone_rounded, 'Liên Hệ', trainer!.phone),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Chưa có HLV phụ trách',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
          ]),
          if (member.notes != null && member.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Section('Ghi Chú', [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  member.notes!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _CheckinTab extends StatelessWidget {
  final List<QueryDocumentSnapshot> checkins;

  const _CheckinTab({required this.checkins});

  @override
  Widget build(BuildContext context) {
    if (checkins.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có lịch sử check-in',
          style: TextStyle(color: AppColors.textHint),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.greenGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${checkins.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Tổng Buổi',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.blueGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        checkins.isNotEmpty
                            ? DateFormat('dd/MM').format(
                                ((checkins.first.data() as Map)['timestamp']
                                        as Timestamp)
                                    .toDate(),
                              )
                            : '---',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Lần Cuối',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: checkins.length,
            itemBuilder: (_, i) {
              final data = checkins[i].data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              final date = ts?.toDate() ?? DateTime.now();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, dd/MM/yyyy').format(date),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(date),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PackageTab extends StatelessWidget {
  final MemberModel member;

  const _PackageTab({required this.member});

  @override
  Widget build(BuildContext context) {
    final hasPackage = member.packageName != null;
    final isActive = member.isActive;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: isActive
                  ? AppColors.greenGradient
                  : AppColors.purpleGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPackage ? member.packageName! : 'Chưa có gói tập',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (member.packageExpiry != null) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hết Hạn',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'dd/MM/yyyy',
                              ).format(member.packageExpiry!),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Còn Lại',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${member.daysRemaining} ngày',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminRenewalScreen()),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.card_membership_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'Gia Hạn Gói Tập',
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
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section(this.title, this.children);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label, value;

  const _Row(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(color: AppColors.textHint, fontSize: 12),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
