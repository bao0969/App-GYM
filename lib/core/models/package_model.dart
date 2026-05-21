enum PackageType { time, session, pt, allAccess, groupClass, trial }

class PackageModel {
  final String id;
  final String name;
  final PackageType type;
  final int durationDays;
  final int sessionCount; // For session-based packages
  final double price;
  final double originalPrice; // For showing discounts
  final String description;
  final List<String> features;
  final bool isActive;
  final String? color; // for UI

  PackageModel({
    required this.id,
    required this.name,
    this.type = PackageType.time,
    required this.durationDays,
    this.sessionCount = 0,
    required this.price,
    this.originalPrice = 0.0,
    required this.description,
    this.features = const [],
    this.isActive = true,
    this.color,
  });

  String get durationLabel {
    if (type == PackageType.session || type == PackageType.pt || type == PackageType.groupClass) {
      return '$sessionCount buổi';
    }
    if (durationDays < 30) return '$durationDays ngày';
    if (durationDays < 365) return '${(durationDays / 30).round()} tháng';
    return '${(durationDays / 365).round()} năm';
  }

  String get priceLabel {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M VNĐ';
    }
    return '${price.toInt()}K VNĐ';
  }

  factory PackageModel.fromJson(Map<String, dynamic> json, String id) {
    return PackageModel(
      id: id,
      name: json['name'] ?? '',
      type: PackageType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PackageType.time,
      ),
      durationDays: json['durationDays'] ?? 30,
      sessionCount: json['sessionCount'] ?? 0,
      price: (json['price'] ?? 0).toDouble(),
      originalPrice: (json['originalPrice'] ?? json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      features: List<String>.from(json['features'] ?? []),
      isActive: json['isActive'] ?? true,
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.name,
        'durationDays': durationDays,
        'sessionCount': sessionCount,
        'price': price,
        'originalPrice': originalPrice,
        'description': description,
        'features': features,
        'isActive': isActive,
        'color': color,
      };

  PackageModel copyWith({
    String? name,
    PackageType? type,
    int? durationDays,
    int? sessionCount,
    double? price,
    double? originalPrice,
    String? description,
    List<String>? features,
    bool? isActive,
    String? color,
  }) {
    return PackageModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      durationDays: durationDays ?? this.durationDays,
      sessionCount: sessionCount ?? this.sessionCount,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      description: description ?? this.description,
      features: features ?? this.features,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
    );
  }
}
