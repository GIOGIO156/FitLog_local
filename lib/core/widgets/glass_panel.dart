import 'package:flutter/material.dart';

import '../fitlog_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 24,
    this.opaque = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    final palette = context.fitLogColors;

    return Container(
      margin: margin,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface.withValues(
            alpha: opaque ? 1 : (palette.isDarkLike ? 0.88 : 0.96),
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: palette.outline.withValues(
              alpha: palette.isDarkLike ? 0.86 : 1,
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.shadow.withValues(
                alpha: palette.isDarkLike ? 0.28 : 0.05,
              ),
              blurRadius: 26,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: padding,
        child: child,
      ),
    );
  }
}
