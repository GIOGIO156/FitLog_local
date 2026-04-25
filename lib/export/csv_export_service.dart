import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/utils/date_utils.dart';
import '../data/repositories/food_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../domain/models/user_profile.dart';
import '../domain/services/daily_summary_service.dart';

class CsvExportService {
  CsvExportService({
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

  Future<String> exportZip() async {
    final foodRecords = await _foodRepository.getAllFoodRecords();
    final workoutSessions = await _workoutRepository.getAllWorkoutSessions();
    final profile =
        await _profileRepository.getProfile() ?? UserProfile.defaults;

    final List<List<dynamic>> foodRows = <List<dynamic>>[
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
    ];

    final List<List<dynamic>> foodItemRows = <List<dynamic>>[
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
    ];

    for (final record in foodRecords) {
      for (final item in record.items) {
        foodItemRows.add(<dynamic>[
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

    final List<List<dynamic>> workoutRows = <List<dynamic>>[
      <dynamic>[
        'date',
        'body_part',
        'exercise_name',
        'exercise_type',
        'duration_minutes',
        'intensity',
        'estimated_calories',
        'notes',
      ],
      ...workoutSessions.map(
        (session) => <dynamic>[
          session.date,
          session.bodyPart,
          session.exerciseName,
          session.exerciseType,
          session.durationMinutes,
          session.intensity,
          session.estimatedCalories,
          session.notes,
        ],
      ),
    ];

    final List<List<dynamic>> workoutSetRows = <List<dynamic>>[
      <dynamic>[
        'workout_session_id',
        'set_number',
        'weight_kg',
        'reps',
        'is_completed',
        'completed_at',
      ],
    ];

    for (final session in workoutSessions) {
      for (final set in session.sets) {
        workoutSetRows.add(<dynamic>[
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

    final List<List<dynamic>> summaryRows = <List<dynamic>>[
      <dynamic>[
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
        'target_protein_g',
        'target_carbs_g',
        'target_fat_g',
        'remaining_protein_g',
        'remaining_carbs_g',
        'remaining_fat_g',
      ],
    ];

    final sortedDates = uniqueDates.toList()..sort();
    for (final date in sortedDates) {
      final daily = await _dailySummaryService.getSummaryForDate(date);
      summaryRows.add(<dynamic>[
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
        daily.targetProteinG,
        daily.targetCarbsG,
        daily.targetFatG,
        daily.remainingProteinG,
        daily.remainingCarbsG,
        daily.remainingFatG,
      ]);
    }

    final List<List<dynamic>> profileRows = <List<dynamic>>[
      <dynamic>[
        'age',
        'height_cm',
        'weight_kg',
        'sex_for_formula',
        'activity_level',
        'daily_energy_goal_type',
        'daily_energy_goal_kcal',
        'protein_ratio_percent',
        'carbs_ratio_percent',
        'fat_ratio_percent',
      ],
      <dynamic>[
        profile.age,
        profile.heightCm,
        profile.weightKg,
        profile.sexForFormula,
        profile.activityLevel,
        profile.dailyEnergyGoalType,
        profile.dailyEnergyGoalKcal,
        profile.proteinRatioPercent,
        profile.carbsRatioPercent,
        profile.fatRatioPercent,
      ],
    ];

    final archive = Archive();
    _addCsvToArchive(archive, 'food_records.csv', foodRows);
    _addCsvToArchive(archive, 'food_items.csv', foodItemRows);
    _addCsvToArchive(archive, 'workout_records.csv', workoutRows);
    _addCsvToArchive(archive, 'workout_sets.csv', workoutSetRows);
    _addCsvToArchive(archive, 'daily_summary.csv', summaryRows);
    _addCsvToArchive(archive, 'user_profile.csv', profileRows);

    final bytes = ZipEncoder().encode(archive);
    if (bytes == null) {
      throw Exception('Failed to create CSV zip archive.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'fitlog_local_${DateUtilsX.formatForExport(DateTime.now())}.zip';
    final filePath = path.join(dir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
  }

  void _addCsvToArchive(
    Archive archive,
    String fileName,
    List<List<dynamic>> rows,
  ) {
    final csvContent = const ListToCsvConverter().convert(rows);
    final encoded = utf8.encode(csvContent);
    archive.addFile(ArchiveFile(fileName, encoded.length, encoded));
  }
}
