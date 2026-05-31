import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_record.dart';
import 'add_food_page.dart';
import 'food_detail_page.dart';

class FoodLogPage extends StatefulWidget {
  const FoodLogPage({super.key});

  @override
  State<FoodLogPage> createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
  Future<List<FoodRecord>> _loadRecords(BuildContext context, String day) {
    return context.read<AppServices>().foodRepository.getFoodRecordsByDate(day);
  }

  Future<void> _openAddFood(BuildContext context, String initialDate) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddFoodPage(initialDate: initialDate),
      ),
    );

    if (saved == true && context.mounted) {
      context.read<RefreshNotifier>().markDataChanged();
    }
  }

  Future<void> _openFoodDetail(BuildContext context, int recordId) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FoodDetailPage(recordId: recordId),
      ),
    );

    if (updated == true && context.mounted) {
      context.read<RefreshNotifier>().markDataChanged();
    }
  }

  Future<void> _deleteRecord(BuildContext context, FoodRecord record) async {
    final services = context.read<AppServices>();
    final refreshNotifier = context.read<RefreshNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.stringsRead;

    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(strings.deleteRecord),
              content: Text(
                strings.deleteFoodConfirm(record.mealName, record.date),
              ),
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

    await services.foodRepository.deleteFoodRecord(record.id!);

    if (!context.mounted) {
      return;
    }

    refreshNotifier.markDataChanged();
    messenger.showSnackBar(SnackBar(content: Text(strings.foodDeleted)));
  }

  Future<void> _copyRecord(
    BuildContext context,
    FoodRecord record,
    String initialDate,
  ) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateUtilsX.parseDay(initialDate),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !context.mounted) {
      return;
    }

    final targetDate = DateUtilsX.formatDate(pickedDate);
    final services = context.read<AppServices>();
    final refreshNotifier = context.read<RefreshNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.stringsRead;

    final copiedRecord = FoodRecord(
      date: targetDate,
      mealName: record.mealName,
      totalWeightG: record.totalWeightG,
      caloriesKcal: record.caloriesKcal,
      proteinG: record.proteinG,
      carbsG: record.carbsG,
      fatG: record.fatG,
      confidence: record.confidence,
      estimationNotes: record.estimationNotes,
      source: record.source,
      items: record.items
          .map(
            (item) => FoodItem(
              name: item.name,
              estimatedWeightG: item.estimatedWeightG,
              caloriesKcal: item.caloriesKcal,
              proteinG: item.proteinG,
              carbsG: item.carbsG,
              fatG: item.fatG,
              notes: item.notes,
            ),
          )
          .toList(),
    );

    try {
      await services.foodRepository.insertFoodRecord(copiedRecord);
      if (!context.mounted) {
        return;
      }
      refreshNotifier.markDataChanged();
      messenger.showSnackBar(
        SnackBar(
          content: Text(strings.foodCopied(record.mealName, targetDate)),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(strings.failedToCopyFood(error))),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Consumer2<RefreshNotifier, SelectedDateNotifier>(
      builder: (context, refresh, selectedDateNotifier, _) {
        refresh.version;
        final selectedDate = selectedDateNotifier.selectedDate;

        return Column(
          children: <Widget>[
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        onPressed: () => _shiftDate(selectedDateNotifier, -1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          DateUtilsX.formatReadable(selectedDate),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _shiftDate(selectedDateNotifier, 1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                      TextButton(
                        onPressed: () =>
                            _pickDate(context, selectedDateNotifier),
                        child: Text(strings.change),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.quickActions,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _openAddFood(context, selectedDate),
                    icon: const Icon(Icons.add),
                    label: Text(strings.addFood),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.estimateNotice,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<FoodRecord>>(
                future: _loadRecords(context, selectedDate),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(strings.failedToLoadFood(snapshot.error!)),
                      ),
                    );
                  }

                  final records = snapshot.data ?? <FoodRecord>[];
                  if (records.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          strings.noFoodRecords,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      bottom:
                          MediaQuery.paddingOf(context).bottom +
                          kBottomNavigationBarHeight +
                          24,
                    ),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return GlassPanel(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _openFoodDetail(context, record.id!),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      record.mealName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      DateUtilsX.formatReadable(record.date),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${record.caloriesKcal.toStringAsFixed(0)} kcal - ${record.totalWeightG.toStringAsFixed(0)} g',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'P ${record.proteinG.toStringAsFixed(1)}  C ${record.carbsG.toStringAsFixed(1)}  F ${record.fatG.toStringAsFixed(1)}',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.7),
                                    ),
                                    child: Text(
                                      strings.sourceLabel(record.source),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  IconButton(
                                    onPressed: () => _copyRecord(
                                      context,
                                      record,
                                      selectedDate,
                                    ),
                                    icon: const Icon(Icons.copy_all_outlined),
                                    tooltip: strings.copy,
                                  ),
                                  const SizedBox(height: 2),
                                  IconButton(
                                    onPressed: () =>
                                        _deleteRecord(context, record),
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: strings.delete,
                                  ),
                                ],
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
          ],
        );
      },
    );
  }
}
