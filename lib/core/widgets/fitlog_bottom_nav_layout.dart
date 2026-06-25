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
  static const double modalSheetOuterGap = 12;
  static const double modalSheetTopGap = 64;
  static const double guideSheetStaticHeight = 104;
  static const double minGuideSheetBodyHeight = 240;
  static const double maxGuideSheetBodyHeight = 580;

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

  static double modalBottomPaddingFor(BuildContext context) {
    return footprintFor(context) + modalSheetOuterGap;
  }

  static double modalTopPaddingFor(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;
    return math.max(modalSheetTopGap, topInset + modalSheetOuterGap * 2);
  }

  static double guideSheetBodyHeightFor(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height -
        modalTopPaddingFor(context) -
        modalBottomPaddingFor(context) -
        guideSheetStaticHeight;
    if (availableHeight <= minGuideSheetBodyHeight) {
      return math.max(0, availableHeight);
    }
    return math.min(maxGuideSheetBodyHeight, availableHeight);
  }

  static double firstViewportHeightFor(
    BuildContext context, {
    required double availableHeight,
  }) {
    return math.max(0, availableHeight - footprintFor(context));
  }
}
