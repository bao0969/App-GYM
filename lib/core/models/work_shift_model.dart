import 'package:cloud_firestore/cloud_firestore.dart';
import 'staff_attendance_model.dart';

class WorkShiftModel {
  final String id;
  final String userId;
  final String userName;
  final EmployeeRole role;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? note;
  final bool isPublished;

  WorkShiftModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.note,
    this.isPublished = true,
  });

  factory WorkShiftModel.fromJson(Map<String, dynamic> json, String id) {
    return WorkShiftModel(
      id: id,
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      role: EmployeeRole.values.firstWhere(
        (value) => value.name == json['role'],
        orElse: () => EmployeeRole.staff,
      ),
      title: json['title'] ?? '',
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      note: json['note'],
      isPublished: json['isPublished'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'role': role.name,
        'title': title,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'note': note,
        'isPublished': isPublished,
      };
}
