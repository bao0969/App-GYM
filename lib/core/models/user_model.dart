import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, staff, trainer, member }

extension UserRoleExtension on UserRole {
  String get roleLabel {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Nhân Viên';
      case UserRole.trainer:
        return 'Huấn Luyện Viên';
      case UserRole.member:
        return 'Hội Viên';
    }
  }
}

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String? avatar;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;
  final String branchId; // Multi-branch support

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.avatar,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.branchId = 'main',
  });

  String get roleLabel {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.staff:
        return 'Nhân Viên';
      case UserRole.trainer:
        return 'Huấn Luyện Viên';
      case UserRole.member:
        return 'Hội Viên';
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatar: json['avatar'],
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.member,
      ),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      branchId: json['branchId'] ?? 'main', // Fallback for migration
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'avatar': avatar,
        'role': role.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
        'branchId': branchId,
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? avatar,
    UserRole? role,
    bool? isActive,
    String? branchId,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      branchId: branchId ?? this.branchId,
    );
  }
}
