import 'package:fitlog_local/domain/models/workout_set.dart';
import 'package:fitlog_local/domain/services/workout_calorie_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutCalorieCalculator', () {
    test('cardio uses net MET (MET - 1)', () {
      final kcal = WorkoutCalorieCalculator.estimateCardioCalories(
        exerciseName: 'Running',
        bodyWeightKg: 80,
        durationMinutes: 30,
      );

      // (8 - 1) * 3.5 * 80 / 200 * 30 = 294
      expect(kcal, closeTo(294, 0.1));
    });

    test(
      'bench sample stays in plausible net range and uses capped duration-density modifier',
      () {
        final benchSets = <WorkoutSet>[
          const WorkoutSet(
            setNumber: 1,
            weightKg: 40,
            reps: 8,
            isCompleted: true,
          ),
          const WorkoutSet(
            setNumber: 2,
            weightKg: 50,
            reps: 8,
            isCompleted: true,
          ),
          const WorkoutSet(
            setNumber: 3,
            weightKg: 60,
            reps: 8,
            isCompleted: true,
          ),
          const WorkoutSet(
            setNumber: 4,
            weightKg: 72.5,
            reps: 5,
            isCompleted: true,
          ),
          const WorkoutSet(
            setNumber: 5,
            weightKg: 70,
            reps: 5,
            isCompleted: true,
          ),
          const WorkoutSet(
            setNumber: 6,
            weightKg: 70,
            reps: 5,
            isCompleted: true,
          ),
          const WorkoutSet(
            setNumber: 7,
            weightKg: 70,
            reps: 5,
            isCompleted: true,
          ),
          const WorkoutSet(
            setNumber: 8,
            weightKg: 70,
            reps: 5,
            isCompleted: true,
          ),
          const WorkoutSet(
            setNumber: 9,
            weightKg: 70,
            reps: 4,
            isCompleted: true,
          ),
        ];

        final kcal45 = WorkoutCalorieCalculator.estimateStrengthCalories(
          exerciseName: 'Bench Press',
          bodyWeightKg: 80,
          sets: benchSets,
          totalSessionDurationMinutes: 45,
        );
        final kcal120 = WorkoutCalorieCalculator.estimateStrengthCalories(
          exerciseName: 'Bench Press',
          bodyWeightKg: 80,
          sets: benchSets,
          totalSessionDurationMinutes: 120,
        );
        final kcal20 = WorkoutCalorieCalculator.estimateStrengthCalories(
          exerciseName: 'Bench Press',
          bodyWeightKg: 80,
          sets: benchSets,
          totalSessionDurationMinutes: 20,
        );
        final kcal100 = WorkoutCalorieCalculator.estimateStrengthCalories(
          exerciseName: 'Bench Press',
          bodyWeightKg: 80,
          sets: benchSets,
          totalSessionDurationMinutes: 100,
        );

        expect(kcal45, inInclusiveRange(58, 78));
        expect(kcal120, inInclusiveRange(52, 75));
        expect(kcal45, greaterThan(kcal120));
        expect(kcal45 / kcal120, lessThan(1.25));
        expect(kcal20 - kcal100, greaterThanOrEqualTo(2));
      },
    );

    test('same volume: lower body compound > upper compound > isolation', () {
      final sameVolumeSets = <WorkoutSet>[
        const WorkoutSet(
          setNumber: 1,
          weightKg: 60,
          reps: 10,
          isCompleted: true,
        ),
        const WorkoutSet(
          setNumber: 2,
          weightKg: 60,
          reps: 10,
          isCompleted: true,
        ),
        const WorkoutSet(
          setNumber: 3,
          weightKg: 60,
          reps: 10,
          isCompleted: true,
        ),
      ];

      final bench = WorkoutCalorieCalculator.estimateStrengthCalories(
        exerciseName: 'Bench Press',
        bodyWeightKg: 80,
        sets: sameVolumeSets,
        totalSessionDurationMinutes: 45,
      );
      final squat = WorkoutCalorieCalculator.estimateStrengthCalories(
        exerciseName: 'Squat',
        bodyWeightKg: 80,
        sets: sameVolumeSets,
        totalSessionDurationMinutes: 45,
      );
      final curl = WorkoutCalorieCalculator.estimateStrengthCalories(
        exerciseName: 'Biceps Curl',
        bodyWeightKg: 80,
        sets: sameVolumeSets,
        totalSessionDurationMinutes: 45,
      );

      expect(squat, greaterThan(bench));
      expect(bench, greaterThan(curl));
    });
  });
}
