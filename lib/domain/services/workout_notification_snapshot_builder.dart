class WorkoutNotificationExerciseInput {
  const WorkoutNotificationExerciseInput({
    required this.displayName,
    required this.exerciseAssetPath,
    required this.sets,
  });

  final String displayName;
  final String exerciseAssetPath;
  final List<WorkoutNotificationSetInput> sets;
}

class WorkoutNotificationSetInput {
  const WorkoutNotificationSetInput({
    required this.setNumber,
    required this.loadText,
    required this.metricText,
    required this.usesDurationMetric,
    required this.isCompleted,
    this.completedAt,
  });

  final int setNumber;
  final String loadText;
  final String metricText;
  final bool usesDurationMetric;
  final bool isCompleted;
  final String? completedAt;
}

class WorkoutNotificationSnapshot {
  const WorkoutNotificationSnapshot({
    required this.title,
    required this.body,
    required this.exerciseAssetPath,
    required this.isComplete,
  });

  final String title;
  final String body;
  final String exerciseAssetPath;
  final bool isComplete;
}

class WorkoutNotificationSnapshotBuilder {
  WorkoutNotificationSnapshotBuilder._();

  static WorkoutNotificationSnapshot? build({
    required List<WorkoutNotificationExerciseInput> exercises,
    required bool isChinese,
  }) {
    final setExercises = exercises
        .where((exercise) => exercise.sets.isNotEmpty)
        .toList();
    if (setExercises.isEmpty) {
      return null;
    }

    final latestCompleted = _latestCompletedSet(setExercises);
    if (latestCompleted != null) {
      final nextSet = _firstIncompleteSet(latestCompleted.exercise);
      if (nextSet != null) {
        return _snapshotForSet(
          exercise: latestCompleted.exercise,
          set: nextSet,
          isChinese: isChinese,
        );
      }
    }

    for (final exercise in setExercises) {
      final nextSet = _firstIncompleteSet(exercise);
      if (nextSet != null) {
        return _snapshotForSet(
          exercise: exercise,
          set: nextSet,
          isChinese: isChinese,
        );
      }
    }

    final completedExercise = latestCompleted?.exercise ?? setExercises.first;
    return WorkoutNotificationSnapshot(
      title: isChinese ? '训练已完成' : 'Workout complete',
      body: isChinese ? '点击返回保存训练' : 'Tap to review and save',
      exerciseAssetPath: completedExercise.exerciseAssetPath,
      isComplete: true,
    );
  }

  static WorkoutNotificationSnapshot _snapshotForSet({
    required WorkoutNotificationExerciseInput exercise,
    required WorkoutNotificationSetInput set,
    required bool isChinese,
  }) {
    final totalSets = exercise.sets.length;
    final body = set.usesDurationMetric
        ? _durationBody(set: set, totalSets: totalSets, isChinese: isChinese)
        : _repsBody(set: set, totalSets: totalSets, isChinese: isChinese);

    return WorkoutNotificationSnapshot(
      title: exercise.displayName.trim(),
      body: body,
      exerciseAssetPath: exercise.exerciseAssetPath,
      isComplete: false,
    );
  }

  static String _repsBody({
    required WorkoutNotificationSetInput set,
    required int totalSets,
    required bool isChinese,
  }) {
    final loadText = set.loadText.trim().isEmpty ? '--' : set.loadText.trim();
    final metricText = set.metricText.trim().isEmpty
        ? '--'
        : set.metricText.trim();
    if (isChinese) {
      return '第 ${set.setNumber} 组，共 $totalSets 组 - $loadText kg x $metricText 次';
    }
    return 'Set ${set.setNumber} of $totalSets - $loadText kg x $metricText reps';
  }

  static String _durationBody({
    required WorkoutNotificationSetInput set,
    required int totalSets,
    required bool isChinese,
  }) {
    final metricText = set.metricText.trim().isEmpty
        ? '--'
        : set.metricText.trim();
    if (isChinese) {
      return '第 ${set.setNumber} 组，共 $totalSets 组 - $metricText';
    }
    return 'Set ${set.setNumber} of $totalSets - $metricText';
  }

  static WorkoutNotificationSetInput? _firstIncompleteSet(
    WorkoutNotificationExerciseInput exercise,
  ) {
    for (final set in exercise.sets) {
      if (!set.isCompleted) {
        return set;
      }
    }
    return null;
  }

  static _CompletedSet? _latestCompletedSet(
    List<WorkoutNotificationExerciseInput> exercises,
  ) {
    _CompletedSet? latest;
    for (final exercise in exercises) {
      for (final set in exercise.sets) {
        if (!set.isCompleted) {
          continue;
        }
        final completedAt = DateTime.tryParse(set.completedAt ?? '');
        if (completedAt == null) {
          continue;
        }
        if (latest == null || completedAt.isAfter(latest.completedAt)) {
          latest = _CompletedSet(
            exercise: exercise,
            set: set,
            completedAt: completedAt,
          );
        }
      }
    }
    return latest;
  }
}

class _CompletedSet {
  const _CompletedSet({
    required this.exercise,
    required this.set,
    required this.completedAt,
  });

  final WorkoutNotificationExerciseInput exercise;
  final WorkoutNotificationSetInput set;
  final DateTime completedAt;
}
