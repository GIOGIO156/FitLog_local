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

  static const Map<String, List<String>>
  bodyPartExercises = <String, List<String>>{
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
    'Shoulders': <String>['Overhead Press', 'Lateral Raise', 'Rear Delt Fly'],
    'Arms': <String>['Biceps Curl', 'Triceps Pushdown', 'Hammer Curl'],
    'Core': <String>['Plank', 'Crunch', 'Hanging Leg Raise'],
    'Cardio': <String>['Running', 'Cycling', 'Rowing Machine', 'Stair Climber'],
    'Full Body': <String>['Deadlift', 'Kettlebell Swing', 'Burpee'],
  };

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
}
