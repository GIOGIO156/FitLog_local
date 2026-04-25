import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/exercise_visuals.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/exercise_thumbnail.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/workout_session.dart';

class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  WorkoutSession? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await context
        .read<AppServices>()
        .workoutRepository
        .getWorkoutSessionById(widget.sessionId);

    if (!mounted) {
      return;
    }

    setState(() {
      _session = data;
      _loading = false;
    });
  }

  Future<void> _toggleSetCompletion(int setId, bool newValue) async {
    await context.read<AppServices>().workoutRepository.completeSet(
      setId: setId,
      completed: newValue,
    );

    await _load();

    if (!mounted) {
      return;
    }

    context.read<RefreshNotifier>().markDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final session = _session;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.workoutLogTitle)),
        body: const Center(child: Text('Workout session not found.')),
      );
    }

    final completedSets = session.sets.where((set) => set.isCompleted).length;
    final color = ExerciseVisuals.colorForBodyPart(session.bodyPart, context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.workoutLogTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    ExerciseThumbnail(
                      bodyPart: session.bodyPart,
                      exerciseName: session.exerciseName,
                      color: color,
                      size: 58,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.exerciseDisplayName(session.exerciseName),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(DateUtilsX.formatReadable(session.date)),
                const SizedBox(height: 4),
                Text(strings.bodyPartLabel(session.bodyPart)),
                Text(
                  '${strings.durationMinutesLabel}: ${session.durationMinutes}',
                ),
                Text(
                  '${strings.estimatedCaloriesLabel}: ${session.estimatedCalories.toStringAsFixed(0)} kcal',
                ),
                if (session.notes.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${strings.notesLabel}: ${session.notes}'),
                  ),
              ],
            ),
          ),
          if (session.exerciseType == 'strength')
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${strings.setsPlan}: $completedSets/${session.sets.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...session.sets.map((set) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('Set ${set.setNumber}'),
                        subtitle: Text(
                          'Weight ${set.weightKg.toStringAsFixed(1)} kg - Reps ${set.reps}',
                        ),
                        trailing: set.id == null
                            ? null
                            : FilledButton.tonal(
                                onPressed: () => _toggleSetCompletion(
                                  set.id!,
                                  !set.isCompleted,
                                ),
                                child: Text(
                                  set.isCompleted
                                      ? strings.completed
                                      : strings.completeSet,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ),
            )
          else
            GlassPanel(
              child: const Text('Cardio session has no set checklist.'),
            ),
        ],
      ),
    );
  }
}
