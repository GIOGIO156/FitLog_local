import 'package:fitlog_local/domain/models/workout_record_draft.dart';
import 'package:fitlog_local/features/workout/workout_editor_resume_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await const WorkoutEditorResumeStore().clear();
  });

  test('active 29-minute new draft auto resumes', () async {
    const store = WorkoutEditorResumeStore();
    final now = DateTime(2026, 7, 27, 10);

    await store.markActive();

    expect(
      await store.shouldAutoResume(
        _draft(updatedAt: now.subtract(const Duration(minutes: 29))),
        now,
      ),
      isTrue,
    );
  });

  test('active exactly 30-minute new draft auto resumes', () async {
    const store = WorkoutEditorResumeStore();
    final now = DateTime(2026, 7, 27, 10);

    await store.markActive();

    expect(
      await store.shouldAutoResume(
        _draft(updatedAt: now.subtract(const Duration(minutes: 30))),
        now,
      ),
      isTrue,
    );
  });

  test('active 31-minute new draft does not auto resume', () async {
    const store = WorkoutEditorResumeStore();
    final now = DateTime(2026, 7, 27, 10);

    await store.markActive();

    expect(
      await store.shouldAutoResume(
        _draft(updatedAt: now.subtract(const Duration(minutes: 31))),
        now,
      ),
      isFalse,
    );
  });

  test('new draft without active marker does not auto resume', () async {
    const store = WorkoutEditorResumeStore();
    final now = DateTime(2026, 7, 27, 10);

    expect(
      await store.shouldAutoResume(
        _draft(updatedAt: now.subtract(const Duration(minutes: 5))),
        now,
      ),
      isFalse,
    );
  });

  test(
    'edit draft never auto resumes from the new-workout editor marker',
    () async {
      const store = WorkoutEditorResumeStore();
      final now = DateTime(2026, 7, 27, 10);

      await store.markActive();

      expect(
        await store.shouldAutoResume(
          _draft(
            kind: WorkoutRecordDraft.kindEditRecord,
            updatedAt: now.subtract(const Duration(minutes: 5)),
          ),
          now,
        ),
        isFalse,
      );
    },
  );

  test('clear removes the active marker', () async {
    const store = WorkoutEditorResumeStore();
    final now = DateTime(2026, 7, 27, 10);

    await store.markActive();
    await store.clear();

    expect(
      await store.shouldAutoResume(
        _draft(updatedAt: now.subtract(const Duration(minutes: 5))),
        now,
      ),
      isFalse,
    );
  });
}

WorkoutRecordDraft _draft({
  String kind = WorkoutRecordDraft.kindNewRecord,
  required DateTime updatedAt,
}) {
  final timestamp = updatedAt.toIso8601String();
  return WorkoutRecordDraft(
    id: WorkoutRecordDraft.activeDraftId,
    kind: kind,
    date: '2026-07-27',
    recordName: 'Draft',
    notes: '',
    payloadJson: '{"exercises":[]}',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
