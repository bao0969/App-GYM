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

  Future<void> updateMember(String id, Map<String, dynamic> data) async {
    await _db.collection('members').doc(id).update(data);
  }

  Future<void> deleteMember(String id) async {
    await _db.collection('members').doc(id).delete();
  }

  Future<void> activateMember(
    String id,
    int durationDays,
    int sessionCount,
  ) async {
    final now = DateTime.now();
    await updateMember(id, {
      'status': MemberStatus.active.name,
      'packageExpiry': Timestamp.fromDate(
        now.add(Duration(days: durationDays)),
      ),
      'sessionsRemaining': sessionCount,
    });
  }

  Future<void> pauseMember(String id, int daysToPause) async {
    final memberDoc = await _db.collection('members').doc(id).get();
    if (!memberDoc.exists) return;

    final member = MemberModel.fromJson(memberDoc.data()!, memberDoc.id);
    if (member.currentStatus == 'active' && member.packageExpiry != null) {
      final newExpiry = member.packageExpiry!.add(Duration(days: daysToPause));
      await updateMember(id, {
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
        .orderBy('joinDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MemberModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Future<List<MemberModel>> getTrainerMembers(String trainerId) async {
    final snap = await _db
        .collection('members')
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('joinDate', descending: true)
        .get();
    return snap.docs.map((d) => MemberModel.fromJson(d.data(), d.id)).toList();
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

  /// Thêm check-in với logic chống spam và trừ buổi (V2)
  Future<CheckInModel> addCheckIn(CheckInModel checkIn) async {
    final memberDoc = await _db
        .collection('members')
        .doc(checkIn.memberId)
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

    // Rule 3: Deduct session if applicable
    if (member.sessionsRemaining > 0) {
      await updateMember(member.id, {
        'sessionsRemaining': member.sessionsRemaining - 1,
      });
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
    final startOfDay = DateTime.now().copyWith(
      hour: 0,
      minute: 0,
      second: 0,
      millisecond: 0,
    );
    final snap = await _db
        .collection('checkins')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((d) => CheckInModel.fromJson(d.data(), d.id)).toList();
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
    final members = await getMembers();
    final trainers = await getTrainers();

    final now = DateTime.now();
    final startOfDay = now.copyWith(hour: 0, minute: 0, second: 0);
    final startOfMonth = DateTime(now.year, now.month, 1);

    final todayCheckins = await _db
        .collection('checkins')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(startOfDay))
        .get();

    final activeMembers = members.where((m) => m.isActive).length;
    final expiredMembers = members
        .where((m) => m.currentStatus == 'expired')
        .length;
    final newThisMonth = members
        .where((m) => m.joinDate.isAfter(startOfMonth))
        .length;

    return {
      'totalMembers': members.length,
      'activeMembers': activeMembers,
      'expiredMembers': expiredMembers,
      'newMembersThisMonth': newThisMonth,
      'totalTrainers': trainers.length,
      'todayCheckIns': todayCheckins.docs.length,
    };
  }

  // ==================== BOOKINGS ====================

  Future<BookingModel> addBooking(BookingModel booking) async {
    final ref = await _db.collection('bookings').add(booking.toJson());
    return booking.copyWith(id: ref.id);
  }

  Stream<List<BookingModel>> streamTrainerBookings(String trainerId) {
    return _db
        .collection('bookings')
        .where('trainerId', isEqualTo: trainerId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BookingModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<BookingModel>> streamMemberBookings(String memberId) {
    return _db
        .collection('bookings')
        .where('memberId', isEqualTo: memberId)
        .orderBy('startTime', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BookingModel.fromJson(d.data(), d.id))
              .toList(),
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

  Future<void> cancelBooking(String bookingId, {bool isLateCancel = false, String? memberId}) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);
    
    if (isLateCancel && memberId != null) {
      // Deduct 1 session for late cancellation if applicable
      final memberDoc = await _db.collection('members').doc(memberId).get();
      if (memberDoc.exists) {
        final data = memberDoc.data()!;
        final packageName = (data['packageName'] as String?)?.toLowerCase() ?? '';
        final sessionsRemaining = data['sessionsRemaining'] as int? ?? 0;
        
        if ((packageName.contains('buổi') || packageName.contains('session')) && sessionsRemaining > 0) {
          await _db.collection('members').doc(memberId).update({
            'sessionsRemaining': sessionsRemaining - 1,
          });
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

  Future<OrderModel> createOnlinePackageOrder({
    required String memberId,
    required PackageModel package,
    PaymentMethod paymentMethod = PaymentMethod.ewallet,
    String? couponCode,
    double discountAmount = 0,
    String? paymentNote,
  }) async {
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

  Future<void> joinClass(String classId, String memberId) async {
    final doc = await _db.collection('classes').doc(classId).get();
    final groupClass = GroupClassModel.fromJson(doc.data()!, doc.id);

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

  Future<void> assignLocker(
    String lockerId, {
    required String memberId,
    required String memberName,
    required int durationDays,
  }) async {
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
        .orderBy('sessionDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PtSessionModel.fromJson(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<PtSessionModel>> streamMemberSessions(String memberId) {
    return _db
        .collection('pt_sessions')
        .where('memberId', isEqualTo: memberId)
        .orderBy('sessionDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PtSessionModel.fromJson(d.data(), d.id))
              .toList(),
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
        .orderBy('date', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return BodyMetricModel.fromJson(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<List<BodyMetricModel>> getMemberMetrics(String memberId) async {
    final snap = await _db
        .collection('body_metrics')
        .where('memberId', isEqualTo: memberId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs
        .map((d) => BodyMetricModel.fromJson(d.data(), d.id))
        .toList();
  }

  // ==================== STAFF ATTENDANCE ====================

  Stream<List<StaffAttendanceModel>> streamAttendanceForUser(String userId) {
    return _db
        .collection('staff_attendance')
        .where('userId', isEqualTo: userId)
        .orderBy('clockInAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => StaffAttendanceModel.fromJson(d.data(), d.id))
              .toList(),
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
