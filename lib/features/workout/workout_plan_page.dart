import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/exercise_visuals.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/number_utils.dart';
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

    sessions.sort((a, b) => _createdAtRaw(a).compareTo(_createdAtRaw(b)));
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

  DateTime _createdAtRaw(WorkoutSession session) {
    final created = DateTime.tryParse(session.createdAt ?? '');
    if (created != null) {
      return created;
    }
    return DateUtilsX.parseDay(session.date);
  }

  DateTime _createdAt(WorkoutSession session) {
    return _createdAtRaw(session).toLocal();
  }

  List<int> _splitDurationByOriginalRatio(
    List<WorkoutSession> sessions,
    int newTotalDurationMinutes,
  ) {
    final safeTotal = math.max(0, newTotalDurationMinutes);
    if (sessions.isEmpty) {
      return const <int>[];
    }

    final previousDurations = sessions
        .map((session) => math.max(0, session.durationMinutes))
        .toList();
    final previousTotal = previousDurations.fold<int>(
      0,
      (sum, value) => sum + value,
    );

    if (previousTotal <= 0) {
      final even = safeTotal ~/ sessions.length;
      var remainder = safeTotal % sessions.length;
      return List<int>.generate(sessions.length, (_) {
        final value = even + (remainder > 0 ? 1 : 0);
        if (remainder > 0) {
          remainder--;
        }
        return value;
      });
    }

    final raw = previousDurations
        .map((duration) => duration * safeTotal / previousTotal)
        .toList();
    final distributed = raw.map((value) => value.floor()).toList();
    var assigned = distributed.fold<int>(0, (sum, value) => sum + value);

    final fractionalIndexes = List<int>.generate(raw.length, (index) => index)
      ..sort(
        (a, b) => (raw[b] - distributed[b]).compareTo(raw[a] - distributed[a]),
      );

    var cursor = 0;
    while (assigned < safeTotal && fractionalIndexes.isNotEmpty) {
      final index = fractionalIndexes[cursor % fractionalIndexes.length];
      distributed[index] += 1;
      assigned += 1;
      cursor += 1;
    }

    return distributed;
  }

  Future<bool> _savePlanEdits({
    required String newDate,
    required TimeOfDay newStartTime,
    required int newTotalDurationMinutes,
  }) async {
    if (_sessions.isEmpty) {
      return false;
    }

    final strings = context.stringsRead;
    final repository = context.read<AppServices>().workoutRepository;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final ordered = List<WorkoutSession>.from(_sessions)
        ..sort((a, b) => _createdAtRaw(a).compareTo(_createdAtRaw(b)));
      final oldStart = _createdAtRaw(ordered.first);

      final day = DateUtilsX.parseDay(newDate);
      final newStart = DateTime(
        day.year,
        day.month,
        day.day,
        newStartTime.hour,
        newStartTime.minute,
      );

      final newDurations = _splitDurationByOriginalRatio(
        ordered,
        newTotalDurationMinutes,
      );

      for (var i = 0; i < ordered.length; i++) {
        final session = ordered[i];
        final previousCreatedAt = _createdAtRaw(session);
        final offset = previousCreatedAt.difference(oldStart);
        final shiftedCreatedAt = newStart.add(offset);

        final previousDuration = session.durationMinutes;
        final updatedDuration = newDurations[i];
        final updatedCalories = previousDuration <= 0
            ? session.estimatedCalories
            : session.estimatedCalories * updatedDuration / previousDuration;

        await repository.updateWorkoutSession(
          session.copyWith(
            date: newDate,
            createdAt: shiftedCreatedAt.toIso8601String(),
            durationMinutes: updatedDuration,
            estimatedCalories: updatedCalories,
          ),
        );
      }

      if (!mounted) {
        return false;
      }

      context.read<RefreshNotifier>().markDataChanged();
      messenger.showSnackBar(SnackBar(content: Text(strings.workoutSaved)));
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(strings.failedToLoadWorkout(error))),
      );
      return false;
    }
  }

  Future<void> _openPlanEditor() async {
    if (_sessions.isEmpty) {
      return;
    }

    final strings = context.stringsRead;
    var draftDate = _sessions.first.date;
    var draftTime = TimeOfDay.fromDateTime(_createdAt(_sessions.first));
    final totalDuration = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final durationController = TextEditingController(
      text: totalDuration.toString(),
    );

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.saveChanges,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.dateLabel),
                    subtitle: Text(DateUtilsX.formatReadable(draftDate)),
                    trailing: TextButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: DateUtilsX.parseDay(draftDate),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (selected != null) {
                                setModalState(() {
                                  draftDate = DateUtilsX.formatDate(selected);
                                });
                              }
                            },
                      child: Text(strings.change),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.startTimeLabel),
                    subtitle: Text(draftTime.format(context)),
                    trailing: TextButton(
                      onPressed: saving
                          ? null
                          : () async {
                              final selected = await showTimePicker(
                                context: context,
                                initialTime: draftTime,
                              );
                              if (selected != null) {
                                setModalState(() {
                                  draftTime = selected;
                                });
                              }
                            },
                      child: Text(strings.change),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: durationController,
                    enabled: !saving,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: strings.totalDurationLabel,
                      suffixText: 'min',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              final newTotalDuration = NumberUtils.toInt(
                                durationController.text,
                                fallback: -1,
                              );
                              if (newTotalDuration <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(strings.invalidDuration),
                                  ),
                                );
                                return;
                              }

                              setModalState(() => saving = true);
                              final saved = await _savePlanEdits(
                                newDate: draftDate,
                                newStartTime: draftTime,
                                newTotalDurationMinutes: newTotalDuration,
                              );
                              if (!context.mounted) {
                                return;
                              }

                              if (saved) {
                                Navigator.of(sheetContext).pop(true);
                              } else {
                                setModalState(() => saving = false);
                              }
                            },
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        saving ? strings.saving : strings.saveChanges,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    durationController.dispose();

    if (changed == true && mounted) {
      await _load();
    }
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
      appBar: AppBar(
        title: Text(strings.workoutPlan),
        actions: <Widget>[
          IconButton(
            onPressed: _openPlanEditor,
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
