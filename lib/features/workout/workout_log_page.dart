import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/workout_session.dart';
import 'add_workout_page.dart';
import 'workout_plan_page.dart';

class WorkoutLogPage extends StatefulWidget {
  const WorkoutLogPage({super.key});

  @override
  State<WorkoutLogPage> createState() => _WorkoutLogPageState();
}

class _WorkoutLogPageState extends State<WorkoutLogPage> {
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  Future<List<WorkoutSession>> _loadSessions(BuildContext context, String day) {
    return context
        .read<AppServices>()
        .workoutRepository
        .getWorkoutSessionsByDate(day);
  }

  Future<void> _openAddWorkout(BuildContext context, String initialDate) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddWorkoutPage(initialDate: initialDate),
      ),
    );

    if (saved == true && context.mounted) {
      context.read<RefreshNotifier>().markDataChanged();
    }
  }

  Future<void> _openPlan(BuildContext context, _WorkoutPlanGroup group) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => WorkoutPlanPage(
          planId: group.planId,
          seedSessionId: group.sessions.first.id!,
        ),
      ),
    );

    if (changed == true && context.mounted) {
      context.read<RefreshNotifier>().markDataChanged();
    }
  }

  Future<void> _deletePlan(
    BuildContext context,
    _WorkoutPlanGroup group,
  ) async {
    final services = context.read<AppServices>();
    final refreshNotifier = context.read<RefreshNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.stringsRead;

    final confirmText = group.planId == null
        ? strings.deleteWorkoutConfirm(
            group.sessions.first.exerciseName,
            group.sessions.first.date,
          )
        : strings.deleteWorkoutPlanConfirm(
            group.exerciseNames.length,
            group.sessions.first.date,
          );

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(strings.deleteRecord),
              content: Text(confirmText),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.cancel),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(strings.delete),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    if (group.planId == null) {
      await services.workoutRepository.deleteWorkoutSession(
        group.sessions.first.id!,
      );
    } else {
      await services.workoutRepository.deleteWorkoutPlan(group.planId!);
    }

    if (!context.mounted) {
      return;
    }

    refreshNotifier.markDataChanged();
    messenger.showSnackBar(SnackBar(content: Text(strings.workoutDeleted)));
  }

  List<_WorkoutPlanGroup> _groupSessions(List<WorkoutSession> sessions) {
    final Map<String, List<WorkoutSession>> grouped =
        <String, List<WorkoutSession>>{};
    for (final session in sessions) {
      final planId = (session.planId ?? '').trim();
      final key = planId.isEmpty ? 'single:${session.id}' : 'plan:$planId';
      grouped.putIfAbsent(key, () => <WorkoutSession>[]).add(session);
    }

    final List<_WorkoutPlanGroup> plans = grouped.values
        .map(_WorkoutPlanGroup.fromSessions)
        .toList();
    plans.sort((a, b) => b.sortTime.compareTo(a.sortTime));
    return plans;
  }

  String _formatStartTime(DateTime startedAt) => _timeFormat.format(startedAt);

  Future<void> _pickDate(
    BuildContext context,
    SelectedDateNotifier selectedDateNotifier,
  ) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateUtilsX.parseDay(selectedDateNotifier.selectedDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null && context.mounted) {
      selectedDateNotifier.setDate(DateUtilsX.formatDate(selected));
    }
  }

  void _shiftDate(SelectedDateNotifier selectedDateNotifier, int deltaDays) {
    final current = DateUtilsX.parseDay(selectedDateNotifier.selectedDate);
    final next = current.add(Duration(days: deltaDays));
    selectedDateNotifier.setDate(DateUtilsX.formatDate(next));
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Consumer2<RefreshNotifier, SelectedDateNotifier>(
      builder: (context, refresh, selectedDateNotifier, _) {
        refresh.version;
        final selectedDate = selectedDateNotifier.selectedDate;
        return Column(
          children: <Widget>[
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => _shiftDate(selectedDateNotifier, -1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          DateUtilsX.formatReadable(selectedDate),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shiftDate(selectedDateNotifier, 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                      TextButton(
                        onPressed: () =>
                            _pickDate(context, selectedDateNotifier),
                        child: Text(strings.change),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openAddWorkout(context, selectedDate),
                    icon: const Icon(Icons.add),
                    label: Text(strings.addWorkout),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<WorkoutSession>>(
                future: _loadSessions(context, selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          strings.failedToLoadWorkout(snapshot.error!),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final sessions = snapshot.data ?? <WorkoutSession>[];
                  final plans = _groupSessions(sessions);
                  if (plans.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          strings.noWorkoutRecords,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: plans.length,
                    padding: EdgeInsets.only(
                      bottom:
                          MediaQuery.paddingOf(context).bottom +
                          kBottomNavigationBarHeight +
                          24,
                    ),
                    itemBuilder: (context, index) {
                      final plan = plans[index];
                      return GlassPanel(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openPlan(context, plan),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.72),
                                    ),
                                    child: Text(
                                      _formatStartTime(plan.startedAt),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(DateUtilsX.formatReadable(plan.date)),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _deletePlan(context, plan),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: strings.delete,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${strings.totalDurationLabel}: ${plan.totalDurationMinutes} min',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${strings.estimatedCaloriesLabel}: ${plan.totalCalories.toStringAsFixed(0)} kcal',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                strings.exerciseNamesLabel,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              ...plan.exerciseNames.map(
                                (name) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    strings.exerciseDisplayName(name),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WorkoutPlanGroup {
  _WorkoutPlanGroup({
    required this.planId,
    required this.sessions,
    required this.startedAt,
    required this.sortTime,
    required this.date,
    required this.totalCalories,
    required this.totalDurationMinutes,
    required this.exerciseNames,
  });

  factory _WorkoutPlanGroup.fromSessions(List<WorkoutSession> rawSessions) {
    final sessions = List<WorkoutSession>.from(rawSessions);
    sessions.sort((a, b) => _createdAt(a).compareTo(_createdAt(b)));

    final names = <String>[];
    final seen = <String>{};
    for (final session in sessions) {
      if (seen.add(session.exerciseName)) {
        names.add(session.exerciseName);
      }
    }

    return _WorkoutPlanGroup(
      planId: sessions.first.planId,
      sessions: sessions,
      startedAt: _createdAt(sessions.first).toLocal(),
      sortTime: _createdAt(sessions.last),
      date: sessions.first.date,
      totalCalories: sessions.fold<double>(
        0,
        (sum, session) => sum + session.estimatedCalories,
      ),
      totalDurationMinutes: sessions.fold<int>(
        0,
        (sum, session) => sum + session.durationMinutes,
      ),
      exerciseNames: names,
    );
  }

  final String? planId;
  final List<WorkoutSession> sessions;
  final DateTime startedAt;
  final DateTime sortTime;
  final String date;
  final double totalCalories;
  final int totalDurationMinutes;
  final List<String> exerciseNames;

  static DateTime _createdAt(WorkoutSession session) {
    final created = DateTime.tryParse(session.createdAt ?? '');
    if (created != null) {
      return created;
    }
    return DateUtilsX.parseDay(session.date);
  }
}
