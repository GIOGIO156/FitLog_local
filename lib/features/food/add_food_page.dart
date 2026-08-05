import 'package:flutter/material.dart';

import '../../core/fitlog_theme.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/widgets/fitlog_ui.dart';
import '../../core/widgets/glass_panel.dart';
import 'manual_food_entry_page.dart';
import 'paste_ai_result_page.dart';

class AddFoodPage extends StatelessWidget {
  const AddFoodPage({super.key, this.initialDate});

  final String? initialDate;

  Future<void> _openPasteAi(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => PasteAiResultPage(initialDate: initialDate),
      ),
    );

    if (saved == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openManualEntry(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ManualFoodEntryPage(initialDate: initialDate),
      ),
    );

    if (saved == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.addFood)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: <Widget>[
            FitLogPageHeader(
              title: strings.addFood,
              subtitle: strings.estimateNotice,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            ),
            _AiAssistedEntryButton(
              title: strings.aiAssistedFoodEntry,
              subtitle: strings.aiAssistedFoodEntrySubtitle,
              onTap: () => _openPasteAi(context),
            ),
            _AddFoodActionCard(
              icon: Icons.edit_note_outlined,
              color: const Color(0xFFF2B545),
              title: strings.manualEntry,
              subtitle: strings.manualEntrySubtitle,
              onTap: () => _openManualEntry(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAssistedEntryButton extends StatelessWidget {
  const _AiAssistedEntryButton({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.fitLogColors;
    final foregroundColor = palette.key == FitLogThemeKey.blackOrange
        ? Colors.white
        : palette.onPrimary;
    final gradientColors = palette.key == FitLogThemeKey.blue
        ? <Color>[palette.primaryBright, palette.primarySoftPressed]
        : <Color>[palette.primaryBright, palette.primary];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.auto_fix_high_outlined,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: foregroundColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foregroundColor.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  key: const ValueKey<String>('ai_assisted_entry_chevron_pill'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: palette.primaryStrong,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddFoodActionCard extends StatelessWidget {
  const _AddFoodActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.fitLogColors;
    return GlassPanel(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: FitLogIconCircle(icon: icon, color: color, size: 42),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: palette.textMuted),
        onTap: onTap,
      ),
    );
  }
}
