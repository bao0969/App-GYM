enum PackageType { time, session, pt, allAccess, groupClass, trial }

class PackageModel {
  final String id;
  final String name;
  final PackageType type;
  final int durationDays;
  final int sessionCount;
  final double price;
  final double originalPrice;
  final String description;
  final List<String> features;
  final bool isActive;
  final String? color;

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

  /// Gói có tính theo buổi (session/PT) hay không?
  /// Chỉ gói session/pt/groupClass mới nên trừ sessionsRemaining khi dùng.
  bool get isSessionBased =>
      type == PackageType.session ||
      type == PackageType.pt ||
      type == PackageType.groupClass;

  String get durationLabel {
    if (type == PackageType.session || type == PackageType.groupClass) {
      return '$sessionCount buoi';
    }
    if (type == PackageType.pt && sessionCount > 0) {
      return '$sessionCount buoi PT';
    }
    if (durationDays % 365 == 0 && durationDays >= 365) {
      return '${(durationDays / 365).round()} nam';
    }
    if (durationDays % 30 == 0 && durationDays >= 30) {
      return '${(durationDays / 30).round()} thang';
    }
    if (durationDays % 7 == 0 && durationDays >= 7) {
      return '${(durationDays / 7).round()} tuan';
    }
    return '$durationDays ngay';
  }

  String get priceLabel {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M VND';
    }
    return '${price.toInt()}K VND';
  }

  factory PackageModel.fromJson(Map<String, dynamic> json, String id) {
    return PackageModel(
      id: id,
      name: json['name'] ?? '',
      type: PackageType.values.firstWhere(
        (value) => value.name == json['type'],
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
