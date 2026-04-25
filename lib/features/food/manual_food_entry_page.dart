import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/number_utils.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_record.dart';

class ManualFoodEntryPage extends StatefulWidget {
  const ManualFoodEntryPage({super.key});

  @override
  State<ManualFoodEntryPage> createState() => _ManualFoodEntryPageState();
}

class _ManualFoodEntryPageState extends State<ManualFoodEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final _mealNameController = TextEditingController();
  final _weightController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _notesController = TextEditingController();

  String _date = DateUtilsX.todayKey();
  bool _saving = false;

  @override
  void dispose() {
    _mealNameController.dispose();
    _weightController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
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

    final record = FoodRecord(
      date: _date,
      mealName: _mealNameController.text.trim(),
      totalWeightG: NumberUtils.toDouble(_weightController.text),
      caloriesKcal: NumberUtils.toDouble(_caloriesController.text),
      proteinG: NumberUtils.toDouble(_proteinController.text),
      carbsG: NumberUtils.toDouble(_carbsController.text),
      fatG: NumberUtils.toDouble(_fatController.text),
      confidence: null,
      estimationNotes: _notesController.text.trim(),
      source: AppConstants.sourceManual,
      items: const <FoodItem>[],
    );

    await context.read<AppServices>().foodRepository.insertFoodRecord(record);

    if (!mounted) {
      return;
    }

    context.read<RefreshNotifier>().markDataChanged();
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Manual food record saved.')));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
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
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'notes'),
              maxLines: 3,
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
            label: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ),
      ),
    );
  }
}
