import '../../data/repositories/food_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../models/daily_summary.dart';
import '../models/user_profile.dart';
import 'nutrition_calculator.dart';

class DailySummaryService {
  DailySummaryService({
    required FoodRepository foodRepository,
    required WorkoutRepository workoutRepository,
    required ProfileRepository profileRepository,
  }) : _foodRepository = foodRepository,
       _workoutRepository = workoutRepository,
       _profileRepository = profileRepository;

  final FoodRepository _foodRepository;
  final WorkoutRepository _workoutRepository;
  final ProfileRepository _profileRepository;

  static const Map<String, double> _activityMultiplier = <String, double>{
    'sedentary': 1.2,
    'lightly_active': 1.375,
    'moderately_active': 1.55,
    'very_active': 1.725,
  };

  static const double _proteinCaloriesPerGram = 4;
  static const double _carbsCaloriesPerGram = 4;
  static const double _fatCaloriesPerGram = 9;

  Future<DailySummary> getSummaryForDate(String day) async {
    final profile =
        await _profileRepository.getProfile() ?? UserProfile.defaults;

    final foodRecords = await _foodRepository.getFoodRecordsByDate(day);
    final workoutSessions = await _workoutRepository.getWorkoutSessionsByDate(
      day,
    );

    final caloriesIn = NutritionCalculator.sumCalories(foodRecords);
    final protein = NutritionCalculator.sumProtein(foodRecords);
    final carbs = NutritionCalculator.sumCarbs(foodRecords);
    final fat = NutritionCalculator.sumFat(foodRecords);

    final exerciseCalories = workoutSessions.fold<double>(
      0,
      (sum, item) => sum + item.estimatedCalories,
    );

    final bmr = calculateBmr(profile);
    final tdee = bmr * (_activityMultiplier[profile.activityLevel] ?? 1.55);
    final actualDailyExpenditure = bmr + exerciseCalories;

    final String goalType =
        profile.isMinor && profile.dailyEnergyGoalType == 'deficit'
        ? 'maintenance'
        : profile.dailyEnergyGoalType;

    double targetIntake;
    switch (goalType) {
      case 'deficit':
        targetIntake = actualDailyExpenditure - profile.dailyEnergyGoalKcal;
        break;
      case 'surplus':
        targetIntake = actualDailyExpenditure + profile.dailyEnergyGoalKcal;
        break;
      case 'maintenance':
      default:
        targetIntake = actualDailyExpenditure;
        break;
    }

    final remaining = targetIntake - caloriesIn;
    final macroRatio = _resolveMacroRatio(profile);
    final targetProteinG =
        targetIntake * macroRatio.protein / _proteinCaloriesPerGram;
    final targetCarbsG =
        targetIntake * macroRatio.carbs / _carbsCaloriesPerGram;
    final targetFatG = targetIntake * macroRatio.fat / _fatCaloriesPerGram;
    final remainingProteinG = targetProteinG - protein;
    final remainingCarbsG = targetCarbsG - carbs;
    final remainingFatG = targetFatG - fat;

    return DailySummary(
      date: day,
      caloriesIn: caloriesIn,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      exerciseCalories: exerciseCalories,
      bmr: bmr,
      tdeeReference: tdee,
      targetIntake: targetIntake,
      remainingCalories: remaining,
      targetProteinG: targetProteinG,
      targetCarbsG: targetCarbsG,
      targetFatG: targetFatG,
      remainingProteinG: remainingProteinG,
      remainingCarbsG: remainingCarbsG,
      remainingFatG: remainingFatG,
      foodRecords: foodRecords,
      workoutSessions: workoutSessions,
    );
  }

  double calculateBmr(UserProfile profile) {
    final male =
        10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age + 5;
    final female =
        10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age - 161;

    switch (profile.sexForFormula) {
      case 'male':
        return male;
      case 'female':
        return female;
      case 'prefer_not_to_say':
      default:
        return (male + female) / 2;
    }
  }

  _MacroRatio _resolveMacroRatio(UserProfile profile) {
    final protein = profile.proteinRatioPercent <= 0
        ? 0
        : profile.proteinRatioPercent;
    final carbs = profile.carbsRatioPercent <= 0
        ? 0
        : profile.carbsRatioPercent;
    final fat = profile.fatRatioPercent <= 0 ? 0 : profile.fatRatioPercent;
    final total = protein + carbs + fat;

    if (total <= 0) {
      return const _MacroRatio(protein: 0.3, carbs: 0.4, fat: 0.3);
    }

    return _MacroRatio(
      protein: protein / total,
      carbs: carbs / total,
      fat: fat / total,
    );
  }
}

class _MacroRatio {
  const _MacroRatio({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double protein;
  final double carbs;
  final double fat;
}
