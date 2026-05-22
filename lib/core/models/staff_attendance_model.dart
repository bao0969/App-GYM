import 'package:cloud_firestore/cloud_firestore.dart';

enum EmployeeRole { staff, trainer }

enum AttendanceStatus { open, completed }

class StaffAttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final EmployeeRole role;
  final String? shiftId;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final AttendanceStatus status;
  final String? note;

  StaffAttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    this.shiftId,
    required this.clockInAt,
    this.clockOutAt,
    this.status = AttendanceStatus.open,
    this.note,
  });

  Duration? get workedDuration {
    if (clockOutAt == null) {
      return null;
    }
    return clockOutAt!.difference(clockInAt);
  }

  factory StaffAttendanceModel.fromJson(Map<String, dynamic> json, String id) {
    return StaffAttendanceModel(
      id: id,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      role: EmployeeRole.values.firstWhere(
        (value) => value.name == json['role'],
        orElse: () => EmployeeRole.staff,
      ),
      shiftId: json['shiftId'],
      clockInAt: (json['clockInAt'] as Timestamp).toDate(),
      clockOutAt: json['clockOutAt'] is Timestamp
          ? (json['clockOutAt'] as Timestamp).toDate()
          : null,
      status: AttendanceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => AttendanceStatus.open,
      ),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'role': role.name,
        'shiftId': shiftId,
        'clockInAt': Timestamp.fromDate(clockInAt),
        'clockOutAt': clockOutAt != null
            ? Timestamp.fromDate(clockOutAt!)
            : null,
        'status': status.name,
        'note': note,
      };
}
