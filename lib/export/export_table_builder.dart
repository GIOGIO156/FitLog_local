import '../core/localization/app_language.dart';
import '../data/repositories/custom_exercise_repository.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../domain/models/diet_adjustment_review.dart';
import '../domain/models/user_profile.dart';
import '../domain/models/workout_session.dart';
import '../domain/models/workout_set.dart';
import '../domain/services/daily_summary_service.dart';
import 'export_localization.dart';

class ExportTableBuilder {
  ExportTableBuilder({
    required FoodRepository foodRepository,
    required CustomExerciseRepository customExerciseRepository,
    required WorkoutRepository workoutRepository,
    required ProfileRepository profileRepository,
    required DailySummaryService dailySummaryService,
    AppLanguage language = AppLanguage.english,
  }) : _foodRepository = foodRepository,
       _customExerciseRepository = customExerciseRepository,
       _workoutRepository = workoutRepository,
       _profileRepository = profileRepository,
       _dailySummaryService = dailySummaryService,
       _localization = ExportLocalization(language);

  final FoodRepository _foodRepository;
  final CustomExerciseRepository _customExerciseRepository;
  final WorkoutRepository _workoutRepository;
  final ProfileRepository _profileRepository;
  final DailySummaryService _dailySummaryService;
  final ExportLocalization _localization;

  Future<ExportData> build() async {
    final foodRecords = await _foodRepository.getAllFoodRecords();
    final workoutSessions = await _workoutRepository.getAllWorkoutSessions();
    final customExercises = await _customExerciseRepository.getAllDefinitions();
    final profile =
        await _profileRepository.getProfile() ?? UserProfile.defaults;
    final bodyMetricLogs = await _profileRepository.getAllBodyMetricLogs();
    final dietAdjustmentReviews = await _profileRepository
        .getAllDietAdjustmentReviews();

    final tables = <ExportTable>[
      _table('food_records', <List<dynamic>>[
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
      ]),
      _table('food_items', <List<dynamic>>[
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
      ]),
      _table('workout_records', _buildWorkoutRecordRows(workoutSessions)),
      _table(
        'workout_exercise_sets',
        _buildWorkoutExerciseSetRows(workoutSessions),
      ),
      _table('custom_exercises', <List<dynamic>>[
        <dynamic>[
          'exercise_key',
          'name',
          'exercise_type',
          'body_part',
          'secondary_body_part',
          'strength_structure',
          'strength_profile',
          'load_input_mode',
          'reps_input_mode',
          'set_metric_type',
          'default_cardio_intensity',
          'is_hidden',
        ],
        ...customExercises.map(
          (exercise) => <dynamic>[
            exercise.key,
            exercise.name,
            exercise.exerciseType,
            exercise.bodyPart,
            exercise.secondaryBodyPart ?? '',
            exercise.strengthStructure,
            exercise.strengthProfile,
            exercise.loadInputMode,
            exercise.repsInputMode,
            exercise.setMetricType,
            exercise.defaultCardioIntensity,
            exercise.isHidden ? 1 : 0,
          ],
        ),
      ]),
      _table('daily_summary', await _buildSummaryRows()),
      _table('user_profile', <List<dynamic>>[
        <dynamic>[
          'nickname',
          'age',
          'height_cm',
          'weight_kg',
          'body_fat_percent',
          'waist_cm',
          'sex_for_formula',
          'activity_level',
          'daily_energy_goal_type',
          'daily_energy_goal_kcal',
          'protein_ratio_percent',
          'carbs_ratio_percent',
          'fat_ratio_percent',
          'diet_goal_phase',
          'diet_calculation_mode',
          'diet_plan_strategy',
          'carb_cycle_pattern_json',
          'carb_cycle_high_multiplier',
          'carb_cycle_medium_multiplier',
          'carb_cycle_low_multiplier',
          'carb_taper_review_period_days',
          'carb_taper_target_loss_pct_per_week',
          'carb_taper_step_g',
          'carb_taper_current_delta_g',
          'last_carb_taper_review_at',
          'training_frequency_per_week',
          'macro_self_check_period_days',
          'macro_self_check_enabled',
          'last_macro_self_check_at',
        ],
        <dynamic>[
          profile.nickname ?? '',
          profile.age,
          profile.heightCm,
          profile.weightKg,
          profile.bodyFatPercent,
          profile.waistCm,
          profile.sexForFormula,
          profile.activityLevel,
          profile.dailyEnergyGoalType,
          profile.dailyEnergyGoalKcal,
          profile.proteinRatioPercent,
          profile.carbsRatioPercent,
          profile.fatRatioPercent,
          profile.dietGoalPhase,
          profile.dietCalculationMode,
          profile.dietPlanStrategy,
          profile.carbCyclePatternJson ?? '',
          profile.carbCycleHighMultiplier,
          profile.carbCycleMediumMultiplier,
          profile.carbCycleLowMultiplier,
          profile.carbTaperReviewPeriodDays,
          profile.carbTaperTargetLossPctPerWeek,
          profile.carbTaperStepG,
          profile.carbTaperCurrentDeltaG,
          profile.lastCarbTaperReviewAt ?? '',
          profile.trainingFrequencyPerWeek,
          profile.macroSelfCheckPeriodDays,
          profile.macroSelfCheckEnabled ? 1 : 0,
          profile.lastMacroSelfCheckAt ?? '',
        ],
      ]),
      _table('body_metric_logs', <List<dynamic>>[
        <dynamic>[
          'date',
          'weight_kg',
          'body_fat_percent',
          'waist_cm',
          'source',
        ],
        ...bodyMetricLogs.map(
          (log) => <dynamic>[
            log.date,
            log.weightKg ?? '',
            log.bodyFatPercent ?? '',
            log.waistCm ?? '',
            log.source,
          ],
        ),
      ]),
      _table(
        'diet_adjustment_reviews',
        _buildDietAdjustmentReviewRows(dietAdjustmentReviews),
      ),
    ];

    return ExportData(
      tables: tables,
      firstRecordDate: _firstRecordDate(<String>[
        ...foodRecords.map((record) => record.date),
        ...workoutSessions.map((session) => session.date),
        ...bodyMetricLogs.map((log) => log.date),
        ...dietAdjustmentReviews.map((review) => review.reviewDate),
      ]),
    );
  }

