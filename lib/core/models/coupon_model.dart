import 'package:cloud_firestore/cloud_firestore.dart';

enum CouponType { percent, fixed }

class CouponModel {
  final String id;
  final String code; // Mã VOUCHER (uppercase)
  final String description;
  final CouponType type;
  final double value; // % nếu type=percent, VNĐ nếu type=fixed
  final double? maxDiscount; // Trần giảm khi dùng percent
  final double minOrderAmount; // Đơn tối thiểu để áp dụng
  final int totalQuantity; // Số lượng phát hành (-1 = không giới hạn)
  final int usedCount; // Đã dùng
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final List<String> applicablePackageIds; // Rỗng = áp dụng tất cả gói

  CouponModel({
    required this.id,
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    this.maxDiscount,
    this.minOrderAmount = 0,
    this.totalQuantity = -1,
    this.usedCount = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.applicablePackageIds = const [],
  });

  bool get isValid {
    final now = DateTime.now();
    if (!isActive) return false;
    if (now.isBefore(startDate) || now.isAfter(endDate)) return false;
    if (totalQuantity != -1 && usedCount >= totalQuantity) return false;
    return true;
  }

  int get remainingQuantity =>
      totalQuantity == -1 ? -1 : (totalQuantity - usedCount);

  /// Tính số tiền giảm cho 1 đơn hàng. Trả về 0 nếu không hợp lệ.
  double calculateDiscount(double orderAmount, {String? packageId}) {
    if (!isValid) return 0;
    if (orderAmount < minOrderAmount) return 0;
    if (applicablePackageIds.isNotEmpty &&
        packageId != null &&
        !applicablePackageIds.contains(packageId)) {
      return 0;
    }

    double discount;
    if (type == CouponType.percent) {
      discount = orderAmount * value / 100;
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      discount = value;
    }

    if (discount > orderAmount) discount = orderAmount;
    return discount;
  }

  String get valueLabel {
    if (type == CouponType.percent) {
      return '-${value.toInt()}%';
    }
    if (value >= 1000000) {
      return '-${(value / 1000000).toStringAsFixed(1)}M';
    }
    return '-${(value / 1000).toInt()}K';
  }

  factory CouponModel.fromJson(Map<String, dynamic> json, String id) {
    return CouponModel(
      id: id,
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      type: CouponType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CouponType.fixed,
      ),
      value: (json['value'] ?? 0).toDouble(),
      maxDiscount: json['maxDiscount']?.toDouble(),
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      totalQuantity: json['totalQuantity'] ?? -1,
      usedCount: json['usedCount'] ?? 0,
      startDate: json['startDate'] is Timestamp
          ? (json['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: json['endDate'] is Timestamp
          ? (json['endDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 30)),
      isActive: json['isActive'] ?? true,
      applicablePackageIds: List<String>.from(
        json['applicablePackageIds'] ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'description': description,
    'type': type.name,
    'value': value,
    'maxDiscount': maxDiscount,
    'minOrderAmount': minOrderAmount,
    'totalQuantity': totalQuantity,
    'usedCount': usedCount,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'isActive': isActive,
    'applicablePackageIds': applicablePackageIds,
  };
}
