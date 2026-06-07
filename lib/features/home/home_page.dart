import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/fitlog_icon_assets.dart';
import '../../core/localization/app_strings.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/fitlog_ui.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/daily_summary.dart';
import '../../domain/models/user_profile.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<_HomePageData> _loadData(BuildContext context, String day) async {
    final services = context.read<AppServices>();
    final results = await Future.wait<Object?>(<Future<Object?>>[
      services.dailySummaryService.getSummaryForDate(day),
      services.profileRepository.getProfile(),
    ]);

    return _HomePageData(
      summary: results[0]! as DailySummary,
      profile: results[1] as UserProfile?,
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

  String _greetingForNow(AppStrings strings) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return strings.morningGreeting;
    }
    if (hour >= 12 && hour < 18) {
      return strings.afternoonGreeting;
    }
    return strings.eveningGreeting;
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return SafeArea(
      child: Consumer2<RefreshNotifier, SelectedDateNotifier>(
        builder: (context, refresh, selectedDateNotifier, _) {
          refresh.version;
          final selectedDate = selectedDateNotifier.selectedDate;

          return FutureBuilder<_HomePageData>(
            future: _loadData(context, selectedDate),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(strings.summaryError(snapshot.error!)),
                );
              }

              final data = snapshot.data;
              if (data == null) {
                return Center(child: Text(strings.noSummaryData));
              }

              final profile = data.profile;
              final summary = data.summary;
              final nickname = ((profile?.nickname ?? '').trim().isEmpty)
                  ? strings.nicknameFallback
                  : profile!.nickname!.trim();
              final greetingPrefix = _greetingForNow(strings);

              return ListView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom + 132,
                ),
                children: <Widget>[
                  FitLogPageHeader(
                    title: '',
                    titleWidget: _HomeGreeting(
                      greetingPrefix: greetingPrefix,
                      nickname: nickname,
                      isChinese: strings.isChinese,
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    trailing: FitLogActionIconButton(
                      icon: Icons.calendar_today_outlined,
                      tooltip: strings.change,
                      onPressed: () => _pickDate(context, selectedDateNotifier),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Text(
                      DateUtilsX.formatReadable(summary.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF7A8973),
                      ),
                    ),
                  ),
                  _CaloriesHero(summary: summary, strings: strings),
                  _MacrosCard(summary: summary, strings: strings),
                  _StrategyCard(
                    summary: summary,
                    profile: profile ?? UserProfile.defaults,
                    strings: strings,
                  ),
                  _TodayRecordsCard(summary: summary, strings: strings),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _HomePageData {
  const _HomePageData({required this.summary, required this.profile});

  final DailySummary summary;
  final UserProfile? profile;
}

class _CaloriesHero extends StatelessWidget {
  const _CaloriesHero({required this.summary, required this.strings});

  final DailySummary summary;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final isGramPerKgMode =
        summary.dietCalculationMode ==
        AppConstants.dietCalculationModeGramPerKg;
    final progressBase = isGramPerKgMode
        ? math.max(summary.macroEnergyEquivalentKcal, 1)
        : math.max(summary.targetIntake, 1);
    final progress = (summary.caloriesIn / progressBase).clamp(0.0, 1.0);
    final heroValue = isGramPerKgMode
        ? summary.macroEnergyEquivalentKcal
        : summary.caloriesIn;

    return GlassPanel(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            strings.caloriesRingTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              SizedBox(
                width: 170,
                height: 170,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 170,
                      height: 170,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: const Color(0xFFEEF3E7),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF74BF56),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          heroValue.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF152013),
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'kcal',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _HeroMetric(
                      label: isGramPerKgMode
                          ? strings.macroEquivalentEnergyLabel
                          : strings.remainingCaloriesLabel,
                      value: isGramPerKgMode
                          ? '${summary.macroEnergyEquivalentKcal.toStringAsFixed(0)} kcal'
                          : '${summary.remainingCalories.toStringAsFixed(0)} kcal',
                      emphasize: const Color(0xFF4E9E3B),
                    ),
                    const SizedBox(height: 18),
                    _HeroMetric(
                      label: isGramPerKgMode
                          ? strings.caloriesInTodayLabel
                          : strings.targetIntakeLabel,
                      value: isGramPerKgMode
                          ? '${summary.caloriesIn.toStringAsFixed(0)} kcal'
                          : '${summary.targetIntake.toStringAsFixed(0)} kcal',
                    ),
                    const SizedBox(height: 18),
                    _HeroMetric(
                      label: strings.exerciseCaloriesTodayLabel,
                      value:
                          '${summary.exerciseCalories.toStringAsFixed(0)} kcal',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value, this.emphasize});

  final String label;
  final String value;
  final Color? emphasize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF75856F)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: emphasize ?? const Color(0xFF152013),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MacrosCard extends StatelessWidget {
  const _MacrosCard({required this.summary, required this.strings});

  final DailySummary summary;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: <Widget>[
          FitLogSectionHeader(
            title: strings.macrosTitle,
            actionLabel: strings.details,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _MacroMetricCard(
                  label: strings.proteinLabel,
                  current: summary.proteinG,
                  target: summary.targetProteinG,
                  color: const Color(0xFF6DBA57),
                  iconAsset: FitLogIconAssets.macroProtein,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroMetricCard(
                  label: strings.carbsLabel,
                  current: summary.carbsG,
                  target: summary.targetCarbsG,
                  color: const Color(0xFFF2B545),
                  iconAsset: FitLogIconAssets.macroCarbs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroMetricCard(
                  label: strings.fatLabel,
                  current: summary.fatG,
                  target: summary.targetFatG,
                  color: const Color(0xFFE89257),
                  iconAsset: FitLogIconAssets.macroFat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroMetricCard extends StatelessWidget {
  const _MacroMetricCard({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.iconAsset,
  });

  final String label;
  final double current;
  final double target;
  final Color color;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

    return SizedBox(
      height: 196,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFC),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8EFE3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _MacroIconBadge(assetName: iconAsset, color: color),
            const SizedBox(height: 12),
            Text(
              current.toStringAsFixed(0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: Text(
                context.strings.macroProgressText(current, target),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7A8973),
                  height: 1.25,
                ),
              ),
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                backgroundColor: color.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting({
    required this.greetingPrefix,
    required this.nickname,
    required this.isChinese,
  });

  final String greetingPrefix;
  final String nickname;
  final bool isChinese;

  bool get _shouldBreakLine {
    final nicknameLength = nickname.runes.length;
    return nicknameLength > (isChinese ? 4 : 12);
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF152013),
      height: 1.1,
    );

    if (_shouldBreakLine) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            isChinese ? '$greetingPrefix，' : '$greetingPrefix,',
            style: style,
          ),
          const SizedBox(height: 2),
          Text(isChinese ? '$nickname！' : '$nickname!', style: style),
        ],
      );
    }

    return Text(
      isChinese ? '$greetingPrefix，$nickname！' : '$greetingPrefix, $nickname!',
      style: style,
    );
  }
}

class _StrategyCard extends StatelessWidget {
  const _StrategyCard({
    required this.summary,
    required this.profile,
    required this.strings,
  });

  final DailySummary summary;
  final UserProfile profile;
  final AppStrings strings;

  void _openGuide(BuildContext context, String modeText) {
    if (summary.dietPlanStrategy == AppConstants.dietPlanStrategyNone) {
      return;
    }

    final strategyLabel =
        summary.dietPlanStrategy == AppConstants.dietPlanStrategyCarbCycling
        ? strings.carbCyclingLabel
        : strings.carbTaperingLabel;

    final baseCarbFloor = math.max(
      profile.weightKg * AppConstants.carbSafetyFloorPerKg,
      AppConstants.carbSafetyFloorMinimumG,
    );
    final guidePrinciple =
        summary.dietPlanStrategy == AppConstants.dietPlanStrategyCarbCycling
        ? strings.carbCyclingGuidePrinciple()
        : strings.carbTaperingGuidePrinciple();
    final guideNumbers =
        summary.dietPlanStrategy == AppConstants.dietPlanStrategyCarbCycling
        ? strings.carbCyclingGuideNumbers(
            highMultiplier: profile.carbCycleHighMultiplier,
            mediumMultiplier: profile.carbCycleMediumMultiplier,
            lowMultiplier: profile.carbCycleLowMultiplier,
            minimumCarbsG: baseCarbFloor,
          )
        : strings.carbTaperingGuideNumbers(
            reviewDays: profile.carbTaperReviewPeriodDays,
            targetLossPctPerWeek: profile.carbTaperTargetLossPctPerWeek,
            stepG: profile.carbTaperStepG,
            conservativeMaxStepG: math.min(20, profile.weightKg * 0.25),
            minimumCarbsG: baseCarbFloor,
          );
    final guideSetup =
        summary.dietPlanStrategy == AppConstants.dietPlanStrategyCarbCycling
        ? strings.carbCyclingGuideSetup()
        : strings.carbTaperingGuideSetup();
    final whatToKnow =
        summary.dietPlanStrategy == AppConstants.dietPlanStrategyCarbCycling
        ? strings.carbCyclingGuideKnow()
        : strings.carbTaperingGuideKnow();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: GlassPanel(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const FitLogSvgIconCircle(
                        assetName: FitLogIconAssets.strategy,
                        backgroundColor: Color(0xFFEAF6E3),
                        tintColor: Color(0xFF6FB95A),
                        size: 44,
                        iconSize: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings.strategyGuideTitle(strategyLabel),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: math.min(
                      MediaQuery.of(context).size.height * 0.72,
                      620,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FitLogStrategyGuideSection(
                            title: strings.strategyGuideBaseMethodTitle,
                            lines: <String>[
                              strings.strategyGuideBaseMethodBody(modeText),
                            ],
                          ),
                          FitLogStrategyGuideSection(
                            title: strings.strategyGuideCorePrincipleTitle,
                            lines: guidePrinciple,
                          ),
                          FitLogStrategyGuideSection(
                            title: strings.strategyGuideNumbersTitle,
                            lines: guideNumbers,
                          ),
                          FitLogStrategyGuideSection(
                            title: strings.strategyGuideSetupTitle,
                            lines: guideSetup,
                          ),
                          FitLogStrategyGuideSection(
                            title: strings.strategyGuideKnowTitle,
                            lines: whatToKnow,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strategyText =
        summary.dietPlanStrategy == AppConstants.dietPlanStrategyCarbCycling
        ? '${strings.carbCyclingLabel} - ${strings.carbDayTypeFullLabel(summary.carbDayType ?? AppConstants.carbDayMedium)}'
        : summary.dietPlanStrategy == AppConstants.dietPlanStrategyCarbTapering
        ? '${strings.carbTaperingLabel} - ${strings.currentTaperLabel} ${summary.carbTaperCurrentDeltaG.toStringAsFixed(0)} g'
        : strings.strategyNoneLabel;
    final modeText =
        summary.dietCalculationMode == AppConstants.dietCalculationModeGramPerKg
        ? strings.gramPerKgModeLabel
        : strings.energyRatioModeLabel;
    final canOpen =
        summary.dietPlanStrategy != AppConstants.dietPlanStrategyNone;

    return GlassPanel(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: canOpen ? () => _openGuide(context, modeText) : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const FitLogSvgIconCircle(
                assetName: FitLogIconAssets.strategy,
                backgroundColor: Color(0xFFEAF6E3),
                tintColor: Color(0xFF6FB95A),
                size: 48,
                iconSize: 24,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${strings.phaseLabel(summary.dietGoalPhase)} - $modeText',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF7A8973),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strategyText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (canOpen)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF7A8973),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayRecordsCard extends StatelessWidget {
  const _TodayRecordsCard({required this.summary, required this.strings});

  final DailySummary summary;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final navController = context.read<RootTabController>();

    return GlassPanel(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: <Widget>[
          FitLogSectionHeader(
            title: strings.todayRecordsTitle,
            actionLabel: strings.viewAll,
          ),
          _RecordRow(
            assetName: FitLogIconAssets.food,
            color: const Color(0xFF74BF56),
            title: strings.foodLabel,
            subtitle: strings.foodRecordsSummary(summary.foodRecords.length),
            value: '${summary.caloriesIn.toStringAsFixed(0)} kcal',
            onTap: () => navController.setIndex(1),
          ),
          const SizedBox(height: 12),
          _RecordRow(
            assetName: FitLogIconAssets.workout,
            color: const Color(0xFF6B9ED6),
            title: strings.workoutLogTitle,
            subtitle: strings.workoutRecordsSummary(
              summary.workoutSessions.length,
            ),
            value: '${summary.exerciseCalories.toStringAsFixed(0)} kcal',
            onTap: () => navController.setIndex(2),
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.assetName,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  final String assetName;
  final Color color;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EFE3)),
        ),
        child: Row(
          children: <Widget>[
            FitLogSvgIconCircle(
              assetName: assetName,
              backgroundColor: color.withValues(alpha: 0.14),
              tintColor: color,
              size: 42,
              iconSize: 21,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF7A8973)),
          ],
        ),
      ),
    );
  }
}

class _MacroIconBadge extends StatelessWidget {
  const _MacroIconBadge({required this.assetName, required this.color});

  final String assetName;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FitLogSvgIconCircle(
      assetName: assetName,
      size: 40,
      iconSize: 22,
      backgroundColor: color.withValues(alpha: 0.14),
    );
  }
}