  ExportTable _table(String tableId, List<List<dynamic>> rows) {
    return ExportTable(
      sheetName: _localization.sheetName(tableId),
      fileName: _localization.fileName(tableId),
      rows: _localization.localizeRows(tableId, rows),
    );
  }

  String? _firstRecordDate(List<String> dates) {
    final validDates =
        dates
            .map((date) => date.trim())
            .where((date) => date.isNotEmpty)
            .toList()
          ..sort();
    if (validDates.isEmpty) {
      return null;
    }
    return validDates.first;
  }

  List<List<dynamic>> _buildWorkoutRecordRows(
    List<WorkoutSession> workoutSessions,
  ) {
    final rows = <List<dynamic>>[
      <dynamic>[
        'workout_record_id',
        'date',
        'record_name',
        'total_duration_minutes',
        'total_volume_kg',
        'total_sets',
        'estimated_calories',
        'exercise_count',
        'exercise_names',
        'notes',
      ],
    ];

    for (final group in _workoutRecordGroups(workoutSessions)) {
      final sessions = group.sessions;
      final first = sessions.first;
      final exerciseNames = sessions
          .map((session) => _localization.exerciseName(session.exerciseName))
          .join(' / ');
      final notes = sessions
          .map((session) => session.notes.trim())
          .where((notes) => notes.isNotEmpty)
          .toSet()
          .join(' / ');

      rows.add(<dynamic>[
        group.id,
        first.date,
        first.recordName ?? '',
        sessions.fold<int>(0, (sum, session) => sum + session.durationMinutes),
        _workoutVolumeKg(sessions),
        sessions.fold<int>(0, (sum, session) => sum + session.sets.length),
        sessions.fold<double>(
          0,
          (sum, session) => sum + session.estimatedCalories,
        ),
        sessions.length,
        exerciseNames,
        notes,
      ]);
    }

    return rows;
  }

  List<List<dynamic>> _buildWorkoutExerciseSetRows(
    List<WorkoutSession> workoutSessions,
  ) {
    final rows = <List<dynamic>>[
      <dynamic>[
        'workout_record_id',
        'workout_session_id',
        'date',
        'record_name',
        'exercise_order',
        'exercise_name',
        'body_part',
        'secondary_body_part',
        'exercise_type',
        'duration_minutes',
        'intensity',
        'set_number',
        'weight_kg',
        'reps',
        'input_weight_kg',
        'input_reps',
        'input_duration_seconds',
        'calculation_load_kg',
        'calculation_reps',
        'load_input_mode',
        'reps_input_mode',
        'set_metric_type',
        'is_completed',
        'completed_at',
        'estimated_calories',
        'notes',
      ],
    ];

    for (final group in _workoutRecordGroups(workoutSessions)) {
      for (var i = 0; i < group.sessions.length; i++) {
        final session = group.sessions[i];
        final sets = session.sets;
        if (sets.isEmpty) {
          rows.add(_workoutExerciseSetRow(group.id, session, i + 1, null));
          continue;
        }

        for (final set in sets) {
          rows.add(_workoutExerciseSetRow(group.id, session, i + 1, set));
        }
      }
    }

    return rows;
  }

  List<dynamic> _workoutExerciseSetRow(
    String workoutRecordId,
    WorkoutSession session,
    int exerciseOrder,
    WorkoutSet? set,
  ) {
    return <dynamic>[
      workoutRecordId,
      session.id ?? '',
      session.date,
      session.recordName ?? '',
      exerciseOrder,
      session.exerciseName,
      session.bodyPart,
      session.secondaryBodyPart ?? '',
      session.exerciseType,
      session.durationMinutes,
      session.intensity,
      set?.setNumber ?? '',
      set?.weightKg ?? '',
      set?.reps ?? '',
      set?.inputWeightKg ?? '',
      set?.inputReps ?? '',
      set?.inputDurationSeconds ?? '',
      set?.calculationLoadKg ?? '',
      set?.calculationReps ?? '',
      set?.loadInputMode ?? session.loadInputMode ?? '',
      set?.repsInputMode ?? session.repsInputMode ?? '',
      set?.setMetricType ?? session.setMetricType ?? '',
      set == null ? '' : (set.isCompleted ? 1 : 0),
      set?.completedAt ?? '',
      session.estimatedCalories,
      session.notes,
    ];
  }

