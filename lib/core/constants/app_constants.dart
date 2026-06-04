class AppConstants {
  AppConstants._();

  static const String sourceAiPaste = 'ai_paste';
  static const String sourceManual = 'manual';

  static const List<String> bodyParts = <String>[
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
    'Full Body',
  ];

  static const Map<String, List<String>> bodyPartExercises =
      <String, List<String>>{
        'Chest': <String>[
          'Bench Press',
          'Incline Dumbbell Press',
          'Push-up',
          'Chest Fly',
        ],
        'Back': <String>[
          'Pull-up',
          'Lat Pulldown',
          'Barbell Row',
          'Seated Cable Row',
        ],
        'Legs': <String>[
          'Squat',
          'Leg Press',
          'Romanian Deadlift',
          'Leg Extension',
          'Leg Curl',
        ],
        'Shoulders': <String>[
          'Overhead Press',
          'Lateral Raise',
          'Rear Delt Fly',
        ],
        'Arms': <String>['Biceps Curl', 'Triceps Pushdown', 'Hammer Curl'],
        'Core': <String>['Plank', 'Crunch', 'Hanging Leg Raise'],
        'Cardio': <String>[
          'Walking',
          'Running',
          'Cycling',
          'Rowing Machine',
          'Stair Climber',
        ],
        'Full Body': <String>['Deadlift', 'Kettlebell Swing', 'Burpee'],
      };

  static const Set<String> bodyweightExercises = <String>{
    'Pull-up',
    'Push-up',
    'Plank',
    'Crunch',
    'Hanging Leg Raise',
    'Burpee',
  };

  static bool isBodyweightExercise(String exerciseName) {
    return bodyweightExercises.contains(exerciseName);
  }

  static const List<String> intensityLevels = <String>['low', 'medium', 'high'];

  static const List<String> sexOptions = <String>[
    'male',
    'female',
    'prefer_not_to_say',
  ];

  static const List<String> activityLevels = <String>[
    'sedentary',
    'lightly_active',
    'moderately_active',
    'very_active',
  ];

  static const List<String> dailyEnergyGoalTypes = <String>[
    'maintenance',
    'deficit',
    'surplus',
  ];

  static const String dietGoalPhaseCutting = 'cutting';
  static const String dietGoalPhaseBulking = 'bulking';
  static const List<String> dietGoalPhases = <String>[
    dietGoalPhaseCutting,
    dietGoalPhaseBulking,
  ];

  static const String dietCalculationModeEnergyRatio = 'energy_ratio';
  static const String dietCalculationModeGramPerKg = 'gram_per_kg';
  static const List<String> dietCalculationModes = <String>[
    dietCalculationModeEnergyRatio,
    dietCalculationModeGramPerKg,
  ];

  static const int defaultTrainingFrequencyPerWeek = 3;
  static const List<int> trainingFrequencyPerWeekOptions = <int>[2, 3, 4, 5];
  static const int defaultMacroSelfCheckPeriodDays = 14;
  static const List<int> macroSelfCheckPeriodDayOptions = <int>[7, 14, 21, 28];
  static const int macroSelfCheckReminderCooldownDays = 7;
  static const int validWorkoutCardioMinutesThreshold = 20;
  static const double validWorkoutCaloriesThreshold = 80;

  static const double defaultProteinRatioPercent = 30;
  static const double defaultCarbsRatioPercent = 40;
  static const double defaultFatRatioPercent = 30;

  static const double bulkingProteinRatioPercent = 25;
  static const double bulkingCarbsRatioPercent = 50;
  static const double bulkingFatRatioPercent = 25;

  static String resolveDietGoalPhase(String? value) {
    if (dietGoalPhases.contains(value)) {
      return value!;
    }
    return dietGoalPhaseCutting;
  }

  static String resolveDietCalculationMode(String? value) {
    if (dietCalculationModes.contains(value)) {
      return value!;
    }
    return dietCalculationModeEnergyRatio;
  }

  static int resolveTrainingFrequencyPerWeek(int? value) {
    if (trainingFrequencyPerWeekOptions.contains(value)) {
      return value!;
    }
    return defaultTrainingFrequencyPerWeek;
  }

  static int resolveMacroSelfCheckPeriodDays(int? value) {
    if (macroSelfCheckPeriodDayOptions.contains(value)) {
      return value!;
    }
    return defaultMacroSelfCheckPeriodDays;
  }
}
