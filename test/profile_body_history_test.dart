import 'package:fitlog_local/app.dart';
import 'package:fitlog_local/core/fitlog_theme.dart';
import 'package:fitlog_local/core/localization/language_controller.dart';
import 'package:fitlog_local/core/theme_controller.dart';
import 'package:fitlog_local/core/utils/date_utils.dart';
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
import 'package:fitlog_local/features/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('body trend x positions start at the first visible point slot', () {
    final firstDay = DateTime(2026, 6, 25);
    final nextDay = DateTime(2026, 6, 26);

    expect(
      bodyTrendChartXRatio(
        firstVisiblePointDay: firstDay,
        pointDay: firstDay,
        rangeDays: 7,
      ),
      0,
    );
    final sevenDayGap = bodyTrendChartXRatio(
      firstVisiblePointDay: firstDay,
      pointDay: nextDay,
      rangeDays: 7,
    );
    final twentyEightDayGap = bodyTrendChartXRatio(
      firstVisiblePointDay: firstDay,
      pointDay: nextDay,
      rangeDays: 28,
    );

    expect(sevenDayGap, closeTo(1 / 6, 0.0001));
    expect(twentyEightDayGap, closeTo(1 / 27, 0.0001));
    expect(sevenDayGap, greaterThan(twentyEightDayGap));
  });

  test('body trend grid values use metric-aware readable intervals', () {
    expect(
      bodyTrendChartGridValues(values: const <double>[81, 82, 83], unit: 'kg'),
      const <double>[81, 82, 83],
    );
    expect(
      bodyTrendChartGridValues(values: const <double>[81.5], unit: 'kg'),
      const <double>[81, 82, 83],
    );
    expect(
      bodyTrendChartGridValues(values: const <double>[80.5, 83], unit: 'cm'),
      const <double>[80, 81, 82, 83],
    );
    expect(
      bodyTrendChartGridValues(values: const <double>[18, 28], unit: '%'),
      const <double>[15, 20, 25, 30],
    );
  });

  testWidgets(
    'body profile shows full fields and trend has no weight history list',
    (tester) async {
      _setTallPhoneView(tester);
      final profileRepository = _FakeProfileRepository(
        profile: UserProfile.defaults.copyWith(
          age: 26,
          heightCm: 174,
          weightKg: 82,
          bodyFatPercent: 20,
          waistCm: 83,
          sexForFormula: 'male',
        ),
      );

      await tester.pumpWidget(_buildProfileTestApp(profileRepository));
      await _pumpUntilFound(tester, find.text('Records 1/14'));

      expect(find.text('Age'), findsOneWidget);
      expect(find.text('Height'), findsOneWidget);
      expect(find.text('Weight'), findsWidgets);
      expect(find.text('Sex'), findsOneWidget);
      expect(find.text('Body Fat'), findsWidgets);
      expect(find.text('Waist'), findsWidgets);
      expect(find.text('Records 1/14'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('profile_weight_history_empty')),
        findsNothing,
      );
    },
  );

  testWidgets('body trend switches between weight, body fat, and waist', (
    tester,
  ) async {
    _setTallPhoneView(tester);
    final olderDay = _dateDaysAgo(5);
    final laterDay = _dateDaysAgo(2);
    final profileRepository = _FakeProfileRepository(
      profile: UserProfile.defaults.copyWith(
        weightKg: 83.2,
        bodyFatPercent: 20.5,
        waistCm: 82.0,
      ),
      bodyMetricLogs: <BodyMetricLog>[
        _bodyMetricLog(date: olderDay, weightKg: 80.5, bodyFatPercent: 21.0),
        _bodyMetricLog(
          date: laterDay,
          weightKg: 83.2,
          bodyFatPercent: 20.5,
          waistCm: 82.0,
        ),
      ],
    );

    await tester.pumpWidget(_buildProfileTestApp(profileRepository));
    await _pumpUntilFound(tester, find.text('14d change +2.7 kg'));
    expect(find.text('Records 3/14'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('profile_body_trend_tooltip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey<String>('profile_body_trend_single')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('profile_body_trend_chart_container')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('profile_body_trend_tooltip')),
      findsOneWidget,
    );

    await _tapVisible(tester, find.text('Body Fat').last);
    expect(find.text('14d change -0.5 %'), findsOneWidget);
    expect(find.text('Records 3/14'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('profile_body_trend_tooltip')),
      findsNothing,
    );

    await _tapVisible(tester, find.text('Waist').last);
    expect(find.text('14d change 0.0 cm'), findsOneWidget);
    expect(find.text('Records 2/14'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('profile_body_trend_single')),
      findsNothing,
    );
  });

  testWidgets(
    'editing a past body record keeps its date and does not update profile',
    (tester) async {
      _setTallPhoneView(tester);
      final editedDay = _dateDaysAgo(1);
      final today = DateUtilsX.todayKey();
      final profileRepository = _FakeProfileRepository(
        profile: UserProfile.defaults.copyWith(
          weightKg: 82.0,
          bodyFatPercent: 20.0,
          waistCm: 83.0,
        ),
        bodyMetricLogs: <BodyMetricLog>[
          _bodyMetricLog(
            date: editedDay,
            weightKg: 81.0,
            bodyFatPercent: 19.5,
            waistCm: 82.0,
          ),
        ],
      );

      await tester.pumpWidget(_buildProfileTestApp(profileRepository));
      await _pumpUntilFound(tester, find.text('Records 2/14'));

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_body_metric_calendar')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.byType(Dialog), findsOneWidget);

      await _tapDatePickerDay(tester, editedDay);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('profile_body_metric_edit_date')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('profile_body_metric_delete')),
        findsOneWidget,
      );

      final weightTile = find.byKey(
        const ValueKey<String>('profile_body_metric_editor_weight'),
      );
      final bodyFatTile = find.byKey(
        const ValueKey<String>('profile_body_metric_editor_body_fat'),
      );
      final waistTile = find.byKey(
        const ValueKey<String>('profile_body_metric_editor_waist'),
      );
      await _pumpUntilFound(tester, weightTile);

      final weightField = find.descendant(
        of: weightTile,
        matching: find.byType(TextField),
      );
      final bodyFatField = find.descendant(
        of: bodyFatTile,
        matching: find.byType(TextField),
      );
      final waistField = find.descendant(
        of: waistTile,
        matching: find.byType(TextField),
      );
      expect(tester.widget<TextField>(weightField).controller?.text, '81.0');
      expect(tester.widget<TextField>(bodyFatField).controller?.text, '19.5');
      expect(tester.widget<TextField>(waistField).controller?.text, '82.0');

      await tester.enterText(weightField, '83.2');
      await tester.enterText(bodyFatField, '18.9');
      await tester.enterText(waistField, '81.5');
      final saveFinder = find.byKey(
        const ValueKey<String>('profile_body_metric_editor_save'),
      );
      await tester.ensureVisible(saveFinder);
      await tester.tap(saveFinder);
      await tester.pumpAndSettle();

      expect(profileRepository.profile.weightKg, 82.0);
      expect(profileRepository.profile.bodyFatPercent, 20.0);
      expect(profileRepository.profile.waistCm, 83.0);
      expect(profileRepository.bodyMetricForDate(today), isNull);
      expect(profileRepository.weightForDate(today), isNull);

      final editedLog = profileRepository.bodyMetricForDate(editedDay);
      expect(editedLog, isNotNull);
      expect(editedLog!.weightKg, 83.2);
      expect(editedLog.bodyFatPercent, 18.9);
      expect(editedLog.waistCm, 81.5);
      expect(profileRepository.weightForDate(editedDay), 83.2);
    },
  );

  testWidgets('saving current body profile records today body metrics', (
    tester,
  ) async {
    _setTallPhoneView(tester);
    final today = DateUtilsX.todayKey();
    final profileRepository = _FakeProfileRepository(
      profile: UserProfile.defaults.copyWith(
        weightKg: 82.0,
        bodyFatPercent: 20.0,
        waistCm: 83.0,
      ),
    );

    await tester.pumpWidget(_buildProfileTestApp(profileRepository));
    await _pumpUntilFound(tester, find.text('Records 1/14'));

    await _tapVisible(
      tester,
      find.byKey(const ValueKey<String>('profile_body_profile_weight')),
    );
    final weightField = find.descendant(
      of: find.byKey(const ValueKey<String>('profile_body_profile_weight')),
      matching: find.byType(TextField),
    );
    final bodyFatField = find.descendant(
      of: find.byKey(const ValueKey<String>('profile_body_profile_body_fat')),
      matching: find.byType(TextField),
    );
    final waistField = find.descendant(
      of: find.byKey(const ValueKey<String>('profile_body_profile_waist')),
      matching: find.byType(TextField),
    );

    await tester.enterText(weightField, '84.4');
    await tester.enterText(bodyFatField, '18.8');
    await tester.enterText(waistField, '80.6');
    final saveFinder = find.byKey(
      const ValueKey<String>('profile_body_profile_save'),
    );
    await tester.ensureVisible(saveFinder);
    await tester.tap(saveFinder);
    await tester.pumpAndSettle();

    final todayLog = profileRepository.bodyMetricForDate(today);
    expect(todayLog, isNotNull);
    expect(todayLog!.weightKg, 84.4);
    expect(todayLog.bodyFatPercent, 18.8);
    expect(todayLog.waistCm, 80.6);
    expect(profileRepository.weightForDate(today), 84.4);
  });

  testWidgets(
    'selecting today from the body record date picker exits edit mode',
    (tester) async {
      _setTallPhoneView(tester);
      final editedDay = _dateDaysAgo(1);
      final todayDay = DateUtilsX.parseDay(
        DateUtilsX.todayKey(),
      ).day.toString();
      final profileRepository = _FakeProfileRepository(
        bodyMetricLogs: <BodyMetricLog>[
          _bodyMetricLog(date: editedDay, weightKg: 81.0),
        ],
      );

      await tester.pumpWidget(_buildProfileTestApp(profileRepository));
      await _pumpUntilFound(tester, find.text('Records 2/14'));

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_body_metric_calendar')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('profile_body_metric_edit_date')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_body_metric_calendar')),
      );
      await tester.pumpAndSettle();
      await _tapDatePickerDay(tester, editedDay);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('profile_body_metric_edit_date')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('profile_body_metric_calendar')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(todayDay).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile_body_metric_edit_date')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('profile_body_metric_delete')),
        findsNothing,
      );
    },
  );

  testWidgets('deleting a past body record removes the body metric log', (
    tester,
  ) async {
    _setTallPhoneView(tester);
    final editedDay = _dateDaysAgo(1);
    final profileRepository = _FakeProfileRepository(
      bodyMetricLogs: <BodyMetricLog>[
        _bodyMetricLog(
          date: editedDay,
          weightKg: 81.0,
          bodyFatPercent: 19.5,
          waistCm: 82.0,
        ),
      ],
      weightLogs: <WeightLog>[
        WeightLog(
          date: editedDay,
          weightKg: 81.0,
          source: 'body_metric_manual',
        ),
      ],
    );

    await tester.pumpWidget(_buildProfileTestApp(profileRepository));
    await _pumpUntilFound(tester, find.text('Records 2/14'));

    await tester.tap(
      find.byKey(const ValueKey<String>('profile_body_metric_calendar')),
    );
    await tester.pumpAndSettle();
    await _tapDatePickerDay(tester, editedDay);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('profile_body_metric_delete')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('profile_body_metric_confirm_delete')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey<String>('profile_body_metric_confirm_delete')),
    );
    await tester.pumpAndSettle();

    expect(profileRepository.bodyMetricForDate(editedDay), isNull);
    expect(profileRepository.weightForDate(editedDay), isNull);
    expect(
      find.byKey(const ValueKey<String>('profile_body_metric_edit_date')),
      findsNothing,
    );
  });

  test(
    'repository saveProfile alone does not create a body metric history row',
    () async {
      final today = DateUtilsX.todayKey();
      final profileRepository = _FakeProfileRepository();

      await profileRepository.saveProfile(
        profileRepository.profile.copyWith(
          weightKg: 84.0,
          bodyFatPercent: 18.0,
          waistCm: 81.0,
        ),
      );

      expect(profileRepository.profile.weightKg, 84.0);
      expect(profileRepository.profile.bodyFatPercent, 18.0);
      expect(profileRepository.profile.waistCm, 81.0);
      expect(profileRepository.bodyMetricForDate(today), isNull);
      expect(profileRepository.weightForDate(today), 84.0);
    },
  );
}

