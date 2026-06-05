import 'dart:convert';

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
import '../../core/widgets/profile_form_fields.dart';
import '../../domain/models/calorie_calibration_state.dart';
import '../../domain/models/carb_taper_review_result.dart';
import '../../domain/models/diet_adjustment_review.dart';
import '../../domain/models/training_frequency_self_check_result.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/services/carb_cycling_calculator.dart';
import '../../domain/services/macro_target_calculator.dart';
import 'diet_plan_strategy_section.dart';

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
  String _dietPlanStrategy = AppConstants.defaultDietPlanStrategy;
  Map<String, String> _carbCyclePattern = AppConstants.defaultCarbCyclePattern();
  int _carbTaperReviewPeriodDays =
      AppConstants.defaultCarbTaperReviewPeriodDays;
  double _carbTaperTargetLossPctPerWeek =
      AppConstants.defaultCarbTaperTargetLossPctPerWeek;
  double _carbTaperStepG = AppConstants.defaultCarbTaperStepG;
  double _carbTaperCurrentDeltaG = AppConstants.defaultCarbTaperCurrentDeltaG;
  String? _lastCarbTaperReviewAt;
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
  CarbTaperReviewResult? _carbTaperReviewResult;
  DietAdjustmentReview? _pendingDietAdjustmentReview;
  bool _handlingSelfCheckAction = false;
  bool _handlingCarbTaperAction = false;
  final MacroTargetCalculator _macroTargetCalculator =
      const MacroTargetCalculator();
  final CarbCyclingCalculator _carbCyclingCalculator =
      const CarbCyclingCalculator();

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
    var pendingDietAdjustmentReview = await services.profileRepository
        .getLatestDietAdjustmentReview(
          userDecision: AppConstants.dietAdjustmentDecisionPending,
        );
    final carbTaperReviewResult = await _loadCarbTaperReview(
      profile,
      pendingDietAdjustmentReview: pendingDietAdjustmentReview,
    );
    pendingDietAdjustmentReview = await services.profileRepository
        .getLatestDietAdjustmentReview(
          userDecision: AppConstants.dietAdjustmentDecisionPending,
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
      _dietPlanStrategy = profile.dietPlanStrategy;
      _carbCyclePattern = profile.carbCyclePattern;
      _carbTaperReviewPeriodDays = profile.carbTaperReviewPeriodDays;
      _carbTaperTargetLossPctPerWeek = profile.carbTaperTargetLossPctPerWeek;
      _carbTaperStepG = profile.carbTaperStepG;
      _carbTaperCurrentDeltaG = profile.carbTaperCurrentDeltaG;
      _lastCarbTaperReviewAt = profile.lastCarbTaperReviewAt;
      _trainingFrequencyPerWeek = profile.trainingFrequencyPerWeek;
      _macroSelfCheckPeriodDays = profile.macroSelfCheckPeriodDays;
      _macroSelfCheckEnabled = profile.macroSelfCheckEnabled;
      _lastMacroSelfCheckAt = profile.lastMacroSelfCheckAt;
      _calibrationState = calibrationState;
      _todayExerciseCalories = exerciseCalories;
      _todayCaloriesIn = caloriesIn;
      _trainingSelfCheckResult = trainingSelfCheckResult;
      _pendingDietAdjustmentReview = pendingDietAdjustmentReview;
      _carbTaperReviewResult = carbTaperReviewResult;
      _normalizeGoalByAge();
      _normalizeStrategyByContext();
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

  bool get _canUseCuttingStrategy => !_isMinor && !_isBulkingPhase;

  void _onAgeChanged() {
    setState(_normalizeGoalByAge);
  }

  void _normalizeGoalByAge() {
    _dailyGoalType = _dailyGoalTypeForPhase();
    if (_isMinor && _dailyGoalType == 'deficit') {
      _dailyGoalType = 'maintenance';
    }
  }

  void _normalizeStrategyByContext() {
    if (_canUseCuttingStrategy) {
      return;
    }
    _dietPlanStrategy = AppConstants.dietPlanStrategyNone;
    _carbTaperCurrentDeltaG = 0;
  }

  String _dailyGoalTypeForPhase() {
    return _isBulkingPhase ? 'surplus' : 'deficit';
  }

  void _setDietGoalPhase(String phase) {
    setState(() {
      _dietGoalPhase = AppConstants.resolveDietGoalPhase(phase);
      _normalizeGoalByAge();
      _normalizeStrategyByContext();
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
    final safeStrategy = _canUseCuttingStrategy
        ? _dietPlanStrategy
        : AppConstants.dietPlanStrategyNone;
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
      dietPlanStrategy: safeStrategy,
      carbCyclePatternJson: jsonEncode(_carbCyclePattern),
      carbCycleHighMultiplier: AppConstants.defaultCarbCycleHighMultiplier,
      carbCycleMediumMultiplier: AppConstants.defaultCarbCycleMediumMultiplier,
      carbCycleLowMultiplier: AppConstants.defaultCarbCycleLowMultiplier,
      carbTaperReviewPeriodDays: _carbTaperReviewPeriodDays,
      carbTaperTargetLossPctPerWeek: _carbTaperTargetLossPctPerWeek,
      carbTaperStepG: _carbTaperStepG,
      carbTaperCurrentDeltaG: safeStrategy ==
              AppConstants.dietPlanStrategyCarbTapering
          ? _carbTaperCurrentDeltaG
          : 0,
      lastCarbTaperReviewAt: _lastCarbTaperReviewAt,
      trainingFrequencyPerWeek: _trainingFrequencyPerWeek,
      macroSelfCheckPeriodDays: _macroSelfCheckPeriodDays,
      macroSelfCheckEnabled: _macroSelfCheckEnabled,
      lastMacroSelfCheckAt: _lastMacroSelfCheckAt,
    );
  }

  Future<CarbTaperReviewResult?> _loadCarbTaperReview(
    UserProfile profile, {
    required DietAdjustmentReview? pendingDietAdjustmentReview,
  }) async {
    if (profile.dietPlanStrategy !=
            AppConstants.dietPlanStrategyCarbTapering &&
        pendingDietAdjustmentReview == null) {
      return null;
    }
    final baseCarbsG = _resolveBaseMacroTargets(profile).carbsTargetG;
    final services = context.read<AppServices>();
    final result = await services.carbTaperReviewService.evaluate(
      profile: profile,
      referenceDay: DateUtilsX.todayKey(),
      latestPendingReviewDate: pendingDietAdjustmentReview?.reviewDate,
      baseCarbsGOverride: baseCarbsG,
      respectCooldown: true,
    );
    if (result.isReviewDue &&
        pendingDietAdjustmentReview == null &&
        result.isApplicable) {
      final createdReview = await services.profileRepository
          .insertDietAdjustmentReview(
            DietAdjustmentReview(
              reviewDate: DateUtilsX.todayKey(),
              windowDays: result.windowDays,
              dietGoalPhase: profile.dietGoalPhase,
              dietCalculationMode: profile.dietCalculationMode,
              dietPlanStrategy: profile.dietPlanStrategy,
              startAvgWeightKg: result.startAvgWeightKg,
              endAvgWeightKg: result.endAvgWeightKg,
              weightChangeKg: result.weightChangeKg,
              lossRatePctPerWeek: result.lossRatePctPerWeek,
              targetLossPctPerWeek: result.targetLossPctPerWeek,
              foodLogCoverage: result.foodLogCoverage,
              activeTrainingDays: result.activeTrainingDays,
              suggestedAction: result.suggestedAction,
              suggestedCarbDeltaG: result.suggestedCarbDeltaG,
              confidence: result.confidence,
              reasonCodes: result.reasonCodes,
              userDecision: AppConstants.dietAdjustmentDecisionPending,
            ),
          );
      _pendingDietAdjustmentReview = createdReview;
    }
    return result;
  }

  MacroTargets _resolveBaseMacroTargets(UserProfile profile) {
    if (profile.dietCalculationMode ==
        AppConstants.dietCalculationModeGramPerKg) {
      return _macroTargetCalculator.calculateByGramPerKg(profile: profile);
    }
    final bmr = context.read<AppServices>().dailySummaryService.calculateBmr(
      profile,
    );
    final baselineNoExerciseTdee = bmr * _currentLifestyleFactor();
    final targetIntake = context
        .read<AppServices>()
        .dailySummaryService
        .calculateNoExerciseTargetIntake(
          baselineNoExerciseTdee: baselineNoExerciseTdee,
          profile: profile,
        );
    return _macroTargetCalculator.calculateByEnergyRatio(
      profile: profile,
      targetIntakeKcal: targetIntake + _todayExerciseCalories,
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

    if (!_canUseCuttingStrategy &&
        _dietPlanStrategy != AppConstants.dietPlanStrategyNone) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.ageMinorNoCuttingStrategy)),
      );
      setState(() {
        _dietPlanStrategy = AppConstants.dietPlanStrategyNone;
        _carbTaperCurrentDeltaG = 0;
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
    var pendingDietAdjustmentReview = await services.profileRepository
        .getLatestDietAdjustmentReview(
          userDecision: AppConstants.dietAdjustmentDecisionPending,
        );
    final trainingSelfCheckResult = await services
        .trainingFrequencySelfCheckService
        .evaluate(
          profile: profile,
          referenceDay: DateUtilsX.todayKey(),
          respectReminderCooldown: true,
        );
    final carbTaperReviewResult = await _loadCarbTaperReview(
      profile,
      pendingDietAdjustmentReview: pendingDietAdjustmentReview,
    );
    pendingDietAdjustmentReview = await services.profileRepository
        .getLatestDietAdjustmentReview(
          userDecision: AppConstants.dietAdjustmentDecisionPending,
        );

    if (!mounted) {
      return;
    }

    refreshNotifier.markDataChanged();
    setState(() {
      _saving = false;
      _loadedProfile = profile;
      _trainingSelfCheckResult = trainingSelfCheckResult;
      _pendingDietAdjustmentReview = pendingDietAdjustmentReview;
      _carbTaperReviewResult = carbTaperReviewResult;
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

  Future<void> _applyCarbTaperSuggestion() async {
    final review = _pendingDietAdjustmentReview;
    final result = _carbTaperReviewResult;
    if (review == null || result == null) {
      return;
    }
    final services = context.read<AppServices>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.stringsRead;
    final reviewedAt = DateTime.now().toIso8601String();

    setState(() => _handlingCarbTaperAction = true);
    try {
      await services.profileRepository.saveCarbTaperReviewDecision(
        review: review,
        userDecision: AppConstants.dietAdjustmentDecisionAccepted,
        reviewedAt: reviewedAt,
        carbTaperCurrentDeltaG: result.projectedCarbDeltaAfterG,
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
        setState(() => _handlingCarbTaperAction = false);
      }
    }
  }

  Future<void> _dismissCarbTaperSuggestion() async {
    final review = _pendingDietAdjustmentReview;
    if (review == null) {
      return;
    }
    final services = context.read<AppServices>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.stringsRead;
    final reviewedAt = DateTime.now().toIso8601String();

    setState(() => _handlingCarbTaperAction = true);
    try {
      await services.profileRepository.saveCarbTaperReviewDecision(
        review: review,
        userDecision: AppConstants.dietAdjustmentDecisionDismissed,
        reviewedAt: reviewedAt,
        carbTaperCurrentDeltaG: _carbTaperCurrentDeltaG,
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
        setState(() => _handlingCarbTaperAction = false);
      }
    }
  }

  List<CarbCyclePreviewRow> _buildCarbCyclePreview({
    required UserProfile profile,
    required MacroTargets base,
  }) {
    final start = DateUtilsX.parseDay(DateUtilsX.todayKey()).subtract(
      Duration(days: DateUtilsX.parseDay(DateUtilsX.todayKey()).weekday - 1),
    );
    return List<CarbCyclePreviewRow>.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final dateKey = DateUtilsX.formatDate(day);
      final result = _carbCyclingCalculator.calculate(
        profile: profile,
        day: dateKey,
        isEnergyTargetMode:
            profile.dietCalculationMode !=
            AppConstants.dietCalculationModeGramPerKg,
        baseProteinG: base.proteinTargetG,
        baseCarbsG: base.carbsTargetG,
        baseFatG: base.fatTargetG,
      );
      return CarbCyclePreviewRow(
        weekdayKey: AppConstants.weekdayKeyFromDateTime(day),
        date: dateKey,
        carbDayType: result.carbDayType ?? AppConstants.carbDayMedium,
        proteinG: result.finalProteinG,
        carbsG: result.finalCarbsG,
        fatG: result.finalFatG,
        macroKcal: result.finalMacroEnergyEquivalentKcal,
      );
    });
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
    final draftProfile = _buildDraftProfile();
    final baseMacroTargets = _resolveBaseMacroTargets(draftProfile);
    final carbCyclePreview = _dietPlanStrategy ==
            AppConstants.dietPlanStrategyCarbCycling
        ? _buildCarbCyclePreview(profile: draftProfile, base: baseMacroTargets)
        : const <CarbCyclePreviewRow>[];

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
                ProfileNumericField(
                  controller: _ageController,
                  labelText: strings.ageLabel,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (NumberUtils.toInt(value, fallback: 0) <= 0) {
                      return strings.enterValidAge;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                ProfileNumericField(
                  controller: _heightController,
                  labelText: strings.heightCmLabel,
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
                ProfileNumericField(
                  controller: _weightController,
                  labelText: strings.weightKgLabel,
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
                ProfileOptionField<String>(
                  value: _sexForFormula,
                  labelText: strings.sexForFormulaLabel,
                  options: AppConstants.sexOptions,
                  labelBuilder: strings.sexOptionLabel,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sexForFormula = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                ProfileOptionField<String>(
                  value: _dietGoalPhase,
                  labelText: strings.goalPhaseLabel,
                  options: AppConstants.dietGoalPhases,
                  labelBuilder: strings.phaseLabel,
                  onChanged: (value) {
                    if (value != null) {
                      _setDietGoalPhase(value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                ProfileOptionField<String>(
                  value: _dietCalculationMode,
                  labelText: strings.dietCalculationModeLabel,
                  options: AppConstants.dietCalculationModes,
                  labelBuilder: (mode) =>
                      mode == AppConstants.dietCalculationModeGramPerKg
                      ? strings.gramPerKgModeLabel
                      : strings.energyRatioModeLabel,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _dietCalculationMode = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DietPlanStrategySection(
                  strings: strings,
                  canUseCuttingStrategy: _canUseCuttingStrategy,
                  isBulkingPhase: _isBulkingPhase,
                  dietPlanStrategy: _dietPlanStrategy,
                  carbCyclePattern: _carbCyclePattern,
                  carbCyclePreview: carbCyclePreview,
                  carbTaperReviewPeriodDays: _carbTaperReviewPeriodDays,
                  carbTaperTargetLossPctPerWeek:
                      _carbTaperTargetLossPctPerWeek,
                  carbTaperStepG: _carbTaperStepG,
                  carbTaperCurrentDeltaG: _carbTaperCurrentDeltaG,
                  carbTaperReviewResult: _carbTaperReviewResult,
                  hasPendingDietAdjustmentReview:
                      _pendingDietAdjustmentReview != null,
                  handlingCarbTaperAction: _handlingCarbTaperAction,
                  onStrategyChanged: _canUseCuttingStrategy
                      ? (value) {
                          if (value != null) {
                            setState(() => _dietPlanStrategy = value);
                          }
                        }
                      : null,
                  onCarbCycleDayTypeChanged: (key, value) {
                    setState(() {
                      _carbCyclePattern = <String, String>{
                        ..._carbCyclePattern,
                        key: value,
                      };
                    });
                  },
                  onCarbTaperReviewPeriodChanged: (value) {
                    if (value != null) {
                      setState(() => _carbTaperReviewPeriodDays = value);
                    }
                  },
                  onCarbTaperTargetLossChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _carbTaperTargetLossPctPerWeek = value;
                      });
                    }
                  },
                  onCarbTaperStepChanged: (value) {
                    if (value != null) {
                      setState(() => _carbTaperStepG = value);
                    }
                  },
                  onApplyCarbTaperSuggestion:
                      _pendingDietAdjustmentReview != null &&
                          _carbTaperReviewResult?.suggestedAction ==
                              AppConstants.dietAdjustmentActionDecreaseCarbs
                      ? _applyCarbTaperSuggestion
                      : null,
                  onDismissCarbTaperSuggestion:
                      _pendingDietAdjustmentReview != null
                      ? _dismissCarbTaperSuggestion
                      : null,
                ),
                const SizedBox(height: 10),
                if (!_isGramPerKgMode) ...<Widget>[
                  ProfileOptionField<String>(
                    value: _activityLevel,
                    labelText: strings.activityLevelLabel,
                    options: AppConstants.activityLevels,
                    labelBuilder: strings.activityOptionLabel,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _activityLevel = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ProfileNumericField(
                    controller: _goalKcalController,
                    labelText: strings.dailyGoalKcalLabelForPhase(
                      _dietGoalPhase,
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
                  ProfileNumericField(
                    controller: _proteinRatioController,
                    labelText: strings.proteinRatioPercentLabel,
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
                  ProfileNumericField(
                    controller: _carbsRatioController,
                    labelText: strings.carbsRatioPercentLabel,
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
                  ProfileNumericField(
                    controller: _fatRatioController,
                    labelText: strings.fatRatioPercentLabel,
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
                  ProfileOptionField<int>(
                    value: _trainingFrequencyPerWeek,
                    labelText: strings.trainingFrequencyPerWeekLabel,
                    options: AppConstants.trainingFrequencyPerWeekOptions,
                    labelBuilder: strings.trainingFrequencyOptionLabel,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _trainingFrequencyPerWeek = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  ProfileOptionField<int>(
                    value: _macroSelfCheckPeriodDays,
                    labelText: strings.macroSelfCheckPeriodLabel,
                    options: AppConstants.macroSelfCheckPeriodDayOptions,
                    labelBuilder: strings.macroSelfCheckPeriodOptionLabel,
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
                  if (_trainingSelfCheckResult!
                      .belowRecommendedRange) ...<Widget>[
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
                    if (_trainingSelfCheckResult!
                        .shouldSuggestAdjustment) ...<Widget>[
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
