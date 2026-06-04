import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/number_utils.dart';
import '../../domain/models/food_item.dart';
import '../../domain/models/food_record.dart';
import 'food_form_support.dart';

class ManualFoodEntryPage extends StatefulWidget {
  const ManualFoodEntryPage({super.key, this.initialDate});

  final String? initialDate;

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

  late String _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateUtilsX.todayKey();
  }

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
      messenger.showSnackBar(
        const SnackBar(content: Text('Manual food record saved.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to save manual record: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
            FoodDateTile(date: _date, onChange: _pickDate),
            const SizedBox(height: 8),
            FoodFormField(
              controller: _mealNameController,
              labelText: 'meal_name',
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Please enter meal name';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            FoodFormField(
              controller: _weightController,
              labelText: 'total_weight_g',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            FoodFormField(
              controller: _caloriesController,
              labelText: 'total_calories_kcal',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            FoodFormField(
              controller: _proteinController,
              labelText: 'protein_g',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            FoodFormField(
              controller: _carbsController,
              labelText: 'carbs_g',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            FoodFormField(
              controller: _fatController,
              labelText: 'fat_g',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 10),
            FoodFormField(
              controller: _notesController,
              labelText: 'notes',
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FoodSaveButton(
            saving: _saving,
            label: 'Save',
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
