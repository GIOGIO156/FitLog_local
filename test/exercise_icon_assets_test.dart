import 'dart:io';

import 'package:fitlog_local/core/constants/exercise_catalog.dart';
import 'package:fitlog_local/core/widgets/fitlog_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all built-in exercises resolve to existing dedicated PNG assets', () {
    for (final exercise in ExerciseCatalog.builtInExercises) {
      final assetPath = fitLogWorkoutAssetForExercise(exercise.name);

      expect(assetPath, isNotNull, reason: exercise.key);
      expect(assetPath, endsWith('.png'), reason: exercise.key);
      expect(
        File(assetPath!).existsSync(),
        isTrue,
        reason: '${exercise.key} -> $assetPath',
      );

      for (final legacyName in exercise.legacyNames) {
        expect(
          fitLogWorkoutAssetForExercise(legacyName),
          assetPath,
          reason: '${exercise.key} legacy name: $legacyName',
        );
      }
    }
  });
}
