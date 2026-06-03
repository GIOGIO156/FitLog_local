import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/language_controller.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/number_utils.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/calorie_calibration_state.dart';
import '../../domain/models/training_frequency_self_check_result.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/services/macro_target_calculator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _goalKcalController = TextEditingController();
  final _proteinRatioController = TextEditingController();
  final _carbsRatioController = TextEditingController();
  final _fatRatioController = TextEditingController();

  String _sexForFormula = AppConstants.sexOptions.last;
  String _activityLevel = AppConstants.activityLevels[2];
  String _dailyGoalType = 'maintenance';
  String _dietGoalPhase = AppConstants.dietGoalPhaseCutting;
  String _dietCalculationMode = AppConstants.dietCalculationModeEnergyRatio;
  int _trainingFrequencyPerWeek = AppConstants.defaultTrainingFrequencyPerWeek;
  int _macroSelfCheckPeriodDays = AppConstants.defaultMacroSelfCheckPeriodDays;
  bool _macroSelfCheckEnabled = true;
  String? _lastMacroSelfCheckAt;

  UserProfile? _loadedProfile;
  bool _loading = true;
  bool _saving = false;
  bool _exportingXlsx = false;
  bool _exportingCsv = false;
  CalorieCalibrationState? _calibrationState;
  double _todayExerciseCalories = 0;
  double _todayCaloriesIn = 0;
  TrainingFrequencySelfCheckResult? _trainingSelfCheckResult;
  bool _handlingSelfCheckAction = false;
  final MacroTargetCalculator _macroTargetCalculator =
      const MacroTargetCalculator();

  @override
  void initState() {
    super.initState();
    _ageController.addListener(_onAgeChanged);
    _load();
  }

  @override
  void dispose() {
    _ageController.removeListener(_onAgeChanged);
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalKcalController.dispose();
    _proteinRatioController.dispose();
    _carbsRatioController.dispose();
    _fatRatioController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final services = context.read<AppServices>();
    final profile =
        await services.profileRepository.getProfile() ?? UserProfile.defaults;
    final calibrationState = await services.profileRepository
        .getCalorieCalibrationState();
    final exerciseCalories = await services.workoutRepository
        .getExerciseCaloriesByDate(DateUtilsX.todayKey());
    final caloriesIn = await services.foodRepository.getCaloriesInByDate(
      DateUtilsX.todayKey(),
    );
    final trainingSelfCheckResult = await services
        .trainingFrequencySelfCheckService
        .evaluate(
          profile: profile,
          referenceDay: DateUtilsX.todayKey(),
          respectReminderCooldown: true,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _loadedProfile = profile;
      _ageController.text = profile.age.toString();
      _heightController.text = profile.heightCm.toStringAsFixed(1);
      _weightController.text = profile.weightKg.toStringAsFixed(1);
      _goalKcalController.text = profile.dailyEnergyGoalKcal.toStringAsFixed(0);
      _proteinRatioController.text = profile.proteinRatioPercent
          .toStringAsFixed(0);
      _carbsRatioController.text = profile.carbsRatioPercent.toStringAsFixed(0);
      _fatRatioController.text = profile.fatRatioPercent.toStringAsFixed(0);
      _sexForFormula = profile.sexForFormula;
      _activityLevel = profile.activityLevel;
      _dailyGoalType = profile.dailyEnergyGoalType;
      _dietGoalPhase = profile.dietGoalPhase;
      _dietCalculationMode = profile.dietCalculationMode;
      _trainingFrequencyPerWeek = profile.trainingFrequencyPerWeek;
      _macroSelfCheckPeriodDays = profile.macroSelfCheckPeriodDays;
      _macroSelfCheckEnabled = profile.macroSelfCheckEnabled;
      _lastMacroSelfCheckAt = profile.lastMacroSelfCheckAt;
      _calibrationState = calibrationState;
      _todayExerciseCalories = exerciseCalories;
      _todayCaloriesIn = caloriesIn;
      _trainingSelfCheckResult = trainingSelfCheckResult;
      _normalizeGoalByAge();
      _loading = false;
    });
  }

  int get _age => NumberUtils.toInt(_ageController.text, fallback: 0);

  double get _heightCm =>
      NumberUtils.toDouble(_heightController.text, fallback: 0);

  double get _weightKg =>
      NumberUtils.toDouble(_weightController.text, fallback: 0);

  double get _goalKcal =>
      NumberUtils.toDouble(_goalKcalController.text, fallback: 0);

  double get _proteinRatioPercent =>
      NumberUtils.toDouble(_proteinRatioController.text, fallback: 0);

  double get _carbsRatioPercent =>
      NumberUtils.toDouble(_carbsRatioController.text, fallback: 0);

  double get _fatRatioPercent =>
      NumberUtils.toDouble(_fatRatioController.text, fallback: 0);

  double get _macroRatioTotal =>
      _proteinRatioPercent + _carbsRatioPercent + _fatRatioPercent;

  bool get _isGramPerKgMode =>
      _dietCalculationMode == AppConstants.dietCalculationModeGramPerKg;

  bool get _isMinor => _age > 0 && _age < 18;

  bool get _isBulkingPhase =>
      _dietGoalPhase == AppConstants.dietGoalPhaseBulking;

  void _onAgeChanged() {
    setState(_normalizeGoalByAge);
  }

  void _normalizeGoalByAge() {
    _dailyGoalType = _dailyGoalTypeForPhase();
    if (_isMinor && _dailyGoalType == 'deficit') {
      _dailyGoalType = 'maintenance';
    }
  }

  String _dailyGoalTypeForPhase() {
    return _isBulkingPhase ? 'surplus' : 'deficit';
  }

  void _setDietGoalPhase(String phase) {
    setState(() {
      _dietGoalPhase = AppConstants.dietGoalPhases.contains(phase)
          ? phase
          : AppConstants.dietGoalPhaseCutting;
      _normalizeGoalByAge();
      final isUntouchedCuttingDefault =
          (_proteinRatioPercent - AppConstants.defaultProteinRatioPercent)
                  .abs() <
              0.01 &&
          (_carbsRatioPercent - AppConstants.defaultCarbsRatioPercent).abs() <
              0.01 &&
          (_fatRatioPercent - AppConstants.defaultFatRatioPercent).abs() < 0.01;
      if (_isBulkingPhase && isUntouchedCuttingDefault) {
        _proteinRatioController.text = AppConstants.bulkingProteinRatioPercent
            .toStringAsFixed(0);
        _carbsRatioController.text = AppConstants.bulkingCarbsRatioPercent
            .toStringAsFixed(0);
        _fatRatioController.text = AppConstants.bulkingFatRatioPercent
            .toStringAsFixed(0);
      }
    });
  }

  UserProfile _buildDraftProfile() {
    return UserProfile(
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      sexForFormula: _sexForFormula,
      activityLevel: _activityLevel,
      dailyEnergyGoalType: _dailyGoalType,
      dailyEnergyGoalKcal: _goalKcal,
      proteinRatioPercent: _proteinRatioPercent,
      carbsRatioPercent: _carbsRatioPercent,
      fatRatioPercent: _fatRatioPercent,
      dietGoalPhase: _dietGoalPhase,
      dietCalculationMode: _dietCalculationMode,
      trainingFrequencyPerWeek: _trainingFrequencyPerWeek,
      macroSelfCheckPeriodDays: _macroSelfCheckPeriodDays,
      macroSelfCheckEnabled: _macroSelfCheckEnabled,
      lastMacroSelfCheckAt: _lastMacroSelfCheckAt,
    );
  }

  double _calculateBmr() {
    final profile = _buildDraftProfile();
    return context.read<AppServices>().dailySummaryService.calculateBmr(
      profile,
    );
  }

  double _calculateNoExerciseBaseline(double bmr) {
    return bmr * _currentLifestyleFactor();
  }

  double _currentLifestyleFactor() {
    final calibrated = _calibrationState?.lifestyleFactor;
    if (calibrated != null && calibrated > 0) {
      return calibrated;
    }
    return context
        .read<AppServices>()
        .dailySummaryService
        .defaultLifestyleFactorForActivity(_activityLevel);
  }

  double _calculateTargetIntake(double bmr) {
    if (_isGramPerKgMode) {
      return 0;
    }
    final baselineNoExerciseTdee = _calculateNoExerciseBaseline(bmr);
    final noExerciseTarget = context
        .read<AppServices>()
        .dailySummaryService
        .calculateNoExerciseTargetIntake(
          baselineNoExerciseTdee: baselineNoExerciseTdee,
          profile: _buildDraftProfile(),
        );
    return noExerciseTarget + _todayExerciseCalories;
  }

  Future<void> _save() async {
    final strings = context.stringsRead;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    _normalizeGoalByAge();

    if (!_isGramPerKgMode && _isMinor && !_isBulkingPhase) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.ageMinorNoDeficit)));
      setState(() {
        _dailyGoalType = 'maintenance';
      });
    }

    if (!_isGramPerKgMode && (_macroRatioTotal - 100).abs() > 0.01) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.macroRatioTotalInvalid)));
      return;
    }

    final services = context.read<AppServices>();
    final refreshNotifier = context.read<RefreshNotifier>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);

    final profile = _buildDraftProfile().copyWith(
      id: _loadedProfile?.id ?? 1,
      createdAt: _loadedProfile?.createdAt,
      updatedAt: _loadedProfile?.updatedAt,
    );

    await services.profileRepository.saveProfile(profile);
    final trainingSelfCheckResult = await services
        .trainingFrequencySelfCheckService
        .evaluate(
          profile: profile,
          referenceDay: DateUtilsX.todayKey(),
          respectReminderCooldown: true,
        );

    if (!mounted) {
      return;
    }

    refreshNotifier.markDataChanged();
    setState(() {
      _saving = false;
      _loadedProfile = profile;
      _trainingSelfCheckResult = trainingSelfCheckResult;
    });
    messenger.showSnackBar(SnackBar(content: Text(strings.profileSaved)));
  }

  Future<void> _exportXlsx() async {
    final service = context.read<AppServices>().xlsxExportService;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _exportingXlsx = true);
    try {
      final filePath = await service.export();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('XLSX: $filePath')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('XLSX error: $e')));
    } finally {
      if (mounted) {
        setState(() => _exportingXlsx = false);
      }
    }
  }

  Future<void> _exportCsvZip() async {
    final service = context.read<AppServices>().csvExportService;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _exportingCsv = true);
    try {
      final filePath = await service.exportZip();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('CSV: $filePath')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text('CSV error: $e')));
    } finally {
      if (mounted) {
        setState(() => _exportingCsv = false);
      }
    }
  }

  Future<void> _clearAllData() async {
    final services = context.read<AppServices>();
    final refreshNotifier = context.read<RefreshNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.stringsRead;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(strings.clearAllDataTitle),
              content: Text(strings.clearAllDataBody),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(strings.cancel),
                ),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(strings.clearData),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    await services.database.clearAllLocalData();

    if (!mounted) {
      return;
    }

    refreshNotifier.markDataChanged();
    await _load();

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(strings.allDataCleared)));
  }

  Future<void> _applySelfCheckSuggestion() async {
    final result = _trainingSelfCheckResult;
    if (result == null) {
      return;
    }
    final now = DateTime.now().toIso8601String();
    final services = context.read<AppServices>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.stringsRead;

    setState(() => _handlingSelfCheckAction = true);
    try {
      await services.profileRepository.saveMacroSelfCheckFeedback(
        trainingFrequencyPerWeek: result.recommendedTrainingFrequency,
        lastMacroSelfCheckAt: now,
      );
      if (!mounted) {
        return;
      }
      context.read<RefreshNotifier>().markDataChanged();
      await _load();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(strings.profileSaved)));
    } finally {
      if (mounted) {
        setState(() => _handlingSelfCheckAction = false);
      }
    }
  }

  Future<void> _keepCurrentSelfCheckSetting() async {
    final now = DateTime.now().toIso8601String();
    final services = context.read<AppServices>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.stringsRead;

    setState(() => _handlingSelfCheckAction = true);
    try {
      await services.profileRepository.saveMacroSelfCheckFeedback(
        lastMacroSelfCheckAt: now,
      );
      if (!mounted) {
        return;
      }
      context.read<RefreshNotifier>().markDataChanged();
      await _load();
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(strings.profileSaved)));
    } finally {
      if (mounted) {
        setState(() => _handlingSelfCheckAction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final strings = context.strings;
    final languageController = context.watch<LanguageController>();

    final bmr = _calculateBmr();
    final lifestyleFactor = _currentLifestyleFactor();
    final tdeeReference = _calculateNoExerciseBaseline(bmr);
    final targetIntake = _calculateTargetIntake(bmr);
    final remaining = targetIntake - _todayCaloriesIn;
    final macroTargets = _isGramPerKgMode
        ? _macroTargetCalculator.calculateByGramPerKg(
            profile: _buildDraftProfile(),
          )
        : null;

    return ListView(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.paddingOf(context).bottom +
            kBottomNavigationBarHeight +
            24,
      ),
      children: <Widget>[
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.languageSettings,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<AppLanguage>(
                segments: <ButtonSegment<AppLanguage>>[
                  ButtonSegment<AppLanguage>(
                    value: AppLanguage.english,
                    label: Text(strings.english),
                  ),
                  ButtonSegment<AppLanguage>(
                    value: AppLanguage.chinese,
                    label: Text(strings.chinese),
                  ),
                ],
                selected: <AppLanguage>{languageController.language},
                onSelectionChanged: (selection) {
                  languageController.setLanguage(selection.first);
                },
              ),
            ],
          ),
        ),
        GlassPanel(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.bodyProfileGoal,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: strings.ageLabel),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (NumberUtils.toInt(value, fallback: 0) <= 0) {
                      return strings.enterValidAge;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(labelText: strings.heightCmLabel),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (NumberUtils.toDouble(value, fallback: 0) <= 0) {
                      return strings.enterValidHeight;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(labelText: strings.weightKgLabel),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (NumberUtils.toDouble(value, fallback: 0) <= 0) {
                      return strings.enterValidWeight;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _sexForFormula,
                  decoration: InputDecoration(
                    labelText: strings.sexForFormulaLabel,
                  ),
                  items: AppConstants.sexOptions
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(strings.sexOptionLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sexForFormula = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _dietGoalPhase,
                  decoration: InputDecoration(labelText: strings.goalPhaseLabel),
                  items: AppConstants.dietGoalPhases
                      .map(
                        (phase) => DropdownMenuItem<String>(
                          value: phase,
                          child: Text(strings.phaseLabel(phase)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _setDietGoalPhase(value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _dietCalculationMode,
                  decoration: InputDecoration(
                    labelText: strings.dietCalculationModeLabel,
                  ),
                  items: AppConstants.dietCalculationModes
                      .map(
                        (mode) => DropdownMenuItem<String>(
                          value: mode,
                          child: Text(
                            mode == AppConstants.dietCalculationModeGramPerKg
                                ? strings.gramPerKgModeLabel
                                : strings.energyRatioModeLabel,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _dietCalculationMode = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                if (!_isGramPerKgMode) ...<Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _activityLevel,
                    decoration: InputDecoration(
                      labelText: strings.activityLevelLabel,
                    ),
                    items: AppConstants.activityLevels
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(strings.activityOptionLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _activityLevel = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _goalKcalController,
                    decoration: InputDecoration(
                      labelText: strings.dailyGoalKcalLabelForPhase(
                        _dietGoalPhase,
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.macroRatioSettingsLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (_isBulkingPhase)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        strings.bulkingMacroRatioSuggestion,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  TextFormField(
                    controller: _proteinRatioController,
                    decoration: InputDecoration(
                      labelText: strings.proteinRatioPercentLabel,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final ratio = NumberUtils.toDouble(value, fallback: -1);
                      if (ratio < 0 || ratio > 100) {
                        return strings.enterValidMacroRatio;
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _carbsRatioController,
                    decoration: InputDecoration(
                      labelText: strings.carbsRatioPercentLabel,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final ratio = NumberUtils.toDouble(value, fallback: -1);
                      if (ratio < 0 || ratio > 100) {
                        return strings.enterValidMacroRatio;
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _fatRatioController,
                    decoration: InputDecoration(
                      labelText: strings.fatRatioPercentLabel,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final ratio = NumberUtils.toDouble(value, fallback: -1);
                      if (ratio < 0 || ratio > 100) {
                        return strings.enterValidMacroRatio;
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${strings.macroRatioHint} (${_macroRatioTotal.toStringAsFixed(1)}%)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if ((_macroRatioTotal - 100).abs() > 0.01)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        strings.macroRatioTotalInvalid,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_dailyGoalType == 'deficit' && _goalKcal > 700)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        strings.aggressiveGoalWarning,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
                if (_isGramPerKgMode) ...<Widget>[
                  Text(
                    strings.gramPerKgTableTitle(_dietGoalPhase),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.gramPerKgPhaseNotice(_dietGoalPhase),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _trainingFrequencyPerWeek,
                    decoration: InputDecoration(
                      labelText: strings.trainingFrequencyPerWeekLabel,
                    ),
                    items: AppConstants.trainingFrequencyPerWeekOptions
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text(strings.trainingFrequencyOptionLabel(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _trainingFrequencyPerWeek = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: _macroSelfCheckPeriodDays,
                    decoration: InputDecoration(
                      labelText: strings.macroSelfCheckPeriodLabel,
                    ),
                    items: AppConstants.macroSelfCheckPeriodDayOptions
                        .map(
                          (value) => DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              strings.macroSelfCheckPeriodOptionLabel(value),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _macroSelfCheckPeriodDays = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _macroSelfCheckEnabled,
                    title: Text(strings.macroSelfCheckEnabledLabel),
                    onChanged: (value) {
                      setState(() => _macroSelfCheckEnabled = value);
                    },
                  ),
                ],
                if (_isMinor)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(strings.minorReminder),
                  ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? strings.saving : strings.saveProfile),
                ),
              ],
            ),
          ),
        ),
        if (_isGramPerKgMode && _trainingSelfCheckResult != null)
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.macroSelfCheckTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                if (!_trainingSelfCheckResult!.isEnabled)
                  Text(strings.macroSelfCheckEnabledLabel)
                else if (!_trainingSelfCheckResult!.hasValidTrainingData)
                  Text(strings.macroSelfCheckNoData)
                else ...<Widget>[
                  Text(
                    strings.macroSelfCheckCurrentFrequencyText(
                      _trainingSelfCheckResult!.currentTrainingFrequency,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.macroSelfCheckActiveDaysText(
                      _trainingSelfCheckResult!.periodDays,
                      _trainingSelfCheckResult!.activeTrainingDays,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.macroSelfCheckAverageFrequencyText(
                      _trainingSelfCheckResult!.averageWeeklyTrainingFrequency,
                    ),
                  ),
                  if (_trainingSelfCheckResult!.belowRecommendedRange) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(strings.macroSelfCheckBelowRangeNotice),
                  ],
                  const SizedBox(height: 8),
                  if (!_trainingSelfCheckResult!.isConsistent) ...<Widget>[
                    Text(
                      strings.macroSelfCheckRecommendedText(
                        _trainingSelfCheckResult!.recommendedTrainingFrequency,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (_trainingSelfCheckResult!.shouldSuggestAdjustment) ...<Widget>[
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _handlingSelfCheckAction
                                  ? null
                                  : _applySelfCheckSuggestion,
                              child: Text(strings.applySuggestion),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonal(
                              onPressed: _handlingSelfCheckAction
                                  ? null
                                  : _keepCurrentSelfCheckSetting,
                              child: Text(strings.keepCurrentSetting),
                            ),
                          ),
                        ],
                      ),
                    ] else ...<Widget>[
                      const SizedBox(height: 6),
                      Text(strings.macroSelfCheckReminderCooldownHint),
                    ],
                  ] else
                    Text(strings.macroSelfCheckConsistent),
                ],
              ],
            ),
          ),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                strings.calculatedReference,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _Line(label: 'BMR', value: bmr.toStringAsFixed(0)),
              _Line(
                label: strings.lifestyleFactorLabel,
                value: lifestyleFactor.toStringAsFixed(3),
              ),
              _Line(
                label: strings.tdeeReferenceLabel,
                value: tdeeReference.toStringAsFixed(0),
              ),
              if (_calibrationState != null)
                _Line(
                  label: strings.calibrationConfidenceLabel,
                  value:
                      '${(_calibrationState!.confidence * 100).toStringAsFixed(0)}%',
                ),
              if (_calibrationState != null &&
                  _calibrationState!.windowDays > 0)
                _Line(
                  label: strings.calibrationWindowLabel,
                  value:
                      '${_calibrationState!.windowDays} d (${_calibrationState!.validDays} valid)',
                ),
              _Line(
                label: strings.goalPhaseLabel,
                value: strings.phaseLabel(_dietGoalPhase),
              ),
              _Line(
                label: strings.todayExerciseCaloriesLabel,
                value: _todayExerciseCalories.toStringAsFixed(0),
              ),
              if (!_isGramPerKgMode) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    strings.energyRatioPhaseNotice(_dietGoalPhase),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                _Line(
                  label: strings.targetIntakeTodayLabel,
                  value: targetIntake.toStringAsFixed(0),
                ),
                _Line(
                  label: strings.remainingTodayLabel,
                  value: remaining.toStringAsFixed(0),
                ),
              ],
              if (_isGramPerKgMode && macroTargets != null) ...<Widget>[
                const SizedBox(height: 8),
                _Line(
                  label: strings.trainingFrequencyPerWeekLabel,
                  value: strings.trainingFrequencyOptionLabel(
                    _trainingFrequencyPerWeek,
                  ),
                ),
                _Line(
                  label: '${strings.proteinLabel} (g)',
                  value: macroTargets.proteinTargetG.toStringAsFixed(1),
                ),
                _Line(
                  label: '${strings.carbsLabel} (g)',
                  value: macroTargets.carbsTargetG.toStringAsFixed(1),
                ),
                _Line(
                  label: '${strings.fatLabel} (g)',
                  value: macroTargets.fatTargetG.toStringAsFixed(1),
                ),
                _Line(
                  label: strings.macroEquivalentEnergyLabel,
                  value:
                      '${macroTargets.macroEnergyEquivalentKcal.toStringAsFixed(0)} kcal',
                ),
              ],
            ],
          ),
        ),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                strings.exportData,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _exportingXlsx ? null : _exportXlsx,
                icon: _exportingXlsx
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.grid_on_outlined),
                label: Text(
                  _exportingXlsx ? strings.saving : strings.exportXlsx,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _exportingCsv ? null : _exportCsvZip,
                icon: _exportingCsv
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_zip_outlined),
                label: Text(_exportingCsv ? strings.saving : strings.exportCsv),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: _clearAllData,
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(strings.clearAllData),
              ),
            ],
          ),
        ),
      ],
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
