import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/exercise_visuals.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/number_utils.dart';
import '../../core/widgets/exercise_thumbnail.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/workout_session.dart';
import '../../domain/models/workout_set.dart';
import '../../domain/services/workout_calorie_calculator.dart';

class AddWorkoutPage extends StatefulWidget {
  const AddWorkoutPage({super.key, this.initialDate});

  final String? initialDate;

  @override
  State<AddWorkoutPage> createState() => _AddWorkoutPageState();
}

class _AddWorkoutPageState extends State<AddWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  final Map<String, _ExercisePlanDraft> _selectedPlans =
      <String, _ExercisePlanDraft>{};

  late final List<_ExerciseOption> _exerciseOptions;
  late final Map<String, _ExerciseOption> _exerciseOptionsByKey;

  late String _date;
  double _profileWeightKg = 65;
  bool _saving = false;
  bool _updatingExerciseSelection = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateUtilsX.todayKey();
    _exerciseOptions = AppConstants.bodyPartExercises.entries
        .expand(
          (entry) => entry.value.map(
            (exercise) => _ExerciseOption(bodyPart: entry.key, name: exercise),
          ),
        )
        .toList();
    _exerciseOptionsByKey = <String, _ExerciseOption>{
      for (final option in _exerciseOptions)
        _exerciseKey(option.bodyPart, option.name): option,
    };
    _loadProfileWeight();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final draft in _selectedPlans.values) {
      draft.dispose();
    }
    super.dispose();
  }

  List<_ExercisePlanDraft> get _selectedDrafts =>
      _selectedPlans.values.toList();

  Future<void> _loadProfileWeight() async {
    final profile = await context
        .read<AppServices>()
        .profileRepository
        .getProfile();
    if (profile == null || !mounted) {
      return;
    }

    setState(() {
      _profileWeightKg = profile.weightKg;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateUtilsX.parseDay(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null && mounted) {
      setState(() => _date = DateUtilsX.formatDate(selected));
    }
  }

  String _exerciseKey(String bodyPart, String exerciseName) =>
      '$bodyPart::$exerciseName';

  String _createPlanId() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _openExerciseLibraryPicker() async {
    final selectedKeys = _selectedPlans.keys.toSet();
    final pickedKeys = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute<List<String>>(
        builder: (_) => _ExerciseLibraryPickerPage(
          options: _exerciseOptions,
          initiallySelectedKeys: selectedKeys,
        ),
      ),
    );

    if (pickedKeys == null || !mounted) {
      return;
    }

    await _applyExerciseSelection(pickedKeys);
  }

  Future<void> _applyExerciseSelection(List<String> pickedKeysInOrder) async {
    setState(() => _updatingExerciseSelection = true);

    final removedKeys = _selectedPlans.keys
        .where((key) => !pickedKeysInOrder.contains(key))
        .toList();
    for (final key in removedKeys) {
      _selectedPlans.remove(key)?.dispose();
    }

    final repository = context.read<AppServices>().workoutRepository;
    final newDrafts = <String, _ExercisePlanDraft>{};
    for (final key in pickedKeysInOrder) {
      if (_selectedPlans.containsKey(key)) {
        continue;
      }
      final option = _exerciseOptionsByKey[key];
      if (option == null) {
        continue;
      }
      final latestSession = await repository.getLatestSessionByExerciseName(
        option.name,
      );
      if (!mounted) {
        return;
      }
      newDrafts[key] = _ExercisePlanDraft.fromHistory(
        bodyPart: option.bodyPart,
        exerciseName: option.name,
        latestSession: latestSession,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      final reordered = <String, _ExercisePlanDraft>{};
      for (final key in pickedKeysInOrder) {
        final existing = _selectedPlans[key] ?? newDrafts[key];
        if (existing != null) {
          reordered[key] = existing;
        }
      }

      for (final entry in newDrafts.entries) {
        reordered.putIfAbsent(entry.key, () => entry.value);
      }

      _selectedPlans
        ..clear()
        ..addAll(reordered);
      _updatingExerciseSelection = false;
    });
  }

  void _addSet(_ExercisePlanDraft draft) {
    var defaultWeight = '';
    var defaultReps = '';
    if (draft.sets.isNotEmpty) {
      final last = draft.sets.last;
      defaultWeight = last.effectiveWeightText;
      defaultReps = last.effectiveRepsText;
    }

    setState(() {
      draft.sets.add(
        _SetDraft(defaultWeight: defaultWeight, defaultReps: defaultReps),
      );
    });
  }

  void _removeSet(_ExercisePlanDraft draft, int index) {
    final target = draft.sets.removeAt(index);
    target.dispose();
    setState(() {});
  }

  void _removeExercise(_ExercisePlanDraft draft) {
    final key = _exerciseKey(draft.bodyPart, draft.exerciseName);
    final target = _selectedPlans.remove(key);
    target?.dispose();
    setState(() {});
  }

  void _toggleSetCompleted(_SetDraft draft) {
    setState(() {
      draft.isCompleted = !draft.isCompleted;
    });
  }

  int _durationForDraft(_ExercisePlanDraft draft) {
    return NumberUtils.toInt(draft.effectiveDurationText, fallback: 0);
  }

  List<WorkoutSet> _buildSetsForPreview(_ExercisePlanDraft draft) {
    final sets = <WorkoutSet>[];
    for (var i = 0; i < draft.sets.length; i++) {
      final setDraft = draft.sets[i];
      final reps = NumberUtils.toInt(setDraft.effectiveRepsText, fallback: 0);
      final weight = NumberUtils.toDouble(
        setDraft.effectiveWeightText,
        fallback: 0,
      );
      if (reps <= 0) {
        continue;
      }
      sets.add(
        WorkoutSet(
          setNumber: i + 1,
          weightKg: weight < 0 ? 0 : weight,
          reps: reps,
          isCompleted: setDraft.isCompleted,
        ),
      );
    }
    return sets;
  }

  double _estimateCaloriesForDraft(_ExercisePlanDraft draft) {
    final durationMinutes = _durationForDraft(draft);
    if (draft.isCardio) {
      if (durationMinutes <= 0) {
        return 0;
      }
      return WorkoutCalorieCalculator.estimateCardioCalories(
        exerciseName: draft.exerciseName,
        bodyWeightKg: _profileWeightKg,
        durationMinutes: durationMinutes,
      );
    }

    final sets = _buildSetsForPreview(draft);
    return WorkoutCalorieCalculator.estimateStrengthCalories(
      exerciseName: draft.exerciseName,
      bodyWeightKg: _profileWeightKg,
      sets: sets,
      totalSessionDurationMinutes: durationMinutes,
    );
  }

  double get _estimatedTotalCalories {
    return _selectedDrafts.fold<double>(
      0,
      (sum, draft) => sum + _estimateCaloriesForDraft(draft),
    );
  }

  Widget _buildSetValueInput({
    required BuildContext context,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required String hintText,
    required bool showAsDefaultValue,
    void Function(String value)? onValueChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeTextColor = isDark ? Colors.white : Colors.black87;
    final defaultTextColor = isDark
        ? Colors.white.withValues(alpha: 0.42)
        : Colors.black.withValues(alpha: 0.42);

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      selectAllOnFocus: true,
      onChanged: (value) {
        onValueChanged?.call(value);
        setState(() {});
      },
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: showAsDefaultValue ? defaultTextColor : activeTextColor,
      ),
      decoration: InputDecoration(
        hintText: hintText.isEmpty ? '--' : hintText,
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.34)
              : Colors.black.withValues(alpha: 0.34),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
      ),
    );
  }

  Future<void> _save() async {
    final strings = context.stringsRead;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPlans.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.chooseAtLeastOneExercise)));
      return;
    }

    final now = DateTime.now().toIso8601String();
    final planId = _createPlanId();
    final notes = _notesController.text.trim();
    final services = context.read<AppServices>();
    final refreshNotifier = context.read<RefreshNotifier>();
    final messenger = ScaffoldMessenger.of(context);

    final drafts = _selectedDrafts;
    setState(() => _saving = true);

    try {
      for (final draft in drafts) {
        final durationMinutes = _durationForDraft(draft);
        if (durationMinutes <= 0) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                strings.invalidDurationForExercise(
                  strings.exerciseDisplayName(draft.exerciseName),
                ),
              ),
            ),
          );
          setState(() => _saving = false);
          return;
        }

        final sets = <WorkoutSet>[];
        if (!draft.isCardio) {
          if (draft.sets.isEmpty) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  strings.noSetsForExercise(
                    strings.exerciseDisplayName(draft.exerciseName),
                  ),
                ),
              ),
            );
            setState(() => _saving = false);
            return;
          }

          for (var i = 0; i < draft.sets.length; i++) {
            final setDraft = draft.sets[i];
            final reps = NumberUtils.toInt(
              setDraft.effectiveRepsText,
              fallback: -1,
            );
            final weight = NumberUtils.toDouble(
              setDraft.effectiveWeightText,
              fallback: double.nan,
            );
            if (reps <= 0 || weight.isNaN || weight < 0) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    strings.invalidSetValue(
                      strings.exerciseDisplayName(draft.exerciseName),
                    ),
                  ),
                ),
              );
              setState(() => _saving = false);
              return;
            }

            sets.add(
              WorkoutSet(
                setNumber: i + 1,
                weightKg: weight,
                reps: reps,
                isCompleted: setDraft.isCompleted,
                completedAt: setDraft.isCompleted ? now : null,
              ),
            );
          }
        }

        final session = WorkoutSession(
          planId: planId,
          date: _date,
          bodyPart: draft.bodyPart,
          exerciseName: draft.exerciseName,
          exerciseType: draft.isCardio ? 'cardio' : 'strength',
          durationMinutes: durationMinutes,
          intensity: 'medium',
          estimatedCalories: draft.isCardio
              ? WorkoutCalorieCalculator.estimateCardioCalories(
                  exerciseName: draft.exerciseName,
                  bodyWeightKg: _profileWeightKg,
                  durationMinutes: durationMinutes,
                )
              : WorkoutCalorieCalculator.estimateStrengthCalories(
                  exerciseName: draft.exerciseName,
                  bodyWeightKg: _profileWeightKg,
                  sets: sets,
                  totalSessionDurationMinutes: durationMinutes,
                ),
          notes: notes,
          sets: sets,
        );

        await services.workoutRepository.insertWorkoutSession(session);
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.failedToLoadWorkout(error))),
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }

    if (!mounted) {
      return;
    }

    refreshNotifier.markDataChanged();
    messenger.showSnackBar(
      SnackBar(content: Text(strings.workoutPlanSavedCount(drafts.length))),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.addWorkout)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.paddingOf(context).bottom +
                kBottomNavigationBarHeight +
                18,
          ),
          children: <Widget>[
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        strings.selectedExercises,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.7),
                        ),
                        child: Text(
                          strings.selectedExercisesCount(_selectedPlans.length),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.exercisePickerCollapsedHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (_saving || _updatingExerciseSelection)
                          ? null
                          : _openExerciseLibraryPicker,
                      icon: _updatingExerciseSelection
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fitness_center),
                      label: Text(strings.addExercises),
                    ),
                  ),
                ],
              ),
            ),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.exercisePlanDetails,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedPlans.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(strings.noExerciseSelectedYet),
                        const SizedBox(height: 4),
                        Text(
                          strings.tapAddExerciseToBuildPlan,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    )
                  else ...<Widget>[
                    Text(
                      strings.completeBeforeSaveHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    ..._selectedDrafts.map((draft) {
                      final color = ExerciseVisuals.colorForBodyPart(
                        draft.bodyPart,
                        context,
                      );
                      final durationHint = draft.defaultDurationHint.isEmpty
                          ? '--'
                          : draft.defaultDurationHint;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.45),
                            border: Border.all(
                              color: color.withValues(alpha: 0.28),
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  ExerciseThumbnail(
                                    bodyPart: draft.bodyPart,
                                    exerciseName: draft.exerciseName,
                                    color: color,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          strings.exerciseDisplayName(
                                            draft.exerciseName,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          strings.bodyPartLabel(draft.bodyPart),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeExercise(draft),
                                    icon: const Icon(Icons.close_rounded),
                                    tooltip: strings.removeExercise,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: draft.durationController,
                                keyboardType: TextInputType.number,
                                selectAllOnFocus: true,
                                enabled: !_saving,
                                decoration: InputDecoration(
                                  labelText: strings.durationMinutesLabel,
                                  hintText: durationHint,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 6),
                              if (draft.isCardio)
                                Text(
                                  strings.cardioDurationHint,
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              else
                                Text(
                                  strings.strengthDurationNotice,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (!draft.isCardio) ...<Widget>[
                                const SizedBox(height: 10),
                                if (draft.isBodyweight)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      strings.bodyweightAddedLoadHint,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: <Widget>[
                                      const SizedBox(width: 56),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          draft.isBodyweight
                                              ? strings.addedWeightKgShortLabel
                                              : strings.weightKgShortLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          strings.repsLabel,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 96),
                                    ],
                                  ),
                                ),
                                ...draft.sets.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final setDraft = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: <Widget>[
                                        SizedBox(
                                          width: 56,
                                          child: Text(
                                            strings.setLabel(index + 1),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildSetValueInput(
                                            context: context,
                                            controller:
                                                setDraft.weightController,
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            hintText:
                                                setDraft.defaultWeightHint,
                                            showAsDefaultValue:
                                                setDraft.showWeightAsDefault,
                                            onValueChanged:
                                                setDraft.markWeightInput,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildSetValueInput(
                                            context: context,
                                            controller: setDraft.repsController,
                                            keyboardType: TextInputType.number,
                                            hintText: setDraft.defaultRepsHint,
                                            showAsDefaultValue:
                                                setDraft.showRepsAsDefault,
                                            onValueChanged:
                                                setDraft.markRepsInput,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _toggleSetCompleted(setDraft),
                                          icon: Icon(
                                            setDraft.isCompleted
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                          ),
                                          color: setDraft.isCompleted
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : null,
                                          tooltip: setDraft.isCompleted
                                              ? strings.completed
                                              : strings.completeSet,
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _removeSet(draft, index),
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          tooltip: strings.removeSet,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                TextButton.icon(
                                  onPressed: () => _addSet(draft),
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: Text(strings.addSet),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.workoutDetails,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(strings.date),
                    subtitle: Text(DateUtilsX.formatReadable(_date)),
                    trailing: TextButton(
                      onPressed: _pickDate,
                      child: Text(strings.change),
                    ),
                  ),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(labelText: strings.notesLabel),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.usingProfileWeight(_profileWeightKg),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${strings.estimatedTotalCaloriesLabel}: ${_estimatedTotalCalories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_saving ? strings.saving : strings.saveWorkoutPlan),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetDraft {
  _SetDraft({required String defaultWeight, required String defaultReps})
    : _defaultWeight = defaultWeight.trim(),
      _defaultReps = defaultReps.trim(),
      weightController = TextEditingController(text: defaultWeight.trim()),
      repsController = TextEditingController(text: defaultReps.trim()),
      _showWeightAsDefault = defaultWeight.trim().isNotEmpty,
      _showRepsAsDefault = defaultReps.trim().isNotEmpty;

  final String _defaultWeight;
  final String _defaultReps;

  final TextEditingController weightController;
  final TextEditingController repsController;
  bool isCompleted = false;
  bool _showWeightAsDefault;
  bool _showRepsAsDefault;

  String get defaultWeightHint => _defaultWeight.isEmpty ? '--' : '';
  String get defaultRepsHint => _defaultReps.isEmpty ? '--' : '';
  bool get showWeightAsDefault => _showWeightAsDefault;
  bool get showRepsAsDefault => _showRepsAsDefault;

  void markWeightInput(String value) {
    final typed = value.trim();
    _showWeightAsDefault = _defaultWeight.isNotEmpty && typed == _defaultWeight;
  }

  void markRepsInput(String value) {
    final typed = value.trim();
    _showRepsAsDefault = _defaultReps.isNotEmpty && typed == _defaultReps;
  }

  String get effectiveWeightText {
    return weightController.text.trim();
  }

  String get effectiveRepsText {
    return repsController.text.trim();
  }

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}

class _ExercisePlanDraft {
  _ExercisePlanDraft({
    required this.bodyPart,
    required this.exerciseName,
    required this.sets,
    required String defaultDuration,
  }) : _defaultDuration = defaultDuration.trim(),
       durationController = TextEditingController();

  factory _ExercisePlanDraft.fromHistory({
    required String bodyPart,
    required String exerciseName,
    WorkoutSession? latestSession,
  }) {
    final isCardio = bodyPart == 'Cardio';
    final historySets = latestSession?.sets ?? const <WorkoutSet>[];
    final defaultDuration =
        latestSession == null || latestSession.durationMinutes <= 0
        ? ''
        : latestSession.durationMinutes.toString();

    return _ExercisePlanDraft(
      bodyPart: bodyPart,
      exerciseName: exerciseName,
      sets: isCardio
          ? <_SetDraft>[]
          : historySets
                .map(
                  (set) => _SetDraft(
                    defaultWeight: _formatWeight(set.weightKg),
                    defaultReps: set.reps <= 0 ? '' : set.reps.toString(),
                  ),
                )
                .toList(),
      defaultDuration: defaultDuration,
    );
  }

  final String bodyPart;
  final String exerciseName;
  final List<_SetDraft> sets;
  final String _defaultDuration;
  final TextEditingController durationController;

  bool get isCardio => bodyPart == 'Cardio';
  bool get isBodyweight => AppConstants.isBodyweightExercise(exerciseName);

  String get defaultDurationHint => _defaultDuration;
  String get effectiveDurationText {
    final typed = durationController.text.trim();
    return typed.isNotEmpty ? typed : _defaultDuration;
  }

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  void dispose() {
    durationController.dispose();
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _ExerciseOption {
  const _ExerciseOption({required this.bodyPart, required this.name});

  final String bodyPart;
  final String name;

  String key() => '$bodyPart::$name';
}

class _ExerciseLibraryPickerPage extends StatefulWidget {
  const _ExerciseLibraryPickerPage({
    required this.options,
    required this.initiallySelectedKeys,
  });

  final List<_ExerciseOption> options;
  final Set<String> initiallySelectedKeys;

  @override
  State<_ExerciseLibraryPickerPage> createState() =>
      _ExerciseLibraryPickerPageState();
}

class _ExerciseLibraryPickerPageState
    extends State<_ExerciseLibraryPickerPage> {
  final _searchController = TextEditingController();
  String? _selectedBodyPartFilter;
  late final Set<String> _selectedKeys;

  @override
  void initState() {
    super.initState();
    _selectedKeys = Set<String>.from(widget.initiallySelectedKeys);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_ExerciseOption> _filteredOptions(AppStrings strings) {
    final queryLower = _searchController.text.trim().toLowerCase();
    return widget.options.where((option) {
      final bodyPartMatch =
          _selectedBodyPartFilter == null ||
          option.bodyPart == _selectedBodyPartFilter;
      if (!bodyPartMatch) {
        return false;
      }
      if (queryLower.isEmpty) {
        return true;
      }
      final candidates = <String>{
        option.name.toLowerCase(),
        strings.exerciseDisplayName(option.name).toLowerCase(),
        option.bodyPart.toLowerCase(),
        strings.bodyPartLabel(option.bodyPart).toLowerCase(),
      };
      return candidates.any((value) => value.contains(queryLower));
    }).toList();
  }

  void _toggleOption(_ExerciseOption option) {
    final key = option.key();
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
    });
  }

  void _submitSelection() {
    final orderedKeys = widget.options
        .map((option) => option.key())
        .where(_selectedKeys.contains)
        .toList();
    Navigator.of(context).pop(orderedKeys);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final filtered = _filteredOptions(strings);

    return Scaffold(
      appBar: AppBar(title: Text(strings.exercisesLibrary)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: strings.searchExercise,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: _selectedBodyPartFilter == null,
                          label: Text(strings.allBodyParts),
                          onSelected: (_) {
                            setState(() => _selectedBodyPartFilter = null);
                          },
                        ),
                      ),
                      ...AppConstants.bodyParts.map((bodyPart) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: _selectedBodyPartFilter == bodyPart,
                            label: Text(strings.bodyPartLabel(bodyPart)),
                            onSelected: (_) {
                              setState(
                                () => _selectedBodyPartFilter = bodyPart,
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = filtered[index];
                final key = option.key();
                final selected = _selectedKeys.contains(key);
                final color = ExerciseVisuals.colorForBodyPart(
                  option.bodyPart,
                  context,
                );
                return InkWell(
                  onTap: () => _toggleOption(option),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: selected
                          ? color.withValues(alpha: 0.16)
                          : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.36),
                    ),
                    child: Row(
                      children: <Widget>[
                        ExerciseThumbnail(
                          bodyPart: option.bodyPart,
                          exerciseName: option.name,
                          color: color,
                          size: 54,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                strings.exerciseDisplayName(option.name),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(strings.bodyPartLabel(option.bodyPart)),
                            ],
                          ),
                        ),
                        Icon(
                          selected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: selected ? color : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: FilledButton(
            onPressed: _submitSelection,
            child: Text(strings.addExercisesWithCount(_selectedKeys.length)),
          ),
        ),
      ),
    );
  }
}
