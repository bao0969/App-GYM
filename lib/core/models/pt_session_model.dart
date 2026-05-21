import 'package:cloud_firestore/cloud_firestore.dart';

enum PtSessionStatus { scheduled, completed, missed, cancelled }

/// 1 buổi PT (Personal Training) - dùng để chấm công, tính hoa hồng cho HLV
class PtSessionModel {
  final String id;
  final String trainerId;
  final String trainerName;
  final String memberId;
  final String memberName;
  final DateTime sessionDate;
  final int durationMinutes;
  final PtSessionStatus status;
  final String? workoutFocus; // VD: "Ngực + Tay sau"
  final String? trainerNote; // Đánh giá của HLV
  final int? memberRating; // 1-5
  final String? memberFeedback;
  final double trainerCommission; // Tiền hoa hồng PT cho buổi này
  final String? bookingId; // Liên kết với booking nếu có
  final DateTime createdAt;

  PtSessionModel({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    required this.memberId,
    required this.memberName,
    required this.sessionDate,
    this.durationMinutes = 60,
    this.status = PtSessionStatus.scheduled,
    this.workoutFocus,
    this.trainerNote,
    this.memberRating,
    this.memberFeedback,
    this.trainerCommission = 0,
    this.bookingId,
    required this.createdAt,
  });

  String get statusLabel {
    switch (status) {
      case PtSessionStatus.scheduled:
        return 'Đã Lên Lịch';
      case PtSessionStatus.completed:
        return 'Hoàn Thành';
      case PtSessionStatus.missed:
        return 'Vắng Mặt';
      case PtSessionStatus.cancelled:
        return 'Đã Huỷ';
    }
  }

  factory PtSessionModel.fromJson(Map<String, dynamic> json, String id) {
    return PtSessionModel(
      id: id,
      trainerId: json['trainerId'] ?? '',
      trainerName: json['trainerName'] ?? '',
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      sessionDate: json['sessionDate'] is Timestamp
          ? (json['sessionDate'] as Timestamp).toDate()
          : DateTime.now(),
      durationMinutes: json['durationMinutes'] ?? 60,
      status: PtSessionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => PtSessionStatus.scheduled,
      ),
      workoutFocus: json['workoutFocus'],
      trainerNote: json['trainerNote'],
      memberRating: json['memberRating'],
      memberFeedback: json['memberFeedback'],
      trainerCommission: (json['trainerCommission'] ?? 0).toDouble(),
      bookingId: json['bookingId'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'trainerId': trainerId,
    'trainerName': trainerName,
    'memberId': memberId,
    'memberName': memberName,
    'sessionDate': Timestamp.fromDate(sessionDate),
    'durationMinutes': durationMinutes,
    'status': status.name,
    'workoutFocus': workoutFocus,
    'trainerNote': trainerNote,
    'memberRating': memberRating,
    'memberFeedback': memberFeedback,
    'trainerCommission': trainerCommission,
    'bookingId': bookingId,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
