// Tính năng 3: Cảnh báo hội viên sắp hết hạn / đã hết hạn
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/member_model.dart';
import '../../core/services/firestore_service.dart';
import 'admin_renewal_screen.dart';

class AdminExpiryAlertsScreen extends StatefulWidget {
  const AdminExpiryAlertsScreen({super.key});

  @override
  State<AdminExpiryAlertsScreen> createState() =>
      _AdminExpiryAlertsScreenState();
}

class _AdminExpiryAlertsScreenState extends State<AdminExpiryAlertsScreen>
    with SingleTickerProviderStateMixin {
  final _db = FirestoreService();
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Cảnh Báo Hết Hạn',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'Hôm Nay'),
            Tab(text: 'Trong 7 Ngày'),
            Tab(text: 'Đã Hết Hạn'),
          ],
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
          final all = snap.data ?? [];
          final now = DateTime.now();

          final expiredToday = all
              .where(
                (m) =>
                    m.packageExpiry != null &&
                    m.packageExpiry!.day == now.day &&
                    m.packageExpiry!.month == now.month &&
                    m.packageExpiry!.year == now.year,
              )
              .toList();

          final expiringSoon =
              all
                  .where(
                    (m) =>
                        m.packageExpiry != null &&
                        m.packageExpiry!.isAfter(now) &&
                        m.daysRemaining <= 7 &&
                        m.daysRemaining > 0,
                  )
                  .toList()
                ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

          final alreadyExpired = all
              .where((m) => m.currentStatus == 'expired')
              .toList();

          return TabBarView(
            controller: _tabCtrl,
            children: [
              _AlertList(
                members: expiredToday,
                emptyMsg: 'Không có hội viên hết hạn hôm nay',
                color: AppColors.error,
                db: _db,
              ),
              _AlertList(
                members: expiringSoon,
                emptyMsg: 'Không có hội viên sắp hết hạn',
                color: AppColors.warning,
                db: _db,
                showDaysRemaining: true,
              ),
              _AlertList(
                members: alreadyExpired,
                emptyMsg: 'Không có hội viên hết hạn',
                color: AppColors.textHint,
                db: _db,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlertList extends StatelessWidget {
  final List<MemberModel> members;
  final String emptyMsg;
  final Color color;
  final FirestoreService db;
  final bool showDaysRemaining;

  const _AlertList({
    required this.members,
    required this.emptyMsg,
    required this.color,
    required this.db,
    this.showDaysRemaining = false,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              emptyMsg,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                '${members.length} hội viên cần chú ý',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: members.length,
            itemBuilder: (_, i) {
              final m = members[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
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
                            m.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            m.phone,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (m.packageExpiry != null)
                            Text(
                              showDaysRemaining
                                  ? 'Còn ${m.daysRemaining} ngày • ${DateFormat('dd/MM/yyyy').format(m.packageExpiry!)}'
                                  : 'Hết hạn: ${DateFormat('dd/MM/yyyy').format(m.packageExpiry!)}',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminRenewalScreen(),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: color.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      child: Text(
                        'Gia Hạn',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
