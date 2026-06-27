import '../../core/utils/number_utils.dart';

class BodyMetricLog {
  const BodyMetricLog({
    this.id,
    required this.date,
    this.weightKg,
    this.bodyFatPercent,
    this.waistCm,
    required this.source,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final String date;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? waistCm;
  final String source;
  final String? createdAt;
  final String? updatedAt;

  bool get hasAnyMetric =>
      weightKg != null || bodyFatPercent != null || waistCm != null;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'date': date,
      'weight_kg': weightKg,
      'body_fat_percent': bodyFatPercent,
      'waist_cm': waistCm,
      'source': source,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory BodyMetricLog.fromMap(Map<String, dynamic> map) {
    return BodyMetricLog(
      id: NumberUtils.toNullableInt(map['id']),
      date: (map['date'] ?? '').toString(),
      weightKg: map['weight_kg'] == null
          ? null
          : NumberUtils.toDouble(map['weight_kg']),
      bodyFatPercent: map['body_fat_percent'] == null
          ? null
          : NumberUtils.toDouble(map['body_fat_percent']),
      waistCm: map['waist_cm'] == null
          ? null
          : NumberUtils.toDouble(map['waist_cm']),
      source: (map['source'] ?? '').toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }
}
