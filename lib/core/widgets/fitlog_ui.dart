import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../localization/localization_extensions.dart';
import '../utils/date_utils.dart';

class FitLogPageHeader extends StatelessWidget {
  const FitLogPageHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 12),
  });

  final String title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      color: const Color(0xFF152013),
    );
    final subtitleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF61715D),
      height: 1.4,
    );

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                titleWidget ?? Text(title, style: titleStyle),
                if ((subtitle ?? '').trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(subtitle!, style: subtitleStyle),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class FitLogSectionHeader extends StatelessWidget {
  const FitLogSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onTap,
    this.padding = const EdgeInsets.only(bottom: 12),
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final actionEnabled =
        onTap != null && (actionLabel ?? '').trim().isNotEmpty;
    return Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF152013),
              ),
            ),
          ),
          if (actionEnabled)
            TextButton(onPressed: onTap, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class FitLogIconCircle extends StatelessWidget {
  const FitLogIconCircle({
    super.key,
    required this.icon,
    required this.color,
    this.size = 42,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    );
  }
}

class FitLogActionIconButton extends StatelessWidget {
  const FitLogActionIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF234120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class FitLogDateStrip extends StatelessWidget {
  const FitLogDateStrip({
    super.key,
    required this.selectedDate,
    required this.onSelect,
    required this.onOpenPicker,
  });

  final String selectedDate;
  final ValueChanged<String> onSelect;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    final selected = DateUtilsX.parseDay(selectedDate);
    final startOfWeek = selected.subtract(Duration(days: selected.weekday - 1));

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                DateUtilsX.formatReadable(selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF152013),
                ),
              ),
            ),
            FitLogActionIconButton(
              icon: Icons.calendar_today_outlined,
              tooltip: context.strings.change,
              onPressed: onOpenPicker,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List<Widget>.generate(7, (index) {
            final day = startOfWeek.add(Duration(days: index));
            final dayKey = DateUtilsX.formatDate(day);
            final isSelected = dayKey == selectedDate;
            final weekdayKey = AppConstants.weekdayKeyFromDateTime(day);

            return Expanded(
              child: GestureDetector(
                onTap: () => onSelect(dayKey),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7BC75B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7BC75B)
                          : const Color(0xFFE2ECDD),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        context.strings.weekdayUltraShortLabel(weekdayKey),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.92)
                              : const Color(0xFF75856F),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF152013),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
