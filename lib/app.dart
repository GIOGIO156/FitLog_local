import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/fitlog_theme.dart';
import 'core/localization/language_controller.dart';
import 'core/localization/localization_extensions.dart';
import 'core/theme_controller.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/workout_notification_bridge.dart';
import 'core/widgets/fitlog_bottom_nav_layout.dart';
import 'data/db/app_database.dart';
import 'data/repositories/custom_exercise_repository.dart';
import 'data/repositories/food_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/workout_draft_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'domain/services/daily_summary_service.dart';
import 'domain/services/diet_plan_strategy_service.dart';
import 'domain/services/carb_taper_review_service.dart';
import 'domain/services/training_frequency_self_check_service.dart';
import 'export/csv_export_service.dart';
import 'export/export_share_service.dart';
import 'export/xlsx_export_service.dart';
import 'features/food/food_log_page.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_page.dart';
import 'features/workout/workout_log_page.dart';

const String _fitlogFontFamily = 'NotoSansSC';
const List<String> _fitlogChineseSansFallback = <String>[
  'Noto Sans CJK SC',
  'Noto Sans SC',
  'Source Han Sans SC',
  'PingFang SC',
  'Hiragino Sans GB',
  'Microsoft YaHei',
  'sans-serif',
];

class FitLogApp extends StatefulWidget {
  const FitLogApp({super.key});

  @override
  State<FitLogApp> createState() => _FitLogAppState();
}

class _FitLogAppState extends State<FitLogApp> {
  late final AppServices _services;
  late final LanguageController _languageController;
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();

    final database = AppDatabase.instance;
    final foodRepository = FoodRepository(database);
    final customExerciseRepository = CustomExerciseRepository(database);
    final workoutRepository = WorkoutRepository(database);
    final workoutDraftRepository = WorkoutDraftRepository(database);
    final profileRepository = ProfileRepository(database);
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

    _services = AppServices(
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
      exportShareService: const SystemExportShareService(),
      carbTaperReviewService: carbTaperReviewService,
      dietPlanStrategyService: dietPlanStrategyService,
      trainingFrequencySelfCheckService: trainingFrequencySelfCheckService,
      database: database,
    );

