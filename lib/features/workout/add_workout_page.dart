import 'dart:math' as math;

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
  final _searchController = TextEditingController();
  final _durationController = TextEditingController(text: '45');
  final _notesController = TextEditingController();

  final Map<String, _ExercisePlanDraft> _selectedPlans =
      <String, _ExercisePlanDraft>{};

  late final List<_ExerciseOption> _exerciseOptions;

  late String _date;
  String? _selectedBodyPartFilter;
  double _profileWeightKg = 65;
  bool _saving = false;

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
    _loadProfileWeight();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    for (final draft in _selectedPlans.values) {
      draft.dispose();
    }
    super.dispose();
  }

  int get _durationMinutes =>
      NumberUtils.toInt(_durationController.text, fallback: 0);

  List<_ExercisePlanDraft> get _selectedDrafts =>
      _selectedPlans.values.toList();

  Widget _buildSetValueInput({
    required BuildContext context,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: '--',
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

  int get _perExerciseDuration {
    final selectedCount = math.max(1, _selectedPlans.length);
    final duration = _durationMinutes;
    if (duration <= 0) {
      return 0;
    }
    return math.max(1, (duration / selectedCount).round());
  }

  double get _estimatedTotalCalories {
    final durationPerExercise = _perExerciseDuration;
    return _selectedDrafts.fold<double>(
      0,
      (sum, draft) =>
          sum + _estimateCaloriesForDraft(draft, durationPerExercise),
    );
  }

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

  Future<void> _toggleExercise(_ExerciseOption option) async {
    final key = _exerciseKey(option.bodyPart, option.name);
    final existing = _selectedPlans[key];
    if (existing != null) {
      existing.dispose();
      setState(() {
        _selectedPlans.remove(key);
      });
      return;
    }

    final latestSession = await context
        .read<AppServices>()
        .workoutRepository
        .getLatestSessionByExerciseName(option.name);

    if (!mounted || _selectedPlans.containsKey(key)) {
      return;
    }

    final draft = _ExercisePlanDraft.fromHistory(
      bodyPart: option.bodyPart,
      exerciseName: option.name,
      latestSession: latestSession,
    );

    setState(() {
      _selectedPlans[key] = draft;
    });
  }

  void _addSet(_ExercisePlanDraft draft) {
    var weight = '';
    var reps = '';
    if (draft.sets.isNotEmpty) {
      final last = draft.sets.last;
      weight = last.weightController.text;
      reps = last.repsController.text;
    }

    setState(() {
      draft.sets.add(_SetDraft(weight: weight, reps: reps));
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

  String _exerciseKey(String bodyPart, String exerciseName) =>
      '$bodyPart::$exerciseName';

  String _createPlanId() => DateTime.now().microsecondsSinceEpoch.toString();

  bool _isExerciseSelected(_ExerciseOption option) {
    return _selectedPlans.containsKey(
      _exerciseKey(option.bodyPart, option.name),
    );
  }

  double _averageAdditionalLoadKg(_ExercisePlanDraft draft) {
    if (!draft.isBodyweight || draft.sets.isEmpty) {
      return 0;
    }

    final normalizedLoads = draft.sets
        .map(
          (setDraft) =>
              NumberUtils.toDouble(setDraft.weightController.text, fallback: 0),
        )
        .map((value) => value < 0 ? 0 : value)
        .toList();

    final total = normalizedLoads.fold<double>(0, (sum, value) => sum + value);
    return total / normalizedLoads.length;
  }

  double _estimateCaloriesForDraft(
    _ExercisePlanDraft draft,
    int durationPerExercise,
  ) {
    if (durationPerExercise <= 0) {
      return 0;
    }

    if (draft.isCardio) {
      return WorkoutCalorieCalculator.estimateCardioCalories(
        exerciseName: draft.exerciseName,
        bodyWeightKg: _profileWeightKg,
        durationMinutes: durationPerExercise,
      );
    }

    return WorkoutCalorieCalculator.estimateStrengthCalories(
      bodyWeightKg: _profileWeightKg,
      durationMinutes: durationPerExercise,
      intensity: 'medium',
      additionalLoadKg: _averageAdditionalLoadKg(draft),
      isBodyweightExercise: draft.isBodyweight,
    );
  }

  List<_ExerciseOption> _buildFilteredOptions(
    String queryLower,
    AppStrings strings,
  ) {
    return _exerciseOptions.where((option) {
      final filterMatch =
          _selectedBodyPartFilter == null ||
          option.bodyPart == _selectedBodyPartFilter;
      if (!filterMatch) {
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
      return candidates.any((text) => text.contains(queryLower));
    }).toList();
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

    final totalDuration = _durationMinutes;
    if (totalDuration <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.invalidDuration)));
      return;
    }

    final now = DateTime.now().toIso8601String();
    final planId = _createPlanId();
    final durationPerExercise = _perExerciseDuration;
    final notes = _notesController.text.trim();
    final services = context.read<AppServices>();
    final refreshNotifier = context.read<RefreshNotifier>();
    final messenger = ScaffoldMessenger.of(context);

    final drafts = _selectedDrafts;
    setState(() => _saving = true);

    try {
      for (final draft in drafts) {
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
              setDraft.repsController.text,
              fallback: -1,
            );
            final weight = NumberUtils.toDouble(
              setDraft.weightController.text,
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
          durationMinutes: durationPerExercise,
          intensity: 'medium',
          estimatedCalories: _estimateCaloriesForDraft(
            draft,
            durationPerExercise,
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
    final queryLower = _searchController.text.trim().toLowerCase();
    final filtered = _buildFilteredOptions(queryLower, strings);
    final durationPerExercise = _perExerciseDuration;

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
                        strings.exercisesLibrary,
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
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => Divider(
                        color: Colors.white.withValues(alpha: 0.2),
                        height: 10,
                      ),
                      itemBuilder: (context, index) {
                        final option = filtered[index];
                        final selected = _isExerciseSelected(option);
                        final color = ExerciseVisuals.colorForBodyPart(
                          option.bodyPart,
                          context,
                        );
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _toggleExercise(option),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: selected
                                  ? color.withValues(alpha: 0.16)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: <Widget>[
                                ExerciseThumbnail(
                                  bodyPart: option.bodyPart,
                                  exerciseName: option.name,
                                  color: color,
                                  size: 58,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        strings.exerciseDisplayName(
                                          option.name,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        strings.bodyPartLabel(option.bodyPart),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.arrow_outward_rounded,
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
            ),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    strings.selectedExercises,
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
                          strings.tapExerciseToBuildPlan,
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
                              if (draft.isCardio)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(strings.cardioNoSetPlan),
                                )
                              else ...<Widget>[
                                const SizedBox(height: 8),
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
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _buildSetValueInput(
                                            context: context,
                                            controller: setDraft.repsController,
                                            keyboardType: TextInputType.number,
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
                    controller: _durationController,
                    decoration: InputDecoration(
                      labelText: strings.durationMinutesLabel,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (NumberUtils.toInt(value, fallback: 0) <= 0) {
                        return strings.invalidDuration;
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
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
                  Text(
                    strings.durationSplitHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${strings.estimatedTotalCaloriesLabel}: ${_estimatedTotalCalories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (_selectedPlans.isNotEmpty)
                    Text(
                      '${strings.durationMinutesLabel}: $durationPerExercise',
                      style: Theme.of(context).textTheme.bodySmall,
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
  _SetDraft({required String weight, required String reps})
    : weightController = TextEditingController(text: weight),
      repsController = TextEditingController(text: reps);

  final TextEditingController weightController;
  final TextEditingController repsController;
  bool isCompleted = false;

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
  });

  factory _ExercisePlanDraft.fromHistory({
    required String bodyPart,
    required String exerciseName,
    WorkoutSession? latestSession,
  }) {
    final isCardio = bodyPart == 'Cardio';
    final historySets = latestSession?.sets ?? const <WorkoutSet>[];
    return _ExercisePlanDraft(
      bodyPart: bodyPart,
      exerciseName: exerciseName,
      sets: isCardio
          ? <_SetDraft>[]
          : historySets
                .map(
                  (set) => _SetDraft(
                    weight: _formatWeight(set.weightKg),
                    reps: set.reps <= 0 ? '' : set.reps.toString(),
                  ),
                )
                .toList(),
    );
  }

  final String bodyPart;
  final String exerciseName;
  final List<_SetDraft> sets;

  bool get isCardio => bodyPart == 'Cardio';
  bool get isBodyweight => AppConstants.isBodyweightExercise(exerciseName);

  static String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
  }
}

class _ExerciseOption {
  const _ExerciseOption({required this.bodyPart, required this.name});

  final String bodyPart;
  final String name;
}
