import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/utils/date_utils.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../domain/models/user_profile.dart';
import '../domain/services/daily_summary_service.dart';

class XlsxExportService {
  XlsxExportService({
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

  Future<String> export() async {
    final excel = Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultSheetName, 'Food Records');

    final foodSheet = excel['Food Records'];
    final foodItemSheet = excel['Food Items'];
    final workoutSheet = excel['Workout Records'];
    final workoutSetSheet = excel['Workout Sets'];
    final summarySheet = excel['Daily Summary'];
    final profileSheet = excel['User Profile'];

    _appendHeader(foodSheet, const <String>[
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
    ]);

    _appendHeader(foodItemSheet, const <String>[
      'food_record_id',
      'name',
      'estimated_weight_g',
      'calories_kcal',
      'protein_g',
      'carbs_g',
      'fat_g',
      'notes',
    ]);

    _appendHeader(workoutSheet, const <String>[
      'date',
      'body_part',
      'exercise_name',
      'exercise_type',
      'duration_minutes',
      'intensity',
      'estimated_calories',
      'notes',
    ]);

    _appendHeader(workoutSetSheet, const <String>[
      'workout_session_id',
      'set_number',
      'weight_kg',
      'reps',
      'is_completed',
      'completed_at',
    ]);

    _appendHeader(summarySheet, const <String>[
      'date',
      'calories_in',
      'protein_g',
      'carbs_g',
      'fat_g',
      'exercise_calories',
      'bmr',
      'tdee_reference',
      'target_intake',
      'remaining_calories',
    ]);

    _appendHeader(profileSheet, const <String>[
      'age',
      'height_cm',
      'weight_kg',
      'sex_for_formula',
      'activity_level',
      'daily_energy_goal_type',
      'daily_energy_goal_kcal',
    ]);

    final foodRecords = await _foodRepository.getAllFoodRecords();
    for (final record in foodRecords) {
      _appendRow(foodSheet, <dynamic>[
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
      ]);

      for (final item in record.items) {
        _appendRow(foodItemSheet, <dynamic>[
          record.id,
          item.name,
          item.estimatedWeightG,
          item.caloriesKcal,
          item.proteinG,
          item.carbsG,
          item.fatG,
          item.notes,
        ]);
      }
    }

    final workoutSessions = await _workoutRepository.getAllWorkoutSessions();
    for (final session in workoutSessions) {
      _appendRow(workoutSheet, <dynamic>[
        session.date,
        session.bodyPart,
        session.exerciseName,
        session.exerciseType,
        session.durationMinutes,
        session.intensity,
        session.estimatedCalories,
        session.notes,
      ]);

      for (final set in session.sets) {
        _appendRow(workoutSetSheet, <dynamic>[
          session.id,
          set.setNumber,
          set.weightKg,
          set.reps,
          set.isCompleted ? 1 : 0,
          set.completedAt ?? '',
        ]);
      }
    }

    final Set<String> uniqueDates = <String>{
      ...await _foodRepository.getDistinctDates(),
      ...await _workoutRepository.getDistinctDates(),
    };

    final List<String> sortedDates = uniqueDates.toList()..sort();
    for (final date in sortedDates) {
      final daily = await _dailySummaryService.getSummaryForDate(date);
      _appendRow(summarySheet, <dynamic>[
        date,
        daily.caloriesIn,
        daily.proteinG,
        daily.carbsG,
        daily.fatG,
        daily.exerciseCalories,
        daily.bmr,
        daily.tdeeReference,
        daily.targetIntake,
        daily.remainingCalories,
      ]);
    }

    final UserProfile profile =
        await _profileRepository.getProfile() ?? UserProfile.defaults;
    _appendRow(profileSheet, <dynamic>[
      profile.age,
      profile.heightCm,
      profile.weightKg,
      profile.sexForFormula,
      profile.activityLevel,
      profile.dailyEnergyGoalType,
      profile.dailyEnergyGoalKcal,
    ]);

    final List<int>? bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode XLSX data.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'fitlog_local_${DateUtilsX.formatForExport(DateTime.now())}.xlsx';
    final filePath = path.join(dir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  void _appendHeader(Sheet sheet, List<String> values) {
    _appendRow(sheet, values);
  }

  void _appendRow(Sheet sheet, List<dynamic> values) {
    sheet.appendRow(values.map(_toCell).toList());
  }

  CellValue _toCell(dynamic value) {
    if (value == null) {
      return TextCellValue('');
    }

    if (value is int) {
      return IntCellValue(value);
    }

    if (value is double) {
      return DoubleCellValue(value);
    }

    if (value is bool) {
      return BoolCellValue(value);
    }

    return TextCellValue(value.toString());
  }
}
