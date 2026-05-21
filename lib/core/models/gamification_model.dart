import 'package:cloud_firestore/cloud_firestore.dart';

/// Hệ thống game hóa - Level, XP, Badges
class MemberProgress {
  final String memberId;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final int totalWorkouts;
  final int currentStreak;
  final int longestStreak;
  final List<String> unlockedBadges;
  final int totalPoints;
  final DateTime lastWorkoutDate;
  final Map<String, int> stats; // workout_count, calories_burned, etc.

  MemberProgress({
    required this.memberId,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    required this.totalWorkouts,
    required this.currentStreak,
    required this.longestStreak,
    required this.unlockedBadges,
    required this.totalPoints,
    required this.lastWorkoutDate,
    required this.stats,
  });

  factory MemberProgress.fromJson(Map<String, dynamic> json) {
    return MemberProgress(
      memberId: json['memberId'] ?? '',
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      xpToNextLevel: json['xpToNextLevel'] ?? 100,
      totalWorkouts: json['totalWorkouts'] ?? 0,
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      unlockedBadges: List<String>.from(json['unlockedBadges'] ?? []),
      totalPoints: json['totalPoints'] ?? 0,
      lastWorkoutDate:
          (json['lastWorkoutDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stats: Map<String, int>.from(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'level': level,
      'xp': xp,
      'xpToNextLevel': xpToNextLevel,
      'totalWorkouts': totalWorkouts,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'unlockedBadges': unlockedBadges,
      'totalPoints': totalPoints,
      'lastWorkoutDate': Timestamp.fromDate(lastWorkoutDate),
      'stats': stats,
    };
  }

  /// Tính XP cần cho level tiếp theo
  static int calculateXpForLevel(int level) {
    return (100 * level * 1.5).round();
  }

  /// Tính level từ tổng XP
  static int calculateLevelFromXp(int totalXp) {
    int level = 1;
    int xpNeeded = 0;
    while (xpNeeded < totalXp) {
      xpNeeded += calculateXpForLevel(level);
      if (xpNeeded <= totalXp) level++;
    }
    return level;
  }

  /// Phần trăm tiến độ đến level tiếp theo
  double get progressToNextLevel {
    return xp / xpToNextLevel;
  }

  /// Rank dựa trên level
  String get rank {
    if (level >= 50) return 'Huyền Thoại';
    if (level >= 40) return 'Đại Sư';
    if (level >= 30) return 'Chuyên Gia';
    if (level >= 20) return 'Cao Thủ';
    if (level >= 10) return 'Trung Cấp';
    return 'Tân Binh';
  }
}

/// Badge/Achievement - Huy hiệu thành tích
class GymBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category; // workout, streak, social, special
  final int requiredValue;
  final String condition; // workouts_count, streak_days, etc.
  final int points;
  final String rarity; // common, rare, epic, legendary

  GymBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.requiredValue,
    required this.condition,
    required this.points,
    required this.rarity,
  });

  factory GymBadge.fromJson(Map<String, dynamic> json) {
    return GymBadge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🏆',
      category: json['category'] ?? 'workout',
      requiredValue: json['requiredValue'] ?? 0,
      condition: json['condition'] ?? '',
      points: json['points'] ?? 0,
      rarity: json['rarity'] ?? 'common',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'requiredValue': requiredValue,
      'condition': condition,
      'points': points,
      'rarity': rarity,
    };
  }

  /// Màu theo độ hiếm
  int get rarityColor {
    switch (rarity) {
      case 'legendary':
        return 0xFFFFD700; // Gold
      case 'epic':
        return 0xFFA855F7; // Purple
      case 'rare':
        return 0xFF3B82F6; // Blue
      default:
        return 0xFF6B7280; // Gray
    }
  }
}

/// Challenge - Thử thách
class Challenge {
  final String id;
  final String name;
  final String description;
  final String type; // daily, weekly, monthly, special
  final DateTime startDate;
  final DateTime endDate;
  final int targetValue;
  final String metric; // workouts, calories, streak, etc.
  final int rewardPoints;
  final String? rewardBadge;
  final bool isActive;
  final List<String> participants;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.targetValue,
    required this.metric,
    required this.rewardPoints,
    this.rewardBadge,
    required this.isActive,
    required this.participants,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'daily',
      startDate: (json['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (json['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetValue: json['targetValue'] ?? 0,
      metric: json['metric'] ?? 'workouts',
      rewardPoints: json['rewardPoints'] ?? 0,
      rewardBadge: json['rewardBadge'],
      isActive: json['isActive'] ?? true,
      participants: List<String>.from(json['participants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'targetValue': targetValue,
      'metric': metric,
      'rewardPoints': rewardPoints,
      'rewardBadge': rewardBadge,
      'isActive': isActive,
      'participants': participants,
    };
  }

  /// Số ngày còn lại
  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }

  /// Đã hết hạn chưa
  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }
}

/// Leaderboard Entry - Bảng xếp hạng
class LeaderboardEntry {
  final String memberId;
  final String memberName;
  final String? memberAvatar;
  final int rank;
  final int points;
  final int level;
  final int workouts;
  final int streak;

