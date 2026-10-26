import 'package:flutter/widgets.dart';

// Design tokens: the only spacing, corner and lift values the screens use, so everything lines up on
// one 8 dp grid (with a 4 dp half step). Serves the "consistency" and "minimalist design" principles.

abstract final class Space {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 16;
  static const double l = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class Corner {
  static const double small = 12; // chips, text boxes
  static const double medium = 16; // cards, buttons
  static const double large = 24; // hero cards, dialogs, sheets

  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get largeRadius => BorderRadius.circular(large);
}

abstract final class Lift {
  static const double flat = 0;
  static const double card = 1;
  static const double raised = 3;
}

/// Fitts's law: every tappable thing is at least this big, with at least [Space.s] between neighbours.
const double minTouchTarget = 48;

/// Longest line of text, so a wide tablet does not stretch it across the whole screen.
const double maxContentWidth = 600;
