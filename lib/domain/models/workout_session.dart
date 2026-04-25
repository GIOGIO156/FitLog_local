import '../../core/utils/number_utils.dart';
import 'workout_set.dart';

class WorkoutSession {
  const WorkoutSession({
    this.id,
    this.planId,
    required this.date,
    required this.bodyPart,
    required this.exerciseName,
    required this.exerciseType,
    required this.durationMinutes,
    required this.intensity,
    required this.estimatedCalories,
    required this.notes,
    this.createdAt,
    this.updatedAt,
    this.sets = const <WorkoutSet>[],
  });

  final int? id;
  final String? planId;
  final String date;
  final String bodyPart;
  final String exerciseName;
  final String exerciseType;
  final int durationMinutes;
  final String intensity;
  final double estimatedCalories;
  final String notes;
  final String? createdAt;
  final String? updatedAt;
  final List<WorkoutSet> sets;

  WorkoutSession copyWith({
    int? id,
    String? planId,
    String? date,
    String? bodyPart,
    String? exerciseName,
    String? exerciseType,
    int? durationMinutes,
    String? intensity,
    double? estimatedCalories,
    String? notes,
    String? createdAt,
    String? updatedAt,
    List<WorkoutSet>? sets,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      date: date ?? this.date,
      bodyPart: bodyPart ?? this.bodyPart,
      exerciseName: exerciseName ?? this.exerciseName,
      exerciseType: exerciseType ?? this.exerciseType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      intensity: intensity ?? this.intensity,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sets: sets ?? this.sets,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'plan_id': planId,
      'date': date,
      'body_part': bodyPart,
      'exercise_name': exerciseName,
      'exercise_type': exerciseType,
      'duration_minutes': durationMinutes,
      'intensity': intensity,
      'estimated_calories': estimatedCalories,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory WorkoutSession.fromMap(
    Map<String, dynamic> map, {
    List<WorkoutSet> sets = const <WorkoutSet>[],
  }) {
    return WorkoutSession(
      id: NumberUtils.toInt(map['id'], fallback: -1) == -1
          ? null
          : NumberUtils.toInt(map['id']),
      planId: map['plan_id']?.toString(),
      date: (map['date'] ?? '').toString(),
      bodyPart: (map['body_part'] ?? '').toString(),
      exerciseName: (map['exercise_name'] ?? '').toString(),
      exerciseType: (map['exercise_type'] ?? '').toString(),
      durationMinutes: NumberUtils.toInt(map['duration_minutes']),
      intensity: (map['intensity'] ?? '').toString(),
      estimatedCalories: NumberUtils.toDouble(map['estimated_calories']),
      notes: (map['notes'] ?? '').toString(),
      createdAt: map['created_at']?.toString(),
      updatedAt: map['updated_at']?.toString(),
      sets: sets,
    );
  }
}
