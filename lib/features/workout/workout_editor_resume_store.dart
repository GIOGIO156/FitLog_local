import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/workout_record_draft.dart';

class WorkoutEditorResumeStore {
  const WorkoutEditorResumeStore();

  static const Duration autoResumeWindow = Duration(minutes: 30);
  static const String activeKey = 'workout_editor_new_draft_active';

  Future<void> markActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(activeKey, true);
    } catch (_) {
      // Draft persistence remains the source of truth if lightweight state fails.
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(activeKey);
    } catch (_) {
      // Draft persistence remains the source of truth if lightweight state fails.
    }
  }

  Future<bool> shouldAutoResume(WorkoutRecordDraft? draft, DateTime now) async {
    if (draft == null || draft.kind != WorkoutRecordDraft.kindNewRecord) {
      return false;
    }
    if (!await _isActive()) {
      return false;
    }
    final updatedAt = DateTime.tryParse(draft.updatedAt);
    if (updatedAt == null) {
      return false;
    }
    final age = now.difference(updatedAt);
    return !age.isNegative && age <= autoResumeWindow;
  }

  Future<bool> _isActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(activeKey) ?? false;
    } catch (_) {
      return false;
    }
  }
}
