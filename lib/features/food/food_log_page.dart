import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/glass_panel.dart';
import '../../domain/models/food_record.dart';
import 'add_food_page.dart';
import 'food_detail_page.dart';

class FoodLogPage extends StatefulWidget {
  const FoodLogPage({super.key});

  @override
  State<FoodLogPage> createState() => _FoodLogPageState();
}

class _FoodLogPageState extends State<FoodLogPage> {
  Future<List<FoodRecord>> _loadRecords(BuildContext context) {
    return context.read<AppServices>().foodRepository.getAllFoodRecords();
  }

  Future<void> _openAddFood(BuildContext context) async {
    final saved = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute<bool>(builder: (_) => const AddFoodPage()));

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

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Consumer<RefreshNotifier>(
      builder: (context, refresh, _) {
        refresh.version;

        return Column(
          children: <Widget>[
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    strings.quickActions,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _openAddFood(context),
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
                future: _loadRecords(context),
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
                    padding: const EdgeInsets.only(bottom: 24),
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
