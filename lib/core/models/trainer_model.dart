import 'package:cloud_firestore/cloud_firestore.dart';

class TrainerModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final String specialization;
  final String? bio;
  final List<String> studentIds;
  final double rating;
  final int experience; // years
  final bool isAvailable;
  final DateTime joinDate;
  final List<String> certifications;
  final double? salary;
  final int maxSlots;
  final String? workingHours;
  final String branchId;

  TrainerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    required this.specialization,
    this.bio,
    required this.studentIds,
    this.rating = 0.0,
    this.experience = 0,
    this.isAvailable = true,
    required this.joinDate,
    this.certifications = const [],
    this.salary,
    this.maxSlots = 1,
    this.workingHours,
    this.branchId = 'main',
  });

  int get totalStudents => studentIds.length;

  factory TrainerModel.fromJson(Map<String, dynamic> json, String id) {
    return TrainerModel(
      id: id,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      specialization: json['specialization'] ?? 'General Fitness',
      bio: json['bio'],
      studentIds: List<String>.from(json['studentIds'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      experience: json['experience'] ?? 0,
      isAvailable: json['isAvailable'] ?? true,
      joinDate: json['joinDate'] is Timestamp
          ? (json['joinDate'] as Timestamp).toDate()
          : DateTime.now(),
      certifications: List<String>.from(json['certifications'] ?? []),
      salary: json['salary']?.toDouble(),
      maxSlots: json['maxSlots'] ?? 1,
      workingHours: json['workingHours'],
      branchId: json['branchId'] ?? 'main',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'specialization': specialization,
        'bio': bio,
        'studentIds': studentIds,
        'rating': rating,
        'experience': experience,
        'isAvailable': isAvailable,
        'joinDate': Timestamp.fromDate(joinDate),
        'certifications': certifications,
        'salary': salary,
        'maxSlots': maxSlots,
        'workingHours': workingHours,
        'branchId': branchId,
      };

  TrainerModel copyWith({
    String? name,
    String? phone,
    String? avatar,
    String? specialization,
    String? bio,
    List<String>? studentIds,
    double? rating,
    int? experience,
    bool? isAvailable,
    List<String>? certifications,
    double? salary,
    int? maxSlots,
    String? workingHours,
    String? branchId,
  }) {
    return TrainerModel(
      id: id,
      userId: userId,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      specialization: specialization ?? this.specialization,
      bio: bio ?? this.bio,
      studentIds: studentIds ?? this.studentIds,
      rating: rating ?? this.rating,
      experience: experience ?? this.experience,
      isAvailable: isAvailable ?? this.isAvailable,
      joinDate: joinDate,
      certifications: certifications ?? this.certifications,
      salary: salary ?? this.salary,
      maxSlots: maxSlots ?? this.maxSlots,
      workingHours: workingHours ?? this.workingHours,
      branchId: branchId ?? this.branchId,
    );
  }
}
