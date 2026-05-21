import 'package:cloud_firestore/cloud_firestore.dart';

class GroupClassModel {
  final String id;
  final String name;
  final String trainerId;
  final String trainerName;
  final String branchId;
  final DateTime startTime;
  final DateTime endTime;
  final int maxSlots;
  final List<String> enrolledMemberIds;
  final List<String> waitlistMemberIds;
  final bool isActive;

  GroupClassModel({
    required this.id,
    required this.name,
    required this.trainerId,
    required this.trainerName,
    this.branchId = 'main',
    required this.startTime,
    required this.endTime,
    required this.maxSlots,
    this.enrolledMemberIds = const [],
    this.waitlistMemberIds = const [],
    this.isActive = true,
  });

  int get availableSlots => maxSlots - enrolledMemberIds.length;
  bool get isFull => availableSlots <= 0;

  factory GroupClassModel.fromJson(Map<String, dynamic> json, String id) {
    return GroupClassModel(
      id: id,
      name: json['name'] ?? '',
      trainerId: json['trainerId'] ?? '',
      trainerName: json['trainerName'] ?? '',
      branchId: json['branchId'] ?? 'main',
      startTime: json['startTime'] is Timestamp
          ? (json['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: json['endTime'] is Timestamp
          ? (json['endTime'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 1)),
      maxSlots: json['maxSlots'] ?? 20,
      enrolledMemberIds: List<String>.from(json['enrolledMemberIds'] ?? []),
      waitlistMemberIds: List<String>.from(json['waitlistMemberIds'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'trainerId': trainerId,
        'trainerName': trainerName,
        'branchId': branchId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'maxSlots': maxSlots,
        'enrolledMemberIds': enrolledMemberIds,
        'waitlistMemberIds': waitlistMemberIds,
        'isActive': isActive,
      };
}
