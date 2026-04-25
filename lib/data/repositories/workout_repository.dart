import '../../core/utils/date_utils.dart';
import '../../domain/models/workout_session.dart';
import '../../domain/models/workout_set.dart';
import '../db/app_database.dart';

class WorkoutRepository {
  WorkoutRepository(this._database);

  final AppDatabase _database;

  Future<int> insertWorkoutSession(WorkoutSession session) async {
    final db = await _database.database;
    final now = DateTime.now().toIso8601String();

    return db.transaction((txn) async {
      final int sessionId = await txn.insert(
        'workout_sessions',
        session.copyWith(createdAt: now, updatedAt: now).toMap()..remove('id'),
      );

      for (final set in session.sets) {
        await txn.insert(
          'workout_sets',
          set.copyWith(workoutSessionId: sessionId).toMap()..remove('id'),
        );
      }

      return sessionId;
    });
  }

  Future<void> updateWorkoutSession(WorkoutSession session) async {
    if (session.id == null) {
      throw ArgumentError('Workout session id is required for update.');
    }

    final db = await _database.database;
    final now = DateTime.now().toIso8601String();
    final existingRows = await db.query(
      'workout_sessions',
      columns: <String>['created_at'],
      where: 'id = ?',
      whereArgs: <Object?>[session.id],
      limit: 1,
    );

    if (existingRows.isEmpty) {
      throw StateError('Workout session not found: id=${session.id}');
    }

    final existingCreatedAt =
        existingRows.first['created_at']?.toString() ?? now;
    final payload = session.copyWith(
      createdAt: existingCreatedAt,
      updatedAt: now,
    );

    await db.transaction((txn) async {
      await txn.update(
        'workout_sessions',
        payload.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: <Object?>[session.id],
      );

      await txn.delete(
        'workout_sets',
        where: 'workout_session_id = ?',
        whereArgs: <Object?>[session.id],
      );

      for (final set in session.sets) {
        await txn.insert(
          'workout_sets',
          set.copyWith(workoutSessionId: session.id).toMap()..remove('id'),
        );
      }
    });
  }

  Future<void> deleteWorkoutSession(int id) async {
    final db = await _database.database;
    await db.delete(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<void> deleteWorkoutPlan(String planId) async {
    final db = await _database.database;
    await db.delete(
      'workout_sessions',
      where: 'plan_id = ?',
      whereArgs: <Object?>[planId],
    );
  }

  Future<List<WorkoutSession>> getAllWorkoutSessions() async {
    final db = await _database.database;
    final rows = await db.query(
      'workout_sessions',
      orderBy: 'date DESC, created_at DESC',
    );

    final List<WorkoutSession> sessions = <WorkoutSession>[];
    for (final row in rows) {
      final int id = row['id'] as int;
      final sets = await getSetsBySessionId(id);
      sessions.add(WorkoutSession.fromMap(row, sets: sets));
    }
    return sessions;
  }

  Future<List<WorkoutSession>> getWorkoutSessionsByDate(String day) async {
    final db = await _database.database;
    final rows = await db.query(
      'workout_sessions',
      where: 'date = ?',
      whereArgs: <Object?>[day],
      orderBy: 'created_at DESC',
    );

    final List<WorkoutSession> sessions = <WorkoutSession>[];
    for (final row in rows) {
      final int id = row['id'] as int;
      final sets = await getSetsBySessionId(id);
      sessions.add(WorkoutSession.fromMap(row, sets: sets));
    }
    return sessions;
  }

  Future<WorkoutSession?> getWorkoutSessionById(int id) async {
    final db = await _database.database;
    final rows = await db.query(
      'workout_sessions',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final sets = await getSetsBySessionId(id);
    return WorkoutSession.fromMap(rows.first, sets: sets);
  }

  Future<WorkoutSession?> getLatestSessionByExerciseName(
    String exerciseName,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      'workout_sessions',
      where: 'exercise_name = ?',
      whereArgs: <Object?>[exerciseName],
      orderBy: 'created_at DESC, id DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final int id = rows.first['id'] as int;
    final sets = await getSetsBySessionId(id);
    return WorkoutSession.fromMap(rows.first, sets: sets);
  }

  Future<List<WorkoutSession>> getWorkoutSessionsByPlanId(String planId) async {
    final db = await _database.database;
    final rows = await db.query(
      'workout_sessions',
      where: 'plan_id = ?',
      whereArgs: <Object?>[planId],
      orderBy: 'created_at ASC',
    );

    final List<WorkoutSession> sessions = <WorkoutSession>[];
    for (final row in rows) {
      final int id = row['id'] as int;
      final sets = await getSetsBySessionId(id);
      sessions.add(WorkoutSession.fromMap(row, sets: sets));
    }
    return sessions;
  }

  Future<List<WorkoutSet>> getSetsBySessionId(int sessionId) async {
    final db = await _database.database;
    final rows = await db.query(
      'workout_sets',
      where: 'workout_session_id = ?',
      whereArgs: <Object?>[sessionId],
      orderBy: 'set_number ASC',
    );

    return rows.map(WorkoutSet.fromMap).toList();
  }

  Future<void> completeSet({
    required int setId,
    required bool completed,
  }) async {
    final db = await _database.database;
    final completedAt = completed ? DateTime.now().toIso8601String() : null;
    await db.update(
      'workout_sets',
      <String, dynamic>{
        'is_completed': completed ? 1 : 0,
        'completed_at': completedAt,
      },
      where: 'id = ?',
      whereArgs: <Object?>[setId],
    );
  }

  Future<double> getExerciseCaloriesByDate(String day) async {
    final sessions = await getWorkoutSessionsByDate(day);
    return sessions.fold<double>(
      0,
      (sum, item) => sum + item.estimatedCalories,
    );
  }

  Future<List<String>> getDistinctDates() async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT date FROM workout_sessions ORDER BY date DESC',
    );
    return rows.map((row) => row['date'].toString()).toList();
  }

  Future<List<WorkoutSession>> getTodayWorkoutSessions() async {
    return getWorkoutSessionsByDate(DateUtilsX.todayKey());
  }
}
