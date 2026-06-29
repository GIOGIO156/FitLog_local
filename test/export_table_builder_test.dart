import 'package:fitlog_local/core/constants/app_constants.dart';
import 'package:fitlog_local/core/constants/exercise_definition.dart';
import 'package:fitlog_local/core/localization/app_language.dart';
import 'package:fitlog_local/core/localization/app_strings.dart';
import 'package:fitlog_local/data/db/app_database.dart';
import 'package:fitlog_local/data/repositories/custom_exercise_repository.dart';
import 'package:fitlog_local/data/repositories/food_repository.dart';
import 'package:fitlog_local/data/repositories/profile_repository.dart';
import 'package:fitlog_local/data/repositories/workout_repository.dart';
import 'package:fitlog_local/domain/models/body_metric_log.dart';
import 'package:fitlog_local/domain/models/diet_adjustment_review.dart';
import 'package:fitlog_local/domain/models/food_item.dart';
import 'package:fitlog_local/domain/models/food_record.dart';
import 'package:fitlog_local/domain/models/user_profile.dart';
import 'package:fitlog_local/domain/models/workout_session.dart';
import 'package:fitlog_local/domain/models/workout_set.dart';
import 'package:fitlog_local/domain/services/daily_summary_service.dart';
import 'package:fitlog_local/domain/services/carb_taper_review_service.dart';
import 'package:fitlog_local/domain/services/diet_plan_strategy_service.dart';
import 'package:fitlog_local/domain/services/training_frequency_self_check_service.dart';
import 'package:fitlog_local/export/export_table_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Chinese export localizes table names and workout parent-child rows',
    () async {
      final database = AppDatabase.instance;
      final foodRepository = _FakeFoodRepository(database)
        ..records = <FoodRecord>[
          FoodRecord(
            id: 1,
            date: '2026-06-01',
            mealName: '早餐',
            totalWeightG: 300,
            caloriesKcal: 500,
            proteinG: 30,
            carbsG: 60,
            fatG: 12,
            confidence: 0.8,
            estimationNotes: 'ok',
            source: AppConstants.sourceAiPaste,
            items: const <FoodItem>[
              FoodItem(
                foodRecordId: 1,
                name: '米饭',
                estimatedWeightG: 200,
                caloriesKcal: 260,
                proteinG: 5,
                carbsG: 56,
                fatG: 1,
                notes: '',
              ),
            ],
          ),
        ];
      final workoutRepository = _FakeWorkoutRepository(database)
        ..sessions = <WorkoutSession>[
          WorkoutSession(
            id: 10,
            planId: 'plan_a',
            recordName: '循环3 周5',
            date: '2026-06-02',
            bodyPart: 'Chest',
            exerciseName: 'Bench Press',
            exerciseType: ExerciseType.strength,
            durationMinutes: 30,
            intensity: 'medium',
            loadInputMode: ExerciseLoadInputMode.totalLoad,
            repsInputMode: ExerciseRepsInputMode.totalReps,
            setMetricType: ExerciseSetMetricType.reps,
            estimatedCalories: 100,
            notes: 'push',
            sets: const <WorkoutSet>[
              WorkoutSet(
                workoutSessionId: 10,
                setNumber: 1,
                weightKg: 50,
                reps: 8,
                calculationLoadKg: 50,
                calculationReps: 8,
                loadInputMode: ExerciseLoadInputMode.totalLoad,
                repsInputMode: ExerciseRepsInputMode.totalReps,
                setMetricType: ExerciseSetMetricType.reps,
                isCompleted: true,
                completedAt: '2026-06-02T10:00:00',
              ),
              WorkoutSet(
                workoutSessionId: 10,
                setNumber: 2,
                weightKg: 55,
                reps: 6,
                calculationLoadKg: 55,
                calculationReps: 6,
                loadInputMode: ExerciseLoadInputMode.totalLoad,
                repsInputMode: ExerciseRepsInputMode.totalReps,
                setMetricType: ExerciseSetMetricType.reps,
                isCompleted: true,
                completedAt: '2026-06-02T10:05:00',
              ),
            ],
          ),
          WorkoutSession(
            id: 11,
            planId: 'plan_a',
            recordName: '循环3 周5',
            date: '2026-06-02',
            bodyPart: 'Legs',
            exerciseName: 'Squat',
            exerciseType: ExerciseType.strength,
            durationMinutes: 40,
            intensity: 'medium',
            loadInputMode: ExerciseLoadInputMode.totalLoad,
            repsInputMode: ExerciseRepsInputMode.totalReps,
            setMetricType: ExerciseSetMetricType.reps,
            estimatedCalories: 120,
            notes: 'legs',
            sets: const <WorkoutSet>[
              WorkoutSet(
                workoutSessionId: 11,
                setNumber: 1,
                weightKg: 80,
                reps: 5,
                calculationLoadKg: 80,
                calculationReps: 5,
                loadInputMode: ExerciseLoadInputMode.totalLoad,
                repsInputMode: ExerciseRepsInputMode.totalReps,
                setMetricType: ExerciseSetMetricType.reps,
                isCompleted: true,
                completedAt: '2026-06-02T10:15:00',
              ),
            ],
          ),
        ];
      final profileRepository = _FakeProfileRepository(database);
      final customExerciseRepository = _FakeCustomExerciseRepository(database);
      final dailySummaryService = DailySummaryService(
        foodRepository: foodRepository,
        workoutRepository: workoutRepository,
        profileRepository: profileRepository,
        trainingFrequencySelfCheckService: TrainingFrequencySelfCheckService(
          workoutRepository: workoutRepository,
        ),
        dietPlanStrategyService: DietPlanStrategyService(
          carbTaperReviewService: CarbTaperReviewService(
            foodRepository: foodRepository,
            workoutRepository: workoutRepository,
            profileRepository: profileRepository,
          ),
        ),
      );

      final exportData = await ExportTableBuilder(
        foodRepository: foodRepository,
        customExerciseRepository: customExerciseRepository,
        workoutRepository: workoutRepository,
        profileRepository: profileRepository,
        dailySummaryService: dailySummaryService,
        language: AppLanguage.chinese,
      ).build();

      expect(exportData.firstRecordDate, '2026-06-01');
      expect(
        exportData.tables.map((table) => table.sheetName),
        contains('饮食记录'),
      );
      expect(
        exportData.tables.map((table) => table.sheetName),
        contains('训练记录'),
      );
      expect(
        exportData.tables.map((table) => table.sheetName),
        contains('训练动作明细'),
      );

      final foodRecords = _table(exportData, '饮食记录');
      expect(foodRecords.fileName, '饮食记录.csv');
      expect(foodRecords.rows.first, contains('来源'));
      expect(
        foodRecords.rows[1],
        contains(AppStrings(AppLanguage.chinese).sourceLabel('ai_paste')),
      );
      final foodItems = _table(exportData, '食物明细');
      expect(foodItems.rows.first, contains('食物名称'));

      final workoutRecords = _table(exportData, '训练记录');
      expect(workoutRecords.fileName, '训练记录.csv');
      expect(
        workoutRecords.rows.first,
        containsAll(<String>['训练记录ID', '总运动量_kg', '记录动作']),
      );
      expect(workoutRecords.rows.length, 2);
      expect(workoutRecords.rows[1][0], 'plan_a');
      expect(workoutRecords.rows[1][3], 70);
      expect(workoutRecords.rows[1][4], 1130);
      expect(workoutRecords.rows[1][5], 3);
      expect(
        workoutRecords.rows[1][8],
        '${AppStrings(AppLanguage.chinese).exerciseDisplayName('Bench Press')} / ${AppStrings(AppLanguage.chinese).exerciseDisplayName('Squat')}',
      );

      final workoutDetails = _table(exportData, '训练动作明细');
      expect(workoutDetails.fileName, '训练动作明细.csv');
      expect(
        workoutDetails.rows.first,
        containsAll(<String>['训练记录ID', '动作名', '部位', '是否完成']),
      );
      expect(workoutDetails.rows.length, 4);
      for (final row in workoutDetails.rows.skip(1)) {
        expect(row[0], 'plan_a');
      }
      expect(
        workoutDetails.rows[1][5],
        AppStrings(AppLanguage.chinese).exerciseDisplayName('Bench Press'),
      );
      expect(
        workoutDetails.rows[1][6],
        AppStrings(AppLanguage.chinese).bodyPartLabel('Chest'),
      );
      expect(workoutDetails.rows[1][8], '力量');
      expect(workoutDetails.rows[1][22], '是');

      final bodyMetricLogs = _table(exportData, '身体指标记录');
      expect(bodyMetricLogs.rows.first, contains('体重_kg'));
    },
  );
}

