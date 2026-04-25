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
}
