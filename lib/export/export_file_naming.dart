import '../core/utils/date_utils.dart';

class ExportFileNaming {
  ExportFileNaming._();

  static String buildBaseName({
    required String? firstRecordDate,
    required DateTime exportedAt,
  }) {
    final exportDate = DateUtilsX.formatForExport(exportedAt);
    if (firstRecordDate == null) {
      return 'fitlog_local_$exportDate';
    }

    final startDate = DateUtilsX.formatForExport(
      DateUtilsX.parseDay(firstRecordDate),
    );
    return 'fitlog_local_${startDate}_to_$exportDate';
  }
}
