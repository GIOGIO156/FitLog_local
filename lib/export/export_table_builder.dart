import '../data/repositories/food_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../domain/models/user_profile.dart';
import '../domain/services/daily_summary_service.dart';

class ExportTableBuilder {
  ExportTableBuilder({
    required FoodRepository foodRepository,
    required WorkoutRepository workoutRepository,
    required ProfileRepository profileRepository,
    required DailySummaryService dailySummaryService,
  }) : _foodRepository = foodRepository,
       _workoutRepository = workoutRepository,
       _profileRepository = profileRepository,
       _dailySummaryService = dailySummaryService;

  final FoodRepository _foodRepository;
  final WorkoutRepository _workoutRepository;
  final ProfileRepository _profileRepository;
  final DailySummaryService _dailySummaryService;

  Future<List<ExportTable>> build() async {
    final foodRecords = await _foodRepository.getAllFoodRecords();
    final workoutSessions = await _workoutRepository.getAllWorkoutSessions();
    final profile =
        await _profileRepository.getProfile() ?? UserProfile.defaults;

    final tables = <ExportTable>[
      ExportTable(
        sheetName: 'Food Records',
        fileName: 'food_records.csv',
        rows: <List<dynamic>>[
          <dynamic>[
            'date',
            'meal_name',
            'total_weight_g',
            'calories_kcal',
            'protein_g',
            'carbs_g',
            'fat_g',
            'confidence',
            'source',
            'estimation_notes',
          ],
          ...foodRecords.map(
            (record) => <dynamic>[
              record.date,
              record.mealName,
              record.totalWeightG,
              record.caloriesKcal,
              record.proteinG,
              record.carbsG,
              record.fatG,
              record.confidence,
              record.source,
              record.estimationNotes,
            ],
          ),
        ],
      ),
      ExportTable(
        sheetName: 'Food Items',
        fileName: 'food_items.csv',
        rows: <List<dynamic>>[
          <dynamic>[
            'food_record_id',
            'name',
            'estimated_weight_g',
            'calories_kcal',
            'protein_g',
            'carbs_g',
            'fat_g',
            'notes',
          ],
          for (final record in foodRecords)
            for (final item in record.items)
              <dynamic>[
                record.id,
                item.name,
                item.estimatedWeightG,
                item.caloriesKcal,
                item.proteinG,
                item.carbsG,
                item.fatG,
                item.notes,
              ],
        ],
      ),
      ExportTable(
        sheetName: 'Workout Records',
        fileName: 'workout_records.csv',
        rows: <List<dynamic>>[
          <dynamic>[
            'date',
            'body_part',
            'exercise_name',
            'exercise_type',
            'duration_minutes',
            'intensity',
            'estimated_calories',
            'notes',
          ],
          ...workoutSessions.map(
            (session) => <dynamic>[
              session.date,
              session.bodyPart,
              session.exerciseName,
              session.exerciseType,
              session.durationMinutes,
              session.intensity,
              session.estimatedCalories,
              session.notes,
            ],
          ),
        ],
      ),
      ExportTable(
        sheetName: 'Workout Sets',
        fileName: 'workout_sets.csv',
        rows: <List<dynamic>>[
          <dynamic>[
            'workout_session_id',
            'set_number',
            'weight_kg',
            'reps',
            'is_completed',
            'completed_at',
          ],
          for (final session in workoutSessions)
            for (final set in session.sets)
              <dynamic>[
                session.id,
                set.setNumber,
                set.weightKg,
                set.reps,
                set.isCompleted ? 1 : 0,
                set.completedAt ?? '',
              ],
        ],
      ),
      ExportTable(
        sheetName: 'Daily Summary',
        fileName: 'daily_summary.csv',
        rows: await _buildSummaryRows(),
      ),
      ExportTable(
        sheetName: 'User Profile',
        fileName: 'user_profile.csv',
        rows: <List<dynamic>>[
          <dynamic>[
            'age',
            'height_cm',
            'weight_kg',
            'sex_for_formula',
            'activity_level',
            'daily_energy_goal_type',
            'daily_energy_goal_kcal',
            'protein_ratio_percent',
            'carbs_ratio_percent',
            'fat_ratio_percent',
            'diet_goal_phase',
            'diet_calculation_mode',
            'training_frequency_per_week',
            'macro_self_check_period_days',
            'macro_self_check_enabled',
            'last_macro_self_check_at',
          ],
          <dynamic>[
            profile.age,
            profile.heightCm,
            profile.weightKg,
            profile.sexForFormula,
            profile.activityLevel,
            profile.dailyEnergyGoalType,
            profile.dailyEnergyGoalKcal,
            profile.proteinRatioPercent,
            profile.carbsRatioPercent,
            profile.fatRatioPercent,
            profile.dietGoalPhase,
            profile.dietCalculationMode,
            profile.trainingFrequencyPerWeek,
            profile.macroSelfCheckPeriodDays,
            profile.macroSelfCheckEnabled ? 1 : 0,
            profile.lastMacroSelfCheckAt ?? '',
          ],
        ],
      ),
    ];

    return tables;
  }

