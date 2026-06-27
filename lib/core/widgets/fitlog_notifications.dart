import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../fitlog_theme.dart';
import 'fitlog_bottom_nav_layout.dart';

enum _FitLogNotificationTone { success, info, error, action }

class FitLogNotifications {
  FitLogNotifications._();

  static OverlayEntry? _activeEntry;
  static VoidCallback? _dismissActive;

  static void success(BuildContext context, String message) {
    _show(
      context,
      message,
      tone: _FitLogNotificationTone.success,
      duration: const Duration(seconds: 2),
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message,
      tone: _FitLogNotificationTone.info,
      duration: const Duration(seconds: 3),
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message,
      tone: _FitLogNotificationTone.error,
      duration: const Duration(seconds: 4),
    );
  }

  static void action(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    _show(
      context,
      message,
      tone: _FitLogNotificationTone.action,
      actionLabel: actionLabel,
      onPressed: onPressed,
      duration: const Duration(seconds: 5),
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required _FitLogNotificationTone tone,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    _dismissActive?.call();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _showSnackBarFallback(
        context,
        message,
        actionLabel: actionLabel,
        onPressed: onPressed,
      );
      return;
    }

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _FitLogNotificationOverlay(
          message: message,
          tone: tone,
          duration: duration,
          actionLabel: actionLabel,
          onActionPressed: onPressed == null
              ? null
              : () {
                  _remove(entry);
                  onPressed();
                },
          onClose: () => _remove(entry),
          onDisposed: () {
            if (_activeEntry == entry) {
              _activeEntry = null;
              _dismissActive = null;
            }
          },
        );
      },
    );

    _activeEntry = entry;
    _dismissActive = () => _remove(entry);
    overlay.insert(entry);
  }

  static void _remove(OverlayEntry entry) {
    if (entry.mounted) {
      entry.remove();
    }
    if (_activeEntry == entry) {
      _activeEntry = null;
      _dismissActive = null;
    }
  }

  static void _showSnackBarFallback(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null || onPressed == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onPressed),
      ),
    );
  }
}

class _FitLogNotificationOverlay extends StatefulWidget {
  const _FitLogNotificationOverlay({
    required this.message,
    required this.tone,
    required this.duration,
    required this.onClose,
    required this.onDisposed,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final _FitLogNotificationTone tone;
  final Duration duration;
  final VoidCallback onClose;
  final VoidCallback onDisposed;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  State<_FitLogNotificationOverlay> createState() =>
      _FitLogNotificationOverlayState();
}

class _FitLogNotificationOverlayState
    extends State<_FitLogNotificationOverlay> {
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.duration, widget.onClose);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    widget.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topOffset = media.viewPadding.top + 12;
    final bottomOffset =
        math.max(
          media.viewInsets.bottom,
          FitLogBottomNavLayout.footprintFor(context),
        ) +
        12;
    final alignTop =
        widget.tone == _FitLogNotificationTone.success ||
        widget.tone == _FitLogNotificationTone.info;

    return Positioned(
      key: const ValueKey<String>('fitlog_notification_overlay'),
      left: 16,
      right: 16,
      top: alignTop ? topOffset : null,
      bottom: alignTop ? null : bottomOffset,
      child: SafeArea(
        top: false,
        bottom: false,
        child: _FitLogNotificationCard(
          message: widget.message,
          tone: widget.tone,
          actionLabel: widget.actionLabel,
          onActionPressed: widget.onActionPressed,
          onClose: widget.onClose,
        ),
      ),
    );
  }
}

class _FitLogNotificationCard extends StatelessWidget {
  const _FitLogNotificationCard({
    required this.message,
    required this.tone,
    required this.onClose,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final _FitLogNotificationTone tone;
  final VoidCallback onClose;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.fitLogColors;
    final colorScheme = Theme.of(context).colorScheme;
    final spec = switch (tone) {
      _FitLogNotificationTone.success => _NotificationSpec(
        key: const ValueKey<String>('fitlog_notification_success'),
        icon: Icons.check_circle_rounded,
        background: palette.primarySoftSelected,
        border: palette.primaryBright,
        foreground: palette.primaryStrong,
      ),
      _FitLogNotificationTone.info => _NotificationSpec(
        key: const ValueKey<String>('fitlog_notification_info'),
        icon: Icons.info_outline_rounded,
        background: palette.surface,
        border: palette.outline,
        foreground: palette.primaryDeep,
      ),
      _FitLogNotificationTone.error => _NotificationSpec(
        key: const ValueKey<String>('fitlog_notification_error'),
        icon: Icons.error_outline_rounded,
        background: colorScheme.errorContainer,
        border: colorScheme.error.withValues(alpha: 0.55),
        foreground: colorScheme.onErrorContainer,
      ),
      _FitLogNotificationTone.action => _NotificationSpec(
        key: const ValueKey<String>('fitlog_notification_action'),
        icon: Icons.notifications_active_outlined,
        background: palette.surface,
        border: palette.primaryBright,
        foreground: palette.textPrimary,
      ),
    };

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: spec.foreground,
      fontWeight: FontWeight.w800,
      height: 1.2,
    );

    return Material(
      key: spec.key,
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.fromLTRB(14, 11, 12, 11),
        decoration: BoxDecoration(
          color: spec.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: spec.border),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.shadow.withValues(
                alpha: palette.isDarkLike ? 0.28 : 0.1,
              ),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(spec.icon, color: spec.foreground, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...<Widget>[
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey<String>(
                  'fitlog_notification_action_button',
                ),
                onPressed: onActionPressed,
                style: TextButton.styleFrom(
                  foregroundColor: palette.primaryStrong,
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                child: Text(actionLabel!),
              ),
            ] else ...<Widget>[
              const SizedBox(width: 4),
              IconButton(
                key: const ValueKey<String>('fitlog_notification_close_button'),
                visualDensity: VisualDensity.compact,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: spec.foreground),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationSpec {
  const _NotificationSpec({
    required this.key,
    required this.icon,
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Key key;
  final IconData icon;
  final Color background;
  final Color border;
  final Color foreground;
}
