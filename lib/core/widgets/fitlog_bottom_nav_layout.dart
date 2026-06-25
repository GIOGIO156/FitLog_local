import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class FitLogBottomNavLayout {
  const FitLogBottomNavLayout._();

  static const double pillHeight = 72;
  static const double minBottomGap = 12;
  static const double horizontalInset = 16;
  static const double ctaHeight = 56;
  static const double ctaToNavGap = 8;
  static const double listAfterCtaGap = 32;

  static double bottomGapFor(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return math.max(bottomInset, minBottomGap);
  }

  static double footprintFor(BuildContext context) {
    return pillHeight + bottomGapFor(context);
  }

  static double ctaBottomFor(BuildContext context) {
    return footprintFor(context) + ctaToNavGap;
  }

  static double ctaListBottomPaddingFor(BuildContext context) {
    return ctaBottomFor(context) + ctaHeight + listAfterCtaGap;
  }

  static double pageScrollBottomPaddingFor(BuildContext context) {
    return footprintFor(context);
  }

  static double firstViewportHeightFor(
    BuildContext context, {
    required double availableHeight,
  }) {
    return math.max(0, availableHeight - footprintFor(context));
  }
}