  LeaderboardEntry({
    required this.memberId,
    required this.memberName,
    this.memberAvatar,
    required this.rank,
    required this.points,
    required this.level,
    required this.workouts,
    required this.streak,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      memberAvatar: json['memberAvatar'],
      rank: json['rank'] ?? 0,
      points: json['points'] ?? 0,
      level: json['level'] ?? 1,
      workouts: json['workouts'] ?? 0,
      streak: json['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'memberAvatar': memberAvatar,
      'rank': rank,
      'points': points,
      'level': level,
      'workouts': workouts,
      'streak': streak,
    };
  }
}

/// Workout Log - Nhật ký tập luyện
class WorkoutLog {
  final String id;
  final String memberId;
  final DateTime date;
  final String workoutType; // cardio, strength, yoga, etc.
  final int durationMinutes;
  final int caloriesBurned;
  final int xpEarned;
  final String? notes;
  final List<String>? exercises;

  WorkoutLog({
    required this.id,
    required this.memberId,
    required this.date,
    required this.workoutType,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.xpEarned,
    this.notes,
    this.exercises,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      id: json['id'] ?? '',
      memberId: json['memberId'] ?? '',
      date: (json['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      workoutType: json['workoutType'] ?? 'general',
      durationMinutes: json['durationMinutes'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      notes: json['notes'],
      exercises: json['exercises'] != null
          ? List<String>.from(json['exercises'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'date': Timestamp.fromDate(date),
      'workoutType': workoutType,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'xpEarned': xpEarned,
      'notes': notes,
      'exercises': exercises,
    };
  }
}

/// Danh sách badges mặc định
class DefaultBadges {
  static List<GymBadge> getAll() {
    return [
      // Workout Count Badges
      GymBadge(
        id: 'first_workout',
        name: 'Bước Đầu Tiên',
        description: 'Hoàn thành buổi tập đầu tiên',
        icon: '🎯',
        category: 'workout',
        requiredValue: 1,
        condition: 'workouts_count',
        points: 10,
        rarity: 'common',
      ),
      GymBadge(
        id: 'workout_10',
        name: 'Kiên Trì',
        description: 'Hoàn thành 10 buổi tập',
        icon: '💪',
        category: 'workout',
        requiredValue: 10,
        condition: 'workouts_count',
        points: 50,
        rarity: 'common',
      ),
      GymBadge(
        id: 'workout_50',
        name: 'Chiến Binh',
        description: 'Hoàn thành 50 buổi tập',
        icon: '⚔️',
        category: 'workout',
        requiredValue: 50,
        condition: 'workouts_count',
        points: 200,
        rarity: 'rare',
      ),
      GymBadge(
        id: 'workout_100',
        name: 'Bất Bại',
        description: 'Hoàn thành 100 buổi tập',
        icon: '🏆',
        category: 'workout',
        requiredValue: 100,
        condition: 'workouts_count',
        points: 500,
        rarity: 'epic',
      ),
      GymBadge(
        id: 'workout_365',
        name: 'Huyền Thoại',
        description: 'Hoàn thành 365 buổi tập',
        icon: '👑',
        category: 'workout',
        requiredValue: 365,
        condition: 'workouts_count',
        points: 2000,
        rarity: 'legendary',
      ),

      // Streak Badges
      GymBadge(
        id: 'streak_7',
        name: 'Tuần Hoàn Hảo',
        description: 'Tập 7 ngày liên tục',
        icon: '🔥',
        category: 'streak',
        requiredValue: 7,
        condition: 'streak_days',
        points: 100,
        rarity: 'rare',
      ),
      GymBadge(
        id: 'streak_30',
        name: 'Tháng Vàng',
        description: 'Tập 30 ngày liên tục',
        icon: '⭐',
        category: 'streak',
        requiredValue: 30,
        condition: 'streak_days',
        points: 500,
        rarity: 'epic',
      ),
      GymBadge(
        id: 'streak_100',
        name: 'Không Thể Ngăn Cản',
        description: 'Tập 100 ngày liên tục',
        icon: '💎',
        category: 'streak',
        requiredValue: 100,
        condition: 'streak_days',
        points: 2000,
        rarity: 'legendary',
      ),

      // Special Badges
      GymBadge(
        id: 'early_bird',
        name: 'Chim Sớm',
        description: 'Tập trước 6h sáng 10 lần',
        icon: '🌅',
        category: 'special',
        requiredValue: 10,
        condition: 'early_workouts',
        points: 150,
        rarity: 'rare',
      ),
      GymBadge(
        id: 'night_owl',
        name: 'Cú Đêm',
        description: 'Tập sau 10h tối 10 lần',
        icon: '🦉',
        category: 'special',
        requiredValue: 10,
        condition: 'night_workouts',
        points: 150,
        rarity: 'rare',
      ),
      GymBadge(
        id: 'weekend_warrior',
        name: 'Chiến Binh Cuối Tuần',
        description: 'Tập cả 2 ngày cuối tuần 4 tuần liên tiếp',
        icon: '🎖️',
        category: 'special',
        requiredValue: 4,
        condition: 'weekend_streaks',
        points: 200,
        rarity: 'epic',
      ),
      GymBadge(
        id: 'social_butterfly',
        name: 'Bướm Xã Hội',
        description: 'Tham gia 20 lớp nhóm',
        icon: '🦋',
        category: 'social',
        requiredValue: 20,
        condition: 'group_classes',
        points: 150,
        rarity: 'rare',
      ),
    ];
  }
}
