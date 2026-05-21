class BranchModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final bool isActive;

  BranchModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    this.isActive = true,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json, String id) {
    return BranchModel(
      id: id,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'phone': phone,
        'isActive': isActive,
      };
}
