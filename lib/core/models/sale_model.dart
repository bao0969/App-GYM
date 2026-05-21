import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_model.dart';

class SaleItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  }) : subtotal = quantity * unitPrice;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'subtotal': subtotal,
  };
}

/// Đơn hàng POS bán lẻ tại quầy (nước, supplement...)
class SaleModel {
  final String id;
  final List<SaleItem> items;
  final String? memberId; // Có thể bán cho vãng lai
  final String? memberName;
  final double total;
  final double discount;
  final double finalAmount;
  final PaymentMethod paymentMethod;
  final String? staffId;
  final String? staffName;
  final DateTime createdAt;
  final String branchId;
  final String? note;

  SaleModel({
    required this.id,
    required this.items,
    this.memberId,
    this.memberName,
    required this.total,
    this.discount = 0,
    required this.finalAmount,
    required this.paymentMethod,
    this.staffId,
    this.staffName,
    required this.createdAt,
    this.branchId = 'main',
    this.note,
  });

  int get totalItems => items.fold(0, (s, i) => s + i.quantity);

  factory SaleModel.fromJson(Map<String, dynamic> json, String id) {
    return SaleModel(
      id: id,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      memberId: json['memberId'],
      memberName: json['memberName'],
      total: (json['total'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      finalAmount: (json['finalAmount'] ?? 0).toDouble(),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      staffId: json['staffId'],
      staffName: json['staffName'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      branchId: json['branchId'] ?? 'main',
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'memberId': memberId,
    'memberName': memberName,
    'total': total,
    'discount': discount,
    'finalAmount': finalAmount,
    'paymentMethod': paymentMethod.name,
    'staffId': staffId,
    'staffName': staffName,
    'createdAt': Timestamp.fromDate(createdAt),
    'branchId': branchId,
    'note': note,
  };
}
