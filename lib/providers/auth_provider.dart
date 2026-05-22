import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../core/models/user_model.dart';
import '../core/services/auth_service.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  late final StreamSubscription<User?> _authSubscription;

  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _error;

  // Flag để tránh _onAuthStateChanged override khi đang xử lý signIn/register
  bool _isManualAuth = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    // Bỏ qua nếu đang xử lý thủ công (signIn / register / google)
    if (_isManualAuth) return;

    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      notifyListeners();
      return;
    }

    try {
      final userModel = await _authService.getUserModel(firebaseUser.uid);
      if (userModel != null) {
        _user = userModel;
        _status = AuthStatus.authenticated;
      } else {
        // User tồn tại trong Firebase Auth nhưng chưa có doc Firestore
        // (ví dụ: đang chờ OTP) → giữ unauthenticated
        _status = AuthStatus.unauthenticated;
        _user = null;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    }
    notifyListeners();
  }

  // ─── Email / Password Login ───────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _error = null;
    _isManualAuth = true;
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      _user = await _authService.signIn(email, password);

      // Firestore doc không tồn tại — tạo doc mặc định từ Firebase Auth user
      _user ??= await _authService.createUserDocFromAuth();

      if (_user == null) {
        _error = 'Không tìm thấy thông tin tài khoản.';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Đã có lỗi xảy ra: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } finally {
      // Delay nhỏ để đảm bảo _onAuthStateChanged không override sau khi signIn xong
      await Future.delayed(const Duration(milliseconds: 500));
      _isManualAuth = false;
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<RegisterResult> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    UserRole role = UserRole.member,
  }) async {
    _error = null;
    _isManualAuth = true;
    try {
      _status = AuthStatus.loading;
      notifyListeners();

      _user = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
        role: role,
      );

      // Authenticate ngay sau khi đăng ký
      _status = AuthStatus.authenticated;
      notifyListeners();
      return RegisterResult.success;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return RegisterResult.failed;
    } catch (e) {
      _error = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return RegisterResult.failed;
    } finally {
      _isManualAuth = false;
    }
  }

  // ─── OTP ──────────────────────────────────────────────────────────────────
  Future<OtpVerifyResult> verifyOtp(String otp) async {
    if (_user == null) return OtpVerifyResult.failed;
    _error = null;
    _isManualAuth = true;
    try {
      final result = await _authService.verifyOtp(_user!.uid, otp);
      switch (result) {
        case OtpResult.success:
        case OtpResult.alreadyVerified:
          _status = AuthStatus.authenticated;
          notifyListeners();
          return OtpVerifyResult.success;
        case OtpResult.expired:
          _error = 'Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.';
          return OtpVerifyResult.expired;
        case OtpResult.invalid:
          _error = 'Mã OTP không đúng. Vui lòng kiểm tra lại.';
          return OtpVerifyResult.invalid;
        case OtpResult.notFound:
          _error = 'Không tìm thấy mã OTP. Vui lòng đăng ký lại.';
          return OtpVerifyResult.failed;
      }
    } catch (e) {
      _error = 'Lỗi xác thực OTP. Vui lòng thử lại.';
      return OtpVerifyResult.failed;
    } finally {
      _isManualAuth = false;
    }
  }

  Future<bool> resendOtp() async {
    if (_user == null) return false;
    try {
      await _authService.resendOtp(_user!.uid, _user!.email);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Password Reset ───────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _error = null;
    try {
      await _authService.sendPasswordReset(email);
      return true;
    } catch (e) {
      _error = 'Không thể gửi email. Kiểm tra lại địa chỉ.';
      return false;
    }
  }

  Future<void> signOut() async {
    _isManualAuth = true;
    try {
      await _authService.signOut();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    } finally {
      _isManualAuth = false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Email không tồn tại trong hệ thống.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return 'Email hoặc mật khẩu không đúng.';
      case 'email-already-in-use':
        return 'Email này đã được đăng ký.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'invalid-email':
        return 'Địa chỉ email không hợp lệ.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Kiểm tra internet.';
      default:
        return 'Đã có lỗi xảy ra ($code).';
    }
  }
}

enum RegisterResult { success, needsOtp, failed }

enum OtpVerifyResult { success, invalid, expired, failed }
