import 'package:fitlog_local/core/fitlog_theme.dart';
import 'package:fitlog_local/core/widgets/exercise_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('non-black themes keep soft body-part badge backgrounds', (
    tester,
  ) async {
    const bodyPartColor = Color(0xFFEF4444);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExerciseThumbnail(
            bodyPart: 'Chest',
            exerciseName: 'Barbell Flat Bench Press',
            color: bodyPartColor,
          ),
        ),
      ),
    );

    final thumbnailContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ExerciseThumbnail),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = thumbnailContainer.decoration! as BoxDecoration;

    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, bodyPartColor.withValues(alpha: 0.14));
    expect(decoration.border, isNull);
  });

  testWidgets(
    'black theme gives every body part a low-glare fill and distinct ring',
    (tester) async {
      const expectedFills = <String, Color>{
        'Chest': Color(0xFF402824),
        'Back': Color(0xFF27303D),
        'Legs': Color(0xFF41341C),
        'Glutes': Color(0xFFD66A3C),
        'Shoulders': Color(0xFF626A72),
        'Arms': Color(0xFF203838),
        'Core': Color(0xFF402830),
        'Cardio': Color(0xFF21382D),
        'Full Body': Color(0xFF68727E),
      };
      const expectedRings = <String, Color>{
        'Chest': Color(0xFF8B5A52),
        'Back': Color(0xFF60718A),
        'Legs': Color(0xFF9A7D40),
        'Glutes': Color(0xFFF1A073),
        'Shoulders': Color(0xFF9AA4AD),
        'Arms': Color(0xFF5D8989),
        'Core': Color(0xFF8B5A68),
        'Cardio': Color(0xFF5F8B70),
        'Full Body': Color(0xFFA0AABD),
      };
      const exerciseNames = <String, String>{
        'Chest': 'Barbell Flat Bench Press',
        'Back': 'Pull-up',
        'Legs': 'Squat',
        'Glutes': 'Barbell Hip Thrust',
        'Shoulders': 'Barbell Overhead Press',
        'Arms': 'Barbell Biceps Curl',
        'Core': 'Crunch',
        'Cardio': 'Running',
        'Full Body': 'Kettlebell Swing',
      };

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const <ThemeExtension<dynamic>>[
              FitLogPalettes.blackOrange,
            ],
          ),
          home: Scaffold(
            body: Column(
              children: expectedFills.keys
                  .map(
                    (bodyPart) => ExerciseThumbnail(
                      bodyPart: bodyPart,
                      exerciseName: exerciseNames[bodyPart]!,
                      color: Colors.white,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );

      final decorations = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(ExerciseThumbnail),
              matching: find.byType(Container),
            ),
          )
          .map((container) => container.decoration! as BoxDecoration)
          .toList();

      expect(
        decorations.map((decoration) => decoration.color).toList(),
        expectedFills.values.toList(),
      );
      expect(
        decorations
            .map((decoration) => (decoration.border! as Border).top.color)
            .toList(),
        expectedRings.values.toList(),
      );
      expect(expectedFills.values.toSet(), hasLength(expectedFills.length));
      expect(expectedRings.values.toSet(), hasLength(expectedRings.length));
    },
  );
}
