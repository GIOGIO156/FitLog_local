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
import '../../domain/services/workout_calorie_calculator.dart';
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
  bool _savingPlanEdits = false;
  String? _lastSaveError;

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

    _lastSaveError = null;
    final services = context.read<AppServices>();
    final repository = services.workoutRepository;
    final profile = await services.profileRepository.getProfile();
    final bodyWeightKg = profile?.weightKg ?? 65;

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

        final updatedDuration = newDurations[i];
        final updatedCalories = session.exerciseType == 'cardio'
            ? WorkoutCalorieCalculator.estimateCardioCalories(
                exerciseName: session.exerciseName,
                bodyWeightKg: bodyWeightKg,
                durationMinutes: updatedDuration,
              )
            : WorkoutCalorieCalculator.estimateStrengthCalories(
                exerciseName: session.exerciseName,
                bodyWeightKg: bodyWeightKg,
                sets: session.sets,
                totalSessionDurationMinutes: updatedDuration,
              );

        await repository.updateWorkoutSession(
          session.copyWith(
            date: newDate,
            createdAt: shiftedCreatedAt.toIso8601String(),
            durationMinutes: updatedDuration,
            estimatedCalories: updatedCalories,
          ),
        );
      }

      return true;
    } catch (error) {
      _lastSaveError = error.toString();
      return false;
    }
  }

  Future<void> _openPlanEditor() async {
    if (_sessions.isEmpty || _savingPlanEdits) {
      return;
    }

    final strings = context.stringsRead;
    final draftDate = _sessions.first.date;
    final draftTime = TimeOfDay.fromDateTime(_createdAt(_sessions.first));
    final totalDuration = _sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationMinutes,
    );
    final draft = await Navigator.of(context).push<_PlanEditDraft>(
      MaterialPageRoute<_PlanEditDraft>(
        builder: (_) => _WorkoutPlanEditorPage(
          initialDate: draftDate,
          initialTime: draftTime,
          initialTotalDuration: totalDuration,
        ),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _savingPlanEdits = true);
    try {
      final saved = await _savePlanEdits(
        newDate: draft.date,
        newStartTime: draft.startTime,
        newTotalDurationMinutes: draft.totalDurationMinutes,
      );
      if (!mounted) {
        return;
      }

      if (saved) {
        context.read<RefreshNotifier>().markDataChanged();
        messenger.showSnackBar(SnackBar(content: Text(strings.workoutSaved)));
        await _load();
      } else {
        final errorText = _lastSaveError == null
            ? strings.failedToLoadWorkout('unknown')
            : strings.failedToLoadWorkout(_lastSaveError!);
        messenger.showSnackBar(SnackBar(content: Text(errorText)));
      }
    } finally {
      if (mounted) {
        setState(() => _savingPlanEdits = false);
      }
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
            onPressed: _savingPlanEdits ? null : _openPlanEditor,
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

class _PlanEditDraft {
  const _PlanEditDraft({
    required this.date,
    required this.startTime,
    required this.totalDurationMinutes,
  });

  final String date;
  final TimeOfDay startTime;
  final int totalDurationMinutes;
}

class _WorkoutPlanEditorPage extends StatefulWidget {
  const _WorkoutPlanEditorPage({
    required this.initialDate,
    required this.initialTime,
    required this.initialTotalDuration,
  });

  final String initialDate;
  final TimeOfDay initialTime;
  final int initialTotalDuration;

  @override
  State<_WorkoutPlanEditorPage> createState() => _WorkoutPlanEditorPageState();
}

class _WorkoutPlanEditorPageState extends State<_WorkoutPlanEditorPage> {
  late String _draftDate;
  late TimeOfDay _draftTime;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _draftDate = widget.initialDate;
    _draftTime = widget.initialTime;
    _durationController = TextEditingController(
      text: widget.initialTotalDuration.toString(),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateUtilsX.parseDay(_draftDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _draftDate = DateUtilsX.formatDate(selected));
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _draftTime,
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _draftTime = selected);
  }

  void _submit() {
    final strings = context.stringsRead;
    final duration = NumberUtils.toInt(_durationController.text, fallback: -1);
    if (duration <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.invalidDuration)));
      return;
    }
    Navigator.of(context).pop(
      _PlanEditDraft(
        date: _draftDate,
        startTime: _draftTime,
        totalDurationMinutes: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(strings.saveChanges)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: <Widget>[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.dateLabel),
            subtitle: Text(DateUtilsX.formatReadable(_draftDate)),
            trailing: TextButton(
              onPressed: _pickDate,
              child: Text(strings.change),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.startTimeLabel),
            subtitle: Text(_draftTime.format(context)),
            trailing: TextButton(
              onPressed: _pickTime,
              child: Text(strings.change),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings.totalDurationLabel,
              suffixText: 'min',
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.save_outlined),
            label: Text(strings.saveChanges),
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
