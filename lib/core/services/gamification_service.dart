import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gamification_model.dart';

class GamificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== MEMBER PROGRESS ====================

  /// Lấy tiến độ của hội viên
  Future<MemberProgress?> getMemberProgress(String memberId) async {
    try {
      final doc = await _db.collection('member_progress').doc(memberId).get();
      if (!doc.exists) {
        // Tạo mới nếu chưa có
        final newProgress = MemberProgress(
          memberId: memberId,
          level: 1,
          xp: 0,
          xpToNextLevel: 100,
          totalWorkouts: 0,
          currentStreak: 0,
          longestStreak: 0,
          unlockedBadges: [],
          totalPoints: 0,
          lastWorkoutDate: DateTime.now(),
          stats: {},
        );
        await _db
            .collection('member_progress')
            .doc(memberId)
            .set(newProgress.toJson());
        return newProgress;
      }
      return MemberProgress.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Stream tiến độ
  Stream<MemberProgress?> streamMemberProgress(String memberId) {
    return _db.collection('member_progress').doc(memberId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return MemberProgress.fromJson(doc.data()!);
    });
  }

  /// Ghi nhận workout và cập nhật XP, streak
  /// Fix #5: Sửa công thức tính totalXp – cộng dồn qua từng level thay vì nhân đơn giản.
  Future<Map<String, dynamic>> logWorkout({
    required String memberId,
    required String workoutType,
    required int durationMinutes,
    int caloriesBurned = 0,
  }) async {
    try {
      final progress = await getMemberProgress(memberId);
      if (progress == null) return {'success': false};

      // Tính XP dựa trên thời gian tập
      int xpEarned = (durationMinutes * 2).clamp(10, 200);

      // Bonus XP cho workout dài
      if (durationMinutes >= 60) xpEarned += 50;
      if (durationMinutes >= 90) xpEarned += 100;

      // Kiểm tra streak
      final now = DateTime.now();
      final lastWorkout = progress.lastWorkoutDate;
      final daysDiff = now.difference(lastWorkout).inDays;

      int newStreak = progress.currentStreak;
      if (daysDiff == 1) {
        newStreak++;
      } else if (daysDiff > 1) {
        newStreak = 1;
      }
      // daysDiff == 0: cùng ngày, không tăng streak nhưng vẫn được XP

      // Bonus XP cho streak
      if (newStreak >= 7) xpEarned += 30;
      if (newStreak >= 30) xpEarned += 100;

      // Fix #5: Tính totalXp thực sự bằng cách cộng dồn XP qua từng level.
      // totalPoints là tổng XP tích lũy từ đầu, dùng để tính level chính xác.
      final newTotalPoints = progress.totalPoints + xpEarned;
      final newLevel = MemberProgress.calculateLevelFromXp(newTotalPoints);
      final xpForNextLevel = MemberProgress.calculateXpForLevel(newLevel);

      // XP hiện tại trong level này = tổng XP trừ XP cỗng dồn của các level trước
      int xpOfPreviousLevels = 0;
      for (int lvl = 1; lvl < newLevel; lvl++) {
        xpOfPreviousLevels += MemberProgress.calculateXpForLevel(lvl);
      }
      final xpInCurrentLevel = newTotalPoints - xpOfPreviousLevels;

      // Cập nhật progress
      final updatedProgress = {
        'level': newLevel,
        'xp': xpInCurrentLevel,
        'xpToNextLevel': xpForNextLevel,
        'totalWorkouts': progress.totalWorkouts + 1,
        'currentStreak': newStreak,
        'longestStreak': newStreak > progress.longestStreak
            ? newStreak
            : progress.longestStreak,
        'totalPoints': newTotalPoints,
        // weeklyPoints dùng cho leaderboard tuần (Fix #9)
        'weeklyPoints': FieldValue.increment(xpEarned),
        'lastWorkoutDate': Timestamp.fromDate(now),
        'stats.total_duration':
            (progress.stats['total_duration'] ?? 0) + durationMinutes,
        'stats.total_calories':
            (progress.stats['total_calories'] ?? 0) + caloriesBurned,
      };

      await _db
          .collection('member_progress')
          .doc(memberId)
          .update(updatedProgress);

      // Log workout
      final workoutLog = WorkoutLog(
        id: '',
        memberId: memberId,
        date: now,
        workoutType: workoutType,
        durationMinutes: durationMinutes,
        caloriesBurned: caloriesBurned,
        xpEarned: xpEarned,
      );
      await _db.collection('workout_logs').add(workoutLog.toJson());

      // Kiểm tra badges mới
      final newBadges = await _checkAndUnlockBadges(memberId, updatedProgress);

      return {
        'success': true,
        'xpEarned': xpEarned,
        'newLevel': newLevel,
        'leveledUp': newLevel > progress.level,
        'newStreak': newStreak,
        'newBadges': newBadges,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Kiểm tra và mở khóa badges mới
  Future<List<GymBadge>> _checkAndUnlockBadges(
    String memberId,
    Map<String, dynamic> progressData,
  ) async {
    try {
      final allBadges = DefaultBadges.getAll();
      final currentProgress = await getMemberProgress(memberId);
      if (currentProgress == null) return [];

      final newBadges = <GymBadge>[];

      for (final badge in allBadges) {
        // Đã unlock rồi thì skip
        if (currentProgress.unlockedBadges.contains(badge.id)) continue;

        bool shouldUnlock = false;

        switch (badge.condition) {
          case 'workouts_count':
            shouldUnlock =
                (progressData['totalWorkouts'] ?? 0) >= badge.requiredValue;
            break;
          case 'streak_days':
            shouldUnlock =
                (progressData['currentStreak'] ?? 0) >= badge.requiredValue;
            break;
          // Thêm các điều kiện khác ở đây
        }

        if (shouldUnlock) {
          newBadges.add(badge);
          // Cập nhật vào database
          await _db.collection('member_progress').doc(memberId).update({
            'unlockedBadges': FieldValue.arrayUnion([badge.id]),
            'totalPoints': FieldValue.increment(badge.points),
          });
        }
      }

      return newBadges;
    } catch (e) {
      return [];
    }
  }

  // ==================== LEADERBOARD ====================

  /// Bảng xếp hạng theo tuần (7 ngày gần nhất - rolling window).
  /// Fix #9: Dùng weeklyPoints (tích lũy từ workout_logs trong 7 ngày)
  /// thay vì totalPoints all-time. weeklyPoints được reset mỗi tuần.
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard({int limit = 50}) async {
    try {
      // Tính điểm XP từng member trong 7 ngày qua từ workout_logs
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final workoutSnap = await _db
          .collection('workout_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
          .get();

      // Tổng hợp XP theo memberId
      final Map<String, int> weeklyXpMap = {};
      for (final doc in workoutSnap.docs) {
        final data = doc.data();
        final memberId = data['memberId'] as String? ?? '';
        final xp = (data['xpEarned'] ?? 0) as int;
        if (memberId.isNotEmpty) {
          weeklyXpMap[memberId] = (weeklyXpMap[memberId] ?? 0) + xp;
        }
      }

      if (weeklyXpMap.isEmpty) return [];

      // Sắp xếp theo điểm tuần giảm dần
      final sortedEntries = weeklyXpMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topEntries = sortedEntries.take(limit).toList();

      final entries = <LeaderboardEntry>[];
      int rank = 1;

      for (final entry in topEntries) {
        final memberId = entry.key;
        final weeklyPoints = entry.value;

        // Lấy thông tin member và progress
        final memberDoc = await _db.collection('members').doc(memberId).get();
        final progressDoc = await _db
            .collection('member_progress')
            .doc(memberId)
            .get();

        final memberName = memberDoc.exists
            ? (memberDoc.data()?['name'] as String?) ?? 'Unknown'
            : 'Unknown';
        final progressData = progressDoc.data();

        entries.add(
          LeaderboardEntry(
            memberId: memberId,
            memberName: memberName,
            rank: rank++,
            points: weeklyPoints, // Điểm trong tuần
            level: progressData?['level'] ?? 1,
            workouts: progressData?['totalWorkouts'] ?? 0,
            streak: progressData?['currentStreak'] ?? 0,
          ),
        );
      }

      return entries;
    } catch (e) {
      return [];
    }
  }

  /// Lấy vị trí của member trong bảng xếp hạng
  Future<int> getMemberRank(String memberId) async {
    try {
      final progress = await getMemberProgress(memberId);
      if (progress == null) return 0;

      final snapshot = await _db
          .collection('member_progress')
          .where('totalPoints', isGreaterThan: progress.totalPoints)
          .get();

      return snapshot.docs.length + 1;
    } catch (e) {
      return 0;
    }
  }

  // ==================== CHALLENGES ====================

  /// Lấy challenges đang active
  Stream<List<Challenge>> streamActiveChallenges() {
    return _db
        .collection('challenges')
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Challenge.fromJson(data);
          }).toList();
        });
  }

  /// Tham gia challenge
  Future<bool> joinChallenge(String challengeId, String memberId) async {
    try {
      await _db.collection('challenges').doc(challengeId).update({
        'participants': FieldValue.arrayUnion([memberId]),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Lấy tiến độ challenge của member
  Future<Map<String, int>> getChallengeProgress(
    String challengeId,
    String memberId,
  ) async {
    try {
      final challenge = await _db
          .collection('challenges')
          .doc(challengeId)
          .get();
      if (!challenge.exists) return {};

      final challengeData = Challenge.fromJson(challenge.data()!);

      // Đếm workouts trong khoảng thời gian challenge
      final workouts = await _db
          .collection('workout_logs')
          .where('memberId', isEqualTo: memberId)
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(challengeData.startDate),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(challengeData.endDate),
          )
          .get();

      return {
        'current': workouts.docs.length,
        'target': challengeData.targetValue,
      };
    } catch (e) {
      return {};
    }
  }

  // ==================== WORKOUT LOGS ====================

  /// Lấy lịch sử workout
  Stream<List<WorkoutLog>> streamWorkoutLogs(
    String memberId, {
    int limit = 30,
  }) {
    return _db
        .collection('workout_logs')
        .where('memberId', isEqualTo: memberId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return WorkoutLog.fromJson(data);
          }).toList();
        });
  }

  /// Thống kê workout theo tuần/tháng
  Future<Map<String, int>> getWorkoutStats(
    String memberId, {
    int days = 30,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _db
          .collection('workout_logs')
          .where('memberId', isEqualTo: memberId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .get();

      int totalWorkouts = snapshot.docs.length;
      int totalDuration = 0;
      int totalCalories = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        totalDuration += (data['durationMinutes'] ?? 0) as int;
        totalCalories += (data['caloriesBurned'] ?? 0) as int;
      }

      return {
        'workouts': totalWorkouts,
        'duration': totalDuration,
        'calories': totalCalories,
        'avgDuration': totalWorkouts > 0
            ? (totalDuration / totalWorkouts).round()
            : 0,
      };
    } catch (e) {
      return {};
    }
  }

  // ==================== SEED DATA ====================

  /// Tạo challenges mẫu
  Future<void> seedChallenges() async {
    try {
      final snapshot = await _db.collection('challenges').limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final now = DateTime.now();
      final challenges = [
        Challenge(
          id: '',
          name: 'Thử Thách 7 Ngày',
          description: 'Tập 7 ngày liên tục để nhận 500 điểm',
          type: 'weekly',
          startDate: now,
          endDate: now.add(const Duration(days: 7)),
          targetValue: 7,
          metric: 'workouts',
          rewardPoints: 500,
          rewardBadge: 'streak_7',
          isActive: true,
          participants: [],
        ),
        Challenge(
          id: '',
          name: 'Chiến Binh Tháng 5',
          description: 'Hoàn thành 20 buổi tập trong tháng',
          type: 'monthly',
          startDate: DateTime(now.year, now.month, 1),
          endDate: DateTime(now.year, now.month + 1, 0),
          targetValue: 20,
          metric: 'workouts',
          rewardPoints: 1000,
          rewardBadge: 'workout_50',
          isActive: true,
          participants: [],
        ),
        Challenge(
          id: '',
          name: 'Đốt Cháy 5000 Calo',
          description: 'Đốt cháy 5000 calories trong 2 tuần',
          type: 'special',
          startDate: now,
          endDate: now.add(const Duration(days: 14)),
          targetValue: 5000,
          metric: 'calories',
          rewardPoints: 800,
          isActive: true,
          participants: [],
        ),
      ];

      for (final challenge in challenges) {
        await _db.collection('challenges').add(challenge.toJson());
      }
    } catch (e) {
      // Ignore
    }
  }
}
