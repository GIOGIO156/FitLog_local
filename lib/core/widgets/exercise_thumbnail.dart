import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.12),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: CustomPaint(
        painter: _ExerciseIconPainter(
          bodyPart: bodyPart,
          exerciseName: exerciseName,
          accent: color,
        ),
      ),
    );
  }
}

enum _Glyph {
  barbell,
  dumbbellRef,
  benchPress,
  inclineDumbbellPress,
  pushUp,
  pullUp,
  latPulldown,
  cableMachine,
  cableRowHandle,
  legPress,
  legExtension,
  legCurl,
  plank,
  crunch,
  burpee,
  hangingLegRaise,
  kettlebell,
  running,
  cycling,
  rowing,
  stairClimber,
}

class _ExerciseIconPainter extends CustomPainter {
  _ExerciseIconPainter({
    required this.bodyPart,
    required this.exerciseName,
    required this.accent,
  });

  final String bodyPart;
  final String exerciseName;
  final Color accent;

  _Glyph get _glyph {
    final lower = exerciseName.toLowerCase();

    if (lower.contains('bench press')) {
      return _Glyph.benchPress;
    }
    if (lower.contains('incline dumbbell press')) {
      return _Glyph.inclineDumbbellPress;
    }
    if (lower.contains('push-up')) {
      return _Glyph.pushUp;
    }
    if (lower.contains('chest fly')) {
      return _Glyph.dumbbellRef;
    }

    if (lower.contains('pull-up')) {
      return _Glyph.pullUp;
    }
    if (lower.contains('lat pulldown')) {
      return _Glyph.latPulldown;
    }
    if (lower.contains('seated cable row')) {
      return _Glyph.cableRowHandle;
    }
    if (lower.contains('barbell row')) {
      return _Glyph.barbell;
    }

    if (lower.contains('squat') ||
        lower.contains('romanian deadlift') ||
        lower.contains('overhead press') ||
        lower.contains('deadlift')) {
      return _Glyph.barbell;
    }

    if (lower.contains('leg press')) {
      return _Glyph.legPress;
    }
    if (lower.contains('leg extension')) {
      return _Glyph.legExtension;
    }
    if (lower.contains('leg curl')) {
      return _Glyph.legCurl;
    }

    if (lower.contains('lateral raise') ||
        lower.contains('rear delt fly') ||
        lower.contains('biceps curl') ||
        lower.contains('hammer curl')) {
      return _Glyph.dumbbellRef;
    }
    if (lower.contains('triceps pushdown')) {
      return _Glyph.cableMachine;
    }

    if (lower.contains('plank')) {
      return _Glyph.plank;
    }
    if (lower.contains('crunch')) {
      return _Glyph.crunch;
    }
    if (lower.contains('burpee')) {
      return _Glyph.burpee;
    }
    if (lower.contains('hanging leg raise')) {
      return _Glyph.hangingLegRaise;
    }

    if (lower.contains('running')) {
      return _Glyph.running;
    }
    if (lower.contains('cycling')) {
      return _Glyph.cycling;
    }
    if (lower.contains('rowing machine')) {
      return _Glyph.rowing;
    }
    if (lower.contains('stair climber')) {
      return _Glyph.stairClimber;
    }

    if (lower.contains('kettlebell swing')) {
      return _Glyph.kettlebell;
    }

    if (bodyPart == 'Cardio') {
      return _Glyph.running;
    }
    return _Glyph.barbell;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.98)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.08;

    final mid = Paint()
      ..color = accent.withValues(alpha: 0.98)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.055;

    final fill = Paint()
      ..color = accent.withValues(alpha: 0.98)
      ..style = PaintingStyle.fill;

