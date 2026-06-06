import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_panel.dart';
import '../../core/widgets/selected_date_header.dart';
import '../../domain/models/daily_summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showDetailedMetrics = false;

  Future<DailySummary> _loadSummary(BuildContext context, String day) {
    return context.read<AppServices>().dailySummaryService.getSummaryForDate(
      day,
    );
  }

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

  String _remainingText(BuildContext context, double remainingCalories) {
    final strings = context.strings;

    if (remainingCalories > 30) {
      return strings.remainingCanEat(remainingCalories);
    }

    if (remainingCalories < -30) {
      return strings.remainingExceeded(remainingCalories.abs());
    }

    return strings.nearTarget;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Consumer2<RefreshNotifier, SelectedDateNotifier>(
      builder: (context, refresh, selectedDateNotifier, _) {
        refresh.version;
        final selectedDate = selectedDateNotifier.selectedDate;

        return FutureBuilder<DailySummary>(
          future: _loadSummary(context, selectedDate),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text(strings.summaryError(snapshot.error!)));
            }

            final summary = snapshot.data;
            if (summary == null) {
              return Center(child: Text(strings.noSummaryData));
            }

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
                      SelectedDateHeader(
                        dateText: DateUtilsX.formatReadable(summary.date),
                        changeLabel: strings.change,
                        onPrevious: () => _shiftDate(selectedDateNotifier, -1),
                        onNext: () => _shiftDate(selectedDateNotifier, 1),
                        onChangeDate: () =>
                            _pickDate(context, selectedDateNotifier),
                        textStyle: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              _showDetailedMetrics = !_showDetailedMetrics;
                            });
                          },
                          child: _OverviewHero(
                            summary: summary,
                            strings: strings,
                            expanded: _showDetailedMetrics,
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: _DashboardDetails(
                            summary: summary,
                            strings: strings,
                            remainingText: _remainingText(
                              context,
                              summary.remainingCalories,
                            ),
                          ),
                        ),
                        crossFadeState: _showDetailedMetrics
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 220),
                      ),
                    ],
                  ),
                ),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.foodLogTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (summary.foodRecords.isEmpty)
                        Text(strings.noFoodRecords)
                      else
                        ...summary.foodRecords.map(
                          (record) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(record.mealName),
                            subtitle: Text(
                              '${record.caloriesKcal.toStringAsFixed(0)} kcal - P ${record.proteinG.toStringAsFixed(1)} C ${record.carbsG.toStringAsFixed(1)} F ${record.fatG.toStringAsFixed(1)}',
                            ),
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
                        strings.workoutLogTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (summary.workoutSessions.isEmpty)
                        Text(strings.noWorkoutRecords)
                      else
                        ...summary.workoutSessions.map(
                          (session) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              strings.exerciseDisplayName(session.exerciseName),
                            ),
                            subtitle: Text(
                              '${session.durationMinutes} min - ${session.estimatedCalories.toStringAsFixed(0)} kcal',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OverviewHero extends StatelessWidget {
  const _OverviewHero({
    required this.summary,
    required this.strings,
    required this.expanded,
  });

  final DailySummary summary;
  final AppStrings strings;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final isGramPerKgMode =
        summary.dietCalculationMode ==
        AppConstants.dietCalculationModeGramPerKg;
    final hasDietStrategy =
        summary.dietPlanStrategy != AppConstants.dietPlanStrategyNone;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[
                  primary.withValues(alpha: 0.26),
                  const Color(0xFF0F1D2C).withValues(alpha: 0.75),
                ]
              : <Color>[
                  primary.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.72),
                ],
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasDietStrategy) ...<Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                Text(
                  strings.phaseLabel(summary.dietGoalPhase),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.62),
                  ),
                ),
                Text(
                  strings.strategyLabel(summary.dietPlanStrategy),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.72)
                        : Colors.black.withValues(alpha: 0.56),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  isGramPerKgMode
                      ? strings.macroTargetModeGramPerKg
                      : strings.caloriesInTodayLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ),
              if (!hasDietStrategy) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  strings.phaseLabel(summary.dietGoalPhase),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.black.withValues(alpha: 0.62),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!isGramPerKgMode)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 4,
              children: <Widget>[
                Text(
                  summary.caloriesIn.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                  ),
                ),
                Text(
                  '/ ${summary.targetIntake.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.88)
                        : Colors.black.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          if (isGramPerKgMode)
            Text(
              strings.todayCaloriesAux(summary.caloriesIn),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.88)
                    : Colors.black.withValues(alpha: 0.82),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _MacroSummaryCell(
                  label: strings.proteinLabel,
                  current: summary.proteinG,
                  target: summary.targetProteinG,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroSummaryCell(
                  label: strings.carbsLabel,
                  current: summary.carbsG,
                  target: summary.targetCarbsG,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroSummaryCell(
                  label: strings.fatLabel,
                  current: summary.fatG,
                  target: summary.targetFatG,
                ),
              ),
            ],
          ),
          if (summary.dietPlanStrategy != AppConstants.dietPlanStrategyNone)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                summary.dietPlanStrategy ==
                        AppConstants.dietPlanStrategyCarbCycling
                    ? '${strings.todayCarbDayTypeLabel}: ${strings.carbDayTypeFullLabel(summary.carbDayType ?? AppConstants.carbDayMedium)} | ${strings.carbAdjustmentLabel}: ${summary.carbAdjustmentG >= 0 ? '+' : ''}${summary.carbAdjustmentG.toStringAsFixed(1)} g'
                    : '${strings.currentTaperLabel}: ${summary.carbTaperCurrentDeltaG.toStringAsFixed(1)} g${summary.hasPendingDietAdjustmentReview ? ' | ${strings.pendingReviewHint}' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.82)
                      : Colors.black.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MacroSummaryCell extends StatelessWidget {
  const _MacroSummaryCell({
    required this.label,
    required this.current,
    required this.target,
  });

  final String label;
  final double current;
  final double target;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withValues(alpha: 0.80);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.8)
                  : Colors.black.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            current.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          Text(
            '/ ${target.toStringAsFixed(1)} g',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.88)
                  : Colors.black.withValues(alpha: 0.74),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardDetails extends StatelessWidget {
  const _DashboardDetails({
    required this.summary,
    required this.strings,
    required this.remainingText,
  });

  final DailySummary summary;
  final AppStrings strings;
  final String remainingText;

  @override
  Widget build(BuildContext context) {
    final isGramPerKgMode =
        summary.dietCalculationMode ==
        AppConstants.dietCalculationModeGramPerKg;

    if (isGramPerKgMode) {
      return Column(
        children: <Widget>[
          _MetricLine(
            label: strings.goalPhaseLabel,
            value: strings.phaseLabel(summary.dietGoalPhase),
          ),
          _MetricLine(
            label: strings.strategyBadgeLabel,
            value: strings.strategyLabel(summary.dietPlanStrategy),
          ),
          _MetricLine(
            label: strings.caloriesInTodayLabel,
            value: '${summary.caloriesIn.toStringAsFixed(0)} kcal',
          ),
          _MetricLine(
            label: strings.exerciseCaloriesTodayLabel,
            value: '${summary.exerciseCalories.toStringAsFixed(0)} kcal',
          ),
          _MetricLine(
            label: '${strings.proteinLabel} (g)',
            value:
                '${summary.proteinG.toStringAsFixed(1)} / ${summary.targetProteinG.toStringAsFixed(1)}',
          ),
          _MetricLine(
            label: '${strings.carbsLabel} (g)',
            value:
                '${summary.carbsG.toStringAsFixed(1)} / ${summary.targetCarbsG.toStringAsFixed(1)}',
          ),
          _MetricLine(
            label: '${strings.fatLabel} (g)',
            value:
                '${summary.fatG.toStringAsFixed(1)} / ${summary.targetFatG.toStringAsFixed(1)}',
          ),
          _MetricLine(
            label: strings.macroEquivalentEnergyLabel,
            value:
                '${summary.macroEnergyEquivalentKcal.toStringAsFixed(0)} kcal',
          ),
          if (summary.dietPlanStrategy ==
              AppConstants.dietPlanStrategyCarbCycling)
            _MetricLine(
              label: strings.todayCarbDayTypeLabel,
              value: strings.carbDayTypeFullLabel(
                summary.carbDayType ?? AppConstants.carbDayMedium,
              ),
            ),
          if (summary.dietPlanStrategy ==
              AppConstants.dietPlanStrategyCarbTapering)
            _MetricLine(
              label: strings.currentTaperLabel,
              value: '${summary.carbTaperCurrentDeltaG.toStringAsFixed(1)} g',
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              strings.gramPerKgModeNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              strings.estimateNotice,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    return Column(
      children: <Widget>[
        _MetricLine(
          label: strings.goalPhaseLabel,
          value: strings.phaseLabel(summary.dietGoalPhase),
        ),
        _MetricLine(
          label: strings.strategyBadgeLabel,
          value: strings.strategyLabel(summary.dietPlanStrategy),
        ),
        _MetricLine(
          label: strings.caloriesInTodayLabel,
          value: '${summary.caloriesIn.toStringAsFixed(0)} kcal',
        ),
        _MetricLine(
          label: strings.exerciseCaloriesTodayLabel,
          value: '${summary.exerciseCalories.toStringAsFixed(0)} kcal',
        ),
        _MetricLine(label: 'BMR', value: summary.bmr.toStringAsFixed(0)),
        _MetricLine(
          label: strings.tdeeReferenceLabel,
          value: summary.tdeeReference.toStringAsFixed(0),
        ),
        _MetricLine(
          label: strings.lifestyleFactorLabel,
          value: summary.lifestyleFactorUsed.toStringAsFixed(3),
        ),
        if (summary.calibrationWindowDays > 0)
          _MetricLine(
            label: strings.calibrationWindowLabel,
            value:
                '${summary.calibrationWindowDays} d (${summary.calibrationValidDays} valid)',
          ),
        if (summary.calibrationWindowDays > 0)
          _MetricLine(
            label: strings.calibrationConfidenceLabel,
            value:
                '${(summary.calibrationConfidence * 100).toStringAsFixed(0)}%',
          ),
        _MetricLine(
          label: strings.targetIntakeLabel,
          value: '${summary.targetIntake.toStringAsFixed(0)} kcal',
        ),
        _MetricLine(
          label: strings.dailyGoalKcalLabelForPhase(summary.dietGoalPhase),
          value:
              '${(summary.noExerciseBaselineTdee - summary.noExerciseTargetIntake).abs().toStringAsFixed(0)} kcal',
        ),
        _MetricLine(
          label: strings.remainingCaloriesLabel,
          value: '${summary.remainingCalories.toStringAsFixed(0)} kcal',
        ),
        if (summary.dietPlanStrategy ==
            AppConstants.dietPlanStrategyCarbCycling)
          _MetricLine(
            label: strings.todayCarbDayTypeLabel,
            value: strings.carbDayTypeFullLabel(
              summary.carbDayType ?? AppConstants.carbDayMedium,
            ),
          ),
        if (summary.dietPlanStrategy != AppConstants.dietPlanStrategyNone)
          _MetricLine(
            label: strings.carbAdjustmentLabel,
            value:
                '${summary.carbAdjustmentG >= 0 ? '+' : ''}${summary.carbAdjustmentG.toStringAsFixed(1)} g',
          ),
        if (summary.dietPlanStrategy ==
            AppConstants.dietPlanStrategyCarbTapering)
          _MetricLine(
            label: strings.currentTaperLabel,
            value: '${summary.carbTaperCurrentDeltaG.toStringAsFixed(1)} g',
          ),
        _MetricLine(
          label: '${strings.proteinLabel} (g)',
          value: summary.proteinG.toStringAsFixed(1),
        ),
        _MetricLine(
          label: '${strings.carbsLabel} (g)',
          value: summary.carbsG.toStringAsFixed(1),
        ),
        _MetricLine(
          label: '${strings.fatLabel} (g)',
          value: summary.fatG.toStringAsFixed(1),
        ),
        const SizedBox(height: 6),
        _MetricLine(
          label: strings.remainingProteinLabel,
          value: summary.remainingProteinG.toStringAsFixed(1),
        ),
        _MetricLine(
          label: strings.remainingCarbsLabel,
          value: summary.remainingCarbsG.toStringAsFixed(1),
        ),
        _MetricLine(
          label: strings.remainingFatLabel,
          value: summary.remainingFatG.toStringAsFixed(1),
        ),
        const SizedBox(height: 10),
        if (summary.hasPendingDietAdjustmentReview)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                strings.pendingReviewHint,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            remainingText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            strings.estimateNotice,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({required this.label, required this.value});

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