ExportTable _table(ExportData data, String sheetName) {
  return data.tables.singleWhere((table) => table.sheetName == sheetName);
}

class _FakeFoodRepository extends FoodRepository {
  _FakeFoodRepository(super.database);

  List<FoodRecord> records = const <FoodRecord>[];

  @override
  Future<List<FoodRecord>> getAllFoodRecords() async => records;

  @override
  Future<List<String>> getDistinctDates() async => const <String>[];
}

class _FakeWorkoutRepository extends WorkoutRepository {
  _FakeWorkoutRepository(super.database);

  List<WorkoutSession> sessions = const <WorkoutSession>[];

  @override
  Future<List<WorkoutSession>> getAllWorkoutSessions() async => sessions;

  @override
  Future<List<String>> getDistinctDates() async => const <String>[];
}

class _FakeCustomExerciseRepository extends CustomExerciseRepository {
  _FakeCustomExerciseRepository(super.database);

  @override
  Future<List<ExerciseDefinition>> getAllDefinitions() async =>
      const <ExerciseDefinition>[];
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(super.database);

  @override
  Future<UserProfile?> getProfile() async => UserProfile.defaults;

  @override
  Future<List<BodyMetricLog>> getAllBodyMetricLogs() async =>
      const <BodyMetricLog>[];

  @override
  Future<List<DietAdjustmentReview>> getAllDietAdjustmentReviews() async =>
      const <DietAdjustmentReview>[];
}
