import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/exercise_visuals.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/exercise_thumbnail.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/workout_session.dart';
import 'add_workout_page.dart';
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
      sessions = session == null ? <WorkoutSession>[] : <WorkoutSession>[session];
    }

    if (!mounted) {
      return;
    }

    sessions.sort((a, b) => _createdAtRaw(a).compareTo(_createdAtRaw(b)));
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  Future<void> _openSession(WorkoutSession session) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutSessionPage(sessionId: session.id!),
      ),
    );
  }

  Future<void> _editRecord() async {
    if (_sessions.isEmpty) {
      return;
    }
    final seed = _sessions.first;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddWorkoutPage(
          initialDate: seed.date,
          editingPlanId: seed.planId,
          seedSessionId: seed.id,
        ),
      ),
    );

    if (changed == true && mounted) {
      context.read<RefreshNotifier>().markDataChanged();
      await _load();
    }
  }

  DateTime _createdAtRaw(WorkoutSession session) {
    final created = DateTime.tryParse(session.createdAt ?? '');
    if (created != null) {
      return created;
    }
    return DateUtilsX.parseDay(session.date);
  }

  String _recordName(WorkoutSession seed, AppStrings strings) {
    final recordName = seed.recordName?.trim() ?? '';
    if (recordName.isNotEmpty) {
      return recordName;
    }
    return strings.exerciseDisplayName(seed.exerciseName);
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
    final startedAt = _createdAtRaw(first).toLocal();
    final totalDuration = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final totalCalories = _sessions.fold<double>(
      0,
      (sum, session) => sum + session.estimatedCalories,
    );
    final totalVolume = _sessions.fold<double>(
      0,
      (sum, session) =>
          sum +
          session.sets.fold<double>(
            0,
            (setSum, set) => setSum + (set.weightKg * set.reps),
          ),
    );
    final totalSets = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.sets.length,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.workoutPlan),
        actions: <Widget>[
          IconButton(
            onPressed: _editRecord,
            icon: const Icon(Icons.edit_outlined),
            tooltip: strings.saveChanges,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _recordName(first, strings),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${DateUtilsX.formatReadable(first.date)} · ${_timeFormat.format(startedAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _MetricBlock(
                        label: strings.totalDurationLabel,
                        value: '$totalDuration min',
                      ),
                    ),
                    Expanded(
                      child: _MetricBlock(
                        label: strings.totalVolumeLabel,
                        value: '${totalVolume.toStringAsFixed(1)} kg',
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _MetricBlock(
                        label: strings.totalSetsLabel,
                        value: '$totalSets',
                        horizontalPadding: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${strings.estimatedCaloriesLabel}: ${totalCalories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (first.notes.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('${strings.notesLabel}: ${first.notes.trim()}'),
                ],
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
                  final volume = session.sets.fold<double>(
                    0,
                    (sum, set) => sum + (set.weightKg * set.reps),
                  );
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
                            .withValues(alpha: 0.36),
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
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(strings.bodyPartLabel(session.bodyPart)),
                                const SizedBox(height: 4),
                                Text(
                                  '${strings.totalSetsLabel}: ${session.sets.length} · ${strings.totalVolumeLabel}: ${volume.toStringAsFixed(1)} kg',
                                ),
                                Text(
                                  '${strings.durationMinutesLabel}: ${session.durationMinutes} · ${session.estimatedCalories.toStringAsFixed(0)} kcal',
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

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    this.horizontalPadding = 0,
  });

  final String label;
  final String value;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
