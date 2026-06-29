import 'package:fitlog_local/export/export_file_naming.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExportFileNaming', () {
    test(
      'includes the first record date and export date when records exist',
      () {
        final baseName = ExportFileNaming.buildBaseName(
          firstRecordDate: '2026-06-01',
          exportedAt: DateTime(2026, 6, 29),
        );

        expect(baseName, 'fitlog_local_2026_06_01_to_2026_06_29');
      },
    );

    test('uses only the export date when no records exist', () {
      final baseName = ExportFileNaming.buildBaseName(
        firstRecordDate: null,
        exportedAt: DateTime(2026, 6, 29),
      );

      expect(baseName, 'fitlog_local_2026_06_29');
    });
  });
}
