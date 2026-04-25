import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/number_utils.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_record.dart';

class FoodDetailPage extends StatefulWidget {
  const FoodDetailPage({super.key, required this.recordId});

  final int recordId;

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  final _formKey = GlobalKey<FormState>();

  final _mealNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _confidenceController = TextEditingController();
  final _notesController = TextEditingController();

  String _date = DateUtilsX.todayKey();
  String _source = '';
  List<_EditableFoodItem> _items = <_EditableFoodItem>[];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mealNameController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _confidenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final record = await context
        .read<AppServices>()
        .foodRepository
        .getFoodRecordById(widget.recordId);

    if (!mounted) {
      return;
    }

    if (record == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Record not found.')));
      Navigator.of(context).pop(false);
      return;
    }

    setState(() {
      _date = record.date;
      _source = record.source;
      _mealNameController.text = record.mealName;
      _weightController.text = record.totalWeightG.toStringAsFixed(1);
      _caloriesController.text = record.caloriesKcal.toStringAsFixed(1);
      _proteinController.text = record.proteinG.toStringAsFixed(1);
      _carbsController.text = record.carbsG.toStringAsFixed(1);
      _fatController.text = record.fatG.toStringAsFixed(1);
      _confidenceController.text = record.confidence?.toStringAsFixed(2) ?? '';
      _notesController.text = record.estimationNotes;
      _items = record.items
          .map(
            (item) => _EditableFoodItem(
              id: item.id,
              name: item.name,
              estimatedWeightG: item.estimatedWeightG.toStringAsFixed(1),
              caloriesKcal: item.caloriesKcal.toStringAsFixed(1),
              proteinG: item.proteinG.toStringAsFixed(1),
              carbsG: item.carbsG.toStringAsFixed(1),
              fatG: item.fatG.toStringAsFixed(1),
              notes: item.notes,
            ),
          )
          .toList();
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateUtilsX.parseDay(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() => _date = DateUtilsX.formatDate(selected));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final updated = FoodRecord(
        id: widget.recordId,
        date: _date,
        mealName: _mealNameController.text.trim(),
        totalWeightG: NumberUtils.toDouble(_weightController.text),
        caloriesKcal: NumberUtils.toDouble(_caloriesController.text),
        proteinG: NumberUtils.toDouble(_proteinController.text),
        carbsG: NumberUtils.toDouble(_carbsController.text),
        fatG: NumberUtils.toDouble(_fatController.text),
        confidence: _confidenceController.text.trim().isEmpty
            ? null
            : NumberUtils.toDouble(_confidenceController.text),
        estimationNotes: _notesController.text.trim(),
        source: _source,
        items: _items.map((item) => item.toFoodItem()).toList(),
      );

      await context.read<AppServices>().foodRepository.updateFoodRecord(updated);

      if (!mounted) {
        return;
      }

      context.read<RefreshNotifier>().markDataChanged();
      messenger.showSnackBar(
        const SnackBar(content: Text('Food record updated.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save food record: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Food Detail')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: <Widget>[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Date'),
                      subtitle: Text(DateUtilsX.formatReadable(_date)),
                      trailing: TextButton(
                        onPressed: _pickDate,
                        child: const Text('Change'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _mealNameController,
                      decoration: const InputDecoration(labelText: 'meal_name'),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Please enter meal name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            decoration: const InputDecoration(
                              labelText: 'total_weight_g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _caloriesController,
                            decoration: const InputDecoration(
                              labelText: 'calories_kcal',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _proteinController,
                            decoration: const InputDecoration(
                              labelText: 'protein_g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _carbsController,
                            decoration: const InputDecoration(
                              labelText: 'carbs_g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _fatController,
                            decoration: const InputDecoration(
                              labelText: 'fat_g',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _confidenceController,
                      decoration: const InputDecoration(
                        labelText: 'confidence',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'estimation_notes',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(label: Text('source: $_source')),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Items',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    if (_items.isEmpty)
                      const Text('No item rows for this record.')
                    else
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: <Widget>[
                                TextFormField(
                                  initialValue: item.name,
                                  decoration: InputDecoration(
                                    labelText: 'Item ${index + 1} name',
                                  ),
                                  onChanged: (value) => item.name = value,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: item.estimatedWeightG,
                                  decoration: const InputDecoration(
                                    labelText: 'estimated_weight_g',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (value) =>
                                      item.estimatedWeightG = value,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: item.caloriesKcal,
                                  decoration: const InputDecoration(
                                    labelText: 'calories_kcal',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (value) =>
                                      item.caloriesKcal = value,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.proteinG,
                                        decoration: const InputDecoration(
                                          labelText: 'protein_g',
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        onChanged: (value) =>
                                            item.proteinG = value,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.carbsG,
                                        decoration: const InputDecoration(
                                          labelText: 'carbs_g',
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        onChanged: (value) =>
                                            item.carbsG = value,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item.fatG,
                                        decoration: const InputDecoration(
                                          labelText: 'fat_g',
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        onChanged: (value) => item.fatG = value,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: item.notes,
                                  decoration: const InputDecoration(
                                    labelText: 'notes',
                                  ),
                                  onChanged: (value) => item.notes = value,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
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
            label: Text(_saving ? 'Saving...' : 'Save Changes'),
          ),
        ),
      ),
    );
  }
}

class _EditableFoodItem {
  _EditableFoodItem({
    this.id,
    required this.name,
    required this.estimatedWeightG,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.notes,
  });

  final int? id;
  String name;
  String estimatedWeightG;
  String caloriesKcal;
  String proteinG;
  String carbsG;
  String fatG;
  String notes;

  FoodItem toFoodItem() {
    return FoodItem(
      id: id,
      name: name.trim().isEmpty ? 'Unnamed item' : name.trim(),
      estimatedWeightG: NumberUtils.toDouble(estimatedWeightG),
      caloriesKcal: NumberUtils.toDouble(caloriesKcal),
      proteinG: NumberUtils.toDouble(proteinG),
      carbsG: NumberUtils.toDouble(carbsG),
      fatG: NumberUtils.toDouble(fatG),
      notes: notes.trim(),
    );
  }
}
