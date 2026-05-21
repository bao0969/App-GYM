import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, paid, cancelled }
enum PaymentMethod { cash, transfer, ewallet, pos }

class OrderModel {
  final String id;
  final String memberId;
  final String? packageId;
  final double originalAmount;
  final double discountAmount;
  final double finalAmount;
  final String? couponCode;
  final PaymentMethod paymentMethod;
  final String? paymentNote;
  final OrderStatus status;
  final DateTime createdAt;
  final String? staffId; // Người xử lý đơn
  final String branchId;

  OrderModel({
    required this.id,
    required this.memberId,
    this.packageId,
    required this.originalAmount,
    this.discountAmount = 0.0,
    required this.finalAmount,
    this.couponCode,
    required this.paymentMethod,
    this.paymentNote,
    this.status = OrderStatus.pending,
    required this.createdAt,
    this.staffId,
    this.branchId = 'main',
  });

  factory OrderModel.fromJson(Map<String, dynamic> json, String id) {
    return OrderModel(
      id: id,
      memberId: json['memberId'] ?? '',
      packageId: json['packageId'],
      originalAmount: (json['originalAmount'] ?? 0).toDouble(),
      discountAmount: (json['discountAmount'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      couponCode: json['couponCode'],
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentNote: json['paymentNote'],
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      staffId: json['staffId'],
      branchId: json['branchId'] ?? 'main',
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'packageId': packageId,
        'originalAmount': originalAmount,
        'discountAmount': discountAmount,
        'finalAmount': finalAmount,
        'couponCode': couponCode,
        'paymentMethod': paymentMethod.name,
        'paymentNote': paymentNote,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'staffId': staffId,
        'branchId': branchId,
      };
}
