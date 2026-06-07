import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/localization/language_controller.dart';
import 'core/localization/localization_extensions.dart';
import 'core/utils/date_utils.dart';
import 'data/db/app_database.dart';
import 'data/repositories/food_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/workout_repository.dart';
import 'domain/services/daily_summary_service.dart';
import 'domain/services/diet_plan_strategy_service.dart';
import 'domain/services/carb_taper_review_service.dart';
import 'domain/services/training_frequency_self_check_service.dart';
import 'export/csv_export_service.dart';
import 'export/xlsx_export_service.dart';
import 'features/food/food_log_page.dart';
import 'features/home/home_page.dart';
import 'features/profile/profile_page.dart';
import 'features/workout/workout_log_page.dart';

class FitLogApp extends StatefulWidget {
  const FitLogApp({super.key});

  @override
  State<FitLogApp> createState() => _FitLogAppState();
}

class _FitLogAppState extends State<FitLogApp> {
  late final AppServices _services;
  late final LanguageController _languageController;

  @override
  void initState() {
    super.initState();

    final database = AppDatabase.instance;
    final foodRepository = FoodRepository(database);
    final workoutRepository = WorkoutRepository(database);
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
      workoutRepository: workoutRepository,
      profileRepository: profileRepository,
      dailySummaryService: dailySummaryService,
      xlsxExportService: XlsxExportService(
        foodRepository: foodRepository,
        workoutRepository: workoutRepository,
        profileRepository: profileRepository,
        dailySummaryService: dailySummaryService,
      ),
      csvExportService: CsvExportService(
        foodRepository: foodRepository,
        workoutRepository: workoutRepository,
        profileRepository: profileRepository,
        dailySummaryService: dailySummaryService,
      ),
      carbTaperReviewService: carbTaperReviewService,
      dietPlanStrategyService: dietPlanStrategyService,
      trainingFrequencySelfCheckService: trainingFrequencySelfCheckService,
      database: database,
    );

    _languageController = LanguageController()..load();
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
      ],
      child: Consumer<LanguageController>(
        builder: (context, languageController, _) {
          if (!languageController.initialized) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(child: Text(context.strings.loading)),
              ),
            );
          }

          return MaterialApp(
            title: context.strings.appName,
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.light,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: const _RootShell(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF78BE5B),
        brightness: brightness,
      ),
    );

    return base.copyWith(
      splashFactory: isDark ? NoSplash.splashFactory : InkRipple.splashFactory,
      splashColor: isDark ? Colors.transparent : base.splashColor,
      highlightColor: isDark ? Colors.transparent : base.highlightColor,
      hoverColor: isDark ? Colors.transparent : base.hoverColor,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0E1117)
          : const Color(0xFFF5F8F1),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        color: isDark
            ? const Color(0xFF171B22).withValues(alpha: 0.88)
            : const Color(0xFFFFFFFF),
      ),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: const TextStyle(color: Color(0xFF61715D)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE6D7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFDCE6D7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF78BE5B), width: 1.4),
        ),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
        isDense: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedItemColor: const Color(0xFF4E9E3B),
        unselectedItemColor: isDark
            ? Colors.white.withValues(alpha: 0.58)
            : const Color(0xFF7A8973),
        backgroundColor: isDark
            ? const Color(0xFF11161F).withValues(alpha: 0.9)
            : Colors.white,
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF152013),
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: const Color(0xFF152013),
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF22311F),
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF51614E),
        ),
      ),
    );
  }
}

class _RootShell extends StatefulWidget {
  const _RootShell();

  @override
  State<_RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<_RootShell> {
  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final navController = context.watch<RootTabController>();
    final pages = <Widget>[
      const HomePage(),
      const FoodLogPage(),
      const WorkoutLogPage(),
      const ProfilePage(),
    ];
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

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFFAFCF7),
              Color(0xFFF3F7EE),
              Color(0xFFF7FAF3),
            ],
          ),
        ),
        child: pages[navController.index],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2ECDD)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF13200F).withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: List<Widget>.generate(items.length, (index) {
              final item = items[index];
              final selected = navController.index == index;

              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => navController.setIndex(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 7,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFEAF6E3)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected
                              ? const Color(0xFF4E9E3B)
                              : const Color(0xFF7A8973),
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Flexible(
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.0,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? const Color(0xFF234120)
                                  : const Color(0xFF7A8973),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
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

  int get index => _index;

  void setIndex(int index) {
    if (_index == index) {
      return;
    }
    _index = index;
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
    required this.workoutRepository,
    required this.profileRepository,
    required this.dailySummaryService,
    required this.xlsxExportService,
    required this.csvExportService,
    required this.carbTaperReviewService,
    required this.dietPlanStrategyService,
    required this.trainingFrequencySelfCheckService,
    required this.database,
  });

  final FoodRepository foodRepository;
  final WorkoutRepository workoutRepository;
  final ProfileRepository profileRepository;
  final DailySummaryService dailySummaryService;
  final XlsxExportService xlsxExportService;
  final CsvExportService csvExportService;
  final CarbTaperReviewService carbTaperReviewService;
  final DietPlanStrategyService dietPlanStrategyService;
  final TrainingFrequencySelfCheckService trainingFrequencySelfCheckService;
  final AppDatabase database;
}
