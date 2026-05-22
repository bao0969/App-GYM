import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Màn hình Gamification đơn giản - sẽ phát triển thêm
class MemberGamificationScreen extends StatelessWidget {
  final String memberId;

  const MemberGamificationScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '🎮 Thành Tích Của Tôi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 32),

              // Level Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.greenGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Level Circle
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'LEVEL',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '15',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Chiến Binh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats Row
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(icon: '💪', label: 'Workouts', value: '127'),
                        _StatItem(icon: '🔥', label: 'Streak', value: '12'),
                        _StatItem(icon: '🏆', label: 'Badges', value: '8'),
                        _StatItem(icon: '⭐', label: 'Points', value: '2,450'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Badges Section
              const Text(
                '🏆 Huy Hiệu Đã Đạt Được',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _BadgeCard(emoji: '🎯', name: 'Bước Đầu', isUnlocked: true),
                  _BadgeCard(emoji: '💪', name: 'Kiên Trì', isUnlocked: true),
                  _BadgeCard(
                    emoji: '🔥',
                    name: 'Tuần Hoàn Hảo',
                    isUnlocked: true,
                  ),
                  _BadgeCard(
                    emoji: '⚔️',
                    name: 'Chiến Binh',
                    isUnlocked: false,
                  ),
                  _BadgeCard(emoji: '🌅', name: 'Chim Sớm', isUnlocked: true),
                  _BadgeCard(emoji: '🦉', name: 'Cú Đêm', isUnlocked: false),
                  _BadgeCard(emoji: '⭐', name: 'Tháng Vàng', isUnlocked: false),
                  _BadgeCard(
                    emoji: '👑',
                    name: 'Huyền Thoại',
                    isUnlocked: false,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Challenges Section
              const Text(
                '🎯 Thử Thách Hiện Tại',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              _ChallengeCard(
                title: 'Thử Thách 7 Ngày',
                description: 'Tập 7 ngày liên tục để nhận 500 điểm',
                progress: 4,
                target: 7,
                reward: '500 Points',
                daysLeft: 3,
              ),

              const SizedBox(height: 12),

              _ChallengeCard(
                title: 'Chiến Binh Tháng 5',
                description: 'Hoàn thành 20 buổi tập trong tháng',
                progress: 12,
                target: 20,
                reward: '1000 Points',
                daysLeft: 18,
              ),

              const SizedBox(height: 32),

              // Leaderboard Preview
              const Text(
                '🏅 Bảng Xếp Hạng',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD700),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('🥇', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nguyễn Văn A',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Lv.25 • 45 workouts',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          '5,240',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Vị trí của bạn: ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '#7',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Log workout
                        _showWorkoutDialog(context);
                      },
                      icon: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Ghi Nhận Tập Luyện',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWorkoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 Tuyệt Vời!',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Bạn đã hoàn thành buổi tập!\n\n+50 XP\n+1 Streak\nBadge mới: "Kiên Trì"',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tuyệt!',
              style: TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String emoji;
  final String name;
  final bool isUnlocked;

  const _BadgeCard({
    required this.emoji,
    required this.name,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.success.withValues(alpha: 0.15)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked
              ? AppColors.success.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: 24,
              color: isUnlocked ? null : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isUnlocked ? AppColors.textPrimary : AppColors.textHint,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final String title;
  final String description;
  final int progress;
  final int target;
  final String reward;
  final int daysLeft;

  const _ChallengeCard({
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.reward,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    final progressPercent = progress / target;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$daysLeft ngày',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$progress / $target',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    reward,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressPercent.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(4),
                    ),
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
