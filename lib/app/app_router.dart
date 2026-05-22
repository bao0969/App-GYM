import 'package:go_router/go_router.dart';
import '../core/models/user_model.dart';
import '../providers/auth_provider.dart' as gym_auth;
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/member/member_dashboard_screen.dart';
import '../screens/staff/staff_dashboard_screen.dart';
import '../screens/trainer/trainer_dashboard_screen.dart';

class AppRouter {
  AppRouter._();

  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const admin = '/admin';
  static const staff = '/staff';
  static const trainer = '/trainer';
  static const member = '/member';

  static GoRouter createRouter(gym_auth.AuthProvider auth) {
    return GoRouter(
      initialLocation: login,
      refreshListenable: auth,
      routes: [
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: otp,
          builder: (context, state) {
            final email = state.uri.queryParameters['email'] ?? '';
            return OtpVerificationScreen(email: email);
          },
        ),
        GoRoute(
          path: admin,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: staff,
          builder: (context, state) => const StaffDashboardScreen(),
        ),
        GoRoute(
          path: trainer,
          builder: (context, state) => const TrainerDashboardScreen(),
        ),
        GoRoute(
          path: member,
          builder: (context, state) => const MemberDashboardScreen(),
        ),
      ],
      redirect: (context, state) {
        if (auth.isLoading) {
          return null;
        }

        final location = state.matchedLocation;
        final isAuthRoute =
            location == login ||
            location == register ||
            location == forgotPassword ||
            location == otp;

        if (!auth.isAuthenticated || auth.user == null) {
          return isAuthRoute ? null : login;
        }

        if (isAuthRoute) {
          return _homeForRole(auth.user!.role);
        }

        final expectedHome = _homeForRole(auth.user!.role);
        final isCorrectArea =
            location == expectedHome || location.startsWith('$expectedHome/');

        return isCorrectArea ? null : expectedHome;
      },
    );
  }

  static String _homeForRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return admin;
      case UserRole.staff:
        return staff;
      case UserRole.trainer:
        return trainer;
      case UserRole.member:
        return member;
    }
  }
}
