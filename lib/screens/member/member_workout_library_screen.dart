import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MemberWorkoutLibraryScreen extends StatelessWidget {
  const MemberWorkoutLibraryScreen({super.key});

  final List<Map<String, dynamic>> _muscleGroups = const [
    {
      'title': 'Cơ Ngực (Chest)',
      'icon': Icons.fitness_center_rounded,
      'color': Color(0xFFE84E1B),
      'exercises': [
        {'name': 'Đẩy ngực ngang (Barbell Bench Press)', 'reps': '4 sets x 8-12 reps'},
        {'name': 'Đẩy ngực dốc lên (Incline Dumbbell Press)', 'reps': '3 sets x 10-12 reps'},
        {'name': 'Ép ngực (Cable Crossover)', 'reps': '3 sets x 12-15 reps'},
      ]
    },
    {
      'title': 'Cơ Lưng (Back)',
      'icon': Icons.accessibility_new_rounded,
      'color': Color(0xFF4CAF50),
      'exercises': [
        {'name': 'Kéo xà đơn (Pull-up)', 'reps': '3 sets x Max reps'},
        {'name': 'Kéo cáp (Lat Pulldown)', 'reps': '4 sets x 10-12 reps'},
        {'name': 'Chèo thuyền (Barbell Row)', 'reps': '4 sets x 8-10 reps'},
      ]
    },
    {
      'title': 'Cơ Chân (Legs)',
      'icon': Icons.directions_run_rounded,
      'color': Color(0xFF2196F3),
      'exercises': [
        {'name': 'Gánh đùi (Squat)', 'reps': '4 sets x 8-12 reps'},
        {'name': 'Đạp đùi (Leg Press)', 'reps': '4 sets x 10-12 reps'},
        {'name': 'Đá đùi trước (Leg Extension)', 'reps': '3 sets x 12-15 reps'},
      ]
    },
    {
      'title': 'Cơ Vai (Shoulders)',
      'icon': Icons.sports_gymnastics_rounded,
      'color': Color(0xFF9C27B0),
      'exercises': [
        {'name': 'Đẩy vai qua đầu (Overhead Press)', 'reps': '4 sets x 8-10 reps'},
        {'name': 'Nâng vai ngang (Lateral Raise)', 'reps': '4 sets x 12-15 reps'},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Thư Viện Bài Tập',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _muscleGroups.length,
        itemBuilder: (context, index) {
          final group = _muscleGroups[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: group['color'],
                collapsedIconColor: Colors.white54,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (group['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    group['icon'],
                    color: group['color'],
                  ),
                ),
                title: Text(
                  group['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                      children: (group['exercises'] as List).map((exercise) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6, right: 12),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: group['color'],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise['name'],
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      exercise['reps'],
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
