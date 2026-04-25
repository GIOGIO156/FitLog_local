import '../../core/utils/number_utils.dart';

class WorkoutSet {
  const WorkoutSet({
    this.id,
    this.workoutSessionId,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.isCompleted,
    this.completedAt,
  });

  final int? id;
  final int? workoutSessionId;
  final int setNumber;
  final double weightKg;
  final int reps;
  final bool isCompleted;
  final String? completedAt;

  WorkoutSet copyWith({
    int? id,
    int? workoutSessionId,
    int? setNumber,
    double? weightKg,
    int? reps,
    bool? isCompleted,
    String? completedAt,
    bool clearCompletedAt = false,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      workoutSessionId: workoutSessionId ?? this.workoutSessionId,
      setNumber: setNumber ?? this.setNumber,
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'workout_session_id': workoutSessionId,
      'set_number': setNumber,
      'weight_kg': weightKg,
      'reps': reps,
      'is_completed': isCompleted ? 1 : 0,
      'completed_at': completedAt,
    };
  }

  factory WorkoutSet.fromMap(Map<String, dynamic> map) {
    return WorkoutSet(
      id: NumberUtils.toInt(map['id'], fallback: -1) == -1
          ? null
          : NumberUtils.toInt(map['id']),
      workoutSessionId:
          NumberUtils.toInt(map['workout_session_id'], fallback: -1) == -1
          ? null
          : NumberUtils.toInt(map['workout_session_id']),
      setNumber: NumberUtils.toInt(map['set_number']),
      weightKg: NumberUtils.toDouble(map['weight_kg']),
      reps: NumberUtils.toInt(map['reps']),
      isCompleted: NumberUtils.toInt(map['is_completed']) == 1,
      completedAt: map['completed_at']?.toString(),
    );
  }
}
