import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as gym_auth;
import 'core/models/user_model.dart';
import 'core/services/seed_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';
import 'screens/trainer/trainer_dashboard_screen.dart';
import 'screens/member/member_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Seed admin account và dữ liệu mẫu nếu chưa có
  await SeedService().seedAdminIfNeeded();
  await SeedService().seedSampleData(); // Chỉ tạo nếu chưa có (không xóa)
  await SeedService().migrateV1ToV2();

  runApp(const GymSyncApp());
}

class GymSyncApp extends StatelessWidget {
  const GymSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => gym_auth.AuthProvider()),
      ],
      child: MaterialApp(
        title: 'GymSync – Smart Gym Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<gym_auth.AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const _SplashScreen();
            }
            if (auth.user == null) {
              return const LoginScreen();
            }
            switch (auth.user!.role) {
              case UserRole.admin:
                return const AdminDashboardScreen();
              case UserRole.staff:
                return const StaffDashboardScreen();
              case UserRole.trainer:
                return const TrainerDashboardScreen();
              case UserRole.member:
                return const MemberDashboardScreen();
            }
          },
        ),
      ),
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
    _scaleAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _opacityAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE84E1B),
                            Color(0xFFFF6B35),
                            Color(0xFFFF8C61),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFFF6B35,
                            ).withValues(alpha: 0.6),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.white,
                        size: 54,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFFE84E1B),
                          Color(0xFFFF6B35),
                          Color(0xFFFF8C61),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'GymSync',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Smart Gym Management',
                      style: TextStyle(
                        color: Color(0xFFB0B0C8),
                        fontSize: 15,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 60),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
