import 'food_record.dart';
import 'workout_session.dart';

class DailySummary {
  const DailySummary({
    required this.date,
    required this.caloriesIn,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.exerciseCalories,
    required this.bmr,
    required this.tdeeReference,
    required this.targetIntake,
    required this.remainingCalories,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    required this.remainingProteinG,
    required this.remainingCarbsG,
    required this.remainingFatG,
    this.foodRecords = const <FoodRecord>[],
    this.workoutSessions = const <WorkoutSession>[],
  });

  final String date;
  final double caloriesIn;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double exerciseCalories;
  final double bmr;
  final double tdeeReference;
  final double targetIntake;
  final double remainingCalories;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final double remainingProteinG;
  final double remainingCarbsG;
  final double remainingFatG;
  final List<FoodRecord> foodRecords;
  final List<WorkoutSession> workoutSessions;
}
