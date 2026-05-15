import 'dart:math' as math;

import '../../core/constants/app_constants.dart';
import '../models/workout_set.dart';

class WorkoutCalorieCalculator {
  WorkoutCalorieCalculator._();

  // Cardio still follows MET x body weight x duration.
  static const Map<String, double> _cardioMetMap = <String, double>{
    'Walking': 4.3,
    'Running': 8,
    'Cycling': 6,
    'Rowing Machine': 7,
    'Stair Climber': 8,
  };

  // Approximate body-mass share moved in common bodyweight movements.
  static const Map<String, double> _bodyweightLoadShare = <String, double>{
    'Push-up': 0.69,
    'Plank': 0.60,
    'Crunch': 0.45,
    'Hanging Leg Raise': 0.90,
    'Pull-up': 1.00,
    'Burpee': 1.00,
  };

  // Strength estimate in kcal per lifted kg:
  // ~20.8 kcal per metric ton of total lifted load.
  static const double _strengthKcalPerLiftedKg = 0.0208;

  static double estimateCardioCalories({
    required String exerciseName,
    required double bodyWeightKg,
    required int durationMinutes,
  }) {
    final double met = _cardioMetMap[exerciseName] ?? 6;
    final safeDurationMinutes = math.max(0, durationMinutes);
    final double durationHours = safeDurationMinutes / 60;
    return met * bodyWeightKg * durationHours;
  }

  static double estimateStrengthCalories({
    required String exerciseName,
    required double bodyWeightKg,
    required List<WorkoutSet> sets,
  }) {
    if (sets.isEmpty) {
      return 0;
    }

    final isBodyweight = AppConstants.isBodyweightExercise(exerciseName);
    final bodyweightShare = _bodyweightLoadShare[exerciseName] ??
        (isBodyweight ? 1.0 : 0.0);

    double totalLiftedKg = 0;
    for (final set in sets) {
      final reps = math.max(0, set.reps);
      if (reps == 0) {
        continue;
      }

      final externalLoadKg = math.max(0, set.weightKg);
      final effectiveLoadKg = isBodyweight
          ? bodyWeightKg * bodyweightShare + externalLoadKg
          : externalLoadKg;
      totalLiftedKg += effectiveLoadKg * reps;
    }

    final calories = totalLiftedKg * _strengthKcalPerLiftedKg;
    if (!calories.isFinite) {
      return 0;
    }
    return math.max(0, calories);
  }
}
