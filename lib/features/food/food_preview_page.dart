import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/number_utils.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_record.dart';

class FoodPreviewPage extends StatefulWidget {
  const FoodPreviewPage({super.key, required this.initialRecord});

  final FoodRecord initialRecord;

  @override
  State<FoodPreviewPage> createState() => _FoodPreviewPageState();
}

class _FoodPreviewPageState extends State<FoodPreviewPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _mealNameController;
  late final TextEditingController _weightController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _confidenceController;
  late final TextEditingController _notesController;

  late String _date;
  late List<_EditableFoodItem> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final record = widget.initialRecord;
    _date = record.date;
    _mealNameController = TextEditingController(text: record.mealName);
    _weightController = TextEditingController(
      text: record.totalWeightG.toStringAsFixed(1),
    );
    _caloriesController = TextEditingController(
      text: record.caloriesKcal.toStringAsFixed(1),
    );
    _proteinController = TextEditingController(
      text: record.proteinG.toStringAsFixed(1),
    );
    _carbsController = TextEditingController(
      text: record.carbsG.toStringAsFixed(1),
    );
    _fatController = TextEditingController(
      text: record.fatG.toStringAsFixed(1),
    );
    _confidenceController = TextEditingController(
      text: record.confidence?.toStringAsFixed(2) ?? '',
    );
    _notesController = TextEditingController(text: record.estimationNotes);
    _items = record.items
        .map(
          (item) => _EditableFoodItem(
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

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateUtilsX.parseDay(_date),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _date = DateUtilsX.formatDate(selected);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);
    final services = context.read<AppServices>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      final record = FoodRecord(
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
        source: widget.initialRecord.source,
        items: _items.map((item) => item.toFoodItem()).toList(),
      );

      await services.foodRepository.insertFoodRecord(record);

      if (!mounted) {
        return;
      }

      context.read<RefreshNotifier>().markDataChanged();
      messenger.showSnackBar(
        const SnackBar(content: Text('Food record saved.')),
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

  Widget _buildMainFields() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
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
            TextFormField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'total_weight_g'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'total_calories_kcal',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _proteinController,
              decoration: const InputDecoration(labelText: 'protein_g'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _carbsController,
              decoration: const InputDecoration(labelText: 'carbs_g'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _fatController,
              decoration: const InputDecoration(labelText: 'fat_g'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confidenceController,
              decoration: const InputDecoration(labelText: 'confidence'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'estimation_notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateUtilsX.formatReadable(_date)),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Change'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItems() {
    if (_items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No item list detected in JSON.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => item.estimatedWeightG = value,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: item.caloriesKcal,
                        decoration: const InputDecoration(
                          labelText: 'calories_kcal',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => item.caloriesKcal = value,
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
                              onChanged: (value) => item.proteinG = value,
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
                              onChanged: (value) => item.carbsG = value,
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
                        decoration: const InputDecoration(labelText: 'notes'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview AI Result')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: <Widget>[_buildMainFields(), _buildItems()],
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
            label: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ),
      ),
    );
  }
}

class _EditableFoodItem {
  _EditableFoodItem({
    required this.name,
    required this.estimatedWeightG,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.notes,
  });

  String name;
  String estimatedWeightG;
  String caloriesKcal;
  String proteinG;
  String carbsG;
  String fatG;
  String notes;

  FoodItem toFoodItem() {
    return FoodItem(
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