    switch (_glyph) {
      case _Glyph.barbell:
        _drawBarbell(canvas, size, fill);
      case _Glyph.dumbbellRef:
        _drawDumbbellRef(canvas, size, fill);
      case _Glyph.benchPress:
        _drawBenchPress(canvas, size, fill, mid);
      case _Glyph.inclineDumbbellPress:
        _drawInclineDumbbellPress(canvas, size, fill, mid);
      case _Glyph.pushUp:
        _drawPushUp(canvas, size, mid, fill);
      case _Glyph.pullUp:
        _drawPullUp(canvas, size, stroke, mid);
      case _Glyph.latPulldown:
        _drawLatPulldown(canvas, size, mid);
      case _Glyph.cableMachine:
        _drawCableMachine(canvas, size, mid, fill);
      case _Glyph.cableRowHandle:
        _drawCableRowHandle(canvas, size, mid);
      case _Glyph.legPress:
        _drawLegPress(canvas, size, mid, fill);
      case _Glyph.legExtension:
        _drawLegExtension(canvas, size, mid, fill);
      case _Glyph.legCurl:
        _drawLegCurl(canvas, size, mid, fill);
      case _Glyph.plank:
        _drawPlank(canvas, size, mid, fill);
      case _Glyph.crunch:
        _drawCrunch(canvas, size, mid, fill);
      case _Glyph.burpee:
        _drawBurpee(canvas, size, mid, fill);
      case _Glyph.hangingLegRaise:
        _drawHangingLegRaise(canvas, size, mid);
      case _Glyph.kettlebell:
        _drawKettlebell(canvas, size, mid, fill);
      case _Glyph.running:
        _drawRunning(canvas, size, mid, fill);
      case _Glyph.cycling:
        _drawCycling(canvas, size, mid);
      case _Glyph.rowing:
        _drawRowing(canvas, size, mid, fill);
      case _Glyph.stairClimber:
        _drawStairClimber(canvas, size, mid);
    }
  }

  void _capsule(Canvas canvas, Rect rect, Paint fill) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      fill,
    );
  }

  void _drawBarbell(Canvas canvas, Size size, Paint fill) {
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.46,
        size.width * 0.52,
        size.height * 0.085,
      ),
      fill,
    );
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.14,
        size.height * 0.39,
        size.width * 0.07,
        size.height * 0.23,
      ),
      fill,
    );
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.42,
        size.width * 0.05,
        size.height * 0.17,
      ),
      fill,
    );
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.75,
        size.height * 0.42,
        size.width * 0.05,
        size.height * 0.17,
      ),
      fill,
    );
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.79,
        size.height * 0.39,
        size.width * 0.07,
        size.height * 0.23,
      ),
      fill,
    );
  }

  void _drawDumbbellRef(Canvas canvas, Size size, Paint fill) {
    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.5);
    canvas.rotate(-0.62);

    _capsule(
      canvas,
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.38,
        height: size.height * 0.085,
      ),
      fill,
    );
    _capsule(
      canvas,
      Rect.fromCenter(
        center: Offset(-size.width * 0.24, 0),
        width: size.width * 0.08,
        height: size.height * 0.2,
      ),
      fill,
    );
    _capsule(
      canvas,
      Rect.fromCenter(
        center: Offset(-size.width * 0.18, 0),
        width: size.width * 0.055,
        height: size.height * 0.15,
      ),
      fill,
    );
    _capsule(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.18, 0),
        width: size.width * 0.055,
        height: size.height * 0.15,
      ),
      fill,
    );
    _capsule(
      canvas,
      Rect.fromCenter(
        center: Offset(size.width * 0.24, 0),
        width: size.width * 0.08,
        height: size.height * 0.2,
      ),
      fill,
    );

    canvas.restore();
  }

  void _drawBenchPress(Canvas canvas, Size size, Paint fill, Paint mid) {
    _drawBarbell(canvas, size, fill);
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.33,
        size.height * 0.66,
        size.width * 0.34,
        size.height * 0.06,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.36, size.height * 0.66),
      Offset(size.width * 0.31, size.height * 0.77),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.66),
      Offset(size.width * 0.69, size.height * 0.77),
      mid,
    );
  }

  void _drawInclineDumbbellPress(
    Canvas canvas,
    Size size,
    Paint fill,
    Paint mid,
  ) {
    _drawDumbbellRef(canvas, size, fill);
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.74),
      Offset(size.width * 0.62, size.height * 0.58),
      mid,
    );
  }

  void _drawPushUp(Canvas canvas, Size size, Paint mid, Paint fill) {
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.68,
        size.width * 0.6,
        size.height * 0.065,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.58),
      Offset(size.width * 0.67, size.height * 0.54),
      mid,
    );
    canvas.drawCircle(
      Offset(size.width * 0.23, size.height * 0.58),
      size.width * 0.03,
      fill,
    );
  }

  void _drawPullUp(Canvas canvas, Size size, Paint stroke, Paint mid) {
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.23),
      Offset(size.width * 0.8, size.height * 0.23),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width * 0.36, size.height * 0.23),
      Offset(size.width * 0.36, size.height * 0.52),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.23),
      Offset(size.width * 0.64, size.height * 0.52),
      mid,
    );
  }

  void _drawLatPulldown(Canvas canvas, Size size, Paint mid) {
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.36),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.42),
      Offset(size.width * 0.75, size.height * 0.42),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.42),
      Offset(size.width * 0.2, size.height * 0.49),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.42),
      Offset(size.width * 0.8, size.height * 0.49),
      mid,
    );
  }

  void _drawCableMachine(Canvas canvas, Size size, Paint mid, Paint fill) {
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.22),
      Offset(size.width * 0.25, size.height * 0.77),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.75, size.height * 0.22),
      Offset(size.width * 0.75, size.height * 0.77),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.25, size.height * 0.22),
      Offset(size.width * 0.75, size.height * 0.22),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.22),
      Offset(size.width * 0.5, size.height * 0.55),
      mid,
    );
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.44,
        size.height * 0.56,
        size.width * 0.12,
        size.height * 0.05,
      ),
      fill,
    );
  }

  void _drawCableRowHandle(Canvas canvas, Size size, Paint mid) {
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.5),
      mid,
    );
    final path = Path()
      ..moveTo(size.width * 0.33, size.height * 0.55)
      ..lineTo(size.width * 0.67, size.height * 0.55)
      ..lineTo(size.width * 0.5, size.height * 0.74)
      ..close();
    canvas.drawPath(path, mid);
  }

  void _drawLegPress(Canvas canvas, Size size, Paint mid, Paint fill) {
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.64,
        size.width * 0.16,
        size.height * 0.08,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.68),
      Offset(size.width * 0.66, size.height * 0.42),
      mid,
    );
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.64,
        size.height * 0.32,
        size.width * 0.13,
        size.height * 0.16,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.72),
      Offset(size.width * 0.74, size.height * 0.36),
      mid,
    );
  }

  void _drawLegExtension(Canvas canvas, Size size, Paint mid, Paint fill) {
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.24,
        size.height * 0.57,
        size.width * 0.2,
        size.height * 0.09,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.43, size.height * 0.61),
      Offset(size.width * 0.63, size.height * 0.48),
      mid,
    );
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.63,
        size.height * 0.44,
        size.width * 0.13,
        size.height * 0.08,
      ),
      fill,
    );
  }

  void _drawLegCurl(Canvas canvas, Size size, Paint mid, Paint fill) {
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.22,
        size.height * 0.5,
        size.width * 0.31,
        size.height * 0.085,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.53, size.height * 0.54),
      Offset(size.width * 0.69, size.height * 0.44),
      mid,
    );
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.69,
        size.height * 0.4,
        size.width * 0.1,
        size.height * 0.08,
      ),
      fill,
    );
  }

  void _drawPlank(Canvas canvas, Size size, Paint mid, Paint fill) {
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.68,
        size.width * 0.6,
        size.height * 0.06,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.26, size.height * 0.57),
      Offset(size.width * 0.67, size.height * 0.58),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.63),
      Offset(size.width * 0.32, size.height * 0.68),
      mid,
    );
  }

  void _drawCrunch(Canvas canvas, Size size, Paint mid, Paint fill) {
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.68,
        size.width * 0.6,
        size.height * 0.06,
      ),
      fill,
    );
    final arcRect = Rect.fromLTWH(
      size.width * 0.32,
      size.height * 0.43,
      size.width * 0.32,
      size.height * 0.22,
    );
    canvas.drawArc(arcRect, math.pi * 0.1, math.pi * 0.9, false, mid);
    canvas.drawCircle(
      Offset(size.width * 0.31, size.height * 0.55),
      size.width * 0.027,
      fill,
    );
  }

  void _drawBurpee(Canvas canvas, Size size, Paint mid, Paint fill) {
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.2,
        size.height * 0.68,
        size.width * 0.6,
        size.height * 0.06,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.58),
      Offset(size.width * 0.56, size.height * 0.6),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.56, size.height * 0.6),
      Offset(size.width * 0.68, size.height * 0.48),
      mid,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.45),
      size.width * 0.024,
      fill,
    );
  }

  void _drawHangingLegRaise(Canvas canvas, Size size, Paint mid) {
    canvas.drawLine(
      Offset(size.width * 0.24, size.height * 0.3),
      Offset(size.width * 0.76, size.height * 0.3),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.36, size.height * 0.3),
      Offset(size.width * 0.36, size.height * 0.54),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.3),
      Offset(size.width * 0.64, size.height * 0.54),
      mid,
    );
  }

  void _drawKettlebell(Canvas canvas, Size size, Paint mid, Paint fill) {
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.58),
      size.width * 0.16,
      fill,
    );
    canvas.drawArc(
      Rect.fromLTWH(
        size.width * 0.35,
        size.height * 0.24,
        size.width * 0.3,
        size.height * 0.22,
      ),
      math.pi,
      math.pi,
      false,
      mid,
    );
  }

  void _drawRunning(Canvas canvas, Size size, Paint mid, Paint fill) {
    final shoe = Path()
      ..moveTo(size.width * 0.2, size.height * 0.62)
      ..lineTo(size.width * 0.44, size.height * 0.62)
      ..lineTo(size.width * 0.56, size.height * 0.52)
      ..lineTo(size.width * 0.73, size.height * 0.56)
      ..lineTo(size.width * 0.8, size.height * 0.64)
      ..lineTo(size.width * 0.2, size.height * 0.64)
      ..close();
    canvas.drawPath(shoe, mid);
    canvas.drawCircle(
      Offset(size.width * 0.36, size.height * 0.58),
      size.width * 0.014,
      fill,
    );
    canvas.drawCircle(
      Offset(size.width * 0.41, size.height * 0.56),
      size.width * 0.014,
      fill,
    );
    canvas.drawCircle(
      Offset(size.width * 0.46, size.height * 0.54),
      size.width * 0.014,
      fill,
    );
  }

  void _drawCycling(Canvas canvas, Size size, Paint mid) {
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.68),
      size.width * 0.12,
      mid,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height * 0.68),
      size.width * 0.12,
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.68),
      Offset(size.width * 0.49, size.height * 0.52),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.49, size.height * 0.52),
      Offset(size.width * 0.72, size.height * 0.68),
      mid,
    );
    canvas.drawLine(
      Offset(size.width * 0.49, size.height * 0.52),
      Offset(size.width * 0.42, size.height * 0.41),
      mid,
    );
  }

  void _drawRowing(Canvas canvas, Size size, Paint mid, Paint fill) {
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.72),
      Offset(size.width * 0.78, size.height * 0.72),
      mid,
    );
    _capsule(
      canvas,
      Rect.fromLTWH(
        size.width * 0.28,
        size.height * 0.63,
        size.width * 0.12,
        size.height * 0.075,
      ),
      fill,
    );
    canvas.drawLine(
      Offset(size.width * 0.54, size.height * 0.56),
      Offset(size.width * 0.72, size.height * 0.48),
      mid,
    );
  }

  void _drawStairClimber(Canvas canvas, Size size, Paint mid) {
    final path = Path()
      ..moveTo(size.width * 0.24, size.height * 0.72)
      ..lineTo(size.width * 0.24, size.height * 0.62)
      ..lineTo(size.width * 0.38, size.height * 0.62)
      ..lineTo(size.width * 0.38, size.height * 0.52)
      ..lineTo(size.width * 0.52, size.height * 0.52)
      ..lineTo(size.width * 0.52, size.height * 0.42)
      ..lineTo(size.width * 0.66, size.height * 0.42)
      ..lineTo(size.width * 0.66, size.height * 0.32);
    canvas.drawPath(path, mid);
  }

  @override
  bool shouldRepaint(covariant _ExerciseIconPainter oldDelegate) {
    return oldDelegate.bodyPart != bodyPart ||
        oldDelegate.exerciseName != exerciseName ||
        oldDelegate.accent != accent;
  }
}
