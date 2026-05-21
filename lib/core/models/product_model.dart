import 'package:cloud_firestore/cloud_firestore.dart';

enum ProductCategory { drink, supplement, apparel, accessory, other }

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final ProductCategory category;
  final double price;
  final double? costPrice; // Giá nhập, để tính lợi nhuận
  final int stock; // Tồn kho hiện tại
  final int lowStockThreshold; // Cảnh báo hết hàng
  final String? imageUrl;
  final String? barcode;
  final bool isActive;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.price,
    this.costPrice,
    this.stock = 0,
    this.lowStockThreshold = 5,
    this.imageUrl,
    this.barcode,
    this.isActive = true,
    required this.updatedAt,
  });

  bool get isLowStock => stock <= lowStockThreshold;
  bool get isOutOfStock => stock <= 0;

  String get categoryLabel {
    switch (category) {
      case ProductCategory.drink:
        return 'Nước Uống';
      case ProductCategory.supplement:
        return 'TPCN';
      case ProductCategory.apparel:
        return 'Quần Áo';
      case ProductCategory.accessory:
        return 'Phụ Kiện';
      case ProductCategory.other:
        return 'Khác';
    }
  }

  String get priceLabel {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    }
    if (price >= 1000) {
      return '${(price / 1000).toInt()}K';
    }
    return price.toInt().toString();
  }

  factory ProductModel.fromJson(Map<String, dynamic> json, String id) {
    return ProductModel(
      id: id,
      name: json['name'] ?? '',
      description: json['description'],
      category: ProductCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ProductCategory.other,
      ),
      price: (json['price'] ?? 0).toDouble(),
      costPrice: json['costPrice']?.toDouble(),
      stock: json['stock'] ?? 0,
      lowStockThreshold: json['lowStockThreshold'] ?? 5,
      imageUrl: json['imageUrl'],
      barcode: json['barcode'],
      isActive: json['isActive'] ?? true,
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category.name,
    'price': price,
    'costPrice': costPrice,
    'stock': stock,
    'lowStockThreshold': lowStockThreshold,
    'imageUrl': imageUrl,
    'barcode': barcode,
    'isActive': isActive,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  ProductModel copyWith({
    String? name,
    String? description,
    ProductCategory? category,
    double? price,
    double? costPrice,
    int? stock,
    int? lowStockThreshold,
    String? imageUrl,
    String? barcode,
    bool? isActive,
    DateTime? updatedAt,
  }) => ProductModel(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    price: price ?? this.price,
    costPrice: costPrice ?? this.costPrice,
    stock: stock ?? this.stock,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    imageUrl: imageUrl ?? this.imageUrl,
    barcode: barcode ?? this.barcode,
    isActive: isActive ?? this.isActive,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
