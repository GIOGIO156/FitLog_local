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
    final exerciseAsset = fitLogWorkoutAssetForExercise(exerciseName);

    if (exerciseAsset != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Image.asset(
          exerciseAsset,
          width: size * 0.66,
          height: size * 0.66,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
    }

    return FitLogSvgIconCircle(
      assetName: fitLogWorkoutAssetForBodyPart(bodyPart),
      size: size,
      iconSize: size * 0.52,
      backgroundColor: color.withValues(alpha: 0.14),
      tintColor: color,
    );
  }
}
