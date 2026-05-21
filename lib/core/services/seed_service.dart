// Seed Service - Tạo dữ liệu mẫu cho Firestore
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'gamification_service.dart';

class SeedService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const _adminEmail = 'admin@gymsync.com';
  static const _memberEmail = 'member@gymsync.com';
  static const _adminPassword = 'admin123';

  /// Tạo admin account + Firestore doc nếu chưa có.
  Future<void> seedAdminIfNeeded() async {
    try {
      UserCredential cred;

      try {
        cred = await _auth.createUserWithEmailAndPassword(
          email: _adminEmail,
          password: _adminPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          cred = await _auth.signInWithEmailAndPassword(
            email: _adminEmail,
            password: _adminPassword,
          );
        } else {
          return;
        }
      }

      if (cred.user == null) return;

      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        final user = UserModel(
          uid: cred.user!.uid,
          name: 'Admin GymSync',
          email: _adminEmail,
          phone: '0900000000',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        );
        await _db.collection('users').doc(cred.user!.uid).set(user.toJson());
      }

      await _auth.signOut();

      // --- SEED MEMBER ---
      UserCredential memberCred;
      try {
        memberCred = await _auth.createUserWithEmailAndPassword(
          email: _memberEmail,
          password: _adminPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          memberCred = await _auth.signInWithEmailAndPassword(
            email: _memberEmail,
            password: _adminPassword,
          );
        } else {
          return;
        }
      }

      if (memberCred.user == null) return;
      final mDoc = await _db
          .collection('users')
          .doc(memberCred.user!.uid)
          .get();
      if (!mDoc.exists) {
        final mUser = UserModel(
          uid: memberCred.user!.uid,
          name: 'Member Demo',
          email: _memberEmail,
          phone: '0911223344',
          role: UserRole.member,
          createdAt: DateTime.now(),
        );
        await _db
            .collection('users')
            .doc(memberCred.user!.uid)
            .set(mUser.toJson());
      }

      await _auth.signOut();
    } catch (e) {
      // Seed thất bại không crash app
    }
  }

  /// Seed toàn bộ dữ liệu mẫu (chỉ tạo nếu chưa có)
  Future<void> seedSampleData() async {
    await _seedPackages();
    await _seedTrainers();
    await _seedMembers();
    await _seedCheckIns();
    await _seedRenewals();
    await _seedCoupons();
    await _seedProducts();
    await _seedLockers();
    await _seedPtSessions();
    await _seedBodyMetrics();
    await _seedSales();
    await _seedGamificationChallenges();
    await _seedEquipment();
    await _seedGroupClasses();
    await _seedNotifications();
    await _seedBookings();
    await _seedWorkoutPrograms();
    await _seedTrainerRatings();
  }

  /// XÓA SẠCH và seed lại toàn bộ — dùng để sửa dữ liệu bị lỗi font
  Future<void> forceReseedAll() async {
    try {
      for (final col in [
        'members',
        'trainers',
        'packages',
        'checkins',
        'group_classes',
        'renewals',
        'coupons',
        'products',
        'lockers',
        'pt_sessions',
        'body_metrics',
        'sales',
        'stock_movements',
        'equipment',
        'notifications',
        'bookings',
        'workout_programs',
        'trainer_ratings',
      ]) {
        final snap = await _db.collection(col).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }
    } catch (_) {}
    await _seedPackages();
    await _seedTrainers();
    await _seedMembers();
    await _seedCheckIns();
    await _seedRenewals();
    await _seedCoupons();
    await _seedProducts();
    await _seedLockers();
    await _seedPtSessions();
    await _seedBodyMetrics();
    await _seedSales();
    await _seedGamificationChallenges();
    await _seedEquipment();
    await _seedGroupClasses();
    await _seedNotifications();
    await _seedBookings();
    await _seedWorkoutPrograms();
    await _seedTrainerRatings();
    
    await _fixUserNames();
  }

  Future<void> _fixUserNames() async {
    try {
      final snap = await _db.collection('users').get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final name = data['name'] as String? ?? '';
        var fixedName = name;
        
        if (name.contains('Ph?m') || name.contains('Dung')) fixedName = 'Phạm Thị Dung';
        else if (name.contains('L Van H') || name.contains('L  Van H')) fixedName = 'Lê Văn Hùng';
        else if (name.contains('Ho ng D') || name.contains('Ho  ng D')) fixedName = 'Hoàng Đức Nam';
        else if (name.contains('Tr?n') || name.contains('Van An')) fixedName = 'Trần Văn An';
        else if (name.contains('Nguy?n') || name.contains('B ch')) fixedName = 'Nguyễn Thị Bích';
        else if (name.contains('Dinh Van Khoa')) fixedName = 'Đinh Văn Khoa';
        
        if (fixedName != name) {
          await doc.reference.update({'name': fixedName});
        }
      }
    } catch (_) {}
  }

  Future<void> _seedPackages() async {
    try {
      final pkgSnap = await _db.collection('packages').limit(1).get();
      if (pkgSnap.docs.isNotEmpty) return;

      final packages = [
        {
          'name': 'Gói Cơ Bản',
          'description': 'Tập gym không giới hạn trong 1 tháng',
          'price': 299000,
          'durationDays': 30,
          'isActive': true,
          'color': 'orange',
          'features': [
            'Tập gym 24/7',
            'Sử dụng phòng thay đồ',
            'Tư vấn dinh dưỡng 1 buổi',
          ],
          'createdAt': Timestamp.now(),
        },
        {
          'name': 'Gói Tiêu Chuẩn',
          'description': 'Gym + Yoga + Zumba trong 3 tháng',
          'price': 799000,
          'durationDays': 90,
          'isActive': true,
          'color': 'blue',
          'features': [
            'Tập gym 24/7',
            'Lớp Yoga (2 buổi/tuần)',
            'Lớp Zumba (2 buổi/tuần)',
            'Tư vấn dinh dưỡng 3 buổi',
            'Khăn tắm miễn phí',
          ],
          'createdAt': Timestamp.now(),
        },
        {
          'name': 'Gói VIP',
          'description': 'Trọn gói các dịch vụ cao cấp nhất trong 1 năm',
          'price': 2590000,
          'durationDays': 365,
          'isActive': true,
          'color': 'purple',
          'features': [
            'Mọi quyền lợi của Gói Tiêu Chuẩn',
            'Tập 1 kèm 1 với HLV (12 buổi)',
            'Đo inbody hàng tháng miễn phí',
            'Gửi xe miễn phí VIP',
            'Tủ đồ cá nhân riêng biệt',
          ],
          'createdAt': Timestamp.now(),
        },
        {
          'name': 'Gói Sinh Viên',
          'description': 'Ưu đãi dành riêng cho học sinh, sinh viên (1 tháng)',
          'price': 199000,
          'durationDays': 30,
          'isActive': true,
          'color': 'green',
          'features': ['Tập gym từ 8:00 - 16:00', 'Sử dụng phòng thay đồ'],
          'createdAt': Timestamp.now(),
        },
      ];
      for (final p in packages) {
        await _db.collection('packages').add(p);
      }
    } catch (_) {}
  }

  Future<void> _seedTrainers() async {
    try {
      final snap = await _db.collection('trainers').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final trainers = [
        {
          'userId': '',
          'name': 'Nguyễn Văn Mạnh',
          'email': 'manh.pt@gymsync.com',
          'phone': '0901234567',
          'specialization': 'Thể hình & Tăng cơ',
          'experience': 5,
          'rating': 4.8,
          'isAvailable': true,
          'joinDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 365)),
          ),
          'bio':
              'Huấn luyện viên thể hình với 5 năm kinh nghiệm, chuyên về tăng cơ giảm mỡ.',
          'certifications': ['ACE Personal Trainer', 'NASM-CPT'],
          'clients': 24,
          'sessions': 312,
        },
        {
          'userId': '',
          'name': 'Trần Thị Lan',
          'email': 'lan.pt@gymsync.com',
          'phone': '0902345678',
          'specialization': 'Yoga & Pilates',
          'experience': 7,
          'rating': 4.9,
          'isAvailable': true,
          'joinDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 730)),
          ),
          'bio':
              'Huấn luyện viên Yoga quốc tế với 7 năm kinh nghiệm. Chứng chỉ RYT-500.',
          'certifications': ['RYT-500 Yoga Alliance', 'BASI Pilates'],
          'clients': 31,
          'sessions': 520,
        },
        {
          'userId': '',
          'name': 'Lê Hoàng Nam',
          'email': 'nam.pt@gymsync.com',
          'phone': '0903456789',
          'specialization': 'Cardio & Giảm cân',
          'experience': 3,
          'rating': 4.6,
          'isAvailable': true,
          'joinDate': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 180)),
          ),
          'bio':
              'Chuyên gia cardio và giảm cân, từng là vận động viên điền kinh quốc gia.',
          'certifications': ['CSCS', 'CPR/AED Certified'],
          'clients': 18,
          'sessions': 156,
        },
      ];
      for (final t in trainers) {
        await _db.collection('trainers').add(t);
      }
    } catch (_) {}
  }

  Future<void> _seedMembers() async {
    try {
      final snap = await _db.collection('members').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final now = DateTime.now();
      final members = [
        {
          'userId': '',
          'name': 'Member Demo',
          'email': 'member@gymsync.com',
          'phone': '0911223344',
          'status': 'active',
          'packageId': '',
          'packageName': 'Gói VIP',
          'packageExpiry': Timestamp.fromDate(
            now.add(const Duration(days: 120)),
          ),
          'qrCode': 'MBR001',
          'joinDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 60)),
          ),
          'address': '123 Nguyễn Huệ, Q1, TP.HCM',
          'notes': 'Hội viên thân thiết',
        },
        {
          'userId': '',
          'name': 'Nguyễn Thị Hoa',
          'email': 'hoa.nguyen@gmail.com',
          'phone': '0912334455',
          'status': 'active',
          'packageId': '',
          'packageName': 'Gói Tiêu Chuẩn',
          'packageExpiry': Timestamp.fromDate(
            now.add(const Duration(days: 45)),
          ),
          'qrCode': 'MBR002',
          'joinDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 45)),
          ),
          'address': '456 Lê Lợi, Q3, TP.HCM',
        },
        {
          'userId': '',
          'name': 'Trần Minh Khoa',
          'email': 'khoa.tran@gmail.com',
          'phone': '0913445566',
          'status': 'active',
          'packageId': '',
          'packageName': 'Gói Cơ Bản',
          'packageExpiry': Timestamp.fromDate(now.add(const Duration(days: 5))),
          // Sắp hết hạn (<=7 ngày)
          'qrCode': 'MBR003',
          'joinDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 25)),
          ),
          'address': '789 Điện Biên Phủ, Q.BT, TP.HCM',
          'notes': 'Cần nhắc gia hạn',
        },
        {
          'userId': '',
          'name': 'Lê Thị Mai',
          'email': 'mai.le@gmail.com',
          'phone': '0914556677',
          'status': 'expired',
          'packageId': '',
          'packageName': 'Gói Cơ Bản',
          'packageExpiry': Timestamp.fromDate(
            now.subtract(const Duration(days: 10)),
          ),
          'qrCode': 'MBR004',
          'joinDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 40)),
          ),
          'address': '321 Hai Bà Trưng, Q1, TP.HCM',
        },
        {
          'userId': '',
          'name': 'Võ Văn Hùng',
          'email': 'hung.vo@gmail.com',
          'phone': '0915667788',
          'status': 'active',
          'packageId': '',
          'packageName': 'Gói Sinh Viên',
          'packageExpiry': Timestamp.fromDate(
            now.add(const Duration(days: 20)),
          ),
          'qrCode': 'MBR005',
          'joinDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 10)),
          ),
          'address': 'KTX ĐHQG, Thủ Đức, TP.HCM',
        },
        {
          'userId': '',
          'name': 'Đinh Thị Thu',
          'email': 'thu.dinh@gmail.com',
          'phone': '0916778899',
          'status': 'paused',
          'packageId': '',
          'packageName': 'Gói Tiêu Chuẩn',
          'packageExpiry': Timestamp.fromDate(
            now.add(const Duration(days: 60)),
          ),
          'qrCode': 'MBR006',
          'joinDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 90)),
          ),
          'address': '654 Trường Chinh, TB, TP.HCM',
          'notes': 'Tạm dừng do đi công tác',
        },
        {
          'userId': '',
          'name': 'Bùi Quang Đức',
          'email': 'duc.bui@gmail.com',
          'phone': '0917889900',
          'status': 'active',
          'packageId': '',
          'packageName': 'Gói VIP',
          'packageExpiry': Timestamp.fromDate(
            now.add(const Duration(days: 150)),
          ),
          'qrCode': 'MBR007',
          'joinDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 30)),
          ),
          'address': '987 CMT8, Q.10, TP.HCM',
        },
        {
          'userId': '',
          'name': 'Hoàng Thị Linh',
          'email': 'linh.hoang@gmail.com',
          'phone': '0918990011',
          'status': 'expired',
          'packageId': '',
          'packageName': 'Gói Cơ Bản',
          'packageExpiry': Timestamp.fromDate(
            now.subtract(const Duration(days: 5)),
          ),
          'qrCode': 'MBR008',
          'joinDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 35)),
          ),
          'address': '147 Nguyễn Trãi, Q5, TP.HCM',
        },
      ];

      for (final m in members) {
        await _db.collection('members').add(m);
      }
    } catch (_) {}
  }

  Future<void> _seedCheckIns() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final ciSnap = await _db
          .collection('checkins')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
          .limit(1)
          .get();
      if (ciSnap.docs.isNotEmpty) return;

      // Lấy danh sách members để check-in
      final membersSnap = await _db
          .collection('members')
          .where('status', isEqualTo: 'active')
          .limit(4)
          .get();

      for (int i = 0; i < membersSnap.docs.length; i++) {
        final m = membersSnap.docs[i];
        await _db.collection('checkins').add({
          'memberId': m.id,
          'memberName': m.data()['name'] ?? 'Hội Viên',
          'timestamp': Timestamp.fromDate(
            startOfDay.add(Duration(hours: 6 + i, minutes: i * 15)),
          ),
          'method': 'manual',
          'isSuccess': true,
        });
      }
    } catch (_) {}
  }

  Future<void> _seedRenewals() async {
    try {
      final snap = await _db.collection('renewals').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final now = DateTime.now();
      final renewals = [
        {
          'memberId': '',
          'memberName': 'Hoàng Văn Em',
          'packageId': '',
          'packageName': 'Gói Cơ Bản',
          'price': 299000,
          'renewedAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 1)),
          ),
        },
        {
          'memberId': '',
          'memberName': 'Bùi Thị Hạnh',
          'packageId': '',
          'packageName': 'Gói Tiêu Chuẩn',
          'price': 799000,
          'renewedAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 2)),
          ),
        },
        {
          'memberId': '',
          'memberName': 'Trần Văn An',
          'packageId': '',
          'packageName': 'Gói Tiêu Chuẩn',
          'price': 799000,
          'renewedAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 5)),
          ),
        },
        {
          'memberId': '',
          'memberName': 'Nguyễn Thị Bích',
          'packageId': '',
          'packageName': 'Gói VIP',
          'price': 2590000,
          'renewedAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 10)),
          ),
        },
        {
          'memberId': '',
          'memberName': 'Lê Minh Châu',
          'packageId': '',
          'packageName': 'Gói VIP',
          'price': 2590000,
          'renewedAt': Timestamp.fromDate(
            now.subtract(const Duration(days: 15)),
          ),
        },
      ];

      for (final r in renewals) {
        await _db.collection('renewals').add(r);
      }
    } catch (_) {}
  }

  /// Nâng cấp dữ liệu từ V1 lên V2 (chạy 1 lần từ Admin)
  Future<void> migrateV1ToV2() async {
    try {
      // 1. Migrate Users
      final usersSnap = await _db.collection('users').get();
      for (final doc in usersSnap.docs) {
        if (!doc.data().containsKey('branchId')) {
          await doc.reference.update({'branchId': 'main'});
        }
      }

      // 2. Migrate Members
      final membersSnap = await _db.collection('members').get();
      for (final doc in membersSnap.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};
        if (!data.containsKey('sessionsRemaining')) {
          updates['sessionsRemaining'] = 0;
        }
        if (!data.containsKey('branchId')) updates['branchId'] = 'main';
        if (data['status'] == 'expired') {
          updates['status'] = 'active'; // Getter will handle expiry dynamically
        }
        if (updates.isNotEmpty) {
          await doc.reference.update(updates);
        }
      }

      // 3. Migrate Packages
      final packagesSnap = await _db.collection('packages').get();
      for (final doc in packagesSnap.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};
        if (!data.containsKey('type')) updates['type'] = 'time';
        if (!data.containsKey('sessionCount')) updates['sessionCount'] = 0;
        if (!data.containsKey('originalPrice')) {
          updates['originalPrice'] = data['price'] ?? 0;
        }
        if (updates.isNotEmpty) {
          await doc.reference.update(updates);
        }
      }

      // 4. Migrate Trainers
      final trainersSnap = await _db.collection('trainers').get();
      for (final doc in trainersSnap.docs) {
        final data = doc.data();
        final updates = <String, dynamic>{};
        if (!data.containsKey('maxSlots')) updates['maxSlots'] = 1;
        if (!data.containsKey('branchId')) updates['branchId'] = 'main';
        if (updates.isNotEmpty) {
          await doc.reference.update(updates);
        }
      }

      // 5. Create default branch if not exists
      final branchesSnap = await _db.collection('branches').get();
      if (branchesSnap.docs.isEmpty) {
        await _db.collection('branches').doc('main').set({
          'name': 'Cơ Sở Chính (Main Branch)',
          'address': '123 Đường Chính, TP.HCM',
          'phone': '0900000000',
          'isActive': true,
        });
      }
    } catch (_) {}
  }

  // ============================================================
  // ============== SEED CÁC DATA MỚI =============================
  // ============================================================

  /// Coupons / Voucher giảm giá
  Future<void> _seedCoupons() async {
    try {
      final snap = await _db.collection('coupons').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final now = DateTime.now();
      final coupons = [
        {
          'code': 'WELCOME10',
          'description': 'Giảm 10% cho hội viên mới (tối đa 200K)',
          'type': 'percent',
          'value': 10,
          'maxDiscount': 200000,
          'minOrderAmount': 500000,
          'totalQuantity': 100,
          'usedCount': 12,
          'startDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 7)),
          ),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 60))),
          'isActive': true,
          'applicablePackageIds': [],
        },
        {
          'code': 'SUMMER2026',
          'description': 'Mùa hè giảm 300K khi đăng ký gói từ 800K',
          'type': 'fixed',
          'value': 300000,
          'minOrderAmount': 800000,
          'totalQuantity': 50,
          'usedCount': 5,
          'startDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 3)),
          ),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 90))),
          'isActive': true,
          'applicablePackageIds': [],
        },
        {
          'code': 'STUDENT15',
          'description': 'Ưu đãi sinh viên 15% (không giới hạn)',
          'type': 'percent',
          'value': 15,
          'maxDiscount': 100000,
          'minOrderAmount': 0,
          'totalQuantity': -1,
          'usedCount': 28,
          'startDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 30)),
          ),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 180))),
          'isActive': true,
          'applicablePackageIds': [],
        },
        {
          'code': 'VIP500',
          'description': 'Giảm 500K cho gói VIP',
          'type': 'fixed',
          'value': 500000,
          'minOrderAmount': 2000000,
          'totalQuantity': 30,
          'usedCount': 8,
          'startDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 14)),
          ),
          'endDate': Timestamp.fromDate(now.add(const Duration(days: 45))),
          'isActive': true,
          'applicablePackageIds': [],
        },
        {
          'code': 'EXPIRED20',
          'description': 'Voucher hết hạn (test)',
          'type': 'percent',
          'value': 20,
          'minOrderAmount': 0,
          'totalQuantity': 100,
          'usedCount': 50,
          'startDate': Timestamp.fromDate(
            now.subtract(const Duration(days: 60)),
          ),
          'endDate': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
          'isActive': true,
          'applicablePackageIds': [],
        },
      ];

      for (final c in coupons) {
        await _db.collection('coupons').add(c);
      }
    } catch (_) {}
  }

  /// Sản phẩm bán tại quầy (POS)
  Future<void> _seedProducts() async {
    try {
      final snap = await _db.collection('products').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final products = [
        // Đồ uống
        {
          'name': 'Nước suối Lavie 500ml',
          'category': 'drink',
          'price': 10000,
          'costPrice': 6000,
          'stock': 120,
          'lowStockThreshold': 20,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Pocari Sweat 500ml',
          'category': 'drink',
          'price': 18000,
          'costPrice': 12000,
          'stock': 60,
          'lowStockThreshold': 15,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Red Bull 250ml',
          'category': 'drink',
          'price': 25000,
          'costPrice': 18000,
          'stock': 4, // Sắp hết
          'lowStockThreshold': 10,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        // Supplement
        {
          'name': 'Whey Protein Optimum 5lbs',
          'category': 'supplement',
          'price': 1850000,
          'costPrice': 1400000,
          'stock': 8,
          'lowStockThreshold': 3,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'BCAA Xtend 30 servings',
          'category': 'supplement',
          'price': 750000,
          'costPrice': 550000,
          'stock': 12,
          'lowStockThreshold': 4,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Creatine Monohydrate 500g',
          'category': 'supplement',
          'price': 580000,
          'costPrice': 420000,
          'stock': 0, // Hết hàng
          'lowStockThreshold': 3,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        // Quần áo
        {
          'name': 'Áo tank GymSync nam',
          'category': 'apparel',
          'price': 250000,
          'costPrice': 150000,
          'stock': 25,
          'lowStockThreshold': 5,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Quần shorts gym nữ',
          'category': 'apparel',
          'price': 220000,
          'costPrice': 130000,
          'stock': 18,
          'lowStockThreshold': 5,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        // Phụ kiện
        {
          'name': 'Găng tay gym',
          'category': 'accessory',
          'price': 120000,
          'costPrice': 65000,
          'stock': 35,
          'lowStockThreshold': 8,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Đai lưng tập tạ',
          'category': 'accessory',
          'price': 350000,
          'costPrice': 220000,
          'stock': 14,
          'lowStockThreshold': 4,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Khăn lau mồ hôi',
          'category': 'accessory',
          'price': 50000,
          'costPrice': 25000,
          'stock': 80,
          'lowStockThreshold': 20,
          'isActive': true,
          'updatedAt': Timestamp.now(),
        },
      ];

      for (final p in products) {
        await _db.collection('products').add(p);
      }
    } catch (_) {}
  }

  /// Tủ đồ
  Future<void> _seedLockers() async {
    try {
      final snap = await _db.collection('lockers').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      // Lấy 3 hội viên active để gán tủ demo
      final memberSnap = await _db
          .collection('members')
          .where('status', isEqualTo: 'active')
          .limit(3)
          .get();

      final assignedMembers = memberSnap.docs;
      final now = DateTime.now();

      // Tạo 30 tủ: A001-A015 (nam), B001-B015 (nữ)
      for (int i = 1; i <= 15; i++) {
        final code = 'A${i.toString().padLeft(3, '0')}';
        Map<String, dynamic> data = {
          'code': code,
          'area': 'Khu A - Nam',
          'status': 'available',
          'monthlyFee': 100000,
          'branchId': 'main',
        };

        if (i <= assignedMembers.length) {
          final m = assignedMembers[i - 1];
          data['status'] = 'assigned';
          data['assignedMemberId'] = m.id;
          data['assignedMemberName'] = m.data()['name'];
          data['assignedDate'] = Timestamp.fromDate(
            now.subtract(Duration(days: 10 + i)),
          );
          data['expiryDate'] = Timestamp.fromDate(
            now.add(Duration(days: 30 - (i * 3))),
          );
        } else if (i == 14) {
          data['status'] = 'maintenance';
          data['note'] = 'Khoá bị kẹt';
        }
        await _db.collection('lockers').add(data);
      }
      for (int i = 1; i <= 15; i++) {
        final code = 'B${i.toString().padLeft(3, '0')}';
        await _db.collection('lockers').add({
          'code': code,
          'area': 'Khu B - Nữ',
          'status': 'available',
          'monthlyFee': 100000,
          'branchId': 'main',
        });
      }
    } catch (_) {}
  }

  /// Buổi tập PT đã hoàn thành
  Future<void> _seedPtSessions() async {
    try {
      final snap = await _db.collection('pt_sessions').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final trainerSnap = await _db.collection('trainers').limit(3).get();
      final memberSnap = await _db
          .collection('members')
          .where('status', isEqualTo: 'active')
          .limit(5)
          .get();

      if (trainerSnap.docs.isEmpty || memberSnap.docs.isEmpty) return;

      final now = DateTime.now();
      final focuses = [
        'Ngực + Tay sau',
        'Lưng + Tay trước',
        'Chân + Mông',
        'Vai + Bụng',
        'Cardio + Core',
        'Toàn thân (Full body)',
      ];

      // Sessions trong 30 ngày qua
      for (int day = 0; day < 30; day++) {
        // Mỗi ngày 2-3 buổi
        final sessionsPerDay = 2 + (day % 2);
        for (int s = 0; s < sessionsPerDay; s++) {
          final trainer = trainerSnap.docs[(day + s) % trainerSnap.docs.length];
          final member = memberSnap.docs[(day + s) % memberSnap.docs.length];
          final sessionDate = now.subtract(
            Duration(days: day, hours: 6 + s * 2),
          );

          await _db.collection('pt_sessions').add({
            'trainerId': trainer.id,
            'trainerName': trainer.data()['name'],
            'memberId': member.id,
            'memberName': member.data()['name'],
            'sessionDate': Timestamp.fromDate(sessionDate),
            'durationMinutes': 60,
            'status': day == 0 && s == 0 ? 'scheduled' : 'completed',
            'workoutFocus': focuses[(day + s) % focuses.length],
            'trainerNote': day == 0
                ? null
                : 'Hội viên tập tốt, tăng được mức tạ',
            'memberRating': day == 0 ? null : 4 + ((day + s) % 2),
            'trainerCommission': day == 0 ? 0 : 150000.0,
            'createdAt': Timestamp.fromDate(sessionDate),
          });
        }
      }
    } catch (_) {}
  }

  /// Body metrics theo dõi inbody của hội viên
  Future<void> _seedBodyMetrics() async {
    try {
      final snap = await _db.collection('body_metrics').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final memberSnap = await _db.collection('members').limit(5).get();
      final now = DateTime.now();

      for (final memberDoc in memberSnap.docs) {
        // Mỗi hội viên có 4-6 lần đo (1 lần/tháng)
        final baseWeight = 60.0 + (memberDoc.id.hashCode % 30).abs();
        final baseBodyFat = 18.0 + (memberDoc.id.hashCode % 8).abs();
        final height = 160.0 + (memberDoc.id.hashCode % 25).abs();

        for (int i = 5; i >= 0; i--) {
          // Theo thời gian, cân nặng và bodyfat giảm dần (tập có hiệu quả)
          final weight = baseWeight - i * 0.4;
          final bodyFat = baseBodyFat - i * 0.5;

          await _db.collection('body_metrics').add({
            'memberId': memberDoc.id,
            'weight': double.parse(weight.toStringAsFixed(1)),
            'height': height,
            'bodyFat': double.parse(bodyFat.toStringAsFixed(1)),
            'chest': 90.0 + (i * 0.3),
            'waist': 80.0 - (i * 0.4),
            'hips': 95.0 + (i * 0.1),
            'date': Timestamp.fromDate(now.subtract(Duration(days: i * 30))),
            'note': i == 5 ? 'Lần đo đầu (mới đăng ký)' : null,
          });
        }
      }
    } catch (_) {}
  }

  /// Đơn POS bán hàng tại quầy
  Future<void> _seedSales() async {
    try {
      final snap = await _db.collection('sales').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final productSnap = await _db.collection('products').limit(8).get();
      if (productSnap.docs.isEmpty) return;

      final now = DateTime.now();

      // Tạo 20 đơn trong 7 ngày
      for (int day = 0; day < 7; day++) {
        for (int s = 0; s < 3; s++) {
          // Random 1-3 sản phẩm
          final itemCount = 1 + ((day + s) % 3);
          final items = <Map<String, dynamic>>[];
          double total = 0;
          for (int j = 0; j < itemCount; j++) {
            final p = productSnap.docs[(day + s + j) % productSnap.docs.length];
            final qty = 1 + (j % 2);
            final price = (p.data()['price'] ?? 0).toDouble();
            final subtotal = price * qty;
            total += subtotal;
            items.add({
              'productId': p.id,
              'productName': p.data()['name'],
              'quantity': qty,
              'unitPrice': price,
              'subtotal': subtotal,
            });
          }

          await _db.collection('sales').add({
            'items': items,
            'total': total,
            'discount': 0,
            'finalAmount': total,
            'paymentMethod': s % 2 == 0 ? 'cash' : 'transfer',
            'createdAt': Timestamp.fromDate(
              now.subtract(Duration(days: day, hours: 8 + s * 3)),
            ),
            'branchId': 'main',
          });
        }
      }
    } catch (_) {}
  }

  /// Seed gamification challenges
  Future<void> _seedGamificationChallenges() async {
    try {
      final gamificationService = GamificationService();
      await gamificationService.seedChallenges();
    } catch (_) {}
  }

  // ============================================================
  // ============ SEED DỮ LIỆU BỔ SUNG (V2) =====================
  // ============================================================

  /// Thiết bị phòng gym
  Future<void> _seedEquipment() async {
    try {
      final snap = await _db.collection('equipment').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final now = DateTime.now();
      final equipment = [
        {
          'name': 'Máy chạy bộ Life Fitness',
          'category': 'Cardio',
          'quantity': 8,
          'status': 'good',
          'lastMaintenance': Timestamp.fromDate(now.subtract(const Duration(days: 15))),
          'notes': 'Hoạt động bình thường, bảo trì định kỳ',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Xe đạp tập Schwinn',
          'category': 'Cardio',
          'quantity': 6,
          'status': 'good',
          'lastMaintenance': Timestamp.fromDate(now.subtract(const Duration(days: 30))),
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Máy elliptical Precor',
          'category': 'Cardio',
          'quantity': 4,
          'status': 'good',
          'lastMaintenance': Timestamp.fromDate(now.subtract(const Duration(days: 20))),
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Máy rowing Concept2',
          'category': 'Cardio',
          'quantity': 3,
          'status': 'maintenance',
          'lastMaintenance': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
          'notes': 'Máy số 2 đang thay dây cáp',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Bộ tạ đơn (1-50kg)',
          'category': 'Tạ',
          'quantity': 2,
          'status': 'good',
          'notes': 'Kệ A và kệ B, đầy đủ',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Ghế đẩy ngực phẳng',
          'category': 'Tạ',
          'quantity': 4,
          'status': 'good',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Khung Squat Rack',
          'category': 'Tạ',
          'quantity': 3,
          'status': 'good',
          'lastMaintenance': Timestamp.fromDate(now.subtract(const Duration(days: 45))),
          'notes': 'Có thanh an toàn',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Máy kéo cáp Cable Machine',
          'category': 'Máy',
          'quantity': 4,
          'status': 'good',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Máy ép đùi Leg Press',
          'category': 'Máy',
          'quantity': 2,
          'status': 'good',
          'lastMaintenance': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Máy tập bụng AB Crunch',
          'category': 'Máy',
          'quantity': 2,
          'status': 'broken',
          'lastMaintenance': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
          'notes': 'Hỏng hệ thống puly, đã đặt linh kiện thay thế',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Thanh xà đơn',
          'category': 'Phụ kiện',
          'quantity': 5,
          'status': 'good',
          'notes': 'Treo tường khu Free Weight',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Thảm Yoga',
          'category': 'Phụ kiện',
          'quantity': 30,
          'status': 'good',
          'notes': 'Phòng Yoga tầng 2',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Bóng tập Gym Ball 65cm',
          'category': 'Phụ kiện',
          'quantity': 15,
          'status': 'good',
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Máy Smith Machine',
          'category': 'Máy',
          'quantity': 2,
          'status': 'good',
          'lastMaintenance': Timestamp.fromDate(now.subtract(const Duration(days: 60))),
          'updatedAt': Timestamp.now(),
        },
        {
          'name': 'Dây kháng lực Resistance Band',
          'category': 'Phụ kiện',
          'quantity': 20,
          'status': 'good',
          'notes': 'Bộ 5 mức độ',
          'updatedAt': Timestamp.now(),
        },
      ];

      for (final e in equipment) {
        await _db.collection('equipment').add(e);
      }
    } catch (_) {}
  }

  /// Lớp học nhóm
  Future<void> _seedGroupClasses() async {
    try {
      final snap = await _db.collection('group_classes').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final now = DateTime.now();
      final trainerSnap = await _db.collection('trainers').limit(3).get();
      final trainerNames = trainerSnap.docs
          .map((d) => (d.data()['name'] as String?) ?? 'HLV')
          .toList();
      final trainerIds = trainerSnap.docs.map((d) => d.id).toList();

      final classes = [
        {
          'name': 'Yoga Buổi Sáng',
          'type': 'yoga',
          'trainerId': trainerIds.isNotEmpty ? trainerIds[1 % trainerIds.length] : '',
          'trainerName': trainerNames.isNotEmpty ? trainerNames[1 % trainerNames.length] : 'HLV',
          'scheduledAt': Timestamp.fromDate(DateTime(now.year, now.month, now.day + 1, 7, 0)),
          'durationMin': 60,
          'maxSlots': 20,
          'enrolledIds': <String>[],
          'createdAt': Timestamp.now(),
          'isActive': true,
        },
        {
          'name': 'Zumba Party',
          'type': 'zumba',
          'trainerId': trainerIds.isNotEmpty ? trainerIds[0] : '',
          'trainerName': trainerNames.isNotEmpty ? trainerNames[0] : 'HLV',
          'scheduledAt': Timestamp.fromDate(DateTime(now.year, now.month, now.day + 1, 18, 30)),
          'durationMin': 45,
          'maxSlots': 25,
          'enrolledIds': <String>[],
          'createdAt': Timestamp.now(),
          'isActive': true,
        },
        {
          'name': 'Boxing Cơ Bản',
          'type': 'boxing',
          'trainerId': trainerIds.isNotEmpty ? trainerIds[2 % trainerIds.length] : '',
          'trainerName': trainerNames.isNotEmpty ? trainerNames[2 % trainerNames.length] : 'HLV',
          'scheduledAt': Timestamp.fromDate(DateTime(now.year, now.month, now.day + 2, 17, 0)),
          'durationMin': 60,
          'maxSlots': 15,
          'enrolledIds': <String>[],
          'createdAt': Timestamp.now(),
          'isActive': true,
        },
        {
          'name': 'Cardio HIIT Chiều',
          'type': 'cardio',
          'trainerId': trainerIds.isNotEmpty ? trainerIds[0] : '',
          'trainerName': trainerNames.isNotEmpty ? trainerNames[0] : 'HLV',
          'scheduledAt': Timestamp.fromDate(DateTime(now.year, now.month, now.day + 2, 19, 0)),
          'durationMin': 45,
          'maxSlots': 20,
          'enrolledIds': <String>[],
          'createdAt': Timestamp.now(),
          'isActive': true,
        },
        {
          'name': 'Pilates Nâng Cao',
          'type': 'pilates',
          'trainerId': trainerIds.isNotEmpty ? trainerIds[1 % trainerIds.length] : '',
          'trainerName': trainerNames.isNotEmpty ? trainerNames[1 % trainerNames.length] : 'HLV',
          'scheduledAt': Timestamp.fromDate(DateTime(now.year, now.month, now.day + 3, 8, 0)),
          'durationMin': 75,
          'maxSlots': 15,
          'enrolledIds': <String>[],
          'createdAt': Timestamp.now(),
          'isActive': true,
        },
        {
          'name': 'Yoga Thư Giãn Tối',
          'type': 'yoga',
          'trainerId': trainerIds.isNotEmpty ? trainerIds[1 % trainerIds.length] : '',
          'trainerName': trainerNames.isNotEmpty ? trainerNames[1 % trainerNames.length] : 'HLV',
          'scheduledAt': Timestamp.fromDate(DateTime(now.year, now.month, now.day + 3, 20, 0)),
          'durationMin': 60,
          'maxSlots': 20,
          'enrolledIds': <String>[],
          'createdAt': Timestamp.now(),
          'isActive': true,
        },
        {
          'name': 'Cardio Dance',
          'type': 'zumba',
          'trainerId': trainerIds.isNotEmpty ? trainerIds[0] : '',
          'trainerName': trainerNames.isNotEmpty ? trainerNames[0] : 'HLV',
          'scheduledAt': Timestamp.fromDate(DateTime(now.year, now.month, now.day + 4, 18, 0)),
          'durationMin': 50,
          'maxSlots': 25,
          'enrolledIds': <String>[],
          'createdAt': Timestamp.now(),
          'isActive': true,
        },
      ];

      for (final c in classes) {
        await _db.collection('group_classes').add(c);
      }
    } catch (_) {}
  }

  /// Thông báo (notifications)
  Future<void> _seedNotifications() async {
    try {
      final snap = await _db.collection('notifications').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final now = DateTime.now();
      final notifications = [
        {
          'title': 'Chào mừng đến GymSync!',
          'body': 'Chúc bạn có trải nghiệm tuyệt vời tại phòng tập. Hãy check-in ngay hôm nay!',
          'type': 'system',
          'isRead': false,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        },
        {
          'title': '🔥 Ưu đãi mùa hè 2026',
          'body': 'Giảm đến 30% cho gói tập 6 tháng và 1 năm. Áp dụng đến hết 30/06/2026.',
          'type': 'promotion',
          'isRead': false,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 6))),
        },
        {
          'title': 'Lớp Yoga mới mở!',
          'body': 'Lớp Yoga Buổi Sáng 7:00 - 8:00, thứ 2-4-6. Đăng ký ngay tại app hoặc quầy lễ tân.',
          'type': 'class',
          'isRead': true,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        },
        {
          'title': 'Bảo trì hệ thống',
          'body': 'Hệ thống sẽ bảo trì từ 23:00 - 01:00 tối nay. Vui lòng check-in trước giờ này.',
          'type': 'system',
          'isRead': true,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        },
        {
          'title': '💪 Thử thách tháng 5',
          'body': 'Hoàn thành 20 buổi tập trong tháng để nhận 1000 điểm thưởng! Tham gia ngay.',
          'type': 'challenge',
          'isRead': false,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        },
        {
          'title': 'Nhắc nhở gia hạn',
          'body': 'Gói tập của bạn sắp hết hạn. Gia hạn sớm để nhận ưu đãi giảm 5%.',
          'type': 'reminder',
          'isRead': false,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1, hours: 5))),
        },
      ];

      for (final n in notifications) {
        await _db.collection('notifications').add(n);
      }
    } catch (_) {}
  }

  /// Đặt lịch (Bookings)
  Future<void> _seedBookings() async {
    try {
      final snap = await _db.collection('bookings').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final now = DateTime.now();
      final memberSnap = await _db
          .collection('members')
          .where('status', isEqualTo: 'active')
          .limit(5)
          .get();
      final trainerSnap = await _db.collection('trainers').limit(3).get();

      if (memberSnap.docs.isEmpty || trainerSnap.docs.isEmpty) return;

      final bookings = <Map<String, dynamic>>[];

      // Tạo bookings trong 7 ngày tới
      for (int day = 0; day < 7; day++) {
        final sessionsPerDay = 2 + (day % 2);
        for (int s = 0; s < sessionsPerDay; s++) {
          final member = memberSnap.docs[(day + s) % memberSnap.docs.length];
          final trainer = trainerSnap.docs[(day + s) % trainerSnap.docs.length];
          final startHour = 7 + s * 2;
          final startTime = DateTime(
            now.year, now.month, now.day + day, startHour, 0,
          );
          final endTime = startTime.add(const Duration(hours: 1));

          bookings.add({
            'memberId': member.id,
            'memberName': member.data()['name'] ?? 'Hội Viên',
            'trainerId': trainer.id,
            'trainerName': trainer.data()['name'] ?? 'HLV',
            'startTime': Timestamp.fromDate(startTime),
            'endTime': Timestamp.fromDate(endTime),
            'status': day < 2 ? 'confirmed' : 'pending',
            'notes': day == 0 ? 'Buổi tập PT thường kỳ' : null,
            'createdAt': Timestamp.now(),
          });
        }
      }

      // Thêm vài booking đã hoàn thành trong quá khứ
      for (int day = 1; day <= 5; day++) {
        final member = memberSnap.docs[day % memberSnap.docs.length];
        final trainer = trainerSnap.docs[day % trainerSnap.docs.length];
        final startTime = DateTime(now.year, now.month, now.day - day, 8, 0);
        final endTime = startTime.add(const Duration(hours: 1));

        bookings.add({
          'memberId': member.id,
          'memberName': member.data()['name'] ?? 'Hội Viên',
          'trainerId': trainer.id,
          'trainerName': trainer.data()['name'] ?? 'HLV',
          'startTime': Timestamp.fromDate(startTime),
          'endTime': Timestamp.fromDate(endTime),
          'status': 'completed',
          'notes': null,
          'createdAt': Timestamp.fromDate(
            startTime.subtract(const Duration(days: 1)),
          ),
        });
      }

      for (final b in bookings) {
        await _db.collection('bookings').add(b);
      }
    } catch (_) {}
  }

  /// Chương trình tập luyện (Workout Programs) cho Trainer
  Future<void> _seedWorkoutPrograms() async {
    try {
      final snap = await _db.collection('workout_programs').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final trainerSnap = await _db.collection('trainers').limit(3).get();
      final memberSnap = await _db
          .collection('members')
          .where('status', isEqualTo: 'active')
          .limit(4)
          .get();

      if (trainerSnap.docs.isEmpty || memberSnap.docs.isEmpty) return;

      final now = DateTime.now();

      final programs = [
        {
          'name': 'Chương trình giảm mỡ 8 tuần',
          'description':
              'Kết hợp cardio cường độ cao và tập tạ để đốt mỡ tối ưu. Phù hợp cho người mới bắt đầu đến trung cấp.',
          'trainerId': trainerSnap.docs[0].id,
          'trainerName': trainerSnap.docs[0].data()['name'],
          'memberId': memberSnap.docs[0].id,
          'memberName': memberSnap.docs[0].data()['name'],
          'durationWeeks': 8,
          'sessionsPerWeek': 4,
          'difficulty': 'intermediate',
          'exercises': [
            {'name': 'Chạy bộ HIIT', 'sets': 5, 'reps': '30 giây', 'rest': '30 giây'},
            {'name': 'Squat', 'sets': 4, 'reps': '12', 'rest': '60 giây'},
            {'name': 'Deadlift', 'sets': 4, 'reps': '10', 'rest': '90 giây'},
            {'name': 'Bench Press', 'sets': 3, 'reps': '12', 'rest': '60 giây'},
            {'name': 'Plank', 'sets': 3, 'reps': '60 giây', 'rest': '30 giây'},
          ],
          'status': 'active',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 14))),
        },
        {
          'name': 'Tăng cơ bắp cho nam',
          'description':
              'Chương trình hypertrophy tập trung vào tăng khối lượng cơ bắp. Chia theo nhóm cơ theo ngày.',
          'trainerId': trainerSnap.docs[0].id,
          'trainerName': trainerSnap.docs[0].data()['name'],
          'memberId': memberSnap.docs[1 % memberSnap.docs.length].id,
          'memberName': memberSnap.docs[1 % memberSnap.docs.length].data()['name'],
          'durationWeeks': 12,
          'sessionsPerWeek': 5,
          'difficulty': 'advanced',
          'exercises': [
            {'name': 'Barbell Squat', 'sets': 5, 'reps': '5', 'rest': '3 phút'},
            {'name': 'Romanian Deadlift', 'sets': 4, 'reps': '8', 'rest': '2 phút'},
            {'name': 'Incline Bench Press', 'sets': 4, 'reps': '8', 'rest': '90 giây'},
            {'name': 'Barbell Row', 'sets': 4, 'reps': '8', 'rest': '90 giây'},
            {'name': 'Overhead Press', 'sets': 4, 'reps': '8', 'rest': '90 giây'},
            {'name': 'Bicep Curl', 'sets': 3, 'reps': '12', 'rest': '60 giây'},
          ],
          'status': 'active',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        },
        {
          'name': 'Yoga & Linh hoạt cơ thể',
          'description':
              'Cải thiện sự linh hoạt, giảm stress và tăng cường sức khỏe tổng thể qua các bài tập Yoga và Pilates.',
          'trainerId': trainerSnap.docs[1 % trainerSnap.docs.length].id,
          'trainerName': trainerSnap.docs[1 % trainerSnap.docs.length].data()['name'],
          'memberId': memberSnap.docs[2 % memberSnap.docs.length].id,
          'memberName': memberSnap.docs[2 % memberSnap.docs.length].data()['name'],
          'durationWeeks': 6,
          'sessionsPerWeek': 3,
          'difficulty': 'beginner',
          'exercises': [
            {'name': 'Sun Salutation', 'sets': 3, 'reps': '5 vòng', 'rest': '30 giây'},
            {'name': 'Warrior Pose', 'sets': 3, 'reps': '30 giây mỗi bên', 'rest': '15 giây'},
            {'name': 'Tree Pose', 'sets': 2, 'reps': '45 giây mỗi bên', 'rest': '15 giây'},
            {'name': 'Child Pose', 'sets': 2, 'reps': '60 giây', 'rest': '15 giây'},
          ],
          'status': 'active',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
        },
        {
          'name': 'Cardio tăng sức bền',
          'description':
              'Chương trình chạy bộ và cardio nâng cao sức bền tim mạch, phù hợp cho người muốn cải thiện thể lực tổng thể.',
          'trainerId': trainerSnap.docs[2 % trainerSnap.docs.length].id,
          'trainerName': trainerSnap.docs[2 % trainerSnap.docs.length].data()['name'],
          'memberId': memberSnap.docs[3 % memberSnap.docs.length].id,
          'memberName': memberSnap.docs[3 % memberSnap.docs.length].data()['name'],
          'durationWeeks': 10,
          'sessionsPerWeek': 4,
          'difficulty': 'intermediate',
          'exercises': [
            {'name': 'Chạy bộ 5K', 'sets': 1, 'reps': '25-30 phút', 'rest': 'N/A'},
            {'name': 'Burpees', 'sets': 4, 'reps': '15', 'rest': '45 giây'},
            {'name': 'Mountain Climbers', 'sets': 4, 'reps': '20', 'rest': '30 giây'},
            {'name': 'Jump Rope', 'sets': 5, 'reps': '60 giây', 'rest': '30 giây'},
            {'name': 'Box Jumps', 'sets': 3, 'reps': '12', 'rest': '60 giây'},
          ],
          'status': 'active',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        },
      ];

      for (final p in programs) {
        await _db.collection('workout_programs').add(p);
      }
    } catch (_) {}
  }

  /// Đánh giá HLV từ hội viên
  Future<void> _seedTrainerRatings() async {
    try {
      final snap = await _db.collection('trainer_ratings').limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final trainerSnap = await _db.collection('trainers').limit(3).get();
      final memberSnap = await _db
          .collection('members')
          .where('status', isEqualTo: 'active')
          .limit(5)
          .get();

      if (trainerSnap.docs.isEmpty || memberSnap.docs.isEmpty) return;

      final now = DateTime.now();
      final comments = [
        'HLV rất nhiệt tình và chuyên nghiệp, mình rất hài lòng!',
        'Buổi tập rất hiệu quả, cảm thấy tiến bộ rõ rệt.',
        'HLV luôn đúng giờ và hướng dẫn rất tận tâm.',
        'Chương trình tập phù hợp với mục tiêu của mình.',
        'Rất tốt, sẽ tiếp tục đăng ký thêm buổi PT.',
        'HLV giải thích kỹ thuật rất rõ ràng, dễ hiểu.',
        'Buổi tập vui vẻ, không quá nặng nhưng hiệu quả.',
        'Cảm thấy cơ thể thay đổi tích cực sau 1 tháng tập.',
      ];

      for (int i = 0; i < trainerSnap.docs.length; i++) {
        final trainer = trainerSnap.docs[i];
        // Mỗi HLV nhận 3-4 đánh giá
        final ratingsCount = 3 + (i % 2);
        for (int j = 0; j < ratingsCount; j++) {
          final member = memberSnap.docs[(i + j) % memberSnap.docs.length];
          final rating = 4 + (j % 2); // 4 hoặc 5 sao
          await _db.collection('trainer_ratings').add({
            'trainerId': trainer.id,
            'trainerName': trainer.data()['name'],
            'memberId': member.id,
            'memberName': member.data()['name'],
            'rating': rating,
            'comment': comments[(i * 3 + j) % comments.length],
            'createdAt': Timestamp.fromDate(
              now.subtract(Duration(days: j * 5 + i * 2)),
            ),
          });
        }
      }
    } catch (_) {}
  }
}
