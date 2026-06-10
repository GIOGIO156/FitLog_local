import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/fitlog_icon_assets.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/fitlog_ui.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/workout_record_draft.dart';
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

  Future<_WorkoutLogData> _loadPageData(
    BuildContext context,
    String day,
  ) async {
    final services = context.read<AppServices>();
    final sessionsFuture = services.workoutRepository.getWorkoutSessionsByDate(
      day,
    );
    final draftFuture = services.workoutDraftRepository.getActiveDraft();
    final sessions = await sessionsFuture;
    final draft = await draftFuture;
    return _WorkoutLogData(sessions: sessions, activeDraft: draft);
  }

  String _draftSummary(WorkoutRecordDraft draft, AppStrings strings) {
    final recordName = draft.recordName.trim();
    if (recordName.isNotEmpty) {
      return recordName;
    }
    final firstExercise = draft.firstExerciseName;
    if (firstExercise != null) {
      return strings.workoutDraftExerciseSummary(
        strings.exerciseDisplayName(firstExercise),
        draft.exerciseCount,
      );
    }
    return strings.workoutDraftUntitled;
  }

  Future<void> _resumeDraft(
    BuildContext context,
    WorkoutRecordDraft draft,
  ) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddWorkoutPage(initialDate: draft.date),
      ),
    );
  }

  Future<void> _discardDraft(
    BuildContext context,
    WorkoutRecordDraft draft,
  ) async {
    final strings = context.stringsRead;
    final refreshNotifier = context.read<RefreshNotifier>();
    final services = context.read<AppServices>();
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                draft.isEditDraft
                    ? strings.discardWorkoutChangesTitle
                    : strings.discardWorkoutDraftTitle,
              ),
              content: Text(
                draft.isEditDraft
                    ? strings.discardWorkoutChangesMessage
                    : strings.discardWorkoutDraftMessage,
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.cancel),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    draft.isEditDraft
                        ? strings.discardWorkoutChangesAction
                        : strings.discardWorkoutDraftAction,
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) {
      return;
    }
    await services.workoutDraftRepository.deleteActiveDraft();
    if (!context.mounted) {
      return;
    }
    refreshNotifier.markDataChanged();
  }

  Future<void> _openAddWorkout(BuildContext context, String initialDate) async {
    final activeDraft = await context
        .read<AppServices>()
        .workoutDraftRepository
        .getActiveDraft();
    if (!context.mounted) {
      return;
    }
    if (activeDraft != null) {
      final strings = context.stringsRead;
      final decision =
          await showDialog<_DraftConflictAction>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(strings.workoutDraftExistsTitle),
                content: Text(strings.workoutDraftExistsMessage),
                actions: <Widget>[
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(_DraftConflictAction.cancel),
                    child: Text(strings.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_DraftConflictAction.resumeExisting),
                    child: Text(strings.continueEditing),
                  ),
                  FilledButton.tonal(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_DraftConflictAction.discardAndOpen),
                    child: Text(strings.discardAndStartNewWorkout),
                  ),
                ],
              );
            },
          ) ??
          _DraftConflictAction.cancel;
      if (!context.mounted) {
        return;
      }
      if (decision == _DraftConflictAction.resumeExisting) {
        await _resumeDraft(context, activeDraft);
        return;
      }
      if (decision != _DraftConflictAction.discardAndOpen) {
        return;
      }
      await context
          .read<AppServices>()
          .workoutDraftRepository
          .deleteActiveDraft();
      if (!context.mounted) {
        return;
      }
      context.read<RefreshNotifier>().markDataChanged();
    }

    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddWorkoutPage(initialDate: initialDate),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return SafeArea(
      child: Consumer2<RefreshNotifier, SelectedDateNotifier>(
        builder: (context, refresh, selectedDateNotifier, _) {
          refresh.version;
          final selectedDate = selectedDateNotifier.selectedDate;
          return Column(
            children: <Widget>[
              FitLogPageHeader(
                title: strings.workoutLogTitle,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              ),
              GlassPanel(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(16),
                child: FitLogDateStrip(
                  selectedDate: selectedDate,
                  onSelect: selectedDateNotifier.setDate,
                  onOpenPicker: () => _pickDate(context, selectedDateNotifier),
                ),
              ),
              Expanded(
                child: FutureBuilder<_WorkoutLogData>(
                  future: _loadPageData(context, selectedDate),
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

                    final pageData =
                        snapshot.data ??
                        const _WorkoutLogData(
                          sessions: <WorkoutSession>[],
                          activeDraft: null,
                        );
                    final sessions = pageData.sessions;
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
                      padding: const EdgeInsets.only(bottom: 96),
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        return GlassPanel(
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          padding: const EdgeInsets.all(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _openPlan(context, plan),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF6E3),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        _formatStartTime(plan.startedAt),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4E9E3B),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    FitLogActionIconButton(
                                      icon: Icons.delete_outline_rounded,
                                      tooltip: strings.delete,
                                      onPressed: () =>
                                          _deletePlan(context, plan),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  plan.displayName(strings),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateUtilsX.formatReadable(plan.date),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF75856F),
                                      ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _WorkoutMetric(
                                        label: strings.totalDurationLabel,
                                        value:
                                            '${plan.totalDurationMinutes} min',
                                      ),
                                    ),
                                    Expanded(
                                      child: _WorkoutMetric(
                                        label: strings.totalVolumeLabel,
                                        value:
                                            '${plan.totalVolumeKg.toStringAsFixed(0)} kg',
                                      ),
                                    ),
                                    Expanded(
                                      child: _WorkoutMetric(
                                        label: strings.totalSetsLabel,
                                        value: '${plan.totalSets}',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: <Widget>[
                                    const FitLogSvgIconCircle(
                                      assetName: FitLogIconAssets.flame,
                                      backgroundColor: Color(0xFFE8F1FC),
                                      tintColor: Color(0xFF6EA4DF),
                                      size: 38,
                                      iconSize: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${plan.totalCalories.toStringAsFixed(0)} kcal',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  plan.exerciseNames
                                      .map(strings.exerciseDisplayName)
                                      .join(' · '),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF61715D),
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
              FutureBuilder<WorkoutRecordDraft?>(
                future: context
                    .read<AppServices>()
                    .workoutDraftRepository
                    .getActiveDraft(),
                builder: (context, snapshot) {
                  final draft = snapshot.data;
                  if (draft == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _resumeDraft(context, draft),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF74BF56),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  strings.workoutDraftBanner(
                                    _draftSummary(draft, strings),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _discardDraft(context, draft),
                                icon: const Icon(Icons.delete_outline_rounded),
                                tooltip: strings.delete,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  onPressed: () => _openAddWorkout(context, selectedDate),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(strings.addWorkout),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFF74BF56),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkoutMetric extends StatelessWidget {
  const _WorkoutMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF7A8973)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _WorkoutLogData {
  const _WorkoutLogData({required this.sessions, required this.activeDraft});

  final List<WorkoutSession> sessions;
  final WorkoutRecordDraft? activeDraft;
}

enum _DraftConflictAction { cancel, resumeExisting, discardAndOpen }

class _WorkoutPlanGroup {
  _WorkoutPlanGroup({
    required this.planId,
    required this.sessions,
    required this.startedAt,
    required this.sortTime,
    required this.date,
    required this.totalCalories,
    required this.totalDurationMinutes,
    required this.totalVolumeKg,
    required this.totalSets,
    required this.exerciseNames,
    required this.recordName,
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
      totalVolumeKg: sessions.fold<double>(
        0,
        (sum, session) =>
            sum +
            session.sets.fold<double>(
              0,
              (setSum, set) => setSum + (set.weightKg * set.reps),
            ),
      ),
      totalSets: sessions.fold<int>(
        0,
        (sum, session) => sum + session.sets.length,
      ),
      exerciseNames: names,
      recordName: sessions.first.recordName?.trim() ?? '',
    );
  }

  final String? planId;
  final List<WorkoutSession> sessions;
  final DateTime startedAt;
  final DateTime sortTime;
  final String date;
  final double totalCalories;
  final int totalDurationMinutes;
  final double totalVolumeKg;
  final int totalSets;
  final List<String> exerciseNames;
  final String recordName;

  String displayName(AppStrings strings) {
    if (recordName.isNotEmpty) {
      return recordName;
    }
    if (exerciseNames.length == 1) {
      return strings.exerciseDisplayName(exerciseNames.first);
    }
    if (exerciseNames.isEmpty) {
      return strings.workoutPlan;
    }
    return '${strings.exerciseDisplayName(exerciseNames.first)} +${exerciseNames.length - 1}';
  }

  static DateTime _createdAt(WorkoutSession session) {
    final created = DateTime.tryParse(session.createdAt ?? '');
    if (created != null) {
      return created;
    }
    return DateUtilsX.parseDay(session.date);
  }
}
