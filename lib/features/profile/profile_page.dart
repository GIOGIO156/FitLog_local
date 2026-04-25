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
import '../../domain/models/user_profile.dart';

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

  String _sexForFormula = AppConstants.sexOptions.last;
  String _activityLevel = AppConstants.activityLevels[2];
  String _dailyGoalType = 'maintenance';

  UserProfile? _loadedProfile;
  bool _loading = true;
  bool _saving = false;
  bool _exportingXlsx = false;
  bool _exportingCsv = false;
  double _todayExerciseCalories = 0;
  double _todayCaloriesIn = 0;

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
    super.dispose();
  }

  Future<void> _load() async {
    final services = context.read<AppServices>();
    final profile =
        await services.profileRepository.getProfile() ?? UserProfile.defaults;
    final exerciseCalories = await services.workoutRepository
        .getExerciseCaloriesByDate(DateUtilsX.todayKey());
    final caloriesIn = await services.foodRepository.getCaloriesInByDate(
      DateUtilsX.todayKey(),
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
      _sexForFormula = profile.sexForFormula;
      _activityLevel = profile.activityLevel;
      _dailyGoalType = profile.dailyEnergyGoalType;
      _todayExerciseCalories = exerciseCalories;
      _todayCaloriesIn = caloriesIn;
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

  bool get _isMinor => _age > 0 && _age < 18;

  void _onAgeChanged() {
    setState(_normalizeGoalByAge);
  }

  void _normalizeGoalByAge() {
    if (_isMinor && _dailyGoalType == 'deficit') {
      _dailyGoalType = 'maintenance';
    }
  }

  List<String> get _goalTypeOptions {
    if (_isMinor) {
      return const <String>['maintenance', 'surplus'];
    }
    return AppConstants.dailyEnergyGoalTypes;
  }

  double _calculateBmr() {
    final profile = UserProfile(
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      sexForFormula: _sexForFormula,
      activityLevel: _activityLevel,
      dailyEnergyGoalType: _dailyGoalType,
      dailyEnergyGoalKcal: _goalKcal,
    );

    return context.read<AppServices>().dailySummaryService.calculateBmr(
      profile,
    );
  }

  double _calculateTdeeReference(double bmr) {
    const multipliers = <String, double>{
      'sedentary': 1.2,
      'lightly_active': 1.375,
      'moderately_active': 1.55,
      'very_active': 1.725,
    };
    return bmr * (multipliers[_activityLevel] ?? 1.55);
  }

  double _calculateTargetIntake(double bmr) {
    final actualExpenditure = bmr + _todayExerciseCalories;
    switch (_dailyGoalType) {
      case 'deficit':
        return actualExpenditure - _goalKcal;
      case 'surplus':
        return actualExpenditure + _goalKcal;
      case 'maintenance':
      default:
        return actualExpenditure;
    }
  }

  Future<void> _save() async {
    final strings = context.stringsRead;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isMinor && _dailyGoalType == 'deficit') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.ageMinorNoDeficit)));
      setState(() {
        _dailyGoalType = 'maintenance';
      });
    }

    final services = context.read<AppServices>();
    final refreshNotifier = context.read<RefreshNotifier>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _saving = true);

    final profile = UserProfile(
      id: _loadedProfile?.id ?? 1,
      age: _age,
      heightCm: _heightCm,
      weightKg: _weightKg,
      sexForFormula: _sexForFormula,
      activityLevel: _activityLevel,
      dailyEnergyGoalType: _dailyGoalType,
      dailyEnergyGoalKcal: _goalKcal,
      createdAt: _loadedProfile?.createdAt,
      updatedAt: _loadedProfile?.updatedAt,
    );

    await services.profileRepository.saveProfile(profile);

    if (!mounted) {
      return;
    }

    refreshNotifier.markDataChanged();
    setState(() {
      _saving = false;
      _loadedProfile = profile;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final strings = context.strings;
    final languageController = context.watch<LanguageController>();

    final bmr = _calculateBmr();
    final tdeeReference = _calculateTdeeReference(bmr);
    final targetIntake = _calculateTargetIntake(bmr);
    final remaining = targetIntake - _todayCaloriesIn;

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
                DropdownButtonFormField<String>(
                  initialValue: _goalTypeOptions.contains(_dailyGoalType)
                      ? _dailyGoalType
                      : _goalTypeOptions.first,
                  decoration: InputDecoration(
                    labelText: strings.dailyGoalTypeLabel,
                  ),
                  items: _goalTypeOptions
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(strings.goalTypeLabel(value)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _dailyGoalType = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _goalKcalController,
                  decoration: InputDecoration(
                    labelText: strings.dailyGoalKcalLabel,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
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
                label: strings.tdeeReferenceLabel,
                value: tdeeReference.toStringAsFixed(0),
              ),
              _Line(
                label: strings.todayExerciseCaloriesLabel,
                value: _todayExerciseCalories.toStringAsFixed(0),
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
