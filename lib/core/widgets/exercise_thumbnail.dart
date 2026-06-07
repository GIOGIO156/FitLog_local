import 'package:flutter/material.dart';

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
    return FitLogSvgIconCircle(
      assetName: fitLogWorkoutAssetForBodyPart(bodyPart),
      size: size,
      iconSize: size * 0.52,
      backgroundColor: color.withValues(alpha: 0.14),
      tintColor: color,
    );
  }
}
