import 'package:cloud_firestore/cloud_firestore.dart';

enum MemberStatus { pending, active, paused, frozen }

class MemberModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final String? packageId;
  final String? packageName;
  final DateTime? packageExpiry;
  final MemberStatus status; // DB status
  final String qrCode;
  final String? trainerId;
  final DateTime joinDate;
  final String? address;
  final String? notes;
  final int sessionsRemaining;
  final String branchId;

  MemberModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    this.packageId,
    this.packageName,
    this.packageExpiry,
    required this.status,
    required this.qrCode,
    this.trainerId,
    required this.joinDate,
    this.address,
    this.notes,
    this.sessionsRemaining = 0,
    this.branchId = 'main',
  });

  /// Trạng thái tính toán dựa trên ngày hết hạn (dùng cho UI & check-in)
  /// Lưu ý: currentStatus khác với status (DB enum).
  /// - status (DB): pending | active | paused | frozen  ← lưu trong Firestore
  /// - currentStatus (computed): thêm 'expired' và 'expiring_soon' dựa trên packageExpiry
  String get currentStatus {
    if (status == MemberStatus.active && packageExpiry != null) {
      final now = DateTime.now();
      if (packageExpiry!.isBefore(now)) {
        return 'expired';
      }
      final diff = packageExpiry!.difference(now).inDays;
      if (diff <= 7) {
        return 'expiring_soon';
      }
    }
    return status.name; // 'pending', 'active', 'paused', 'frozen'
  }

  /// Kiểm tra DB status có phải active không (dùng cho pause/unfreeze logic)
  /// Khác với isActive (computed), isDbActive không phụ thuộc vào expiry date
  bool get isDbActive => status == MemberStatus.active;

  String get statusLabel {
    final s = currentStatus;
    switch (s) {
      case 'active':
        return 'Hoạt Động';
      case 'pending':
        return 'Chờ Kích Hoạt';
      case 'expiring_soon':
        return 'Sắp Hết Hạn';
      case 'expired':
        return 'Hết Hạn';
      case 'paused':
        return 'Tạm Dừng';
      case 'frozen':
        return 'Đã Khóa';
      default:
        return 'Không Rõ';
    }
  }

  bool get isActive => currentStatus == 'active' || currentStatus == 'expiring_soon';

  int get daysRemaining {
    if (packageExpiry == null) return 0;
    final diff = packageExpiry!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  factory MemberModel.fromJson(Map<String, dynamic> json, String id) {
    return MemberModel(
      id: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      packageId: json['packageId'],
      packageName: json['packageName'],
      packageExpiry: json['packageExpiry'] is Timestamp
          ? (json['packageExpiry'] as Timestamp).toDate()
          : null,
      status: MemberStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MemberStatus.active,
      ),
      qrCode: json['qrCode'] ?? id,
      trainerId: json['trainerId'],
      joinDate: json['joinDate'] is Timestamp
          ? (json['joinDate'] as Timestamp).toDate()
          : DateTime.now(),
      address: json['address'],
      notes: json['notes'],
      sessionsRemaining: json['sessionsRemaining'] ?? 0,
      branchId: json['branchId'] ?? 'main',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'packageId': packageId,
        'packageName': packageName,
        'packageExpiry': packageExpiry != null
            ? Timestamp.fromDate(packageExpiry!)
            : null,
        'status': status.name,
        'qrCode': qrCode,
        'trainerId': trainerId,
        'joinDate': Timestamp.fromDate(joinDate),
        'address': address,
        'notes': notes,
        'sessionsRemaining': sessionsRemaining,
        'branchId': branchId,
      };

  MemberModel copyWith({
    String? name,
    String? phone,
    String? avatar,
    String? packageId,
    String? packageName,
    DateTime? packageExpiry,
    MemberStatus? status,
    String? trainerId,
    String? address,
    String? notes,
    int? sessionsRemaining,
    String? branchId,
  }) {
    return MemberModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      packageId: packageId ?? this.packageId,
      packageName: packageName ?? this.packageName,
      packageExpiry: packageExpiry ?? this.packageExpiry,
      status: status ?? this.status,
      qrCode: qrCode,
      trainerId: trainerId ?? this.trainerId,
      joinDate: joinDate,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      sessionsRemaining: sessionsRemaining ?? this.sessionsRemaining,
      branchId: branchId ?? this.branchId,
    );
  }
}
