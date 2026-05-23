import 'package:cloud_firestore/cloud_firestore.dart';

enum CheckInMethod { qr, manual, rfid, face }

class CheckInModel {
  final String id;
  final String memberId;
  final String memberName;
  final String? staffId;
  final String? staffName;
  final DateTime timestamp;
  final CheckInMethod method;
  final bool isSuccess;
  final String? note;

  CheckInModel({
    required this.id,
    required this.memberId,
    required this.memberName,
    this.staffId,
    this.staffName,
    required this.timestamp,
    required this.method,
    this.isSuccess = true,
    this.note,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json, String id) {
    return CheckInModel(
      id: id,
      memberId: json['memberId'] ?? '',
      memberName: json['memberName'] ?? '',
      staffId: json['staffId'],
      staffName: json['staffName'],
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : (json['timestamp'] is String
              ? DateTime.tryParse(json['timestamp']) ?? DateTime(2000)
              : DateTime(2000)),
      method: CheckInMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => CheckInMethod.manual,
      ),
      isSuccess: json['isSuccess'] ?? true,
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'memberName': memberName,
        'staffId': staffId,
        'staffName': staffName,
        'timestamp': Timestamp.fromDate(timestamp),
        'method': method.name,
        'isSuccess': isSuccess,
        'note': note,
      };
}
