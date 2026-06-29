import 'dart:ui';

import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

abstract class ExportShareService {
  Future<void> shareExportFile({
    required String filePath,
    required String title,
    required String text,
    Rect? sharePositionOrigin,
  });
}

class SystemExportShareService implements ExportShareService {
  const SystemExportShareService();

  @override
  Future<void> shareExportFile({
    required String filePath,
    required String title,
    required String text,
    Rect? sharePositionOrigin,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(filePath, mimeType: _mimeTypeForFile(filePath))],
        title: title,
        subject: title,
        text: text,
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  String? _mimeTypeForFile(String filePath) {
    switch (path.extension(filePath).toLowerCase()) {
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.zip':
        return 'application/zip';
    }
    return null;
  }
}

class NoopExportShareService implements ExportShareService {
  const NoopExportShareService();

  @override
  Future<void> shareExportFile({
    required String filePath,
    required String title,
    required String text,
    Rect? sharePositionOrigin,
  }) async {}
}
