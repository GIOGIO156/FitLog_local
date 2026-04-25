import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/daily_summary.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<DailySummary> _loadSummary(BuildContext context) {
    return context.read<AppServices>().dailySummaryService.getSummaryForDate(
      DateUtilsX.todayKey(),
    );
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

    return Consumer<RefreshNotifier>(
      builder: (context, refresh, _) {
        refresh.version;
        return FutureBuilder<DailySummary>(
          future: _loadSummary(context),
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
                      Text(
                        DateUtilsX.formatReadable(summary.date),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _MetricLine(
                        label: strings.caloriesInTodayLabel,
                        value: '${summary.caloriesIn.toStringAsFixed(0)} kcal',
                      ),
                      _MetricLine(
                        label: strings.exerciseCaloriesTodayLabel,
                        value:
                            '${summary.exerciseCalories.toStringAsFixed(0)} kcal',
                      ),
                      _MetricLine(
                        label: 'BMR',
                        value: summary.bmr.toStringAsFixed(0),
                      ),
                      _MetricLine(
                        label: 'TDEE',
                        value: summary.tdeeReference.toStringAsFixed(0),
                      ),
                      _MetricLine(
                        label: strings.targetIntakeLabel,
                        value: summary.targetIntake.toStringAsFixed(0),
                      ),
                      _MetricLine(
                        label: strings.remainingCaloriesLabel,
                        value: summary.remainingCalories.toStringAsFixed(0),
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
                      const SizedBox(height: 10),
                      Text(
                        _remainingText(context, summary.remainingCalories),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.estimateNotice,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.todayFoodList,
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
                        strings.todayWorkoutList,
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