    _languageController = LanguageController()..load();
    _themeController = ThemeController()..load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppServices>.value(value: _services),
        ChangeNotifierProvider<RefreshNotifier>(
          create: (_) => RefreshNotifier(),
        ),
        ChangeNotifierProvider<RootTabController>(
          create: (_) => RootTabController(),
        ),
        ChangeNotifierProvider<SelectedDateNotifier>(
          create: (_) => SelectedDateNotifier(),
        ),
        ChangeNotifierProvider<LanguageController>.value(
          value: _languageController,
        ),
        ChangeNotifierProvider<ThemeController>.value(value: _themeController),
      ],
      child: Consumer2<LanguageController, ThemeController>(
        builder: (context, languageController, themeController, _) {
          if (!languageController.initialized || !themeController.initialized) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(child: Text(context.strings.loading)),
              ),
            );
          }

          final palette = FitLogPalettes.byKey(themeController.theme);

          return MaterialApp(
            title: context.strings.appName,
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: _buildTheme(palette),
            darkTheme: _buildTheme(palette),
            home: const _RootShell(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(FitLogColors palette) {
    final isDark = palette.isDarkLike;
    final base = ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.seed,
        brightness: palette.brightness,
      ),
      extensions: <ThemeExtension<dynamic>>[palette],
    );
    final textTheme = base.textTheme
        .apply(
          fontFamily: _fitlogFontFamily,
          fontFamilyFallback: _fitlogChineseSansFallback,
        )
        .copyWith(
          headlineSmall: _withFontFallback(
            base.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          titleLarge: _withFontFallback(
            base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          titleMedium: _withFontFallback(
            base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          bodyMedium: _withFontFallback(
            base.textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
          ),
        );

    return base.copyWith(
      splashFactory: isDark ? NoSplash.splashFactory : InkRipple.splashFactory,
      splashColor: isDark ? Colors.transparent : base.splashColor,
      highlightColor: isDark ? Colors.transparent : base.highlightColor,
      hoverColor: isDark ? Colors.transparent : base.hoverColor,
      scaffoldBackgroundColor: palette.background,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: palette.navBackground,
        titleTextStyle: _withFontFallback(
          TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        color: palette.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: _withFontFallback(TextStyle(color: palette.textSecondary)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.primaryBright, width: 1.4),
        ),
        filled: true,
        fillColor: palette.input,
        isDense: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedItemColor: palette.primary,
        selectedLabelStyle: _withFontFallback(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        unselectedItemColor: palette.textMuted,
        unselectedLabelStyle: _withFontFallback(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.transparent,
      ),
      textTheme: textTheme,
    );
  }
}

TextStyle? _withFontFallback(TextStyle? style) {
  return style?.copyWith(
    fontFamily: _fitlogFontFamily,
    fontFamilyFallback: _fitlogChineseSansFallback,
  );
}

class _RootShell extends StatefulWidget {
  const _RootShell({this.pages});

  final List<Widget>? pages;

  @override
  State<_RootShell> createState() => _RootShellState();
}

@visibleForTesting
Widget buildRootShellForTest({required List<Widget> pages}) {
  return _RootShell(pages: pages);
}

class _RootShellState extends State<_RootShell> {
  late final List<Widget> _pages;
  bool _checkedWorkoutEditorAutoResume = false;

  @override
  void initState() {
    super.initState();
    _pages =
        widget.pages ??
        const <Widget>[
          HomePage(),
          FoodLogPage(),
          WorkoutLogPage(),
          ProfilePage(),
        ];
    WorkoutNotificationBridge.setOpenActiveDraftHandler(
      () => openActiveWorkoutDraftFromNotification(context),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleInitialWorkoutOpenRequests());
    });
  }

  Future<void> _handleInitialWorkoutOpenRequests() async {
    if (!mounted) {
      return;
    }
    final didAutoResume = await _autoResumeWorkoutEditorOnce();
    if (!mounted || didAutoResume) {
      return;
    }
    await WorkoutNotificationBridge.consumeInitialOpenRequest();
  }

  Future<bool> _autoResumeWorkoutEditorOnce() async {
    if (_checkedWorkoutEditorAutoResume) {
      return false;
    }
    _checkedWorkoutEditorAutoResume = true;
    return maybeAutoResumeActiveWorkoutDraftOnColdStart(context);
  }

  @override
  void dispose() {
    WorkoutNotificationBridge.setOpenActiveDraftHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final palette = context.fitLogColors;
    final navController = context.watch<RootTabController>();
    final items = <_ShellNavItem>[
      _ShellNavItem(
        label: strings.navHome,
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
      ),
      _ShellNavItem(
        label: strings.navFood,
        icon: Icons.restaurant_menu_outlined,
        activeIcon: Icons.restaurant_menu_rounded,
      ),
      _ShellNavItem(
        label: strings.navWorkout,
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center_rounded,
      ),
      _ShellNavItem(
        label: strings.navProfile,
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            palette.pageGradientTop,
            palette.pageGradientMiddle,
            palette.pageGradientBottom,
          ],
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: IndexedStack(index: navController.index, children: _pages),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ShellBottomNav(items: items),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellBottomNav extends StatelessWidget {
  const _ShellBottomNav({required this.items});

  final List<_ShellNavItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.fitLogColors;
    final navController = context.watch<RootTabController>();
    final bottomGap = FitLogBottomNavLayout.bottomGapFor(context);

    return Padding(
      key: const ValueKey('fitlog_bottom_nav_overlay'),
      padding: EdgeInsets.fromLTRB(
        FitLogBottomNavLayout.horizontalInset,
        0,
        FitLogBottomNavLayout.horizontalInset,
        bottomGap,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final segmentWidth = trackWidth / items.length;
          const indicatorInset = 5.0;
          const indicatorVerticalMargin = 7.0;
          final indicatorWidth = segmentWidth - indicatorInset * 2;
          final shieldHeight =
              FitLogBottomNavLayout.pillHeight / 2 + bottomGap + 1;

          final navPill = Container(
            key: const ValueKey('fitlog_bottom_nav_pill'),
            height: FitLogBottomNavLayout.pillHeight,
            decoration: BoxDecoration(
              color: palette.navBackground,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: palette.outline),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: palette.shadow.withValues(
                    alpha: palette.isDarkLike ? 0.25 : 0.08,
                  ),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  left: navController.index * segmentWidth + indicatorInset,
                  top: indicatorVerticalMargin,
                  width: indicatorWidth,
                  height:
                      FitLogBottomNavLayout.pillHeight -
                      indicatorVerticalMargin * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.navIndicator,
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                Row(
                  children: List<Widget>.generate(items.length, (index) {
                    final item = items[index];
                    final selected = navController.index == index;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => navController.setIndex(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                selected ? item.activeIcon : item.icon,
                                color: selected
                                    ? palette.primary
                                    : palette.textMuted,
                                size: 22,
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                style: _withFontFallback(
                                  TextStyle(
                                    fontSize: 11,
                                    height: 1.0,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: selected
                                        ? palette.primaryText
                                        : palette.textMuted,
                                  ),
                                )!,
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );

          return IgnorePointer(
            ignoring: navController.interactionLocked,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: navController.interactionLocked ? 0.34 : 1,
              child: SizedBox(
                height: FitLogBottomNavLayout.pillHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      right: 0,
                      top: FitLogBottomNavLayout.pillHeight / 2,
                      height: shieldHeight,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          key: const ValueKey('fitlog_bottom_nav_shield'),
                          decoration: BoxDecoration(color: palette.background),
                        ),
                      ),
                    ),
                    navPill,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class RefreshNotifier extends ChangeNotifier {
  int _version = 0;

  int get version => _version;

  void markDataChanged() {
    _version++;
    notifyListeners();
  }
}

class RootTabController extends ChangeNotifier {
  int _index = 0;
  bool _interactionLocked = false;

  int get index => _index;
  bool get interactionLocked => _interactionLocked;

  void setIndex(int index) {
    if (_interactionLocked) {
      return;
    }
    if (_index == index) {
      return;
    }
    _index = index;
    notifyListeners();
  }

  void setInteractionLocked(bool locked) {
    if (_interactionLocked == locked) {
      return;
    }
    _interactionLocked = locked;
    notifyListeners();
  }
}

class SelectedDateNotifier extends ChangeNotifier {
  String _selectedDate = DateUtilsX.todayKey();

  String get selectedDate => _selectedDate;

  void setDate(String date) {
    if (_selectedDate == date) {
      return;
    }
    _selectedDate = date;
    notifyListeners();
  }
}

class AppServices {
  const AppServices({
    required this.foodRepository,
    required this.customExerciseRepository,
    required this.workoutRepository,
    required this.workoutDraftRepository,
    required this.profileRepository,
    required this.dailySummaryService,
    required this.xlsxExportService,
    required this.csvExportService,
    required this.exportShareService,
    required this.carbTaperReviewService,
    required this.dietPlanStrategyService,
    required this.trainingFrequencySelfCheckService,
    required this.database,
  });

  final FoodRepository foodRepository;
  final CustomExerciseRepository customExerciseRepository;
  final WorkoutRepository workoutRepository;
  final WorkoutDraftRepository workoutDraftRepository;
  final ProfileRepository profileRepository;
  final DailySummaryService dailySummaryService;
  final XlsxExportService xlsxExportService;
  final CsvExportService csvExportService;
  final ExportShareService exportShareService;
  final CarbTaperReviewService carbTaperReviewService;
  final DietPlanStrategyService dietPlanStrategyService;
  final TrainingFrequencySelfCheckService trainingFrequencySelfCheckService;
  final AppDatabase database;
}
