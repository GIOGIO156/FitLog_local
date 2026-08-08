import 'package:flutter/material.dart';

import '../fitlog_theme.dart';
import 'fitlog_ui.dart';

class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({
    super.key,
    required this.bodyPart,
    required this.exerciseName,
    required this.color,
    this.size = 56,
  });

  final String bodyPart;
  final String exerciseName;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.fitLogColors;
    final exerciseAsset = fitLogWorkoutAssetForExercise(exerciseName);
    final badgeColors = _exerciseBadgeColors(
      palette: palette,
      bodyPart: bodyPart,
      bodyPartColor: color,
    );
    final assetScale = switch (bodyPart) {
      'Full Body' => 0.82,
      'Cardio' => 0.74,
      _ => 0.66,
    };
    final fallbackScale = switch (bodyPart) {
      'Full Body' => 0.7,
      'Cardio' => 0.62,
      _ => 0.52,
    };

    if (exerciseAsset != null) {
      return Container(
        width: size,
        height: size,
        decoration: _exerciseBadgeDecoration(size: size, colors: badgeColors),
        alignment: Alignment.center,
        child: Image.asset(
          exerciseAsset,
          width: size * assetScale,
          height: size * assetScale,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: _exerciseBadgeDecoration(size: size, colors: badgeColors),
      alignment: Alignment.center,
      child: FitLogAssetIcon(
        assetName: fitLogWorkoutAssetForBodyPart(bodyPart),
        size: size * fallbackScale,
        tintColor: color,
      ),
    );
  }
}

BoxDecoration _exerciseBadgeDecoration({
  required double size,
  required _ExerciseBadgeColors colors,
}) {
  return BoxDecoration(
    color: colors.fill,
    shape: BoxShape.circle,
    border: colors.ring == null
        ? null
        : Border.all(
            color: colors.ring!,
            width: (size * 0.04).clamp(2.0, 4.0).toDouble(),
          ),
  );
}

_ExerciseBadgeColors _exerciseBadgeColors({
  required FitLogColors palette,
  required String bodyPart,
  required Color bodyPartColor,
}) {
  if (palette.key != FitLogThemeKey.blackOrange) {
    return _ExerciseBadgeColors(fill: bodyPartColor.withValues(alpha: 0.14));
  }

  return switch (bodyPart) {
    'Chest' => const _ExerciseBadgeColors(
      fill: Color(0xFF402824),
      ring: Color(0xFF8B5A52),
    ),
    'Back' => const _ExerciseBadgeColors(
      fill: Color(0xFF27303D),
      ring: Color(0xFF60718A),
    ),
    'Legs' => const _ExerciseBadgeColors(
      fill: Color(0xFF41341C),
      ring: Color(0xFF9A7D40),
    ),
    'Glutes' => const _ExerciseBadgeColors(
      fill: Color(0xFFD66A3C),
      ring: Color(0xFFF1A073),
    ),
    'Shoulders' => const _ExerciseBadgeColors(
      fill: Color(0xFF626A72),
      ring: Color(0xFF9AA4AD),
    ),
    'Arms' => const _ExerciseBadgeColors(
      fill: Color(0xFF203838),
      ring: Color(0xFF5D8989),
    ),
    'Core' => const _ExerciseBadgeColors(
      fill: Color(0xFF402830),
      ring: Color(0xFF8B5A68),
    ),
    'Cardio' => const _ExerciseBadgeColors(
      fill: Color(0xFF21382D),
      ring: Color(0xFF5F8B70),
    ),
    'Full Body' => const _ExerciseBadgeColors(
      fill: Color(0xFF68727E),
      ring: Color(0xFFA0AABD),
    ),
    _ => _ExerciseBadgeColors(fill: bodyPartColor.withValues(alpha: 0.22)),
  };
}

class _ExerciseBadgeColors {
  const _ExerciseBadgeColors({required this.fill, this.ring});

  final Color fill;
  final Color? ring;
}
