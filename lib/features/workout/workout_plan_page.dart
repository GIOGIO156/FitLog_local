import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/exercise_visuals.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/exercise_thumbnail.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/workout_session.dart';
import 'workout_session_page.dart';

class WorkoutPlanPage extends StatefulWidget {
  const WorkoutPlanPage({super.key, required this.seedSessionId, this.planId});

  final int seedSessionId;
  final String? planId;

  @override
  State<WorkoutPlanPage> createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  List<WorkoutSession> _sessions = <WorkoutSession>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = context.read<AppServices>().workoutRepository;
    late final List<WorkoutSession> sessions;
    if (widget.planId != null && widget.planId!.isNotEmpty) {
      sessions = await repository.getWorkoutSessionsByPlanId(widget.planId!);
    } else {
      final session = await repository.getWorkoutSessionById(
        widget.seedSessionId,
      );
      sessions = session == null
          ? <WorkoutSession>[]
          : <WorkoutSession>[session];
    }

    if (!mounted) {
      return;
    }

    sessions.sort((a, b) => _createdAt(a).compareTo(_createdAt(b)));
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  Future<void> _openSession(WorkoutSession session) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkoutSessionPage(sessionId: session.id!),
      ),
    );

    if (changed == true && mounted) {
      context.read<RefreshNotifier>().markDataChanged();
      await _load();
    }
  }

  DateTime _createdAt(WorkoutSession session) {
    final created = DateTime.tryParse(session.createdAt ?? '');
    if (created != null) {
      return created.toLocal();
    }
    return DateUtilsX.parseDay(session.date);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.workoutPlan)),
        body: Center(child: Text(strings.noActionsInPlan)),
      );
    }

    final first = _sessions.first;
    final startedAt = _createdAt(first);
    final totalDuration = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final totalCalories = _sessions.fold<double>(
      0,
      (sum, session) => sum + session.estimatedCalories,
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.workoutPlan)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  DateUtilsX.formatReadable(first.date),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                _Line(
                  label: strings.startTimeLabel,
                  value: _timeFormat.format(startedAt),
                ),
                _Line(
                  label: strings.totalDurationLabel,
                  value: '$totalDuration min',
                ),
                _Line(
                  label: strings.estimatedCaloriesLabel,
                  value: '${totalCalories.toStringAsFixed(0)} kcal',
                ),
              ],
            ),
          ),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.actionsInPlan,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ..._sessions.map((session) {
                  final color = ExerciseVisuals.colorForBodyPart(
                    session.bodyPart,
                    context,
                  );
                  final completedSets = session.sets
                      .where((set) => set.isCompleted)
                      .length;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _openSession(session),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.42),
                      ),
                      child: Row(
                        children: <Widget>[
                          ExerciseThumbnail(
                            bodyPart: session.bodyPart,
                            exerciseName: session.exerciseName,
                            color: color,
                            size: 54,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  strings.exerciseDisplayName(
                                    session.exerciseName,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${strings.bodyPartLabel(session.bodyPart)} - ${session.durationMinutes} min',
                                ),
                                Text(
                                  '${session.estimatedCalories.toStringAsFixed(0)} kcal',
                                ),
                                if (session.exerciseType == 'strength')
                                  Text(
                                    '${strings.setsPlan}: $completedSets/${session.sets.length}',
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
