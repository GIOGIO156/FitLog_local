import '../../core/constants/app_constants.dart';
import '../../core/utils/number_utils.dart';

class UserProfile {
  const UserProfile({
    this.id,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.sexForFormula,
    required this.activityLevel,
    required this.dailyEnergyGoalType,
    required this.dailyEnergyGoalKcal,
    required this.proteinRatioPercent,
    required this.carbsRatioPercent,
    required this.fatRatioPercent,
    this.createdAt,
    this.updatedAt,
  });

  final int? id;
  final int age;
  final double heightCm;
  final double weightKg;
  final String sexForFormula;
  final String activityLevel;
  final String dailyEnergyGoalType;
  final double dailyEnergyGoalKcal;
  final double proteinRatioPercent;
  final double carbsRatioPercent;
  final double fatRatioPercent;
  final String? createdAt;
  final String? updatedAt;

  static const UserProfile defaults = UserProfile(
    id: 1,
    age: 25,
    heightCm: 170,
    weightKg: 65,
    sexForFormula: 'prefer_not_to_say',
    activityLevel: 'moderately_active',
    dailyEnergyGoalType: 'maintenance',
    dailyEnergyGoalKcal: 300,
    proteinRatioPercent: AppConstants.defaultProteinRatioPercent,
    carbsRatioPercent: AppConstants.defaultCarbsRatioPercent,
    fatRatioPercent: AppConstants.defaultFatRatioPercent,
  );

  bool get isMinor => age < 18;

  double get macroRatioTotal =>
      proteinRatioPercent + carbsRatioPercent + fatRatioPercent;

  bool get hasValidMacroRatio => macroRatioTotal > 0;

  UserProfile copyWith({
    int? id,
    int? age,
    double? heightCm,
    double? weightKg,
    String? sexForFormula,
    String? activityLevel,
    String? dailyEnergyGoalType,
    double? dailyEnergyGoalKcal,
    double? proteinRatioPercent,
    double? carbsRatioPercent,
    double? fatRatioPercent,
    String? createdAt,
    String? updatedAt,
  }) {
    final String safeGoal = (age ?? this.age) < 18
        ? 'maintenance'
        : (dailyEnergyGoalType ?? this.dailyEnergyGoalType);

    return UserProfile(
      id: id ?? this.id,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      sexForFormula: sexForFormula ?? this.sexForFormula,
      activityLevel: activityLevel ?? this.activityLevel,
      dailyEnergyGoalType: AppConstants.dailyEnergyGoalTypes.contains(safeGoal)
          ? safeGoal
          : 'maintenance',
      dailyEnergyGoalKcal: dailyEnergyGoalKcal ?? this.dailyEnergyGoalKcal,
      proteinRatioPercent: proteinRatioPercent ?? this.proteinRatioPercent,
      carbsRatioPercent: carbsRatioPercent ?? this.carbsRatioPercent,
      fatRatioPercent: fatRatioPercent ?? this.fatRatioPercent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'age': age,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'sex_for_formula': sexForFormula,
      'activity_level': activityLevel,
      'daily_energy_goal_type': dailyEnergyGoalType,
      'daily_energy_goal_kcal': dailyEnergyGoalKcal,
      'protein_ratio_percent': proteinRatioPercent,
      'carbs_ratio_percent': carbsRatioPercent,
      'fat_ratio_percent': fatRatioPercent,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: NumberUtils.toInt(map['id'], fallback: -1) == -1
          ? null
          : NumberUtils.toInt(map['id']),
      age: NumberUtils.toInt(map['age'], fallback: 25),
      heightCm: NumberUtils.toDouble(map['height_cm'], fallback: 170),
      weightKg: NumberUtils.toDouble(map['weight_kg'], fallback: 65),
      sexForFormula: (map['sex_for_formula'] ?? 'prefer_not_to_say').toString(),
      activityLevel: (map['activity_level'] ?? 'moderately_active').toString(),
      dailyEnergyGoalType: (map['daily_energy_goal_type'] ?? 'maintenance')
          .toString(),
      dailyEnergyGoalKcal: NumberUtils.toDouble(
        map['daily_energy_goal_kcal'],
        fallback: 300,
      ),
      proteinRatioPercent: NumberUtils.toDouble(
        map['protein_ratio_percent'],
        fallback: AppConstants.defaultProteinRatioPercent,
      ),
      carbsRatioPercent: NumberUtils.toDouble(
        map['carbs_ratio_percent'],
        fallback: AppConstants.defaultCarbsRatioPercent,
      ),
      fatRatioPercent: NumberUtils.toDouble(
        map['fat_ratio_percent'],
        fallback: AppConstants.defaultFatRatioPercent,
      ),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
    );
  }
}
