import 'package:fitlog_local/domain/services/workout_notification_snapshot_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutNotificationSnapshotBuilder', () {
    test('shows the first incomplete set before any set is completed', () {
      final snapshot = WorkoutNotificationSnapshotBuilder.build(
        exercises: <WorkoutNotificationExerciseInput>[
          _exercise(
            'Bench Press',
            sets: <WorkoutNotificationSetInput>[
              _set(1, loadText: '40', metricText: '8'),
              _set(2, loadText: '50', metricText: '8'),
            ],
          ),
          _exercise(
            'Lateral Raise',
            sets: <WorkoutNotificationSetInput>[
              _set(1, loadText: '6', metricText: '12'),
            ],
          ),
        ],
        isChinese: false,
      );

      expect(snapshot?.title, 'Bench Press');
      expect(snapshot?.body, 'Set 1 of 2 - 40 kg x 8 reps');
      expect(snapshot?.isComplete, isFalse);
    });

    test('stays on the current exercise after a set is completed', () {
      final snapshot = WorkoutNotificationSnapshotBuilder.build(
        exercises: <WorkoutNotificationExerciseInput>[
          _exercise(
            'Bench Press',
            sets: <WorkoutNotificationSetInput>[
              _set(
                1,
                loadText: '40',
                metricText: '8',
                isCompleted: true,
                completedAt: '2026-06-30T10:00:00.000',
              ),
              _set(2, loadText: '50', metricText: '8'),
            ],
          ),
          _exercise(
            'Lateral Raise',
            sets: <WorkoutNotificationSetInput>[
              _set(1, loadText: '6', metricText: '12'),
            ],
          ),
        ],
        isChinese: true,
      );

      expect(snapshot?.title, 'Bench Press');
      expect(snapshot?.body, '第 2 组，共 2 组 - 50 kg x 8 次');
    });

    test('switches to the exercise with the latest completed set', () {
      final snapshot = WorkoutNotificationSnapshotBuilder.build(
        exercises: <WorkoutNotificationExerciseInput>[
          _exercise(
            'Bench Press',
            sets: <WorkoutNotificationSetInput>[
              _set(
                1,
                loadText: '40',
                metricText: '8',
                isCompleted: true,
                completedAt: '2026-06-30T10:00:00.000',
              ),
              _set(2, loadText: '50', metricText: '8'),
            ],
          ),
          _exercise(
            'Lateral Raise',
            sets: <WorkoutNotificationSetInput>[
              _set(
                1,
                loadText: '6',
                metricText: '12',
                isCompleted: true,
                completedAt: '2026-06-30T10:02:00.000',
              ),
              _set(2, loadText: '6', metricText: '12'),
            ],
          ),
        ],
        isChinese: false,
      );

      expect(snapshot?.title, 'Lateral Raise');
      expect(snapshot?.body, 'Set 2 of 2 - 6 kg x 12 reps');
    });

    test('falls back to the first unfinished exercise in workout order', () {
      final snapshot = WorkoutNotificationSnapshotBuilder.build(
        exercises: <WorkoutNotificationExerciseInput>[
          _exercise(
            'Bench Press',
            sets: <WorkoutNotificationSetInput>[
              _set(1, loadText: '40', metricText: '8'),
              _set(2, loadText: '50', metricText: '8'),
            ],
          ),
          _exercise(
            'Lateral Raise',
            sets: <WorkoutNotificationSetInput>[
              _set(
                1,
                loadText: '6',
                metricText: '12',
                isCompleted: true,
                completedAt: '2026-06-30T10:02:00.000',
              ),
            ],
          ),
        ],
        isChinese: false,
      );

      expect(snapshot?.title, 'Bench Press');
      expect(snapshot?.body, 'Set 1 of 2 - 40 kg x 8 reps');
    });

    test('recalculates after the latest completed set is unchecked', () {
      final snapshot = WorkoutNotificationSnapshotBuilder.build(
        exercises: <WorkoutNotificationExerciseInput>[
          _exercise(
            'Bench Press',
            sets: <WorkoutNotificationSetInput>[
              _set(
                1,
                loadText: '40',
                metricText: '8',
                isCompleted: true,
                completedAt: '2026-06-30T10:00:00.000',
              ),
              _set(2, loadText: '50', metricText: '8'),
            ],
          ),
          _exercise(
            'Lateral Raise',
            sets: <WorkoutNotificationSetInput>[
              _set(1, loadText: '6', metricText: '12'),
              _set(2, loadText: '6', metricText: '12'),
            ],
          ),
        ],
        isChinese: false,
      );

      expect(snapshot?.title, 'Bench Press');
      expect(snapshot?.body, 'Set 2 of 2 - 50 kg x 8 reps');
    });

    test('returns a complete state when all sets are completed', () {
      final snapshot = WorkoutNotificationSnapshotBuilder.build(
        exercises: <WorkoutNotificationExerciseInput>[
          _exercise(
            'Bench Press',
            sets: <WorkoutNotificationSetInput>[
              _set(
                1,
                loadText: '40',
                metricText: '8',
                isCompleted: true,
                completedAt: '2026-06-30T10:00:00.000',
              ),
            ],
          ),
          _exercise(
            'Lateral Raise',
            sets: <WorkoutNotificationSetInput>[
              _set(
                1,
                loadText: '6',
                metricText: '12',
                isCompleted: true,
                completedAt: '2026-06-30T10:02:00.000',
              ),
            ],
          ),
        ],
        isChinese: false,
      );

      expect(snapshot?.title, 'Workout complete');
      expect(snapshot?.body, 'Tap to review and save');
      expect(snapshot?.isComplete, isTrue);
      expect(snapshot?.exerciseAssetPath, 'assets/lateral.png');
    });
  });
}

WorkoutNotificationExerciseInput _exercise(
  String name, {
  required List<WorkoutNotificationSetInput> sets,
}) {
  final asset = name == 'Lateral Raise'
      ? 'assets/lateral.png'
      : 'assets/bench.png';
  return WorkoutNotificationExerciseInput(
    displayName: name,
    exerciseAssetPath: asset,
    sets: sets,
  );
}

WorkoutNotificationSetInput _set(
  int setNumber, {
  required String loadText,
  required String metricText,
  bool isCompleted = false,
  String? completedAt,
}) {
  return WorkoutNotificationSetInput(
    setNumber: setNumber,
    loadText: loadText,
    metricText: metricText,
    usesDurationMetric: false,
    isCompleted: isCompleted,
    completedAt: completedAt,
  );
}
