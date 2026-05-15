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

  // Strength estimate:
  // net strength kcal = active lifting kcal + small capped recovery extra kcal.
  // Active part uses net-MET ((MET - 1)...) and active lifting time from reps.
  static const double _defaultRepTempoSeconds = 4.0;
  static const double _recoveryKcalPerLiftedKg = 0.0105;
  static const double _maxRecoveryExtraKcal = 40.0;
  static const double _maxRecoveryToActiveRatio = 1.6;

  static const Set<String> _highDemandStrengthExercises = <String>{
    'Squat',
    'Deadlift',
    'Romanian Deadlift',
    'Leg Press',
    'Overhead Press',
    'Bench Press',
    'Pull-up',
    'Burpee',
  };

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
    final bodyweightShare =
        _bodyweightLoadShare[exerciseName] ?? (isBodyweight ? 1.0 : 0.0);

    double totalLiftedKg = 0;
    int totalReps = 0;
    for (final set in sets) {
      final reps = math.max(0, set.reps);
      if (reps == 0) {
        continue;
      }
      totalReps += reps;

      final externalLoadKg = math.max(0, set.weightKg);
      final effectiveLoadKg = isBodyweight
          ? bodyWeightKg * bodyweightShare + externalLoadKg
          : externalLoadKg;
      totalLiftedKg += effectiveLoadKg * reps;
    }

    if (totalReps <= 0 || totalLiftedKg <= 0 || bodyWeightKg <= 0) {
      return 0;
    }

    final activeMinutes = totalReps * _defaultRepTempoSeconds / 60;
    final averageLoadKg = totalLiftedKg / totalReps;
    final loadRatio = averageLoadKg / bodyWeightKg;
    final repsPerSet = totalReps / math.max(1, sets.length);

    final grossMet = _estimateStrengthGrossMet(
      exerciseName: exerciseName,
      loadRatio: loadRatio,
      repsPerSet: repsPerSet,
    );
    final activeNetKcal = _netMetCalories(
      bodyWeightKg: bodyWeightKg,
      met: grossMet,
      durationMinutes: activeMinutes,
    );

    final recoveryExtraRaw = totalLiftedKg * _recoveryKcalPerLiftedKg;
    final recoveryExtraCapFromActive =
        activeNetKcal * _maxRecoveryToActiveRatio;
    final recoveryExtraKcal = math.min(
      _maxRecoveryExtraKcal,
      math.min(recoveryExtraRaw, recoveryExtraCapFromActive),
    );

    final total = activeNetKcal + math.max(0, recoveryExtraKcal);
    if (!total.isFinite) {
      return 0;
    }
    return math.max(0, total);
  }

  static double _estimateStrengthGrossMet({
    required String exerciseName,
    required double loadRatio,
    required double repsPerSet,
  }) {
    var met = 5.0;

    if (_highDemandStrengthExercises.contains(exerciseName)) {
      met += 0.8;
    }

    met += loadRatio.clamp(0.0, 1.5) * 1.2;

    if (repsPerSet <= 6) {
      met += 0.4;
    } else if (repsPerSet >= 12) {
      met -= 0.2;
    }

    return met.clamp(3.5, 8.0);
  }

  static double _netMetCalories({
    required double bodyWeightKg,
    required double met,
    required double durationMinutes,
  }) {
    final netMet = math.max(0, met - 1);
    if (netMet <= 0 || bodyWeightKg <= 0 || durationMinutes <= 0) {
      return 0;
    }
    return netMet * 3.5 * bodyWeightKg / 200 * durationMinutes;
  }
}
