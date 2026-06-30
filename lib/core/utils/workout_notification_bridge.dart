import 'package:flutter/services.dart';

import '../../domain/services/workout_notification_snapshot_builder.dart';
import '../constants/fitlog_icon_assets.dart';

class WorkoutNotificationBridge {
  WorkoutNotificationBridge._();

  static const MethodChannel _channel = MethodChannel(
    'fitlog.local/workout_notification',
  );

  static Future<void> Function()? _openActiveDraftHandler;

  static void setOpenActiveDraftHandler(Future<void> Function()? handler) {
    _openActiveDraftHandler = handler;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openActiveWorkoutDraft') {
        await _openActiveDraftHandler?.call();
      }
    });
  }

  static Future<void> consumeInitialOpenRequest() async {
    try {
      final shouldOpen =
          await _channel.invokeMethod<bool>('consumeInitialOpenRequest') ??
          false;
      if (shouldOpen) {
        await _openActiveDraftHandler?.call();
      }
    } on MissingPluginException {
      // Desktop and widget tests do not provide the Android channel.
    } on PlatformException {
      // Notification failure should not block local workout editing.
    }
  }

  static Future<void> showOrUpdate(WorkoutNotificationSnapshot snapshot) async {
    try {
      await _channel.invokeMethod<void>('showOrUpdateWorkoutNotification', {
        'title': snapshot.title,
        'body': snapshot.body,
        'appIconAssetPath': FitLogIconAssets.app,
        'exerciseAssetPath': snapshot.exerciseAssetPath,
        'isComplete': snapshot.isComplete,
      });
    } on MissingPluginException {
      // Non-Android platforms should keep the local-first UI usable.
    } on PlatformException {
      // Notification failure should not block local workout editing.
    }
  }

  static Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancelWorkoutNotification');
    } on MissingPluginException {
      // Non-Android platforms should keep the local-first UI usable.
    } on PlatformException {
      // Notification failure should not block local workout editing.
    }
  }
}
