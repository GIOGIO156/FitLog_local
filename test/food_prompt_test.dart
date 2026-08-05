import 'package:fitlog_local/core/constants/prompt_templates.dart';
import 'package:fitlog_local/core/fitlog_theme.dart';
import 'package:fitlog_local/core/localization/app_language.dart';
import 'package:fitlog_local/core/localization/language_controller.dart';
import 'package:fitlog_local/domain/services/nutrition_calculator.dart';
import 'package:fitlog_local/features/food/add_food_page.dart';
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

  for (final testCase in <({AppLanguage language, String buttonLabel})>[
    (language: AppLanguage.chinese, buttonLabel: '复制 AI 食物提示词'),
    (language: AppLanguage.english, buttonLabel: 'Copy AI Food Prompt'),
  ]) {
    testWidgets('${testCase.language.code} mode copies its localized prompt', (
      tester,
    ) async {
      final controller = LanguageController();
      await controller.setLanguage(testCase.language);
      addTearDown(controller.dispose);

      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedText =
                  (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );

      await tester.pumpWidget(_buildTestApp(controller));
      await tester.tap(
        find.text(
          testCase.language == AppLanguage.chinese
              ? 'AI 辅助录入'
              : 'AI-assisted Entry',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(testCase.buttonLabel), findsOneWidget);

      await tester.ensureVisible(find.byIcon(Icons.content_copy_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.content_copy_rounded));
      await tester.pump();

      expect(copiedText, PromptTemplates.promptForLanguage(testCase.language));
      if (testCase.language == AppLanguage.chinese) {
        expect(copiedText, contains('本次对话后续所有消息的长期规则'));
        expect(copiedText, contains('文字和图片是并列、互补的证据'));
        expect(copiedText, contains('自然语言值使用用户当前消息的主要语言'));
      } else {
        expect(copiedText, contains('persistent rules for all later messages'));
        expect(copiedText, contains('Text and photos are parallel'));
        expect(copiedText, contains('main language of the user'));
      }
    });
  }

  test('both prompts preserve schema and require complete reconciled JSON', () {
    for (final prompt in <String>[
      PromptTemplates.aiFoodPromptZh,
      PromptTemplates.aiFoodPromptEn,
    ]) {
      expect(prompt, contains('"estimation_notes"'));
      expect(prompt, isNot(contains('"comment"')));
      expect(prompt, contains('"meal_name"'));
      expect(prompt, contains('"items"'));
      expect(prompt, contains('"estimated_weight_g"'));
      expect(prompt, contains('"total_calories_kcal"'));
    }

    expect(PromptTemplates.aiFoodPromptZh, contains('长期规则'));
    expect(PromptTemplates.aiFoodPromptZh, contains('完整 JSON'));
    expect(PromptTemplates.aiFoodPromptZh, contains('五组加总'));
    expect(PromptTemplates.aiFoodPromptZh, contains('items 是重量和营养总计的唯一计算来源'));

    expect(PromptTemplates.aiFoodPromptEn, contains('persistent rules'));
    expect(PromptTemplates.aiFoodPromptEn, contains('complete JSON'));
    expect(PromptTemplates.aiFoodPromptEn, contains('the five sums'));
    expect(
      PromptTemplates.aiFoodPromptEn,
      contains('items are the only source'),
    );
  });

  test('existing AI food JSON schema still parses with estimation_notes', () {
    final record = NutritionCalculator.parseAiFoodJson('''
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
''');

    expect(record.mealName, 'Chicken and rice');
    expect(record.totalWeightG, 300);
    expect(record.caloriesKcal, 460);
    expect(record.items, hasLength(2));
    expect(record.estimationNotes, isEmpty);
  });
}

Widget _buildTestApp(LanguageController controller) {
  final palette = FitLogPalettes.green;
  return ChangeNotifierProvider<LanguageController>.value(
    value: controller,
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: palette.brightness,
        scaffoldBackgroundColor: palette.background,
        extensions: <ThemeExtension<dynamic>>[palette],
      ),
      home: const AddFoodPage(),
    ),
  );
}
