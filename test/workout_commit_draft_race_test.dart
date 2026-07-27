import 'dart:async';

import 'package:fitlog_local/app.dart';
import 'package:fitlog_local/core/constants/exercise_definition.dart';
import 'package:fitlog_local/core/localization/language_controller.dart';
import 'package:fitlog_local/data/db/app_database.dart';
import 'package:fitlog_local/data/repositories/custom_exercise_repository.dart';
import 'package:fitlog_local/data/repositories/food_repository.dart';
import 'package:fitlog_local/data/repositories/profile_repository.dart';
import 'package:fitlog_local/data/repositories/workout_draft_repository.dart';
import 'package:fitlog_local/data/repositories/workout_repository.dart';
import 'package:fitlog_local/domain/models/body_metric_log.dart';
import 'package:fitlog_local/domain/models/calorie_calibration_state.dart';
import 'package:fitlog_local/domain/models/diet_adjustment_review.dart';
import 'package:fitlog_local/domain/models/user_profile.dart';
import 'package:fitlog_local/domain/models/weight_log.dart';
import 'package:fitlog_local/domain/models/workout_record_draft.dart';
import 'package:fitlog_local/domain/models/workout_session.dart';
import 'package:fitlog_local/domain/models/workout_set.dart';
import 'package:fitlog_local/domain/services/carb_taper_review_service.dart';
import 'package:fitlog_local/domain/services/daily_summary_service.dart';
import 'package:fitlog_local/domain/services/diet_plan_strategy_service.dart';
import 'package:fitlog_local/domain/services/training_frequency_self_check_service.dart';
import 'package:fitlog_local/export/csv_export_service.dart';
import 'package:fitlog_local/export/export_share_service.dart';
import 'package:fitlog_local/export/xlsx_export_service.dart';
import 'package:fitlog_local/features/workout/add_workout_page.dart';
import 'package:fitlog_local/features/workout/workout_editor_resume_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _notificationChannel = MethodChannel('fitlog.local/workout_notification');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const WorkoutEditorResumeStore().clear();
  });

  testWidgets(
    'formal save drains an older draft write and blocks lifecycle autosave',
    (tester) async {
      final harness = _WorkoutCommitHarness();
      final notificationCalls = <String>[];
      await const WorkoutEditorResumeStore().markActive();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_notificationChannel, (call) async {
            notificationCalls.add(call.method);
            return null;
          });
      addTearDown(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_notificationChannel, null);
      });

      await tester.pumpWidget(harness.buildApp());
      await tester.pumpAndSettle();

      final blockedDraftSave = harness.draftRepository.blockNextSave();
      await tester.scrollUntilVisible(
        _recordNameField(),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(_recordNameField(), 'Updated chest day');
      await tester.pump(const Duration(milliseconds: 600));
      expect(harness.draftRepository.saveCallCount, 1);

      await tester.tap(_saveButton());
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(harness.draftRepository.saveCallCount, 1);
      expect(harness.workoutRepository.replaceCallCount, 0);

      blockedDraftSave.complete();
      await tester.pumpAndSettle();

      expect(harness.workoutRepository.replaceCallCount, 1);
      expect(harness.workoutRepository.clearActiveDraftRequests, <bool>[true]);
      expect(harness.draftRepository.activeDraft, isNull);
      expect(harness.draftRepository.operations.last, 'delete');
      expect(notificationCalls.last, 'cancelWorkoutNotification');
      expect(await _resumeMarkerActive(), isFalse);

      await harness.workoutRepository.deleteWorkoutPlan('plan-1');
      expect(harness.draftRepository.activeDraft, isNull);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    },
  );

  testWidgets('failed formal save restores the latest editable draft', (
    tester,
  ) async {
    final harness = _WorkoutCommitHarness()
      ..workoutRepository.failReplace = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationChannel, (call) async => null);
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_notificationChannel, null);
    });

    await tester.pumpWidget(harness.buildApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      _recordNameField(),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(_recordNameField(), 'Latest failed edit');
    await tester.tap(_saveButton());
    await tester.pumpAndSettle();

    expect(harness.workoutRepository.replaceCallCount, 1);
    expect(harness.draftRepository.activeDraft, isNotNull);
    expect(
      harness.draftRepository.activeDraft!.recordName,
      'Latest failed edit',
    );
    expect(_saveButton(), findsOneWidget);
  });
}

Future<bool> _resumeMarkerActive() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(WorkoutEditorResumeStore.activeKey) ?? false;
}

Finder _recordNameField() {
  return find.byKey(const ValueKey('workout_record_name_field'));
}

Finder _saveButton() {
  return find.widgetWithIcon(FilledButton, Icons.save_outlined);
}

class _WorkoutCommitHarness {
  _WorkoutCommitHarness()
    : workoutRepository = _FakeWorkoutRepository(AppDatabase.instance),
      draftRepository = _FakeWorkoutDraftRepository(AppDatabase.instance);

  final _FakeWorkoutRepository workoutRepository;
  final _FakeWorkoutDraftRepository draftRepository;