  Future<List<List<dynamic>>> _buildSummaryRows() async {
    final uniqueDates = <String>{
      ...await _foodRepository.getDistinctDates(),
      ...await _workoutRepository.getDistinctDates(),
    }.toList()..sort();

    final rows = <List<dynamic>>[
      <dynamic>[
        'date',
        'diet_goal_phase',
        'diet_calculation_mode',
        'is_energy_target_mode',
        'calories_in',
        'protein_g',
        'carbs_g',
        'fat_g',
        'exercise_calories',
        'bmr',
        'tdee_reference',
        'lifestyle_factor_used',
        'no_exercise_target_intake',
        'target_intake',
        'remaining_calories',
        'calibration_confidence',
        'calibration_window_days',
        'calibration_valid_days',
        'target_protein_g',
        'target_carbs_g',
        'target_fat_g',
        'remaining_protein_g',
        'remaining_carbs_g',
        'remaining_fat_g',
        'macro_energy_equivalent_kcal',
        'macro_self_check_current_frequency',
        'macro_self_check_recommended_frequency',
        'macro_self_check_active_training_days',
        'macro_self_check_period_days',
        'macro_self_check_average_weekly_frequency',
        'macro_self_check_should_suggest',
        'macro_self_check_has_valid_training_data',
        'macro_self_check_below_recommended_range',
      ],
    ];

    for (final date in uniqueDates) {
      final daily = await _dailySummaryService.getSummaryForDate(date);
      rows.add(<dynamic>[
        date,
        daily.dietGoalPhase,
        daily.dietCalculationMode,
        daily.isEnergyTargetMode ? 1 : 0,
        daily.caloriesIn,
        daily.proteinG,
        daily.carbsG,
        daily.fatG,
        daily.exerciseCalories,
        daily.bmr,
        daily.tdeeReference,
        daily.lifestyleFactorUsed,
        daily.noExerciseTargetIntake,
        daily.targetIntake,
        daily.remainingCalories,
        daily.calibrationConfidence,
        daily.calibrationWindowDays,
        daily.calibrationValidDays,
        daily.targetProteinG,
        daily.targetCarbsG,
        daily.targetFatG,
        daily.remainingProteinG,
        daily.remainingCarbsG,
        daily.remainingFatG,
        daily.macroEnergyEquivalentKcal,
        daily.macroSelfCheckCurrentFrequency,
        daily.macroSelfCheckRecommendedFrequency,
        daily.macroSelfCheckActiveTrainingDays,
        daily.macroSelfCheckPeriodDays,
        daily.macroSelfCheckAverageWeeklyFrequency,
        daily.macroSelfCheckShouldSuggest ? 1 : 0,
        daily.macroSelfCheckHasValidTrainingData ? 1 : 0,
        daily.macroSelfCheckBelowRecommendedRange ? 1 : 0,
      ]);
    }

    return rows;
  }
}

class ExportTable {
  const ExportTable({
    required this.sheetName,
    required this.fileName,
    required this.rows,
  });

  final String sheetName;
  final String fileName;
  final List<List<dynamic>> rows;
}
