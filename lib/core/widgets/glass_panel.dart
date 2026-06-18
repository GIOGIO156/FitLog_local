import 'package:flutter/material.dart';

import '../fitlog_theme.dart';

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.borderRadius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = context.fitLogColors;

    return Container(
      margin: margin,
      child: Container(
        decoration: BoxDecoration(
          color: palette.surface.withValues(
            alpha: palette.isDarkLike ? 1 : 0.96,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: palette.outline),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: palette.shadow.withValues(
                alpha: palette.isDarkLike ? 0.25 : 0.05,
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
