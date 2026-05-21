import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/member_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Email / Password Login ───────────────────────────────────────────────
  Future<UserModel?> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user == null) return null;
    return await getUserModel(cred.user!.uid);
  }

  // ─── Register ─────────────────────────────────────────────────────────────
  Future<UserModel?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
    UserRole role = UserRole.member,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    if (cred.user == null) return null;

    final user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email.trim(),
      phone: phone,
      role: role,
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(cred.user!.uid).set(user.toJson());

    // If member role, create member document
    if (role == UserRole.member) {
      await _db.collection('members').add({
        'userId': cred.user!.uid,
        'name': name,
        'email': email.trim(),
        'phone': phone,
        'status': MemberStatus.active.name,
        'qrCode': cred.user!.uid,
        'joinDate': Timestamp.now(),
      });
    }

    // Generate & store OTP, then send Firebase email verification
    // Đã bỏ yêu cầu xác thực OTP theo yêu cầu
    // await generateAndSendOtp(cred.user!.uid, email.trim());

    return user;
  }

  // ─── OTP ──────────────────────────────────────────────────────────────────

  /// Tạo OTP 6 chữ số, lưu vào Firestore với thời hạn 10 phút
  Future<String> generateAndSendOtp(String uid, String email) async {
    final otp = _generateOtp();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    await _db.collection('otp_verifications').doc(uid).set({
      'otp': otp,
      'email': email,
      'expiresAt': Timestamp.fromDate(expiry),
      'verified': false,
      'createdAt': Timestamp.now(),
    });

    // Gửi email xác thực Firebase (production nên dùng Cloud Functions
    // để gửi email tùy chỉnh kèm mã OTP)
    await _auth.currentUser?.sendEmailVerification();

    return otp;
  }

  /// Xác thực OTP người dùng nhập
  Future<OtpResult> verifyOtp(String uid, String inputOtp) async {
    final doc = await _db.collection('otp_verifications').doc(uid).get();
    if (!doc.exists) return OtpResult.notFound;

    final data = doc.data()!;
    final storedOtp = data['otp'] as String;
    final expiresAt = (data['expiresAt'] as Timestamp).toDate();
    final verified = data['verified'] as bool? ?? false;

    if (verified) return OtpResult.alreadyVerified;
    if (DateTime.now().isAfter(expiresAt)) return OtpResult.expired;
    if (inputOtp.trim() != storedOtp) return OtpResult.invalid;

    await _db.collection('otp_verifications').doc(uid).update({
      'verified': true,
    });
    return OtpResult.success;
  }

  /// Gửi lại OTP
  Future<void> resendOtp(String uid, String email) async {
    await generateAndSendOtp(uid, email);
  }

  /// Kiểm tra OTP đã xác thực chưa
  Future<bool> isOtpVerified(String uid) async {
    final doc = await _db.collection('otp_verifications').doc(uid).get();
    if (!doc.exists) return false;
    return doc.data()?['verified'] == true;
  }

  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<UserModel?> getUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromJson(doc.data()!, uid);
  }

  /// Tạo Firestore doc từ Firebase Auth user hiện tại (fallback khi doc bị thiếu)
  Future<UserModel?> createUserDocFromAuth() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // Kiểm tra lại lần nữa (tránh tạo trùng)
    final existing = await getUserModel(firebaseUser.uid);
    if (existing != null) return existing;

    final user = UserModel(
      uid: firebaseUser.uid,
      name:
          firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'User',
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber ?? '',
      avatar: firebaseUser.photoURL,
      role: UserRole.admin, // Default admin cho tài khoản tạo thủ công
      createdAt: DateTime.now(),
    );

    await _db.collection('users').doc(firebaseUser.uid).set(user.toJson());
    return user;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}

enum OtpResult { success, invalid, expired, notFound, alreadyVerified }
