import 'package:cloud_firestore/cloud_firestore.dart';

class BodyMetricModel {
  final String id;
  final String memberId;
  final double? weight;
  final double? height;
  final double? bodyFat;
  final double? chest;
  final double? waist;
  final double? hips;
  final DateTime date;
  final String? note;

  BodyMetricModel({
    required this.id,
    required this.memberId,
    this.weight,
    this.height,
    this.bodyFat,
    this.chest,
    this.waist,
    this.hips,
    required this.date,
    this.note,
  });

  double? get bmi {
    if (weight != null && height != null && height! > 0) {
      final h = height! / 100; // cm to m
      return weight! / (h * h);
    }
    return null;
  }

  factory BodyMetricModel.fromJson(Map<String, dynamic> json, String id) {
    return BodyMetricModel(
      id: id,
      memberId: json['memberId'] ?? '',
      weight: json['weight']?.toDouble(),
      height: json['height']?.toDouble(),
      bodyFat: json['bodyFat']?.toDouble(),
      chest: json['chest']?.toDouble(),
      waist: json['waist']?.toDouble(),
      hips: json['hips']?.toDouble(),
      date: json['date'] is Timestamp
          ? (json['date'] as Timestamp).toDate()
          : DateTime.now(),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'memberId': memberId,
        'weight': weight,
        'height': height,
        'bodyFat': bodyFat,
        'chest': chest,
        'waist': waist,
        'hips': hips,
        'date': Timestamp.fromDate(date),
        'note': note,
      };
}
