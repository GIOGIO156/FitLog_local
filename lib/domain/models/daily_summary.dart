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
    required this.dietGoalPhase,
    required this.dietCalculationMode,
    required this.isEnergyTargetMode,
    required this.macroEnergyEquivalentKcal,
    required this.lifestyleFactorUsed,
    required this.exerciseCaloriesNet,
    required this.noExerciseBaselineTdee,
    required this.noExerciseTargetIntake,
    required this.calibrationConfidence,
    required this.calibrationWindowDays,
    required this.calibrationValidDays,
    this.macroSelfCheckCurrentFrequency,
    this.macroSelfCheckRecommendedFrequency,
    this.macroSelfCheckActiveTrainingDays,
    this.macroSelfCheckPeriodDays,
    this.macroSelfCheckAverageWeeklyFrequency,
    this.macroSelfCheckShouldSuggest = false,
    this.macroSelfCheckHasValidTrainingData = false,
    this.macroSelfCheckBelowRecommendedRange = false,
    this.calibrationUpdatedToday = false,
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
  final String dietGoalPhase;
  final String dietCalculationMode;
  final bool isEnergyTargetMode;
  final double macroEnergyEquivalentKcal;
  final double lifestyleFactorUsed;
  final double exerciseCaloriesNet;
  final double noExerciseBaselineTdee;
  final double noExerciseTargetIntake;
  final double calibrationConfidence;
  final int calibrationWindowDays;
  final int calibrationValidDays;
  final int? macroSelfCheckCurrentFrequency;
  final int? macroSelfCheckRecommendedFrequency;
  final int? macroSelfCheckActiveTrainingDays;
  final int? macroSelfCheckPeriodDays;
  final double? macroSelfCheckAverageWeeklyFrequency;
  final bool macroSelfCheckShouldSuggest;
  final bool macroSelfCheckHasValidTrainingData;
  final bool macroSelfCheckBelowRecommendedRange;
  final bool calibrationUpdatedToday;
  final List<FoodRecord> foodRecords;
  final List<WorkoutSession> workoutSessions;
}