  Widget buildApp() {
    final database = AppDatabase.instance;
    final foodRepository = _FakeFoodRepository(database);
    final customExerciseRepository = _FakeCustomExerciseRepository(database);
    final profileRepository = _FakeProfileRepository(database);
    final trainingFrequencySelfCheckService = TrainingFrequencySelfCheckService(
      workoutRepository: workoutRepository,
    );
    final carbTaperReviewService = CarbTaperReviewService(
      foodRepository: foodRepository,
      workoutRepository: workoutRepository,
      profileRepository: profileRepository,
    );
    final dietPlanStrategyService = DietPlanStrategyService(
      carbTaperReviewService: carbTaperReviewService,
    );
    final dailySummaryService = DailySummaryService(
      foodRepository: foodRepository,
      workoutRepository: workoutRepository,
      profileRepository: profileRepository,
      trainingFrequencySelfCheckService: trainingFrequencySelfCheckService,
      dietPlanStrategyService: dietPlanStrategyService,
    );

    return MultiProvider(
      providers: [
        Provider<AppServices>.value(
          value: AppServices(
            foodRepository: foodRepository,
            customExerciseRepository: customExerciseRepository,
            workoutRepository: workoutRepository,
            workoutDraftRepository: draftRepository,
            profileRepository: profileRepository,
            dailySummaryService: dailySummaryService,
            xlsxExportService: XlsxExportService(
              foodRepository: foodRepository,
              customExerciseRepository: customExerciseRepository,
              workoutRepository: workoutRepository,
              profileRepository: profileRepository,
              dailySummaryService: dailySummaryService,
            ),
            csvExportService: CsvExportService(
              foodRepository: foodRepository,
              customExerciseRepository: customExerciseRepository,
              workoutRepository: workoutRepository,
              profileRepository: profileRepository,
              dailySummaryService: dailySummaryService,
            ),
            exportShareService: const NoopExportShareService(),
            carbTaperReviewService: carbTaperReviewService,
            dietPlanStrategyService: dietPlanStrategyService,
            trainingFrequencySelfCheckService:
                trainingFrequencySelfCheckService,
            database: database,
          ),
        ),
        ChangeNotifierProvider<RefreshNotifier>(
          create: (_) => RefreshNotifier(),
        ),
        ChangeNotifierProvider<RootTabController>(
          create: (_) => RootTabController(),
        ),
        ChangeNotifierProvider<SelectedDateNotifier>(
          create: (_) => SelectedDateNotifier(),
        ),
        ChangeNotifierProvider<LanguageController>(
          create: (_) => LanguageController(),
        ),
      ],
      child: const MaterialApp(
        home: AddWorkoutPage(
          initialDate: '2026-07-11',
          editingPlanId: 'plan-1',
          seedSessionId: 1,
        ),
      ),
    );
  }
}

class _FakeWorkoutRepository extends WorkoutRepository {
  _FakeWorkoutRepository(super.database);

  int replaceCallCount = 0;
  bool failReplace = false;
  final List<bool> clearActiveDraftRequests = <bool>[];

  final WorkoutSession seed = const WorkoutSession(
    id: 1,
    planId: 'plan-1',
    recordName: 'Chest day',
    date: '2026-07-11',
    bodyPart: 'Chest',
    exerciseName: 'Bench Press',
    exerciseKey: 'bench_press',
    exerciseSource: ExerciseSource.builtin,
    exerciseType: ExerciseType.strength,
    durationMinutes: 20,
    intensity: 'medium',
    estimatedCalories: 100,
    notes: '',
    sets: <WorkoutSet>[
      WorkoutSet(
        setNumber: 1,
        weightKg: 50,
        reps: 8,
        isCompleted: true,
        completedAt: '2026-07-11T10:00:00.000',
      ),
    ],
  );

  @override
  Future<List<WorkoutSession>> getWorkoutSessionsByPlanId(String planId) async {
    return planId == seed.planId ? <WorkoutSession>[seed] : <WorkoutSession>[];
  }

  @override
  Future<WorkoutSession?> getWorkoutSessionById(int id) async => seed;

  @override
  Future<void> replaceWorkoutPlan({
    required String planId,
    required List<WorkoutSession> sessions,
    bool clearActiveDraft = false,
  }) async {
    replaceCallCount++;
    clearActiveDraftRequests.add(clearActiveDraft);
    if (failReplace) {
      throw StateError('delayed commit failed');
    }
  }

  @override
  Future<void> deleteWorkoutPlan(String planId) async {}
}

class _FakeWorkoutDraftRepository extends WorkoutDraftRepository {
  _FakeWorkoutDraftRepository(super.database);

  WorkoutRecordDraft? activeDraft;
  int saveCallCount = 0;
  final List<String> operations = <String>[];
  Completer<void>? _nextSaveBlocker;

  Completer<void> blockNextSave() {
    return _nextSaveBlocker = Completer<void>();
  }

  @override
  Future<WorkoutRecordDraft?> getActiveDraft() async => activeDraft;

  @override
  Future<void> saveActiveDraft(WorkoutRecordDraft draft) async {
    saveCallCount++;
    operations.add('save-start');
    final blocker = _nextSaveBlocker;
    _nextSaveBlocker = null;
    await blocker?.future;
    activeDraft = draft;
    operations.add('save-end');
  }

  @override
  Future<void> deleteActiveDraft() async {
    activeDraft = null;
    operations.add('delete');
  }
}

class _FakeCustomExerciseRepository extends CustomExerciseRepository {
  _FakeCustomExerciseRepository(super.database);

  @override
  Future<List<ExerciseDefinition>> getActiveDefinitions() async =>
      const <ExerciseDefinition>[];
}

class _FakeFoodRepository extends FoodRepository {
  _FakeFoodRepository(super.database);
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(super.database);

  @override
  Future<UserProfile?> getProfile() async => UserProfile.defaults;

  @override
  Future<CalorieCalibrationState?> getCalorieCalibrationState() async => null;

  @override
  Future<List<WeightLog>> getWeightLogsBetween({
    required String startDate,
    required String endDate,
  }) async => const <WeightLog>[];

  @override
  Future<List<BodyMetricLog>> getBodyMetricLogsBetween({
    required String startDate,
    required String endDate,
  }) async => const <BodyMetricLog>[];

  @override
  Future<DietAdjustmentReview?> getLatestDietAdjustmentReview({
    String? userDecision,
  }) async => null;
}
