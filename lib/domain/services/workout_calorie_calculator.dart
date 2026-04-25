class WorkoutCalorieCalculator {
  WorkoutCalorieCalculator._();

  static const Map<String, double> _cardioMetMap = <String, double>{
    'Running': 8,
    'Cycling': 6,
    'Rowing Machine': 7,
    'Stair Climber': 8,
  };

  static const Map<String, double> _strengthIntensityFactor = <String, double>{
    'low': 0.04,
    'medium': 0.06,
    'high': 0.08,
  };

  static double estimateCardioCalories({
    required String exerciseName,
    required double bodyWeightKg,
    required int durationMinutes,
  }) {
    final double met = _cardioMetMap[exerciseName] ?? 6;
    final double durationHours = durationMinutes / 60;
    return met * bodyWeightKg * durationHours;
  }

  static double estimateStrengthCalories({
    required double bodyWeightKg,
    required int durationMinutes,
    required String intensity,
  }) {
    final double factor = _strengthIntensityFactor[intensity] ?? 0.06;
    return durationMinutes * bodyWeightKg * factor;
  }
}