  List<_WorkoutRecordGroup> _workoutRecordGroups(
    List<WorkoutSession> workoutSessions,
  ) {
    final grouped = <String, List<WorkoutSession>>{};
    for (final session in workoutSessions) {
      final id = _workoutRecordId(session);
      grouped.putIfAbsent(id, () => <WorkoutSession>[]).add(session);
    }

    return grouped.entries.map((entry) {
      final sessions = [...entry.value]
        ..sort((a, b) {
          final aId = a.id ?? 0;
          final bId = b.id ?? 0;
          return aId.compareTo(bId);
        });
      return _WorkoutRecordGroup(id: entry.key, sessions: sessions);
    }).toList();
  }

  String _workoutRecordId(WorkoutSession session) {
    final planId = (session.planId ?? '').trim();
    if (planId.isNotEmpty) {
      return planId;
    }
    return 'session_${session.id ?? session.date}';
  }

  double _workoutVolumeKg(List<WorkoutSession> sessions) {
    return sessions.fold<double>(0, (sessionSum, session) {
      return sessionSum +
          session.sets.fold<double>(0, (setSum, set) {
            return setSum +
                set.effectiveCalculationLoadKg * set.effectiveCalculationReps;
          });
    });
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
        'diet_plan_strategy',
        'carb_day_type',
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
        'base_target_calories',
        'base_protein_target_g',
        'base_carbs_target_g',
        'base_fat_target_g',
        'final_target_calories',
        'final_protein_target_g',
        'final_carbs_target_g',
        'final_fat_target_g',
        'carb_adjustment_g',
        'carb_taper_current_delta_g',
        'calibration_confidence',
        'calibration_window_days',
        'calibration_valid_days',
        'target_protein_g',
        'target_carbs_g',
        'target_fat_g',
        'remaining_protein_g',
        'remaining_carbs_g',
        'remaining_fat_g',
        'base_macro_energy_equivalent_kcal',
        'final_macro_energy_equivalent_kcal',
        'macro_energy_equivalent_kcal',
        'diet_strategy_reason_codes',
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
        daily.dietPlanStrategy,
        daily.carbDayType ?? '',
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
        daily.baseTargetCalories,
        daily.baseProteinTargetG,
        daily.baseCarbsTargetG,
        daily.baseFatTargetG,
        daily.finalTargetCalories,
        daily.finalProteinTargetG,
        daily.finalCarbsTargetG,
        daily.finalFatTargetG,
        daily.carbAdjustmentG,
        daily.carbTaperCurrentDeltaG,
        daily.calibrationConfidence,
        daily.calibrationWindowDays,
        daily.calibrationValidDays,
        daily.targetProteinG,
        daily.targetCarbsG,
        daily.targetFatG,
        daily.remainingProteinG,
        daily.remainingCarbsG,
        daily.remainingFatG,
        daily.baseMacroEnergyEquivalentKcal,
        daily.finalMacroEnergyEquivalentKcal,
        daily.macroEnergyEquivalentKcal,
        daily.dietStrategyReasonCodes.join('|'),
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

  List<List<dynamic>> _buildDietAdjustmentReviewRows(
    List<DietAdjustmentReview> reviews,
  ) {
    return <List<dynamic>>[
      <dynamic>[
        'review_date',
        'window_days',
        'diet_goal_phase',
        'diet_calculation_mode',
        'diet_plan_strategy',
        'start_avg_weight_kg',
        'end_avg_weight_kg',
        'weight_change_kg',
        'loss_rate_pct_per_week',
        'target_loss_pct_per_week',
        'food_log_coverage',
        'active_training_days',
        'suggested_action',
        'suggested_carb_delta_g',
        'applied_delta_after_g',
        'confidence',
        'reason_codes_json',
        'user_decision',
      ],
      ...reviews.map(
        (review) => <dynamic>[
          review.reviewDate,
          review.windowDays,
          review.dietGoalPhase,
          review.dietCalculationMode,
          review.dietPlanStrategy,
          review.startAvgWeightKg,
          review.endAvgWeightKg,
          review.weightChangeKg,
          review.lossRatePctPerWeek,
          review.targetLossPctPerWeek,
          review.foodLogCoverage,
          review.activeTrainingDays,
          review.suggestedAction,
          review.suggestedCarbDeltaG,
          review.appliedDeltaAfterG,
          review.confidence,
          review.reasonCodesJson,
          review.userDecision,
        ],
      ),
    ];
  }
}

class ExportData {
  const ExportData({required this.tables, required this.firstRecordDate});

  final List<ExportTable> tables;
  final String? firstRecordDate;
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

class _WorkoutRecordGroup {
  const _WorkoutRecordGroup({required this.id, required this.sessions});

  final String id;
  final List<WorkoutSession> sessions;
}
