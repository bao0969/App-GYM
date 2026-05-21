import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingType { pt, classSession, room }

// ignore: constant_identifier_names
enum BookingStatus { pending, confirmed, cancelled, completed, noShow }

class BookingModel {
  final String id;
  final String memberId;
  final String memberName;
  final BookingType type;

  // Thông tin liên quan tuỳ theo loại booking
  final String? trainerId;
  final String? trainerName;
  final String? classId;
  final String? className;

  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final String notes;

  BookingModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.type,
    this.trainerId,
    this.trainerName,
    this.classId,
    this.className,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes = '',
  });

  factory BookingModel.fromJson(Map<String, dynamic> json, String id) {
    return BookingModel(
      id: id,
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      type: BookingType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BookingType.pt,
      ),
      trainerId: json['trainerId'],
      trainerName: json['trainerName'],
      classId: json['classId'],
      className: json['className'],
      startTime: (json['startTime'] as Timestamp).toDate(),
      endTime: (json['endTime'] as Timestamp).toDate(),
      status: BookingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BookingStatus.pending,
      ),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId,
      'memberName': memberName,
      'type': type.name,
      'trainerId': trainerId,
      'trainerName': trainerName,
      'classId': classId,
      'className': className,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status.name,
      'notes': notes,
    };
  }

  BookingModel copyWith({
    String? id,
    String? memberId,
    String? memberName,
    BookingType? type,
    String? trainerId,
    String? trainerName,
    String? classId,
    String? className,
    DateTime? startTime,
    DateTime? endTime,
    BookingStatus? status,
    String? notes,
  }) {
    return BookingModel(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      memberName: memberName ?? this.memberName,
      type: type ?? this.type,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
