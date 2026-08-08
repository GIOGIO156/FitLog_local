import 'dart:convert';

import 'package:fitlog_local/core/constants/exercise_catalog.dart';
import 'package:fitlog_local/core/constants/fitlog_icon_assets.dart';
import 'package:fitlog_local/core/widgets/fitlog_ui.dart';
import 'package:fitlog_local/data/db/legacy_exercise_migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  test('legacy bench press resolves to the canonical built-in exercise', () {
    expect(
      ExerciseCatalog.builtInExercises.where(
        (exercise) => exercise.key == 'bench_press',
      ),
      isEmpty,
    );

    final canonical = ExerciseCatalog.byName('Bench Press');
    expect(canonical, isNotNull);
    expect(canonical!.key, 'barbell_flat_bench_press');
    expect(canonical.name, 'Barbell Flat Bench Press');
    expect(canonical.legacyNames, contains('Bench Press'));

    expect(
      fitLogWorkoutAssetForExercise('Bench Press'),
      FitLogIconAssets.exerciseBarbellFlatBenchPress,
    );
    expect(
      fitLogWorkoutAssetForExercise('Barbell Flat Bench Press'),
      FitLogIconAssets.exerciseBarbellFlatBenchPress,
    );
  });

  test(
    'migration canonicalizes only legacy built-in bench press rows',
    () async {
      final database = _FakeDatabaseExecutor(<Map<String, Object?>>[
        <String, Object?>{
          'id': 1,
          'exercise_key': 'bench_press',
          'exercise_name': 'Bench Press',
          'exercise_source': 'builtin',
          'exercise_type': 'strength',
          'body_part': 'Chest',
          'exercise_snapshot_json': jsonEncode(<String, Object?>{
            'exercise_key': 'bench_press',
            'exercise_name': 'Bench Press',
            'exercise_type': 'strength',
          }),
        },
        <String, Object?>{
          'id': 2,
          'exercise_key': null,
          'exercise_name': 'Bench Press',
          'exercise_source': null,
          'exercise_type': 'strength',
          'body_part': 'Chest',
          'exercise_snapshot_json': '{invalid',
        },
        <String, Object?>{
          'id': 3,
          'exercise_key': 'custom_bench_press',
          'exercise_name': 'Bench Press',
          'exercise_source': 'custom',
          'exercise_type': 'strength',
          'body_part': 'Chest',
          'exercise_snapshot_json': null,
        },
        <String, Object?>{
          'id': 4,
          'exercise_key': null,
          'exercise_name': 'Bench Press',
          'exercise_source': null,
          'exercise_type': 'strength',
          'body_part': 'Back',
          'exercise_snapshot_json': null,
        },
      ]);

      await migrateLegacyBenchPressRecords(database);

      expect(database.updates, hasLength(2));
      expect(database.updates.map((update) => update.id), <Object?>[1, 2]);
      for (final update in database.updates) {
        expect(update.values['exercise_key'], 'barbell_flat_bench_press');
        expect(update.values['exercise_name'], 'Barbell Flat Bench Press');
      }

      final migratedSnapshot =
          jsonDecode(
                database.updates.first.values['exercise_snapshot_json']!
                    as String,
              )
              as Map<String, dynamic>;
      expect(migratedSnapshot['exercise_key'], 'barbell_flat_bench_press');
      expect(migratedSnapshot['exercise_name'], 'Barbell Flat Bench Press');
      expect(
        database.updates.last.values,
        isNot(contains('exercise_snapshot_json')),
      );
    },
  );
}

class _FakeDatabaseExecutor implements DatabaseExecutor {
  _FakeDatabaseExecutor(this.rows);

  final List<Map<String, Object?>> rows;
  final List<_RecordedUpdate> updates = <_RecordedUpdate>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #query) {
      return Future<List<Map<String, Object?>>>.value(rows);
    }
    if (invocation.memberName == #update) {
      final values = Map<String, Object?>.from(
        invocation.positionalArguments[1] as Map,
      );
      final whereArgs = invocation.namedArguments[#whereArgs] as List<Object?>;
      updates.add(_RecordedUpdate(id: whereArgs.single, values: values));
      return Future<int>.value(1);
    }
    return super.noSuchMethod(invocation);
  }
}

class _RecordedUpdate {
  const _RecordedUpdate({required this.id, required this.values});

  final Object? id;
  final Map<String, Object?> values;
}
