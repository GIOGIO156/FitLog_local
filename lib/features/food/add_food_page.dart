import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/prompt_templates.dart';
import '../../core/localization/localization_extensions.dart';
import '../../core/widgets/glass_panel.dart';
import 'manual_food_entry_page.dart';
import 'paste_ai_result_page.dart';

class AddFoodPage extends StatelessWidget {
  const AddFoodPage({super.key});

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
      MaterialPageRoute<bool>(builder: (_) => const PasteAiResultPage()),
    );

    if (saved == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openManualEntry(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const ManualFoodEntryPage()),
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
      body: ListView(
        children: <Widget>[
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  strings.recommendedFlow,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(strings.step1),
                const SizedBox(height: 4),
                Text(strings.step2),
                const SizedBox(height: 4),
                Text(strings.step3),
                const SizedBox(height: 4),
                Text(strings.step4),
                const SizedBox(height: 4),
                Text(strings.step5),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.45),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        strings.recommendedGpt,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(strings.recommendedGptHint),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _copyPrompt(context),
                  icon: const Icon(Icons.copy_all_outlined),
                  label: Text(strings.copyAiFoodPrompt),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          GlassPanel(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.paste_outlined),
                  title: Text(strings.pasteAiResult),
                  subtitle: Text(strings.pasteAiSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openPasteAi(context),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.edit_note_outlined),
                  title: Text(strings.manualEntry),
                  subtitle: Text(strings.manualEntrySubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openManualEntry(context),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: Text(strings.photoAiAnalysis),
                  subtitle: Text(strings.comingSoon),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
