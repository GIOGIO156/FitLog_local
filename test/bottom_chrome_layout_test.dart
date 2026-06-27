import 'package:fitlog_local/app.dart';
import 'package:fitlog_local/core/constants/app_constants.dart';
import 'package:fitlog_local/core/fitlog_theme.dart';
import 'package:fitlog_local/core/localization/language_controller.dart';
import 'package:fitlog_local/core/theme_controller.dart';
import 'package:fitlog_local/core/widgets/fitlog_bottom_nav_layout.dart';
import 'package:fitlog_local/core/widgets/fitlog_notifications.dart';
import 'package:fitlog_local/data/db/app_database.dart';
import 'package:fitlog_local/data/repositories/custom_exercise_repository.dart';
import 'package:fitlog_local/data/repositories/food_repository.dart';
import 'package:fitlog_local/data/repositories/profile_repository.dart';
import 'package:fitlog_local/data/repositories/workout_draft_repository.dart';
import 'package:fitlog_local/data/repositories/workout_repository.dart';
import 'package:fitlog_local/domain/models/body_metric_log.dart';
import 'package:fitlog_local/domain/models/calorie_calibration_state.dart';
import 'package:fitlog_local/domain/models/diet_adjustment_review.dart';
import 'package:fitlog_local/domain/models/food_record.dart';
import 'package:fitlog_local/domain/models/user_profile.dart';
import 'package:fitlog_local/domain/models/weight_log.dart';
import 'package:fitlog_local/domain/models/workout_record_draft.dart';
import 'package:fitlog_local/domain/models/workout_session.dart';
import 'package:fitlog_local/domain/services/carb_taper_review_service.dart';
import 'package:fitlog_local/domain/services/daily_summary_service.dart';
import 'package:fitlog_local/domain/services/diet_plan_strategy_service.dart';
import 'package:fitlog_local/domain/services/training_frequency_self_check_service.dart';
import 'package:fitlog_local/export/csv_export_service.dart';
import 'package:fitlog_local/export/xlsx_export_service.dart';
import 'package:fitlog_local/features/food/food_log_page.dart';
import 'package:fitlog_local/features/home/home_page.dart';
import 'package:fitlog_local/features/profile/profile_page.dart';
import 'package:fitlog_local/features/workout/workout_log_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Bottom nav is an overlay while keeping measured pill geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildRootShellChromeTestApp(initialTab: 0));
    await _pumpUntilFound(tester, find.byKey(_navPillKey));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isNull);

    final navOverlayRect = tester.getRect(find.byKey(_navOverlayKey));
    final navPillRect = tester.getRect(find.byKey(_navPillKey));
    final navShieldRect = tester.getRect(find.byKey(_navShieldKey));

    expect(navOverlayRect.left, 0);
    expect(navOverlayRect.right, 390);
    expect(navOverlayRect.height, _expectedNavFootprint);
    expect(navOverlayRect.bottom, 844);
    expect(navPillRect.left, 16);
    expect(navPillRect.right, 374);
    expect(navPillRect.height, FitLogBottomNavLayout.pillHeight);
    expect(navPillRect.top, 844 - _expectedNavFootprint);
    expect(navPillRect.bottom, 844 - FitLogBottomNavLayout.minBottomGap);
    expect(navShieldRect.left, navPillRect.left);
    expect(navShieldRect.right, navPillRect.right);
    expect(navShieldRect.width, navPillRect.width);
    expect(navShieldRect.left, isNot(0));
    expect(navShieldRect.right, isNot(390));
    expect(
      navShieldRect.top,
      navPillRect.top + FitLogBottomNavLayout.pillHeight / 2,
    );
    expect(navShieldRect.height, _expectedShieldHeight);

    final navPill = tester.widget<Container>(find.byKey(_navPillKey));
    final navDecoration = navPill.decoration! as BoxDecoration;
    expect(navDecoration.color, FitLogPalettes.green.navBackground);
    expect((navDecoration.color!.toARGB32() >> 24) & 0xFF, 0xFF);
    expect(navDecoration.boxShadow, isNotEmpty);
    final navShield = tester.widget<DecoratedBox>(find.byKey(_navShieldKey));
    final shieldDecoration = navShield.decoration as BoxDecoration;
    expect(shieldDecoration.color, FitLogPalettes.green.background);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home first viewport bottom stays aligned to nav pill top', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildRootShellChromeTestApp(initialTab: 0));
    await tester.pumpAndSettle();

    final navPillRect = tester.getRect(find.byKey(_navPillKey));
    final firstViewportRect = tester.getRect(find.byKey(_homeFirstViewportKey));

    expect(firstViewportRect.height, 844 - _expectedNavFootprint);
    expect(firstViewportRect.bottom, navPillRect.top);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Food add CTA and list padding are anchored to nav helper', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildRootShellChromeTestApp(
        initialTab: 1,
        foodRecords: const <FoodRecord>[_foodRecord],
      ),
    );
    await tester.pumpAndSettle();

    final navPillRect = tester.getRect(find.byKey(_navPillKey));
    final rect = tester.getRect(find.byKey(_foodCtaKey));
    final listView = tester.widget<ListView>(find.byType(ListView));
    final listPadding = listView.padding as EdgeInsets;

    expect(rect.left, 16);
    expect(rect.right, 374);
    expect(rect.height, 56);
    expect(
      rect.bottom,
      844 - _expectedNavFootprint - FitLogBottomNavLayout.ctaToNavGap,
    );
    expect(navPillRect.top - rect.bottom, FitLogBottomNavLayout.ctaToNavGap);
    expect(listPadding.bottom, _expectedCtaListBottomPadding);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Workout add CTA and list padding are anchored to nav helper', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildRootShellChromeTestApp(
        initialTab: 2,
        workoutSessions: <WorkoutSession>[_workoutSession],
      ),
    );
    await tester.pumpAndSettle();

    final navPillRect = tester.getRect(find.byKey(_navPillKey));
    final rect = tester.getRect(find.byKey(_workoutCtaKey));
    final listView = tester.widget<ListView>(find.byType(ListView));
    final listPadding = listView.padding as EdgeInsets;

    expect(rect.left, 16);
    expect(rect.right, 374);
    expect(rect.height, 56);
    expect(
      rect.bottom,
      844 - _expectedNavFootprint - FitLogBottomNavLayout.ctaToNavGap,
    );
    expect(navPillRect.top - rect.bottom, FitLogBottomNavLayout.ctaToNavGap);
    expect(listPadding.bottom, _expectedCtaListBottomPadding);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home strategy guide sheet stays above dimmed bottom nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildRootShellChromeTestApp(
        initialTab: 0,
        profile: UserProfile.defaults.copyWith(
          dietPlanStrategy: AppConstants.dietPlanStrategyCarbCycling,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Carb cycle').first);
    await tester.pumpAndSettle();

    final navPillRect = tester.getRect(find.byKey(_navPillKey));
    final guideRect = tester.getRect(find.byKey(_guideSheetPanelKey));

    expect(find.byType(ModalBarrier), findsWidgets);
    expect(guideRect.bottom, lessThanOrEqualTo(navPillRect.top));
    expect(navPillRect.top - guideRect.bottom, _guideSheetToNavGap);
    expect(guideRect.top, greaterThanOrEqualTo(_expectedGuideTopGap));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Profile method guide sheet stays above dimmed bottom nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_buildRootShellChromeTestApp(initialTab: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.info_outline_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final navPillRect = tester.getRect(find.byKey(_navPillKey));
    final guideRect = tester.getRect(find.byKey(_guideSheetPanelKey));

    expect(find.byType(ModalBarrier), findsWidgets);
    expect(guideRect.bottom, lessThanOrEqualTo(navPillRect.top));
    expect(navPillRect.top - guideRect.bottom, _guideSheetToNavGap);
    expect(guideRect.top, greaterThanOrEqualTo(_expectedGuideTopGap));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Success notification is a lightweight top notice above nav', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildRootShellChromeTestApp(
        initialTab: 0,
        pages: const <Widget>[
          _NotificationTestPage(kind: _NotificationKind.success),
          SizedBox.shrink(),
          SizedBox.shrink(),
          SizedBox.shrink(),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_notificationTriggerKey));
    await tester.pump();

    final navPillRect = tester.getRect(find.byKey(_navPillKey));
    final noticeRect = tester.getRect(
      find.byKey(const ValueKey<String>('fitlog_notification_success')),
    );

    expect(noticeRect.bottom, lessThan(navPillRect.top));
    expect(noticeRect.top, greaterThanOrEqualTo(12));

    await tester.tap(find.byKey(_notificationCloseKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Error notification floats above the bottom nav footprint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildRootShellChromeTestApp(
        initialTab: 0,
        pages: const <Widget>[
          _NotificationTestPage(kind: _NotificationKind.error),
          SizedBox.shrink(),
          SizedBox.shrink(),
          SizedBox.shrink(),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_notificationTriggerKey));
    await tester.pump();

    final navPillRect = tester.getRect(find.byKey(_navPillKey));
    final noticeRect = tester.getRect(
      find.byKey(const ValueKey<String>('fitlog_notification_error')),
    );

    expect(noticeRect.bottom, lessThanOrEqualTo(navPillRect.top));
    expect(navPillRect.top - noticeRect.bottom, 12);

    await tester.tap(find.byKey(_notificationCloseKey));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Action notification keeps its button callback', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _buildRootShellChromeTestApp(
        initialTab: 0,
        pages: const <Widget>[
          _NotificationTestPage(kind: _NotificationKind.action),
          SizedBox.shrink(),
          SizedBox.shrink(),
          SizedBox.shrink(),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_notificationTriggerKey));
    await tester.pump();
    expect(find.text('Action count 0'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('fitlog_notification_action_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Action count 1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('fitlog_notification_action')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

const _navOverlayKey = ValueKey<String>('fitlog_bottom_nav_overlay');
const _navPillKey = ValueKey<String>('fitlog_bottom_nav_pill');
const _navShieldKey = ValueKey<String>('fitlog_bottom_nav_shield');
const _guideSheetPanelKey = ValueKey<String>('fitlog_guide_sheet_panel');
const _homeFirstViewportKey = ValueKey<String>('fitlog_home_first_viewport');
const _foodCtaKey = ValueKey<String>('fitlog_food_add_cta');
const _workoutCtaKey = ValueKey<String>('fitlog_workout_add_cta');
const _notificationTriggerKey = ValueKey<String>('fitlog_notification_trigger');
const _notificationCloseKey = ValueKey<String>(
  'fitlog_notification_close_button',
);
const _referenceDay = '2026-06-25';
const _expectedNavFootprint =
    FitLogBottomNavLayout.pillHeight + FitLogBottomNavLayout.minBottomGap;
const _expectedShieldHeight =
    FitLogBottomNavLayout.pillHeight / 2 +
    FitLogBottomNavLayout.minBottomGap +
    1;
const _expectedCtaListBottomPadding =
    _expectedNavFootprint +
    FitLogBottomNavLayout.ctaToNavGap +
    FitLogBottomNavLayout.ctaHeight +
    FitLogBottomNavLayout.listAfterCtaGap;
const _guideSheetToNavGap = FitLogBottomNavLayout.modalSheetOuterGap;
const _expectedGuideTopGap = FitLogBottomNavLayout.modalSheetTopGap;
const _foodRecord = FoodRecord(
  date: _referenceDay,
  mealName: 'A',
  totalWeightG: 1,
  caloriesKcal: 1,
  proteinG: 1,
  carbsG: 1,
  fatG: 1,
  estimationNotes: '',
  source: 'manual',
);
final _workoutSession = WorkoutSession(
  date: _referenceDay,
  bodyPart: 'Chest',
  exerciseName: 'Bench Press',
  exerciseType: 'strength',
  durationMinutes: 40,
  intensity: 'medium',
  estimatedCalories: 180,
  notes: '',
);

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsOneWidget);
}

Widget _buildRootShellChromeTestApp({
  required int initialTab,
  List<FoodRecord> foodRecords = const <FoodRecord>[],
  List<WorkoutSession> workoutSessions = const <WorkoutSession>[],
  UserProfile? profile,
  List<Widget>? pages,
}) {
  final database = AppDatabase.instance;
  final foodRepository = _FakeFoodRepository(database)
    ..recordsByDate[_referenceDay] = foodRecords;
  final customExerciseRepository = CustomExerciseRepository(database);
  final workoutRepository = _FakeWorkoutRepository(database)
    ..sessionsByDate[_referenceDay] = workoutSessions;
  final workoutDraftRepository = _FakeWorkoutDraftRepository(database);
  final profileRepository = _FakeProfileRepository(database)
    ..profile = profile ?? UserProfile.defaults;
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
  final selectedDateNotifier = SelectedDateNotifier()..setDate(_referenceDay);
  final rootTabController = RootTabController()..setIndex(initialTab);
  final palette = FitLogPalettes.green;

  return MultiProvider(
    providers: [
      Provider<AppServices>.value(
        value: AppServices(
          foodRepository: foodRepository,
          customExerciseRepository: customExerciseRepository,
          workoutRepository: workoutRepository,
          workoutDraftRepository: workoutDraftRepository,
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
          carbTaperReviewService: carbTaperReviewService,
          dietPlanStrategyService: dietPlanStrategyService,
          trainingFrequencySelfCheckService: trainingFrequencySelfCheckService,
          database: database,
        ),
      ),
      ChangeNotifierProvider<RefreshNotifier>(create: (_) => RefreshNotifier()),
      ChangeNotifierProvider<RootTabController>.value(value: rootTabController),
      ChangeNotifierProvider<SelectedDateNotifier>.value(
        value: selectedDateNotifier,
      ),
      ChangeNotifierProvider<LanguageController>(
        create: (_) => LanguageController(),
      ),
      ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController()),
    ],
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: palette.brightness,
        scaffoldBackgroundColor: palette.background,
        extensions: <ThemeExtension<dynamic>>[palette],
      ),
      home: buildRootShellForTest(
        pages:
            pages ??
            const <Widget>[
              HomePage(),
              FoodLogPage(),
              WorkoutLogPage(),
              ProfilePage(),
            ],
      ),
    ),
  );
}

enum _NotificationKind { success, error, action }

class _NotificationTestPage extends StatefulWidget {
  const _NotificationTestPage({required this.kind});

  final _NotificationKind kind;

  @override
  State<_NotificationTestPage> createState() => _NotificationTestPageState();
}

class _NotificationTestPageState extends State<_NotificationTestPage> {
  int _actionCount = 0;

  void _showNotification() {
    switch (widget.kind) {
      case _NotificationKind.success:
        FitLogNotifications.success(context, 'Saved');
        break;
      case _NotificationKind.error:
        FitLogNotifications.error(context, 'Invalid input');
        break;
      case _NotificationKind.action:
        FitLogNotifications.action(
          context,
          'Restore record',
          actionLabel: 'Restore',
          onPressed: () => setState(() => _actionCount++),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Action count $_actionCount'),
            FilledButton(
              key: _notificationTriggerKey,
              onPressed: _showNotification,
              child: const Text('Show notification'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FakeFoodRepository extends FoodRepository {
  _FakeFoodRepository(super.database);

  final Map<String, List<FoodRecord>> recordsByDate =
      <String, List<FoodRecord>>{};

  @override
  Future<List<FoodRecord>> getFoodRecordsByDate(String day) async {
    return recordsByDate[day] ?? const <FoodRecord>[];
  }

  @override
  Future<double> getCaloriesInByDate(String day) async {
    return (recordsByDate[day] ?? const <FoodRecord>[]).fold<double>(
      0,
      (sum, record) => sum + record.caloriesKcal,
    );
  }

  @override
  Future<Map<String, double>> getDailyCaloriesBetween({
    required String startDate,
    required String endDate,
  }) async {
    return <String, double>{
      for (final entry in recordsByDate.entries)
        if (entry.key.compareTo(startDate) >= 0 &&
            entry.key.compareTo(endDate) <= 0)
          entry.key: entry.value.fold<double>(
            0,
            (sum, record) => sum + record.caloriesKcal,
          ),
    };
  }
}

class _FakeWorkoutRepository extends WorkoutRepository {
  _FakeWorkoutRepository(super.database);

  final Map<String, List<WorkoutSession>> sessionsByDate =
      <String, List<WorkoutSession>>{};

  @override
  Future<List<WorkoutSession>> getWorkoutSessionsByDate(String day) async {
    return sessionsByDate[day] ?? const <WorkoutSession>[];
  }

  @override
  Future<List<WorkoutSession>> getWorkoutSessionsBetween({
    required String startDate,
    required String endDate,
  }) async {
    return sessionsByDate.entries
        .where(
          (entry) =>
              entry.key.compareTo(startDate) >= 0 &&
              entry.key.compareTo(endDate) <= 0,
        )
        .expand((entry) => entry.value)
        .toList();
  }

  @override
  Future<Map<String, double>> getDailyExerciseCaloriesBetween({
    required String startDate,
    required String endDate,
  }) async {
    return <String, double>{
      for (final entry in sessionsByDate.entries)
        if (entry.key.compareTo(startDate) >= 0 &&
            entry.key.compareTo(endDate) <= 0)
          entry.key: entry.value.fold<double>(
            0,
            (sum, session) => sum + session.estimatedCalories,
          ),
    };
  }

  @override
  Future<double> getExerciseCaloriesByDate(String day) async {
    return (sessionsByDate[day] ?? const <WorkoutSession>[]).fold<double>(
      0,
      (sum, session) => sum + session.estimatedCalories,
    );
  }
}

class _FakeWorkoutDraftRepository extends WorkoutDraftRepository {
  _FakeWorkoutDraftRepository(super.database);

  @override
  Future<WorkoutRecordDraft?> getActiveDraft() async => null;
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository(super.database);

  UserProfile profile = UserProfile.defaults;

  @override
  Future<UserProfile?> getProfile() async => profile;

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
