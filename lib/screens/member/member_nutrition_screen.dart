import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MemberNutritionScreen extends StatelessWidget {
  const MemberNutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text(
            'Gợi Ý Dinh Dưỡng',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.success,
            labelColor: AppColors.success,
            unselectedLabelColor: AppColors.textHint,
            tabs: [
              Tab(text: 'Tăng Cơ (Bulking)'),
              Tab(text: 'Giảm Mỡ (Cutting)'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _NutritionPlan(
              calories: '2800 kcal',
              protein: '160g',
              meals: [
                {'meal': 'Sáng', 'food': '4 quả trứng luộc, 2 lát bánh mì đen, 1 ly sữa tươi', 'cals': '550 kcal'},
                {'meal': 'Trưa', 'food': '200g ức gà nướng, 1 bát cơm trắng, súp lơ xanh', 'cals': '700 kcal'},
                {'meal': 'Phụ chiều', 'food': '1 quả chuối, 1 muỗng Whey Protein', 'cals': '250 kcal'},
                {'meal': 'Tối', 'food': '200g thịt bò xào măng tây, 1 bát cơm, canh rau', 'cals': '800 kcal'},
              ],
            ),
            _NutritionPlan(
              calories: '1800 kcal',
              protein: '140g',
              meals: [
                {'meal': 'Sáng', 'food': '2 quả trứng ốp la, 1 lát bánh mì nguyên cám', 'cals': '300 kcal'},
                {'meal': 'Trưa', 'food': '150g ức gà luộc, 1 củ khoai lang, xà lách', 'cals': '450 kcal'},
                {'meal': 'Phụ chiều', 'food': 'Sữa chua không đường, vài hạt hạnh nhân', 'cals': '150 kcal'},
                {'meal': 'Tối', 'food': '150g cá hồi nướng, salad dưa chuột cà chua', 'cals': '500 kcal'},
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionPlan extends StatelessWidget {
  final String calories;
  final String protein;
  final List<Map<String, String>> meals;

  const _NutritionPlan({
    required this.calories,
    required this.protein,
    required this.meals,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Mục Tiêu Calo',
                value: calories,
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFE84E1B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Protein',
                value: protein,
                icon: Icons.fitness_center_rounded,
                color: const Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Thực Đơn Mẫu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        ...meals.map((meal) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    meal['meal']!,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['food']!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '~ ${meal['cals']}',
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
