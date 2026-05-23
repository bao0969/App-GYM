import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../models/trainer_model.dart';
import '../models/package_model.dart';
import '../models/checkin_model.dart';
import '../models/user_model.dart';
import '../models/booking_model.dart';
import '../models/order_model.dart';
import '../models/body_metric_model.dart';
import '../models/group_class_model.dart';
import '../models/branch_model.dart';
import '../models/coupon_model.dart';
import '../models/product_model.dart';
import '../models/sale_model.dart';
import '../models/locker_model.dart';
import '../models/pt_session_model.dart';
import '../models/staff_attendance_model.dart';
import '../models/work_shift_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ==================== MEMBERS ====================

  Stream<List<MemberModel>> streamMembers() {
    return _db
        .collection('members')
        .orderBy('joinDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MemberModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<List<MemberModel>> getMembers() async {
    final snap = await _db
        .collection('members')
        .orderBy('joinDate', descending: true)
        .get();
    return snap.docs.map((d) => MemberModel.fromJson(d.data(), d.id)).toList();
  }

  Future<MemberModel?> getMemberByUserId(String userId) async {
    final snap = await _db
        .collection('members')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return MemberModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
  }

  Stream<MemberModel?> streamMemberByUserId(String userId) {
    return _db
        .collection('members')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return MemberModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
    });
  }

  Future<MemberModel?> getMemberByQR(String qrCode) async {
    final snap = await _db
        .collection('members')
        .where('qrCode', isEqualTo: qrCode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return MemberModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<void> addMember(Map<String, dynamic> data) async {
    await _db.collection('members').add(data);
  }

  Future<String> _resolveMemberDocId(String id) async {
    final doc = await _db.collection('members').doc(id).get();
    if (doc.exists) return id;
    final query = await _db.collection('members').where('userId', isEqualTo: id).limit(1).get();
    if (query.docs.isNotEmpty) return query.docs.first.id;
    return id;
  }

  Future<void> updateMember(String id, Map<String, dynamic> data) async {
    final docId = await _resolveMemberDocId(id);
    await _db.collection('members').doc(docId).update(data);
  }

  Future<void> deleteMember(String id) async {
    final docId = await _resolveMemberDocId(id);
    await _db.collection('members').doc(docId).delete();
  }

  /// Kích hoạt membership mới. Nếu hội viên còn hạn, cộng ngày từ expiry cũ.
  /// Nếu hết hạn hoặc chưa có expiry, tính từ hôm nay. (Fix #2)
  Future<void> activateMember(
    String id,
    int durationDays,
    int sessionCount, {
    bool stackOnExisting = true, // Cộng ngày vào hạn cũ nếu còn hạn
  }) async {
    final now = DateTime.now();
    final docId = await _resolveMemberDocId(id);

    // Lấy expiry hiện tại để quyết định tính từ đâu
    DateTime baseDate = now;
    if (stackOnExisting) {
      final memberDoc = await _db.collection('members').doc(docId).get();
      if (memberDoc.exists) {
        final data = memberDoc.data()!;
        if (data['packageExpiry'] is Timestamp) {
          final existingExpiry = (data['packageExpiry'] as Timestamp).toDate();
          // Nếu còn hạn → cộng từ expiry cũ; nếu hết hạn → cộng từ hôm nay
          if (existingExpiry.isAfter(now)) {
            baseDate = existingExpiry;
          }
        }
      }
    }

    await updateMember(docId, {
      'status': MemberStatus.active.name,
      'packageExpiry': Timestamp.fromDate(
        baseDate.add(Duration(days: durationDays)),
      ),
      'sessionsRemaining': sessionCount,
    });
  }

  /// Tạm dừng membership. Cộng số ngày pause vào ngày hết hạn để hội viên
  /// không mất thời gian tập. (Fix #8: dùng isDbActive thay vì currentStatus)
  Future<void> pauseMember(String id, int daysToPause) async {
    final docId = await _resolveMemberDocId(id);
    final memberDoc = await _db.collection('members').doc(docId).get();
    if (!memberDoc.exists) return;

    final member = MemberModel.fromJson(memberDoc.data()!, memberDoc.id);
    // Fix #8: dùng isDbActive (DB enum) thay vì currentStatus (computed string)
    // để không block member có status 'expiring_soon'
    if (member.isDbActive && member.packageExpiry != null) {
      final newExpiry = member.packageExpiry!.add(Duration(days: daysToPause));
      await updateMember(docId, {
        'status': MemberStatus.paused.name,
        'packageExpiry': Timestamp.fromDate(newExpiry),
      });
    }
  }

  // ==================== TRAINERS ====================

  Stream<List<TrainerModel>> streamTrainers() {
    return _db
        .collection('trainers')
        .orderBy('joinDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TrainerModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<List<TrainerModel>> getTrainers() async {
    final snap = await _db.collection('trainers').get();
    return snap.docs.map((d) => TrainerModel.fromJson(d.data(), d.id)).toList();
  }

  Future<TrainerModel?> getTrainerByUserId(String userId) async {
    final snap = await _db
        .collection('trainers')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return TrainerModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<void> addTrainer(Map<String, dynamic> data) async {
    await _db.collection('trainers').add(data);
  }

  Future<void> updateTrainer(String id, Map<String, dynamic> data) async {
    await _db.collection('trainers').doc(id).update(data);
  }

  Future<void> assignMemberToTrainer({
    required String memberId,
    required String trainerId,
  }) async {
    final memberRef = _db.collection('members').doc(memberId);
    final trainerRef = _db.collection('trainers').doc(trainerId);

    final batch = _db.batch();
    batch.update(memberRef, {'trainerId': trainerId});
    batch.update(trainerRef, {
      'studentIds': FieldValue.arrayUnion([memberId]),
    });
    await batch.commit();
  }

  Future<void> unassignMemberFromTrainer({
    required String memberId,
    required String trainerId,
  }) async {
    final memberRef = _db.collection('members').doc(memberId);
    final trainerRef = _db.collection('trainers').doc(trainerId);

    final batch = _db.batch();
    batch.update(memberRef, {'trainerId': null});
    batch.update(trainerRef, {
      'studentIds': FieldValue.arrayRemove([memberId]),
    });
    await batch.commit();
  }

  Stream<List<MemberModel>> streamTrainerMembers(String trainerId) {
    return _db
        .collection('members')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => MemberModel.fromJson(d.data(), d.id))
                .toList();
            list.sort((a, b) => b.joinDate.compareTo(a.joinDate));
            return list;
          },
        );
  }

  Future<List<MemberModel>> getTrainerMembers(String trainerId) async {
    final snap = await _db
        .collection('members')
        .where('trainerId', isEqualTo: trainerId)
        .get();
    final list = snap.docs
        .map((d) => MemberModel.fromJson(d.data(), d.id))
        .toList();
    list.sort((a, b) => b.joinDate.compareTo(a.joinDate));
    return list;
  }

  Future<void> deleteTrainer(String id) async {
    await _db.collection('trainers').doc(id).delete();
  }

  // ==================== PACKAGES ====================

  Stream<List<PackageModel>> streamPackages() {
    return _db
        .collection('packages')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PackageModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<List<PackageModel>> getPackages() async {
    final snap = await _db.collection('packages').get();
    return snap.docs.map((d) => PackageModel.fromJson(d.data(), d.id)).toList();
  }

  Future<int> getMemberCountByPackageName(String packageName) async {
    final snap = await _db
        .collection('members')
        .where('packageName', isEqualTo: packageName)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<void> addPackage(Map<String, dynamic> data) async {
    await _db.collection('packages').add(data);
  }

  Future<void> updatePackage(String id, Map<String, dynamic> data) async {
    await _db.collection('packages').doc(id).update(data);
  }

  Future<void> deletePackage(String id) async {
    await _db.collection('packages').doc(id).delete();
  }

  // ==================== CHECK-INS ====================

  Stream<List<CheckInModel>> streamTodayCheckIns() {
    final startOfDay = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    return _db
        .collection('checkins')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CheckInModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<List<CheckInModel>> getRecentCheckIns({int limit = 20}) async {
    final snap = await _db
        .collection('checkins')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => CheckInModel.fromJson(d.data(), d.id)).toList();
  }

  /// Thêm check-in với logic chống spam và trừ buổi (Fix #1 + #7)
  ///
  /// Fix #7: Chỉ trừ sessionsRemaining nếu member có gói session/PT-based.
  ///         Gói time-based (30/90/365 ngày) KHÔNG trừ buổi khi check-in thường.
  /// Fix #1: addCheckIn() không trừ buổi PT – việc đó do completePtSession() làm.
  Future<CheckInModel> addCheckIn(CheckInModel checkIn) async {
    final docId = await _resolveMemberDocId(checkIn.memberId);
    final memberDoc = await _db
        .collection('members')
        .doc(docId)
        .get();
    if (!memberDoc.exists) throw Exception('Member not found');

    final member = MemberModel.fromJson(memberDoc.data()!, memberDoc.id);

    // Rule 1: Check active
    if (!member.isActive) {
      throw Exception(
        'Thẻ tập không hợp lệ (Trạng thái: ${member.currentStatus})',
      );
    }

    // Rule 2: Anti-spam 60 mins
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 60));
    final recentCheckin = await _db
        .collection('checkins')
        .where('memberId', isEqualTo: member.id)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoffTime))
        .limit(1)
        .get();

    if (recentCheckin.docs.isNotEmpty) {
      throw Exception(
        'Bạn vừa check-in gần đây, vui lòng thử lại sau 60 phút.',
      );
    }

    // Rule 3: Chỉ trừ buổi nếu là gói session-based (session/groupClass).
    // Gói PT không trừ ở đây – completePtSession() chịu trách nhiệm trừ buổi PT.
    // Gói time-based (30/90/365 ngày) không bao giờ trừ sessionsRemaining khi check-in.
    if (member.packageId != null && member.sessionsRemaining > 0) {
      final pkgDoc = await _db
          .collection('packages')
          .doc(member.packageId)
          .get();
      if (pkgDoc.exists) {
        final pkg = PackageModel.fromJson(pkgDoc.data()!, pkgDoc.id);
        // Chỉ trừ nếu là gói session hoặc groupClass (không phải PT, không phải time)
        if (pkg.type == PackageType.session ||
            pkg.type == PackageType.groupClass) {
          await updateMember(member.id, {
            'sessionsRemaining': member.sessionsRemaining - 1,
          });
        }
      }
    }

    final ref = await _db.collection('checkins').add(checkIn.toJson());
    return CheckInModel.fromJson(checkIn.toJson(), ref.id);
  }

  /// Kiểm tra hội viên đã check-in hôm nay chưa
  Future<bool> hasCheckedInToday(String memberId) async {
    final startOfDay = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    final snap = await _db
        .collection('checkins')
        .where('memberId', isEqualTo: memberId)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Lấy danh sách check-in hôm nay
  Future<List<CheckInModel>> getTodayCheckIns() async {
    final now = DateTime.now();
    final startOfDay = now.copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final snap = await _db
        .collection('checkins')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: true)
        .get(const GetOptions(source: Source.server));
    return snap.docs
        .map((d) => CheckInModel.fromJson(d.data(), d.id))
        .toList();
  }

  // ==================== USERS ====================

  Stream<List<UserModel>> streamUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => UserModel.fromJson(d.data(), d.id)).toList(),
        );
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({'role': role.name});
  }

  // ==================== DASHBOARD STATS ====================

  Future<Map<String, dynamic>> getDashboardStats() async {
    final now = DateTime.now();
    final startOfDay = now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    final results = await Future.wait([
      getMembers(),
      getTrainers(),
      _db
          .collection('checkins')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get(const GetOptions(source: Source.server)),
    ]);

    final members = results[0] as List<MemberModel>;
    final trainers = results[1] as List<TrainerModel>;
    final todayCheckins = results[2] as QuerySnapshot<Map<String, dynamic>>;

    final activeMembers = members.where((m) => m.isActive).length;
    final expiredMembers = members
        .where((m) => m.currentStatus == 'expired')
        .length;
    final newThisMonth = members
        .where((m) => m.joinDate.isAfter(startOfMonth) && m.joinDate.isBefore(endOfMonth))
        .length;

    final validTodayCheckins = todayCheckins.docs.where((d) {
      final data = d.data();
      return data['timestamp'] is Timestamp;
    }).length;

    return {
      'totalMembers': members.length,
      'activeMembers': activeMembers,
      'expiredMembers': expiredMembers,
      'newMembersThisMonth': newThisMonth,
      'totalTrainers': trainers.length,
      'todayCheckIns': validTodayCheckins,
    };
  }

  // ==================== BOOKINGS ====================

  Future<BookingModel> addBooking(BookingModel booking) async {
    final ref = await _db.collection('bookings').add(booking.toJson());
    return booking.copyWith(id: ref.id);
  }

  /// Stream booking của trainer. Sort phía client để tránh cần composite index.
  Stream<List<BookingModel>> streamTrainerBookings(String trainerId) {
    return _db
        .collection('bookings')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => BookingModel.fromJson(d.data(), d.id))
                .toList();
            list.sort((a, b) => a.startTime.compareTo(b.startTime));
            return list;
          },
        );
  }

  /// Stream booking của member. Sort phía client để tránh cần composite index.
  Stream<List<BookingModel>> streamMemberBookings(String memberId) {
    return _db
        .collection('bookings')
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => BookingModel.fromJson(d.data(), d.id))
                .toList();
            list.sort((a, b) => a.startTime.compareTo(b.startTime));
            return list;
          },
        );
  }

  Stream<List<BookingModel>> streamAdminBookings() {
    return _db
        .collection('bookings')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BookingModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    await _db.collection('bookings').doc(bookingId).update({
      'status': status.name,
    });
  }

  /// Hủy booking. Nếu hủy muộn (isLateCancel), trừ 1 buổi của hội viên.
  /// Fix #6: Dùng packageType từ Firestore thay vì string matching tên gói.
  Future<void> cancelBooking(
    String bookingId, {
    bool isLateCancel = false,
    String? memberId,
  }) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);

    if (isLateCancel && memberId != null) {
      // Trừ 1 buổi khi hủy muộn – chỉ áp dụng cho gói session-based
      final memberDoc = await _db.collection('members').doc(memberId).get();
      if (memberDoc.exists) {
        final memberData = memberDoc.data()!;
        final sessionsRemaining = memberData['sessionsRemaining'] as int? ?? 0;
        final packageId = memberData['packageId'] as String?;

        if (sessionsRemaining > 0 && packageId != null) {
          // Fix #6: Kiểm tra packageType từ package document, không dùng tên gói
          final pkgDoc = await _db.collection('packages').doc(packageId).get();
          if (pkgDoc.exists) {
            final pkg = PackageModel.fromJson(pkgDoc.data()!, pkgDoc.id);
            if (pkg.isSessionBased) {
              await _db.collection('members').doc(memberId).update({
                'sessionsRemaining': sessionsRemaining - 1,
              });
            }
          }
        }
      }
    }
  }

  // ==================== ORDERS & PAYMENTS (V2) ====================

  Future<OrderModel> createOrder(OrderModel order) async {
    final ref = await _db.collection('orders').add(order.toJson());
    return OrderModel.fromJson(order.toJson(), ref.id);
  }

  Stream<List<OrderModel>> streamMemberOrders(String memberId) {
    return _db
        .collection('orders')
        .where('memberId', isEqualTo: memberId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => OrderModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  /// Tạo đơn mua gói online. Fix #4: Nếu có coupon, dùng Transaction atomic
  /// để kiểm tra và tăng usedCount cùng lúc, tránh race condition.
  Future<OrderModel> createOnlinePackageOrder({
    required String memberId,
    required PackageModel package,
    PaymentMethod paymentMethod = PaymentMethod.ewallet,
    String? couponCode,
    double discountAmount = 0,
    String? paymentNote,
  }) async {
    // Fix #4: Nếu có coupon, xử lý atomic trong Transaction
    if (couponCode != null && couponCode.isNotEmpty) {
      return await _db.runTransaction<OrderModel>((transaction) async {
        // Tìm coupon document
        final couponSnap = await _db
            .collection('coupons')
            .where('code', isEqualTo: couponCode.toUpperCase().trim())
            .limit(1)
            .get();

        if (couponSnap.docs.isEmpty) {
          throw Exception('Mã giảm giá không tồn tại.');
        }

        final couponDoc = couponSnap.docs.first;
        final coupon = CouponModel.fromJson(couponDoc.data(), couponDoc.id);

        // Kiểm tra coupon hợp lệ TRONG transaction
        if (!coupon.isValid) {
          throw Exception('Mã giảm giá đã hết hạn hoặc không còn hiệu lực.');
        }
        if (package.price < coupon.minOrderAmount) {
          throw Exception(
            'Đơn hàng chưa đủ điều kiện (tối thiểu ${coupon.minOrderAmount.toInt()} VNĐ).',
          );
        }
        if (coupon.applicablePackageIds.isNotEmpty &&
            !coupon.applicablePackageIds.contains(package.id)) {
          throw Exception('Mã giảm giá không áp dụng cho gói này.');
        }

        // Kiểm tra lại số lượng còn lại (trong transaction, tránh race condition)
        final currentUsed = couponDoc.data()['usedCount'] as int? ?? 0;
        final totalQty = couponDoc.data()['totalQuantity'] as int? ?? -1;
        if (totalQty != -1 && currentUsed >= totalQty) {
          throw Exception('Mã giảm giá đã hết lượt sử dụng.');
        }

        // Tính discount thực tế
        final actualDiscount = coupon.calculateDiscount(package.price,
            packageId: package.id);

        // Tăng usedCount trong cùng transaction
        transaction.update(couponDoc.reference, {
          'usedCount': FieldValue.increment(1),
        });

        // Tạo order document
        final orderRef = _db.collection('orders').doc();
        final order = OrderModel(
          id: orderRef.id,
          memberId: memberId,
          packageId: package.id,
          originalAmount: package.price,
          discountAmount: actualDiscount,
          finalAmount: package.price - actualDiscount,
          couponCode: couponCode.toUpperCase().trim(),
          paymentMethod: paymentMethod,
          paymentNote: paymentNote ?? 'online-package-purchase',
          status: OrderStatus.pending,
          createdAt: DateTime.now(),
        );
        transaction.set(orderRef, order.toJson());
        return order;
      });
    }

    // Không có coupon: tạo order bình thường
    final order = OrderModel(
      id: '',
      memberId: memberId,
      packageId: package.id,
      originalAmount: package.price,
      discountAmount: discountAmount,
      finalAmount: package.price - discountAmount,
      couponCode: couponCode,
      paymentMethod: paymentMethod,
      paymentNote: paymentNote ?? 'online-package-purchase',
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );
    return createOrder(order);
  }

  Future<void> processPayment(String orderId) async {
    await _db.collection('orders').doc(orderId).update({
      'status': OrderStatus.paid.name,
    });
    final orderDoc = await _db.collection('orders').doc(orderId).get();
    final order = OrderModel.fromJson(orderDoc.data()!, orderDoc.id);

    if (order.packageId != null) {
      final pkgDoc = await _db
          .collection('packages')
          .doc(order.packageId)
          .get();
      if (pkgDoc.exists) {
        final pkg = PackageModel.fromJson(pkgDoc.data()!, pkgDoc.id);
        await activateMember(
          order.memberId,
          pkg.durationDays,
          pkg.sessionCount,
        );
      }
    }
  }

  Future<void> markOrderPaid(String orderId, {String? paymentNote}) async {
    final updateData = <String, dynamic>{'status': OrderStatus.paid.name};
    if (paymentNote != null && paymentNote.isNotEmpty) {
      updateData['paymentNote'] = paymentNote;
    }
    await _db.collection('orders').doc(orderId).update(updateData);
    await processPayment(orderId);
  }

  Stream<List<OrderModel>> streamPendingOrders() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.pending.name)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => OrderModel.fromJson(d.data(), d.id))
                .toList();
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return list;
          },
        );
  }

  // ==================== BODY METRICS (V2) ====================

  Future<void> addBodyMetric(BodyMetricModel metric) async {
    await _db.collection('body_metrics').add(metric.toJson());
  }

  Stream<List<BodyMetricModel>> streamMemberMetrics(String memberId) {
    return _db
        .collection('body_metrics')
        .where('memberId', isEqualTo: memberId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BodyMetricModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  // ==================== GROUP CLASSES (V2) ====================

  Future<void> addGroupClass(GroupClassModel groupClass) async {
    await _db.collection('classes').add(groupClass.toJson());
  }

  Stream<List<GroupClassModel>> streamClasses() {
    return _db
        .collection('classes')
        .where('isActive', isEqualTo: true)
        .orderBy('startTime')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => GroupClassModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  /// Đăng ký tham gia lớp học nhóm. Fix #10: Kiểm tra đã đăng ký chưa.
  /// Throw exception nếu đã trong danh sách enrolled hoặc waitlist.
  Future<void> joinClass(String classId, String memberId) async {
    final doc = await _db.collection('classes').doc(classId).get();
    if (!doc.exists) throw Exception('Lớp học không tồn tại.');

    final groupClass = GroupClassModel.fromJson(doc.data()!, doc.id);

    // Fix #10: Kiểm tra xem member đã đăng ký chưa
    if (groupClass.enrolledMemberIds.contains(memberId)) {
      throw Exception('Bạn đã đăng ký lớp học này rồi.');
    }
    if (groupClass.waitlistMemberIds.contains(memberId)) {
      throw Exception('Bạn đang trong danh sách chờ của lớp học này.');
    }

    if (groupClass.isFull) {
      await _db.collection('classes').doc(classId).update({
        'waitlistMemberIds': FieldValue.arrayUnion([memberId]),
      });
    } else {
      await _db.collection('classes').doc(classId).update({
        'enrolledMemberIds': FieldValue.arrayUnion([memberId]),
      });
    }
  }

  // ==================== BRANCHES (V2) ====================

  Future<List<BranchModel>> getBranches() async {
    final snap = await _db.collection('branches').get();
    return snap.docs.map((d) => BranchModel.fromJson(d.data(), d.id)).toList();
  }

  // ==================== COUPONS / VOUCHERS ====================

  Stream<List<CouponModel>> streamCoupons() {
    return _db
        .collection('coupons')
        .orderBy('endDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CouponModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<CouponModel?> findCouponByCode(String code) async {
    final snap = await _db
        .collection('coupons')
        .where('code', isEqualTo: code.toUpperCase().trim())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return CouponModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<void> addCoupon(CouponModel coupon) async {
    await _db.collection('coupons').add(coupon.toJson());
  }

  Future<void> updateCoupon(String id, Map<String, dynamic> data) async {
    await _db.collection('coupons').doc(id).update(data);
  }

  Future<void> deleteCoupon(String id) async {
    await _db.collection('coupons').doc(id).delete();
  }

  Future<void> incrementCouponUsage(String couponId) async {
    await _db.collection('coupons').doc(couponId).update({
      'usedCount': FieldValue.increment(1),
    });
  }

  // ==================== PRODUCTS (POS / Kho) ====================

  Stream<List<ProductModel>> streamProducts() {
    return _db
        .collection('products')
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProductModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<List<ProductModel>> getProducts({bool onlyActive = true}) async {
    Query<Map<String, dynamic>> query = _db.collection('products');
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snap = await query.get();
    return snap.docs.map((d) => ProductModel.fromJson(d.data(), d.id)).toList();
  }

  Future<void> addProduct(ProductModel product) async {
    await _db.collection('products').add(product.toJson());
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _db.collection('products').doc(id).update(data);
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection('products').doc(id).delete();
  }

  Future<void> adjustStock(
    String productId,
    int delta, {
    String? reason,
  }) async {
    await _db.collection('products').doc(productId).update({
      'stock': FieldValue.increment(delta),
      'updatedAt': Timestamp.now(),
    });
    // Ghi log nhập/xuất kho để truy vết
    await _db.collection('stock_movements').add({
      'productId': productId,
      'delta': delta,
      'reason': reason ?? (delta > 0 ? 'Nhập kho' : 'Xuất kho'),
      'timestamp': Timestamp.now(),
    });
  }

  // ==================== SALES (POS) ====================

  /// Tạo đơn POS: trừ kho từng sản phẩm và lưu sale
  Future<SaleModel> createSale(SaleModel sale) async {
    final batch = _db.batch();

    // Trừ kho từng item
    for (final item in sale.items) {
      final productRef = _db.collection('products').doc(item.productId);
      batch.update(productRef, {
        'stock': FieldValue.increment(-item.quantity),
        'updatedAt': Timestamp.now(),
      });
    }

    final saleRef = _db.collection('sales').doc();
    batch.set(saleRef, sale.toJson());

    await batch.commit();
    return SaleModel.fromJson(sale.toJson(), saleRef.id);
  }

  Stream<List<SaleModel>> streamRecentSales({int limit = 50}) {
    return _db
        .collection('sales')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => SaleModel.fromJson(d.data(), d.id)).toList(),
        );
  }

  Future<List<SaleModel>> getSalesInRange(DateTime from, DateTime to) async {
    final snap = await _db
        .collection('sales')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();
    return snap.docs.map((d) => SaleModel.fromJson(d.data(), d.id)).toList();
  }

  // ==================== LOCKERS ====================

  Stream<List<LockerModel>> streamLockers() {
    return _db
        .collection('lockers')
        .orderBy('code')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => LockerModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<List<LockerModel>> getLockers() async {
    final snap = await _db.collection('lockers').orderBy('code').get();
    return snap.docs.map((d) => LockerModel.fromJson(d.data(), d.id)).toList();
  }

  Future<void> addLocker(LockerModel locker) async {
    await _db.collection('lockers').add(locker.toJson());
  }

  /// Gán tủ đồ cho hội viên. Fix #11: Kiểm tra hội viên chưa có tủ đang hoạt động.
  Future<void> assignLocker(
    String lockerId, {
    required String memberId,
    required String memberName,
    required int durationDays,
  }) async {
    // Fix #11: Kiểm tra member đã có tủ đang hoạt động chưa
    final existingLockers = await _db
        .collection('lockers')
        .where('assignedMemberId', isEqualTo: memberId)
        .where('status', isEqualTo: LockerStatus.assigned.name)
        .get();

    if (existingLockers.docs.isNotEmpty) {
      // Nếu tủ hiện tại đã hết hạn thì cho phép gán tủ mới
      final hasActiveLocker = existingLockers.docs.any((doc) {
        final expiryTs = doc.data()['expiryDate'];
        if (expiryTs == null) return true;
        final expiry = (expiryTs as Timestamp).toDate();
        return expiry.isAfter(DateTime.now()); // Còn hạn
      });

      if (hasActiveLocker) {
        throw Exception(
          'Hội viên này đã có tủ đồ đang sử dụng. '  
          'Vui lòng trả tủ cũ trước khi thuê tủ mới.',
        );
      }
    }

    final now = DateTime.now();
    await _db.collection('lockers').doc(lockerId).update({
      'status': LockerStatus.assigned.name,
      'assignedMemberId': memberId,
      'assignedMemberName': memberName,
      'assignedDate': Timestamp.fromDate(now),
      'expiryDate': Timestamp.fromDate(now.add(Duration(days: durationDays))),
    });
  }

  Future<void> releaseLocker(String lockerId) async {
    await _db.collection('lockers').doc(lockerId).update({
      'status': LockerStatus.available.name,
      'assignedMemberId': null,
      'assignedMemberName': null,
      'assignedDate': null,
      'expiryDate': null,
    });
  }

  Future<void> updateLocker(String id, Map<String, dynamic> data) async {
    await _db.collection('lockers').doc(id).update(data);
  }

  Future<void> deleteLocker(String id) async {
    await _db.collection('lockers').doc(id).delete();
  }

  // ==================== PT SESSIONS / Buổi PT ====================

  Future<PtSessionModel> addPtSession(PtSessionModel session) async {
    final ref = await _db.collection('pt_sessions').add(session.toJson());
    return PtSessionModel.fromJson(session.toJson(), ref.id);
  }

  Stream<List<PtSessionModel>> streamTrainerSessions(String trainerId) {
    return _db
        .collection('pt_sessions')
        .where('trainerId', isEqualTo: trainerId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => PtSessionModel.fromJson(d.data(), d.id))
                .toList();
            list.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
            return list;
          },
        );
  }

  Stream<List<PtSessionModel>> streamMemberSessions(String memberId) {
    return _db
        .collection('pt_sessions')
        .where('memberId', isEqualTo: memberId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => PtSessionModel.fromJson(d.data(), d.id))
                .toList();
            list.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
            return list;
          },
        );
  }

  Future<void> updatePtSession(String id, Map<String, dynamic> data) async {
    await _db.collection('pt_sessions').doc(id).update(data);
  }

  /// HLV chấm buổi tập đã hoàn thành: trừ buổi của hội viên + cộng hoa hồng
  Future<void> completePtSession(
    String sessionId, {
    required String memberId,
    required double commission,
    String? trainerNote,
  }) async {
    final batch = _db.batch();

    final sessionRef = _db.collection('pt_sessions').doc(sessionId);
    final updateData = <String, dynamic>{
      'status': PtSessionStatus.completed.name,
      'trainerCommission': commission,
    };
    if (trainerNote != null) {
      updateData['trainerNote'] = trainerNote;
    }
    batch.update(sessionRef, updateData);

    final memberRef = _db.collection('members').doc(memberId);
    batch.update(memberRef, {'sessionsRemaining': FieldValue.increment(-1)});

    await batch.commit();
  }

  /// Tổng hoa hồng PT trong khoảng thời gian
  Future<double> getTrainerCommissionTotal(
    String trainerId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final snap = await _db
        .collection('pt_sessions')
        .where('trainerId', isEqualTo: trainerId)
        .where('status', isEqualTo: PtSessionStatus.completed.name)
        .where('sessionDate', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('sessionDate', isLessThanOrEqualTo: Timestamp.fromDate(to))
        .get();
    return snap.docs.fold<double>(
      0,
      (total, d) =>
          total + ((d.data()['trainerCommission'] ?? 0) as num).toDouble(),
    );
  }

  // ==================== BODY METRICS - Helper bổ sung ====================

  Future<BodyMetricModel?> getLatestMetric(String memberId) async {
    final snap = await _db
        .collection('body_metrics')
        .where('memberId', isEqualTo: memberId)
        .get();
    if (snap.docs.isEmpty) return null;
    // Sort phía client, lấy bản ghi mới nhất
    final list = snap.docs
        .map((d) => BodyMetricModel.fromJson(d.data(), d.id))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list.first;
  }

  Future<List<BodyMetricModel>> getMemberMetrics(String memberId) async {
    final snap = await _db
        .collection('body_metrics')
        .where('memberId', isEqualTo: memberId)
        .get();
    final list = snap.docs
        .map((d) => BodyMetricModel.fromJson(d.data(), d.id))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ==================== STAFF ATTENDANCE ====================

  Stream<List<StaffAttendanceModel>> streamAttendanceForUser(String userId) {
    return _db
        .collection('staff_attendance')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snap) {
            final list = snap.docs
                .map((d) => StaffAttendanceModel.fromJson(d.data(), d.id))
                .toList();
            list.sort((a, b) => b.clockInAt.compareTo(a.clockInAt));
            return list;
          },
        );
  }

  Future<StaffAttendanceModel> clockInStaff(StaffAttendanceModel attendance) async {
    final ref = await _db.collection('staff_attendance').add(attendance.toJson());
    return StaffAttendanceModel.fromJson(attendance.toJson(), ref.id);
  }

  Future<void> clockOutStaff(String attendanceId, {String? note}) async {
    final updateData = <String, dynamic>{
      'clockOutAt': Timestamp.fromDate(DateTime.now()),
      'status': AttendanceStatus.completed.name,
    };
    if (note != null) {
      updateData['note'] = note;
    }
    await _db.collection('staff_attendance').doc(attendanceId).update(updateData);
  }

  // ==================== WORK SHIFTS ====================

  Stream<List<WorkShiftModel>> streamShiftsForUser(String userId) {
    return _db
        .collection('work_shifts')
        .where('userId', isEqualTo: userId)
        .where('isPublished', isEqualTo: true)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => WorkShiftModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> addWorkShift(WorkShiftModel shift) async {
    await _db.collection('work_shifts').add(shift.toJson());
  }
}
