import 'package:flutter/widgets.dart';

abstract final class AppTokens {
  static const double space2 = 2;
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space28 = 28;
  static const double space32 = 32;
  static const double space36 = 36;

  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 20;
  static const double radiusPill = 999;

  static const double minimumTouchTarget = 48;

  static const double compactNavigationBreakpoint = 760;
  static const double extendedNavigationBreakpoint = 1120;
  static const double gridTwoColumnBreakpoint = 560;
  static const double gridThreeColumnBreakpoint = 850;
  static const double gridFourColumnBreakpoint = 1200;

  static const double compactNoteCardExtent = 250;
  static const double regularNoteCardExtent = 270;
  static const double maxEditorWidth = 980;
  static const double maxContentWidth = 720;

  static const Duration searchDebounce = Duration(milliseconds: 220);
  static const Duration autosaveDebounce = Duration(milliseconds: 650);
  static const Duration standardMotion = Duration(milliseconds: 200);

  static const EdgeInsets pagePadding = EdgeInsets.all(space16);
  static const EdgeInsets largePagePadding = EdgeInsets.all(space24);
}
