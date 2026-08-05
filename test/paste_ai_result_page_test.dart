import 'package:fitlog_local/core/constants/prompt_templates.dart';
import 'package:fitlog_local/core/fitlog_theme.dart';
import 'package:fitlog_local/core/localization/app_language.dart';
import 'package:fitlog_local/core/localization/language_controller.dart';
import 'package:fitlog_local/features/food/add_food_page.dart';
import 'package:fitlog_local/features/food/paste_ai_result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('AddFoodPage shows one highlighted AI-assisted entry', (
    tester,
  ) async {
    final controller = LanguageController();
    await controller.setLanguage(AppLanguage.chinese);
    addTearDown(controller.dispose);

    await tester.pumpWidget(_buildHarness(controller, const AddFoodPage()));

    expect(find.text('AI 辅助录入'), findsOneWidget);
    expect(find.text('复制 Prompt 给外部 AI\n粘贴返回的完整 JSON'), findsOneWidget);
    expect(find.byIcon(Icons.auto_fix_high_outlined), findsOneWidget);
    expect(find.text('复制 AI 食物提示词'), findsNothing);
    expect(find.text('粘贴外部 AI JSON 并解析'), findsNothing);
    expect(find.text('外部 AI 食物估算流程'), findsNothing);
    expect(find.text('图片 AI 分析'), findsNothing);
    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
  });

  testWidgets('black-orange AI-assisted entry uses white foreground text', (
    tester,
  ) async {
    final controller = LanguageController();
    await controller.setLanguage(AppLanguage.english);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        controller,
        const AddFoodPage(),
        palette: FitLogPalettes.blackOrange,
      ),
    );

    final title = tester.widget<Text>(find.text('AI-assisted Entry'));
    final subtitle = tester.widget<Text>(
      find.text(
        'Copy the prompt to external AI\nPaste the complete JSON response',
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.auto_fix_high_outlined));
    final chevronPill = tester.widget<Container>(
      find.byKey(const ValueKey<String>('ai_assisted_entry_chevron_pill')),
    );
    final chevronDecoration = chevronPill.decoration! as BoxDecoration;

    expect(title.style?.color, Colors.white);
    expect(subtitle.style?.color, Colors.white.withValues(alpha: 0.88));
    expect(icon.color, Colors.white);
    expect(chevronDecoration.color, Colors.white);
  });

  for (final testCase in <({AppLanguage language, String label})>[
    (language: AppLanguage.chinese, label: '复制 AI 食物提示词'),
    (language: AppLanguage.english, label: 'Copy AI Food Prompt'),
  ]) {
    testWidgets(
      'AddFoodPage copy button copies the ${testCase.language.code} prompt',
      (tester) async {
        final controller = LanguageController();
        await controller.setLanguage(testCase.language);
        addTearDown(controller.dispose);

        String? copiedText;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              if (call.method == 'Clipboard.setData') {
                copiedText =
                    (call.arguments as Map<dynamic, dynamic>)['text']
                        as String?;
              }
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null),
        );

        await tester.pumpWidget(_buildHarness(controller, const AddFoodPage()));
        await tester.tap(
          find.text(
            testCase.language == AppLanguage.chinese
                ? 'AI 辅助录入'
                : 'AI-assisted Entry',
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(testCase.label), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey<String>('paste_copy_prompt_button')),
        );
        await tester.pump();

        expect(
          copiedText,
          PromptTemplates.promptForLanguage(testCase.language),
        );
        expect(find.textContaining('ChatGPT or Gemini'), findsNothing);
        expect(find.textContaining('ChatGPT 或 Gemini'), findsNothing);
        expect(
          find.textContaining(
            testCase.language == AppLanguage.chinese
                ? 'Prompt 已复制'
                : 'Prompt copied',
          ),
          findsOneWidget,
        );
      },
    );
  }

  testWidgets('PasteAiResultPage shows the stepped setup card with copy', (
    tester,
  ) async {
    final controller = LanguageController();
    await controller.setLanguage(AppLanguage.chinese);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(controller, const PasteAiResultPage()),
    );

    expect(find.text('AI 辅助录入'), findsOneWidget);
    expect(find.text('建立长期食物估算对话'), findsOneWidget);
    expect(find.text('使用方式'), findsOneWidget);
    expect(find.text('①'), findsOneWidget);
    expect(find.text('新对话发送一次 Prompt'), findsOneWidget);
    expect(find.text('在外部 AI 新对话中发送一次此 Prompt。'), findsNothing);
    expect(find.text('②'), findsOneWidget);
    expect(find.text('上传食物图片或补充描述'), findsOneWidget);
    expect(find.text('之后上传食物图片，或补充文字描述。'), findsNothing);
    expect(find.text('③'), findsOneWidget);
    expect(find.text('粘贴完整 JSON 到下方解析'), findsOneWidget);
    expect(find.text('将返回的完整 JSON 粘贴到下方解析。'), findsNothing);
    expect(find.text('推荐 GPT'), findsOneWidget);
    expect(
      find.text('推荐在 ChatGPT 中使用「FitLog 中文助手」或「FitLog Estimator」。'),
      findsOneWidget,
    );
    expect(find.text('可用外部 AI'), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('paste_prompt_setup_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('paste_json_editor_card')),
      findsOneWidget,
    );
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(
      find.byKey(const ValueKey<String>('paste_keyboard_layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('paste_copy_prompt_button')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.content_copy_rounded), findsOneWidget);
  });

  testWidgets('PasteAiResultPage keeps the English card copy localized', (
    tester,
  ) async {
    final controller = LanguageController();
    await controller.setLanguage(AppLanguage.english);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(controller, const PasteAiResultPage()),
    );

    expect(find.text('AI-assisted Entry'), findsOneWidget);
    expect(find.text('Set up a reusable food-estimation chat'), findsOneWidget);
    expect(find.text('How to use'), findsOneWidget);
    expect(
      find.text('Send the Prompt once in a new external AI chat'),
      findsOneWidget,
    );
    expect(
      find.text('Send this Prompt once in a new external AI chat.'),
      findsNothing,
    );
    expect(find.text('Upload food photos or add descriptions'), findsOneWidget);
    expect(
      find.text('Afterward, upload food photos or add descriptions.'),
      findsNothing,
    );
    expect(
      find.text('Paste the complete JSON response below for parsing.'),
      findsNothing,
    );
    expect(
      find.text('Paste the complete JSON below for parsing'),
      findsOneWidget,
    );
    expect(find.text('Recommended GPTs'), findsOneWidget);
    expect(
      find.text(
        'For ChatGPT, we recommend “FitLog 中文助手” or “FitLog Estimator”.',
      ),
      findsOneWidget,
    );
    expect(find.text('Supported external AI'), findsNothing);
  });

  testWidgets(
    'keyboard inset fades prompt and translates JSON editor by Agent formula',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = LanguageController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildHarness(controller, const PasteAiResultPage()),
      );

      final editor = find.byKey(const ValueKey<String>('paste_json_editor'));
      final promptSlot = find.byKey(
        const ValueKey<String>('paste_prompt_supporting_slot'),
      );
      final actionSlot = find.byKey(
        const ValueKey<String>('paste_parse_supporting_slot'),
      );
      final promptFade = find.byKey(
        const ValueKey<String>('paste_prompt_keyboard_fade'),
      );

      final initialEditorRect = tester.getRect(editor);
      final initialPromptRect = tester.getRect(promptSlot);
      final initialActionRect = tester.getRect(actionSlot);
      final initialEditorRender = tester.renderObject(editor);
      final initialPromptRender = tester.renderObject(promptSlot);
      final initialActionRender = tester.renderObject(actionSlot);
      final textField = tester.widget<TextField>(editor);
      final editorController = textField.controller;
      final editorFocusNode = textField.focusNode;
      expect(
        find.byKey(const ValueKey<String>('paste_focus_background')),
        findsNothing,
      );
      expect(tester.widget<Opacity>(promptFade).opacity, 1);

      await tester.tap(editor);
      await tester.pump();
      await tester.enterText(editor, '{"meal_name":"test"}');
      expect(editorFocusNode?.hasFocus, isTrue);
      expect(tester.widget<Opacity>(promptFade).opacity, 1);

      final editorTops = <double, double>{};
      final promptOpacities = <double, double>{};
      for (final inset in <double>[40, 52, 64, 80, 180, 336]) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump();

        final currentRect = tester.getRect(editor);
        editorTops[inset] = currentRect.top;
        promptOpacities[inset] = tester.widget<Opacity>(promptFade).opacity;
        expect(currentRect.size, initialEditorRect.size);
        expect(tester.renderObject(editor), same(initialEditorRender));
        expect(tester.renderObject(promptSlot), same(initialPromptRender));
        expect(tester.renderObject(actionSlot), same(initialActionRender));
        expect(initialEditorRender.debugNeedsLayout, isFalse);
        expect(initialPromptRender.debugNeedsLayout, isFalse);
        expect(initialActionRender.debugNeedsLayout, isFalse);
        if (inset >= 336) {
          final keyboardTop =
              tester.view.physicalSize.height / tester.view.devicePixelRatio -
              inset;
          expect(currentRect.bottom, lessThanOrEqualTo(keyboardTop - 14));
        }
        expect(tester.getRect(promptSlot), initialPromptRect);
        expect(tester.getRect(actionSlot), initialActionRect);
        expect(
          tester
              .widget<IgnorePointer>(
                find.byKey(
                  const ValueKey<String>('paste_prompt_keyboard_guard'),
                ),
              )
              .ignoring,
          isTrue,
        );
        expect(
          tester
              .widget<IgnorePointer>(
                find.byKey(
                  const ValueKey<String>('paste_action_keyboard_guard'),
                ),
              )
              .ignoring,
          isTrue,
        );
      }

      for (final inset in <double>[40, 52, 64, 80, 180, 336]) {
        expect(
          editorTops[inset],
          closeTo(
            initialEditorRect.top - _expectedKeyboardTranslation(inset),
            0.001,
          ),
        );
        expect(
          promptOpacities[inset],
          closeTo(_expectedPromptOpacity(inset), 0.001),
        );
      }
      expect(_expectedKeyboardTranslation(40), 0);
      expect(_expectedKeyboardTranslation(64), 12);
      expect(_expectedKeyboardTranslation(64.001), closeTo(12.001, 0.001));
      expect(promptOpacities[40], allOf(greaterThan(0), lessThan(1)));
      expect(promptOpacities[80], lessThan(promptOpacities[40]!));
      expect(promptOpacities[180], 0);

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();

      expect(tester.getRect(editor), initialEditorRect);
      expect(tester.getRect(promptSlot), initialPromptRect);
      expect(tester.getRect(actionSlot), initialActionRect);
      expect(tester.widget<Opacity>(promptFade).opacity, 1);
      expect(
        tester
            .widget<IgnorePointer>(
              find.byKey(const ValueKey<String>('paste_prompt_keyboard_guard')),
            )
            .ignoring,
        isFalse,
      );
      expect(
        tester
            .widget<IgnorePointer>(
              find.byKey(const ValueKey<String>('paste_action_keyboard_guard')),
            )
            .ignoring,
        isFalse,
      );
      expect(editorFocusNode?.hasFocus, isTrue);
      expect(editorController?.text, '{"meal_name":"test"}');
    },
  );

  testWidgets('PasteAiResultPage remains bounded on a short viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = LanguageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(controller, const PasteAiResultPage()),
    );

    final editor = find.byKey(const ValueKey<String>('paste_json_editor'));
    final initialSize = tester.getSize(editor);
    expect(initialSize.height, greaterThan(0));
    expect(tester.takeException(), isNull);

    await tester.tap(editor);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pump();

    expect(tester.getSize(editor), initialSize);
    expect(tester.getRect(editor).top, greaterThanOrEqualTo(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'expanded JSON waits for keyboard close and syncs text selection',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = LanguageController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _buildHarness(
          controller,
          const PasteAiResultPage(),
          palette: FitLogPalettes.blackOrange,
        ),
      );

      final compactEditor = find.byKey(
        const ValueKey<String>('paste_json_editor'),
      );
      final expandButton = find.byKey(
        const ValueKey<String>('paste_expand_json_editor'),
      );
      await tester.tap(compactEditor);
      await tester.enterText(compactEditor, '{"meal_name":"before"}');
      final compactField = tester.widget<TextField>(compactEditor);
      compactField.controller!.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 8,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      await tester.pump();

      tester.widget<IconButton>(expandButton).onPressed!.call();
      await tester.pump();

      expect(compactField.focusNode?.hasFocus, isFalse);
      expect(
        find.byKey(const ValueKey<String>('paste_expanded_json_modal')),
        findsNothing,
      );

      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.pump();
      await tester.pumpAndSettle();

      final modal = find.byKey(
        const ValueKey<String>('paste_expanded_json_modal'),
      );
      final expandedEditor = find.byKey(
        const ValueKey<String>('paste_expanded_json_field'),
      );
      expect(modal, findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('paste_modal_backdrop_filter')),
        findsOneWidget,
      );
      expect(find.text('JSON editor'), findsOneWidget);
      expect(
        find.descendant(
          of: modal,
          matching: find.byKey(
            const ValueKey<String>('paste_prompt_setup_card'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: modal,
          matching: find.byKey(
            const ValueKey<String>('paste_copy_prompt_button'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: modal,
          matching: find.byKey(const ValueKey<String>('paste_ai_parse_button')),
        ),
        findsNothing,
      );

      final expandedField = tester.widget<TextField>(expandedEditor);
      expect(expandedField.autofocus, isFalse);
      expect(expandedField.focusNode?.hasFocus, isFalse);
      expect(expandedField.controller?.text, '{"meal_name":"before"}');
      expect(
        expandedField.controller?.selection,
        const TextSelection(baseOffset: 2, extentOffset: 8),
      );

      await tester.tap(expandedEditor);
      await tester.enterText(expandedEditor, '{"meal_name":"after"}');
      expandedField.controller!.selection = const TextSelection.collapsed(
        offset: 12,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('paste_collapse_json_editor')),
      );
      await tester.pumpAndSettle();

      expect(modal, findsNothing);
      expect(compactField.controller?.text, '{"meal_name":"after"}');
      expect(
        compactField.controller?.selection,
        const TextSelection.collapsed(offset: 12),
      );
      expect(compactField.focusNode?.hasFocus, isFalse);
    },
  );

  testWidgets('empty and invalid JSON keep input and show parse errors', (
    tester,
  ) async {
    final controller = LanguageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(controller, const PasteAiResultPage()),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('paste_ai_parse_button')),
    );
    await tester.pump();
    expect(find.text('Please paste JSON first.'), findsOneWidget);

    final editor = find.byKey(const ValueKey<String>('paste_json_editor'));
    await tester.enterText(editor, '{');
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('paste_ai_parse_button')),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.startsWith('Unable to parse JSON:') ?? false),
      ),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(editor).controller?.text, '{');
  });

  testWidgets('valid JSON parse opens the preview flow', (tester) async {
    final controller = LanguageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _buildHarness(
        controller,
        const PasteAiResultPage(initialDate: '2026-08-05'),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('paste_json_editor')),
      '''
{
  "meal_name": "Chicken and rice",
  "total_weight_g": 300,
  "total_calories_kcal": 460,
  "protein_g": 40,
  "carbs_g": 52,
  "fat_g": 10,
  "confidence": 0.85,
  "items": [
    {
      "name": "Chicken breast",
      "estimated_weight_g": 150,
      "calories_kcal": 250,
      "protein_g": 40,
      "carbs_g": 0,
      "fat_g": 6,
      "notes": "Cooked weight"
    },
    {
      "name": "Rice",
      "estimated_weight_g": 150,
      "calories_kcal": 210,
      "protein_g": 0,
      "carbs_g": 52,
      "fat_g": 4,
      "notes": "Cooked weight"
    }
  ],
  "estimation_notes": ""
}
''',
    );
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey<String>('paste_ai_parse_button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preview AI Result'), findsOneWidget);
    expect(find.text('Chicken and rice'), findsOneWidget);
  });
}

Widget _buildHarness(
  LanguageController controller,
  Widget home, {
  FitLogColors palette = FitLogPalettes.green,
}) {
  return ChangeNotifierProvider<LanguageController>.value(
    value: controller,
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: palette.brightness,
        scaffoldBackgroundColor: palette.background,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: palette.textMuted),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: palette.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: palette.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: palette.primaryBright, width: 1.4),
          ),
          filled: true,
          fillColor: palette.surfaceVariant,
          isDense: true,
        ),
        extensions: <ThemeExtension<dynamic>>[palette],
      ),
      home: home,
    ),
  );
}

double _expectedKeyboardTranslation(double inset) {
  if (inset <= 40) {
    return 0;
  }
  if (inset >= 64) {
    return inset - 52;
  }

  final progress = (inset - 40) / 24;
  return 12 * progress * progress;
}

double _expectedPromptOpacity(double inset) {
  final linear = (inset / 180).clamp(0.0, 1.0).toDouble();
  final progress = Curves.easeInOutCubic.transform(linear);
  return 1 - progress;
}
