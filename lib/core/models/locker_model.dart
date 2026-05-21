import 'package:cloud_firestore/cloud_firestore.dart';

enum LockerStatus { available, assigned, maintenance, broken }

class LockerModel {
  final String id;
  final String code; // VD: A001, B015
  final String area; // Khu A, Khu B (nam/nữ)
  final LockerStatus status;
  final String? assignedMemberId;
  final String? assignedMemberName;
  final DateTime? assignedDate;
  final DateTime? expiryDate; // Hạn sử dụng tủ
  final double monthlyFee;
  final String? note;
  final String branchId;

  LockerModel({
    required this.id,
    required this.code,
    required this.area,
    this.status = LockerStatus.available,
    this.assignedMemberId,
    this.assignedMemberName,
    this.assignedDate,
    this.expiryDate,
    this.monthlyFee = 100000,
    this.note,
    this.branchId = 'main',
  });

  bool get isAvailable => status == LockerStatus.available;
  bool get isExpired =>
      expiryDate != null && DateTime.now().isAfter(expiryDate!);

  String get statusLabel {
    if (status == LockerStatus.assigned && isExpired) return 'Hết Hạn';
    switch (status) {
      case LockerStatus.available:
        return 'Trống';
      case LockerStatus.assigned:
        return 'Đang Dùng';
      case LockerStatus.maintenance:
        return 'Bảo Trì';
      case LockerStatus.broken:
        return 'Hỏng';
    }
  }

  factory LockerModel.fromJson(Map<String, dynamic> json, String id) {
    return LockerModel(
      id: id,
      code: json['code'] ?? '',
      area: json['area'] ?? 'A',
      status: LockerStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => LockerStatus.available,
      ),
      assignedMemberId: json['assignedMemberId'],
      assignedMemberName: json['assignedMemberName'],
      assignedDate: json['assignedDate'] is Timestamp
          ? (json['assignedDate'] as Timestamp).toDate()
          : null,
      expiryDate: json['expiryDate'] is Timestamp
          ? (json['expiryDate'] as Timestamp).toDate()
          : null,
      monthlyFee: (json['monthlyFee'] ?? 100000).toDouble(),
      note: json['note'],
      branchId: json['branchId'] ?? 'main',
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'area': area,
    'status': status.name,
    'assignedMemberId': assignedMemberId,
    'assignedMemberName': assignedMemberName,
    'assignedDate': assignedDate != null
        ? Timestamp.fromDate(assignedDate!)
        : null,
    'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    'monthlyFee': monthlyFee,
    'note': note,
    'branchId': branchId,
  };
}
