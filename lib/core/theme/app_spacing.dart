import 'package:flutter/material.dart';

/// Spacing, radii, durations and shadows shared by every component.
abstract final class AppSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal gutter for screen content.
  static const double gutter = 20;
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: gutter);
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

abstract final class AppDurations {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 600);
}

abstract final class AppShadows {
  static List<BoxShadow> soft(Brightness b) => b == Brightness.light
      ? const [
          BoxShadow(color: Color(0x14102A2C), blurRadius: 24, offset: Offset(0, 10)),
          BoxShadow(color: Color(0x0A102A2C), blurRadius: 4, offset: Offset(0, 1)),
        ]
      : const [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8))];
}
