import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/constants/exercise_definition.dart';

const String _legacyBenchPressKey = 'bench_press';
const String _legacyBenchPressName = 'Bench Press';
const String _barbellFlatBenchPressKey = 'barbell_flat_bench_press';
const String _barbellFlatBenchPressName = 'Barbell Flat Bench Press';

Future<void> migrateLegacyBenchPressRecords(DatabaseExecutor database) async {
  final rows = await database.query(
    'workout_sessions',
    columns: <String>[
      'id',
      'exercise_key',
      'exercise_name',
      'exercise_source',
      'exercise_type',
      'body_part',
      'exercise_snapshot_json',
    ],
    where: 'exercise_key = ? OR exercise_name = ?',
    whereArgs: const <Object?>[_legacyBenchPressKey, _legacyBenchPressName],
  );

  for (final row in rows) {
    if (!_isLegacyBuiltInBenchPress(row)) {
      continue;
    }

    final id = row['id'];
    if (id == null) {
      continue;
    }

    final canonicalSnapshot = _canonicalizeSnapshot(
      row['exercise_snapshot_json']?.toString(),
    );
    await database.update(
      'workout_sessions',
      <String, Object?>{
        'exercise_key': _barbellFlatBenchPressKey,
        'exercise_name': _barbellFlatBenchPressName,
        'exercise_snapshot_json': ?canonicalSnapshot,
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}

bool _isLegacyBuiltInBenchPress(Map<String, Object?> row) {
  final source = row['exercise_source']?.toString().trim() ?? '';
  if (source.isNotEmpty && source != ExerciseSource.builtin) {
    return false;
  }

  final key = row['exercise_key']?.toString().trim() ?? '';
  if (key == _legacyBenchPressKey) {
    return true;
  }
  if (key.isNotEmpty) {
    return false;
  }

  return row['exercise_name']?.toString() == _legacyBenchPressName &&
      row['body_part']?.toString() == 'Chest' &&
      row['exercise_type']?.toString() == ExerciseType.strength;
}

String? _canonicalizeSnapshot(String? rawSnapshot) {
  if ((rawSnapshot ?? '').trim().isEmpty) {
    return null;
  }

  try {
    final decoded = jsonDecode(rawSnapshot!);
    if (decoded is! Map) {
      return null;
    }
    final snapshot = Map<String, dynamic>.from(decoded);
    snapshot['exercise_key'] = _barbellFlatBenchPressKey;
    snapshot['exercise_name'] = _barbellFlatBenchPressName;
    return jsonEncode(snapshot);
  } on FormatException {
    return null;
  }
}
