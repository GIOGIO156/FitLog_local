import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/prompt_templates.dart';
import '../../core/fitlog_theme.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/widgets/fitlog_ui.dart';
import '../../core/widgets/glass_panel.dart';
import 'manual_food_entry_page.dart';
import 'paste_ai_result_page.dart';

class AddFoodPage extends StatelessWidget {
  const AddFoodPage({super.key, this.initialDate});

  final String? initialDate;

  Future<void> _copyPrompt(BuildContext context) async {
    final language = context.languageController.language;
    await Clipboard.setData(
      ClipboardData(text: PromptTemplates.promptForLanguage(language)),
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.strings.promptCopied)));
  }

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
    final palette = context.fitLogColors;

    return Scaffold(
      appBar: AppBar(title: Text(strings.addFood)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: <Widget>[
            FitLogPageHeader(
              title: strings.addFood,
              subtitle: strings.localFirstAiBoundaryHint,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
            ),
            _PromptShortcutButton(
              title: strings.copyAiFoodPrompt,
              subtitle: strings.copyPromptSubtitle,
              onTap: () => _copyPrompt(context),
            ),
            _AddFoodActionCard(
              icon: Icons.paste_outlined,
              color: palette.primaryBright,
              title: strings.pasteAiResult,
              subtitle: strings.pasteAiSubtitle,
              onTap: () => _openPasteAi(context),
            ),
            _AddFoodActionCard(
              icon: Icons.edit_note_outlined,
              color: const Color(0xFFF2B545),
              title: strings.manualEntry,
              subtitle: strings.manualEntrySubtitle,
              onTap: () => _openManualEntry(context),
            ),
            _AddFoodActionCard(
              icon: Icons.photo_camera_outlined,
              color: const Color(0xFF6EA4DF),
              title: strings.photoAiAnalysis,
              subtitle: strings.photoAiPlaceholderHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptShortcutButton extends StatelessWidget {
  const _PromptShortcutButton({
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
                    Icons.content_copy_rounded,
                    color: palette.onPrimary,
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
                              color: palette.onPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.onPrimary.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.strings.copy,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: palette.primaryStrong,
                    ),
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
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

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
        trailing: onTap == null
            ? Text(
                context.strings.comingSoon,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: palette.textMuted,
                ),
              )
            : Icon(Icons.chevron_right_rounded, color: palette.textMuted),
        onTap: onTap,
      ),
    );
  }
}
