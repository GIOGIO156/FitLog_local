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

    final dailySummaryService = DailySummaryService(
      foodRepository: foodRepository,
      workoutRepository: workoutRepository,
      profileRepository: profileRepository,
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
            themeMode: ThemeMode.system,
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
        seedColor: const Color(0xFF1ED760),
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
          : const Color(0xFFF2F5F5),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: isDark
            ? const Color(0xFF171B22).withValues(alpha: 0.88)
            : Colors.white.withValues(alpha: 0.85),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.32)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.64),
        isDense: true,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedItemColor: const Color(0xFF16A34A),
        unselectedItemColor: isDark
            ? Colors.white.withValues(alpha: 0.58)
            : const Color(0xFF6B7280),
        backgroundColor: isDark
            ? const Color(0xFF11161F).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.86),
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
  int _index = 0;

  final List<Widget> _pages = const <Widget>[
    HomePage(),
    FoodLogPage(),
    WorkoutLogPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titles = <String>[
      strings.homeDashboardTitle,
      strings.foodLogTitle,
      strings.workoutLogTitle,
      strings.profileSettingsTitle,
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(titles[_index])),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? <Color>[
                    const Color(0xFF0E1117),
                    const Color(0xFF121926),
                    const Color(0xFF0E1117),
                  ]
                : <Color>[
                    const Color(0xFFF4F7F7),
                    const Color(0xFFE8EFF0),
                    const Color(0xFFF7F9FA),
                  ],
          ),
        ),
        child: _pages[_index],
      ),
      bottomNavigationBar: Theme(
        data: theme.copyWith(
          splashFactory: isDark ? NoSplash.splashFactory : theme.splashFactory,
          splashColor: isDark ? Colors.transparent : theme.splashColor,
          highlightColor: isDark ? Colors.transparent : theme.highlightColor,
          hoverColor: isDark ? Colors.transparent : theme.hoverColor,
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          enableFeedback: !isDark,
          onTap: (value) => setState(() => _index = value),
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: strings.navHome,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.restaurant_menu_outlined),
              activeIcon: const Icon(Icons.restaurant_menu),
              label: strings.navFood,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.fitness_center_outlined),
              activeIcon: const Icon(Icons.fitness_center),
              label: strings.navWorkout,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: strings.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class RefreshNotifier extends ChangeNotifier {
  int _version = 0;

  int get version => _version;

  void markDataChanged() {
    _version++;
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
    required this.database,
  });

  final FoodRepository foodRepository;
  final WorkoutRepository workoutRepository;
  final ProfileRepository profileRepository;
  final DailySummaryService dailySummaryService;
  final XlsxExportService xlsxExportService;
  final CsvExportService csvExportService;
  final AppDatabase database;
}
