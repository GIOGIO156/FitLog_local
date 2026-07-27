import 'dart:convert';

import 'package:fitlog_local/app.dart';
import 'package:fitlog_local/core/constants/exercise_definition.dart';
import 'package:fitlog_local/core/fitlog_theme.dart';
import 'package:fitlog_local/core/localization/language_controller.dart';
import 'package:fitlog_local/core/theme_controller.dart';
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
import 'package:fitlog_local/domain/services/carb_taper_review_service.dart';
import 'package:fitlog_local/domain/services/daily_summary_service.dart';
import 'package:fitlog_local/domain/services/diet_plan_strategy_service.dart';
import 'package:fitlog_local/domain/services/training_frequency_self_check_service.dart';
import 'package:fitlog_local/export/csv_export_service.dart';
import 'package:fitlog_local/export/export_share_service.dart';
import 'package:fitlog_local/export/xlsx_export_service.dart';
import 'package:fitlog_local/features/workout/active_workout_draft_route_state.dart';
import 'package:fitlog_local/features/workout/add_workout_page.dart';
import 'package:fitlog_local/features/workout/workout_editor_resume_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _openEditorKey = ValueKey<String>('open-editor');
const _notificationChannel = MethodChannel('fitlog.local/workout_notification');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    ActiveWorkoutDraftRouteState.isEditorVisible = false;
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const WorkoutEditorResumeStore().clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationChannel, (call) async => null);
  });

  tearDown(() {
    ActiveWorkoutDraftRouteState.isEditorVisible = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_notificationChannel, null);
  });

  testWidgets(
    'cold root auto resumes active new draft, restores fields, and does not push twice',
    (tester) async {
      final harness = _WorkoutEditorResumeHarness(
        activeDraft: _draft(
          updatedAt: DateTime.now().subtract(const Duration(minutes: 29)),
          includeExercise: true,
        ),
      );
      await const WorkoutEditorResumeStore().markActive();

      await tester.pumpWidget(harness.buildRootApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(harness.rootTabController.index, 2);
      expect(find.byType(AddWorkoutPage), findsOneWidget);
      expect(_textFormValues(tester), contains('45'));
      expect(_textFieldValues(tester), contains('72.5'));
      expect(_textFieldValues(tester), contains('8'));
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      await tester.scrollUntilVisible(
        _recordNameField(),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester.widget<TextFormField>(_recordNameField()).controller?.text,
        'Restored chest day',
      );
      await tester.scrollUntilVisible(
        find.text('Jul 21, 2026'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Jul 21, 2026'), findsOneWidget);
      expect(_textFormValues(tester), contains('Keep shoulder blades packed'));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.byType(AddWorkoutPage), findsOneWidget);
    },
  );

  testWidgets(
    'explicit back keeps the SQLite draft but clears auto-resume for the next root',
    (tester) async {
      final harness = _WorkoutEditorResumeHarness(
        activeDraft: _draft(
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      await const WorkoutEditorResumeStore().markActive();

      await tester.pumpWidget(harness.buildLauncherApp());
      await tester.tap(find.byKey(_openEditorKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _pumpUntil(
        tester,
        () async => find.byType(AddWorkoutPage).evaluate().isEmpty,
      );
      await _pumpUntil(tester, () async => !await _resumeMarkerActive());

      expect(harness.draftRepository.activeDraft, isNotNull);
      expect(await _resumeMarkerActive(), isFalse);

      await tester.pumpWidget(harness.buildRootApp());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(AddWorkoutPage), findsNothing);
      expect(harness.rootTabController.index, 0);
    },
  );

  testWidgets('discarding the draft clears the auto-resume marker', (
    tester,
  ) async {
    final harness = _WorkoutEditorResumeHarness(
      activeDraft: _draft(
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    );
    await const WorkoutEditorResumeStore().markActive();

    await tester.pumpWidget(harness.buildLauncherApp());
    await tester.tap(find.byKey(_openEditorKey));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(OutlinedButton, 'Discard This Workout'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.widgetWithText(OutlinedButton, 'Discard This Workout'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Discard This Workout'));
    await tester.pumpAndSettle();
    await _pumpUntil(
      tester,
      () async => harness.draftRepository.activeDraft == null,
    );

    expect(harness.draftRepository.activeDraft, isNull);
    expect(await _resumeMarkerActive(), isFalse);
  });

  testWidgets(
    'clearing the editable draft content clears the auto-resume marker',
    (tester) async {
      final harness = _WorkoutEditorResumeHarness(
        activeDraft: _draft(
          recordName: 'Temporary workout',
          updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );
      await const WorkoutEditorResumeStore().markActive();

      await tester.pumpWidget(harness.buildLauncherApp());
      await tester.tap(find.byKey(_openEditorKey));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        _recordNameField(),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(_recordNameField(), '');
      expect(
        tester.widget<TextFormField>(_recordNameField()).controller?.text,
        '',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await _pumpUntil(
        tester,
        () async => harness.draftRepository.activeDraft == null,
      );

      expect(harness.draftRepository.activeDraft, isNull);
      expect(await _resumeMarkerActive(), isFalse);
    },
  );
}

Finder _recordNameField() {
  return find.byKey(const ValueKey('workout_record_name_field'));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Future<bool> Function() condition,
) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (await condition()) {
      return;
    }
  }
  expect(await condition(), isTrue);
}

List<String> _textFormValues(WidgetTester tester) {
  return tester
      .widgetList<TextFormField>(find.byType(TextFormField))
      .map((field) => field.controller?.text ?? '')
      .toList();
}

List<String> _textFieldValues(WidgetTester tester) {
  return tester
      .widgetList<TextField>(find.byType(TextField))
      .map((field) => field.controller?.text ?? '')
      .toList();
}

Future<bool> _resumeMarkerActive() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(WorkoutEditorResumeStore.activeKey) ?? false;
}

WorkoutRecordDraft _draft({
  String recordName = 'Restored chest day',
  required DateTime updatedAt,
  bool includeExercise = false,
}) {
  final exercises = includeExercise
      ? <Map<String, Object?>>[
          <String, Object?>{
            'exercise_key': 'bench_press',
            'exercise_source': ExerciseSource.builtin,
            'body_part': 'Chest',
            'secondary_body_part': null,
            'exercise_name': 'Bench Press',
            'exercise_type': ExerciseType.strength,
            'strength_profile': ExerciseStrengthProfile.upperBodyCompound,
            'load_input_mode': ExerciseLoadInputMode.totalLoad,
            'reps_input_mode': ExerciseRepsInputMode.totalReps,
            'set_metric_type': ExerciseSetMetricType.reps,
            'cardio_intensity_basis': CardioIntensityBasis.moderate30To60,
            'default_duration': '',
            'duration_text': '45',
            'default_active_duration': '',
            'active_duration_text': '',
            'sets': <Map<String, Object?>>[
              <String, Object?>{
                'default_weight': '',
                'default_reps': '',
                'weight_text': '72.5',
                'reps_text': '8',
                'is_completed': true,
                'completed_at': '2026-07-21T10:15:00.000',
                'show_weight_as_default': false,
                'show_reps_as_default': false,
              },
            ],
          },
        ]
      : <Map<String, Object?>>[];
  final timestamp = updatedAt.toIso8601String();
  return WorkoutRecordDraft(
    id: WorkoutRecordDraft.activeDraftId,
    kind: WorkoutRecordDraft.kindNewRecord,
    date: '2026-07-21',
    recordName: recordName,
    notes: includeExercise ? 'Keep shoulder blades packed' : '',
    payloadJson: jsonEncode(<String, Object?>{
      'kind': WorkoutRecordDraft.kindNewRecord,
      'date': '2026-07-21',
      'record_name': recordName,
      'notes': includeExercise ? 'Keep shoulder blades packed' : '',
      'exercises': exercises,
    }),
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

class _WorkoutEditorResumeHarness {
  _WorkoutEditorResumeHarness({WorkoutRecordDraft? activeDraft})
    : draftRepository = _FakeWorkoutDraftRepository(AppDatabase.instance)
        ..activeDraft = activeDraft;

  final _FakeWorkoutDraftRepository draftRepository;
  final RootTabController rootTabController = RootTabController();

  Widget buildRootApp() {
    return _buildProviderApp(
      home: buildRootShellForTest(
        pages: const <Widget>[
          _PlaceholderPage('Home'),
          _PlaceholderPage('Food'),
          _PlaceholderPage('Workout'),
          _PlaceholderPage('Profile'),
        ],
      ),
    );
  }

  Widget buildLauncherApp() {
    return _buildProviderApp(
      home: const _EditorLauncher(initialDate: '2026-07-21'),
    );
  }

  Widget _buildProviderApp({required Widget home}) {
    final database = AppDatabase.instance;
    final foodRepository = _FakeFoodRepository(database);
    final workoutRepository = _FakeWorkoutRepository(database);
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
    const palette = FitLogPalettes.green;

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
        ChangeNotifierProvider<RootTabController>.value(
          value: rootTabController,
        ),
        ChangeNotifierProvider<SelectedDateNotifier>(
          create: (_) => SelectedDateNotifier(),
        ),
        ChangeNotifierProvider<LanguageController>(
          create: (_) => LanguageController(),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: palette.brightness,
          scaffoldBackgroundColor: palette.background,
          extensions: <ThemeExtension<dynamic>>[palette],
        ),
        home: home,
      ),
    );
  }
}

class _EditorLauncher extends StatelessWidget {
  const _EditorLauncher({required this.initialDate});

  final String initialDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: _openEditorKey,
          onPressed: () {
            Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => AddWorkoutPage(initialDate: initialDate),
              ),
            );
          },
          child: const Text('Open editor'),
        ),
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(label));
  }
}

class _FakeFoodRepository extends FoodRepository {
  _FakeFoodRepository(super.database);
}

class _FakeCustomExerciseRepository extends CustomExerciseRepository {
  _FakeCustomExerciseRepository(super.database);

  @override
  Future<List<ExerciseDefinition>> getActiveDefinitions() async =>
      const <ExerciseDefinition>[];
}

class _FakeWorkoutRepository extends WorkoutRepository {
  _FakeWorkoutRepository(super.database);

  @override
  Future<List<WorkoutSession>> getWorkoutSessionsByPlanId(String planId) async {
    return const <WorkoutSession>[];
  }

  @override
  Future<WorkoutSession?> getWorkoutSessionById(int id) async => null;
}

class _FakeWorkoutDraftRepository extends WorkoutDraftRepository {
  _FakeWorkoutDraftRepository(super.database);

  WorkoutRecordDraft? activeDraft;
  int saveCallCount = 0;
  int deleteCallCount = 0;

  @override
  Future<WorkoutRecordDraft?> getActiveDraft() async => activeDraft;

  @override
  Future<void> saveActiveDraft(WorkoutRecordDraft draft) async {
    saveCallCount++;
    activeDraft = draft;
  }

  @override
  Future<void> deleteActiveDraft() async {
    deleteCallCount++;
    activeDraft = null;
  }
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
  }) async {
    return const <WeightLog>[];
  }

  @override
  Future<List<BodyMetricLog>> getBodyMetricLogsBetween({
    required String startDate,
    required String endDate,
  }) async {
    return const <BodyMetricLog>[];
  }

  @override
  Future<DietAdjustmentReview?> getLatestDietAdjustmentReview({
    String? userDecision,
  }) async {
    return null;
  }
}
