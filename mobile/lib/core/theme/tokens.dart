import 'package:flutter/material.dart';

/// Colours, radii and motion from nirmal-mart-app-design/design-tokens.json (matched to nirmalmart.in).
abstract final class NmColors {
  static const brand = Color(0xFF317239);
  static const brandSoft = Color(0xFFE9F3EB);
  static const brandDark = Color(0xFF1E4D25);
  static const background = Color(0xFFFAFAF8);
  static const surface = Color(0xFFFFFFFF);
  static const muted = Color(0xFFF3F3F0);
  static const line = Color(0xFFE5E5E0);
  static const outline = Color(0xFF8A8D84); // text field and segmented-button borders
  static const ink = Color(0xFF111217);
  static const inkSoft = Color(0xFF4C4F5C);
  static const inkFaint = Color(0xFF5F6270);
  static const deal = Color(0xFFB92418);
  static const success = Color(0xFF15803D);
  static const gold = Color(0xFFD8AB54);
  static const goldSoft = Color(0xFFF3D9A4); // highlight text on brand green
  static const maroon = Color(0xFF46080C);
  static const navBar = Color(0xFFF1F3EE);

  // Dark mode
  static const darkBackground = Color(0xFF111217);
  static const darkSurface = Color(0xFF1B1D22);
  static const darkLine = Color(0xFF2A2D33);
  static const darkInk = Color(0xFFF3F3F0);
  static const darkInkFaint = Color(0xFFA3A6AE);
  static const brandOnDark = Color(0xFF8FCB98);
}

/// Android (Material 3) radii from the design
abstract final class NmRadius {
  static const card = 12.0;
  static const button = 28.0;
  static const chip = 8.0;
  static const sheet = 28.0;
  static const textField = 4.0;
  static const field = 14.0; // filled input fields
  static const panel = 32.0; // white sheet over a coloured header
}

abstract final class NmSizes {
  static const buttonHeight = 56.0;
  static const minTouch = 44.0;
}

abstract final class NmMotion {
  static const entrance = Duration(milliseconds: 550);
  static const entranceCurve = Cubic(0.2, 0.8, 0.2, 1);
  static const stagger = Duration(milliseconds: 60);
  static const sheet = Duration(milliseconds: 380);
  static const sheetCurve = Cubic(0.2, 0.9, 0.25, 1);
  static const press = Duration(milliseconds: 150);
  static const carouselEvery = Duration(milliseconds: 3800);
  static const carouselSlide = Duration(milliseconds: 700);
}
