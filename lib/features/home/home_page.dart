import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
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
                    subtitle: strings.homeConsistencyHint,
                    trailing: FitLogActionIconButton(
                      icon: Icons.calendar_today_outlined,
                      tooltip: strings.change,
                      onPressed: () => _pickDate(context, selectedDateNotifier),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      DateUtilsX.formatReadable(summary.date),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF7A8973),
                      ),
                    ),
                  ),
                  _CaloriesHero(summary: summary, strings: strings),
                  _MacrosCard(summary: summary, strings: strings),
                  _StrategyCard(summary: summary, strings: strings),
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
    final progressValue = summary.caloriesIn;
    final progress = (progressValue / progressBase).clamp(0.0, 1.0);
    final heroValue =
        summary.dietCalculationMode == AppConstants.dietCalculationModeGramPerKg
        ? summary.macroEnergyEquivalentKcal
        : summary.caloriesIn;
    final targetValue = summary.targetIntake;

    return GlassPanel(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                          : '${targetValue.toStringAsFixed(0)} kcal',
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
                  iconType: _MacroIconType.protein,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroMetricCard(
                  label: strings.carbsLabel,
                  current: summary.carbsG,
                  target: summary.targetCarbsG,
                  color: const Color(0xFFF2B545),
                  iconType: _MacroIconType.carbs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroMetricCard(
                  label: strings.fatLabel,
                  current: summary.fatG,
                  target: summary.targetFatG,
                  color: const Color(0xFFE89257),
                  iconType: _MacroIconType.fat,
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
    required this.iconType,
  });

  final String label;
  final double current;
  final double target;
  final Color color;
  final _MacroIconType iconType;

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
            _MacroIconBadge(type: iconType, color: color),
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
              height: 42,
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
        children: <Widget>[
          Text(
            isChinese ? '$greetingPrefix，' : '$greetingPrefix,',
            style: style,
          ),
          const SizedBox(height: 4),
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
  const _StrategyCard({required this.summary, required this.strings});

  final DailySummary summary;
  final AppStrings strings;

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
    final explanation = switch (summary.dietPlanStrategy) {
      AppConstants.dietPlanStrategyCarbCycling =>
        strings.homeCarbCyclingSummary(modeText),
      AppConstants.dietPlanStrategyCarbTapering =>
        strings.homeCarbTaperingSummary(modeText),
      _ => null,
    };

    return GlassPanel(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const FitLogIconCircle(
            icon: Icons.spa_outlined,
            color: Color(0xFF6FB95A),
            size: 48,
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
                if (explanation != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    explanation,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF61715D),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
            icon: Icons.restaurant_menu_outlined,
            color: const Color(0xFF74BF56),
            title: strings.foodLabel,
            subtitle: strings.foodRecordsSummary(summary.foodRecords.length),
            value: '${summary.caloriesIn.toStringAsFixed(0)} kcal',
            onTap: () => navController.setIndex(1),
          ),
          const SizedBox(height: 12),
          _RecordRow(
            icon: Icons.fitness_center_outlined,
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
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
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
            FitLogIconCircle(icon: icon, color: color, size: 42),
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

enum _MacroIconType { protein, carbs, fat }

class _MacroIconBadge extends StatelessWidget {
  const _MacroIconBadge({required this.type, required this.color});

  final _MacroIconType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: const Size.square(20),
        painter: _MacroIconPainter(type: type, color: color),
      ),
    );
  }
}

class _MacroIconPainter extends CustomPainter {
  const _MacroIconPainter({required this.type, required this.color});

  final _MacroIconType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    switch (type) {
      case _MacroIconType.protein:
        final eggRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: size.width * 0.62,
          height: size.height * 0.8,
        );
        canvas.drawOval(eggRect, stroke);
        final yolk = Path()
          ..moveTo(size.width * 0.5, size.height * 0.42)
          ..quadraticBezierTo(
            size.width * 0.62,
            size.height * 0.54,
            size.width * 0.5,
            size.height * 0.68,
          )
          ..quadraticBezierTo(
            size.width * 0.38,
            size.height * 0.54,
            size.width * 0.5,
            size.height * 0.42,
          );
        canvas.drawPath(yolk, fill);
        canvas.drawPath(yolk, stroke);
        return;
      case _MacroIconType.carbs:
        canvas.drawLine(
          Offset(size.width * 0.5, size.height * 0.2),
          Offset(size.width * 0.5, size.height * 0.82),
          stroke,
        );
        for (final entry in <Offset>[
          Offset(size.width * 0.34, size.height * 0.32),
          Offset(size.width * 0.34, size.height * 0.46),
          Offset(size.width * 0.34, size.height * 0.6),
          Offset(size.width * 0.66, size.height * 0.32),
          Offset(size.width * 0.66, size.height * 0.46),
          Offset(size.width * 0.66, size.height * 0.6),
        ]) {
          final grain = Path()
            ..moveTo(entry.dx, entry.dy)
            ..quadraticBezierTo(
              entry.dx + (entry.dx < size.width / 2 ? -2.4 : 2.4),
              entry.dy + 2.6,
              entry.dx,
              entry.dy + 5.2,
            )
            ..quadraticBezierTo(
              entry.dx + (entry.dx < size.width / 2 ? 2.4 : -2.4),
              entry.dy + 2.6,
              entry.dx,
              entry.dy,
            );
          canvas.drawPath(grain, stroke);
        }
        return;
      case _MacroIconType.fat:
        final body = Path()
          ..moveTo(size.width * 0.5, size.height * 0.14)
          ..quadraticBezierTo(
            size.width * 0.82,
            size.height * 0.2,
            size.width * 0.8,
            size.height * 0.52,
          )
          ..quadraticBezierTo(
            size.width * 0.78,
            size.height * 0.82,
            size.width * 0.5,
            size.height * 0.86,
          )
          ..quadraticBezierTo(
            size.width * 0.22,
            size.height * 0.82,
            size.width * 0.2,
            size.height * 0.52,
          )
          ..quadraticBezierTo(
            size.width * 0.18,
            size.height * 0.2,
            size.width * 0.5,
            size.height * 0.14,
          );
        canvas.drawPath(body, stroke);
        final pit = Rect.fromCenter(
          center: Offset(size.width * 0.53, size.height * 0.56),
          width: size.width * 0.18,
          height: size.height * 0.22,
        );
        canvas.drawOval(pit, fill);
        canvas.drawOval(pit, stroke);
        return;
    }
  }

  @override
  bool shouldRepaint(covariant _MacroIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