void _setTallPhoneView(WidgetTester tester) {
  tester.view.physicalSize = const Size(430, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _buildProfileTestApp(_FakeProfileRepository profileRepository) {
  final database = AppDatabase.instance;
  final foodRepository = _FakeFoodRepository(database);
  final customExerciseRepository = CustomExerciseRepository(database);
  final workoutRepository = _FakeWorkoutRepository(database);
  final workoutDraftRepository = _FakeWorkoutDraftRepository(database);
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
      ChangeNotifierProvider<RootTabController>(
        create: (_) => RootTabController(),
      ),
      ChangeNotifierProvider<SelectedDateNotifier>(
        create: (_) => SelectedDateNotifier(),
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
      home: const Scaffold(body: ProfilePage()),
    ),
  );
}

String _dateDaysAgo(int days) {
  return DateUtilsX.formatDate(
    DateUtilsX.parseDay(DateUtilsX.todayKey()).subtract(Duration(days: days)),
  );
}

BodyMetricLog _bodyMetricLog({
  required String date,
  double? weightKg,
  double? bodyFatPercent,
  double? waistCm,
}) {
  return BodyMetricLog(
    date: date,
    weightKg: weightKg,
    bodyFatPercent: bodyFatPercent,
    waistCm: waistCm,
    source: 'body_metric_manual',
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsOneWidget);
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    280,
    maxScrolls: 20,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapDatePickerDay(WidgetTester tester, String date) async {
  final dayText = DateUtilsX.parseDay(date).day.toString();
  await tester.tap(find.text(dayText).last);
  await tester.pumpAndSettle();
}

class _FakeFoodRepository extends FoodRepository {
  _FakeFoodRepository(super.database);

  @override
  Future<List<FoodRecord>> getFoodRecordsByDate(String day) async {
    return const <FoodRecord>[];
  }

  @override
  Future<double> getCaloriesInByDate(String day) async => 0;
}

class _FakeWorkoutRepository extends WorkoutRepository {
  _FakeWorkoutRepository(super.database);

  @override
  Future<List<WorkoutSession>> getWorkoutSessionsBetween({
    required String startDate,
    required String endDate,
  }) async {
    return const <WorkoutSession>[];
  }

  @override
  Future<double> getExerciseCaloriesByDate(String day) async => 0;
}

class _FakeWorkoutDraftRepository extends WorkoutDraftRepository {
  _FakeWorkoutDraftRepository(super.database);

  @override
  Future<WorkoutRecordDraft?> getActiveDraft() async => null;
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository({
    UserProfile? profile,
    List<BodyMetricLog> bodyMetricLogs = const <BodyMetricLog>[],
    List<WeightLog> weightLogs = const <WeightLog>[],
  }) : profile = profile ?? UserProfile.defaults,
       bodyMetricLogs = bodyMetricLogs.toList(),
       weightLogs = weightLogs.toList(),
       super(AppDatabase.instance);

  UserProfile profile;
  List<BodyMetricLog> bodyMetricLogs;
  List<WeightLog> weightLogs;

  BodyMetricLog? bodyMetricForDate(String date) {
    for (final log in bodyMetricLogs) {
      if (log.date == date) {
        return log;
      }
    }
    return null;
  }

  double? weightForDate(String date) {
    for (final log in weightLogs) {
      if (log.date == date) {
        return log.weightKg;
      }
    }
    return null;
  }

  @override
  Future<UserProfile?> getProfile() async => profile;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    this.profile = profile;
    await upsertWeightLog(
      date: DateUtilsX.todayKey(),
      weightKg: profile.weightKg,
      source: 'profile_save',
    );
  }

  @override
  Future<void> upsertWeightLog({
    required String date,
    required double weightKg,
    String source = 'manual',
  }) async {
    final existingIndex = weightLogs.indexWhere((log) => log.date == date);
    final updatedLog = WeightLog(
      date: date,
      weightKg: weightKg,
      source: source,
    );
    if (existingIndex == -1) {
      weightLogs.add(updatedLog);
      return;
    }
    weightLogs[existingIndex] = updatedLog;
  }

  @override
  Future<List<WeightLog>> getWeightLogsBetween({
    required String startDate,
    required String endDate,
  }) async {
    return weightLogs
        .where(
          (log) =>
              log.date.compareTo(startDate) >= 0 &&
              log.date.compareTo(endDate) <= 0,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<BodyMetricLog?> getBodyMetricLogByDate(String date) async {
    return bodyMetricForDate(date);
  }

  @override
  Future<List<BodyMetricLog>> getBodyMetricLogsBetween({
    required String startDate,
    required String endDate,
  }) async {
    return bodyMetricLogs
        .where(
          (log) =>
              log.date.compareTo(startDate) >= 0 &&
              log.date.compareTo(endDate) <= 0,
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<List<BodyMetricLog>> getAllBodyMetricLogs() async {
    return bodyMetricLogs.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> upsertBodyMetricLog({
    required String date,
    double? weightKg,
    double? bodyFatPercent,
    double? waistCm,
    String source = 'manual',
  }) async {
    final existingIndex = bodyMetricLogs.indexWhere((log) => log.date == date);
    final updatedLog = BodyMetricLog(
      date: date,
      weightKg: weightKg,
      bodyFatPercent: bodyFatPercent,
      waistCm: waistCm,
      source: source,
    );
    if (existingIndex == -1) {
      bodyMetricLogs.add(updatedLog);
    } else {
      bodyMetricLogs[existingIndex] = updatedLog;
    }
    if (weightKg != null) {
      await upsertWeightLog(date: date, weightKg: weightKg, source: source);
    }
  }

  @override
  Future<void> deleteBodyMetricLogByDate(String date) async {
    final existing = bodyMetricForDate(date);
    bodyMetricLogs.removeWhere((log) => log.date == date);
    if (existing?.weightKg != null) {
      weightLogs.removeWhere((log) => log.date == date);
    }
  }

  @override
  Future<CalorieCalibrationState?> getCalorieCalibrationState() async => null;

  @override
  Future<DietAdjustmentReview?> getLatestDietAdjustmentReview({
    String? userDecision,
  }) async {
    return null;
  }
}
