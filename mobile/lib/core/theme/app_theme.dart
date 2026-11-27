import 'package:flutter/material.dart';

import 'tokens.dart';

/// Material 3 theme built from the design tokens. Inter for Latin text, Noto Sans Devanagari for Marathi.
abstract final class AppTheme {
  static const _font = 'Inter';
  static const _fallback = ['NotoSansDevanagari'];

  static ThemeData light() => _build(
        brightness: Brightness.light,
        primary: NmColors.brand,
        background: NmColors.background,
        surface: NmColors.surface,
        line: NmColors.line,
        ink: NmColors.ink,
        inkFaint: NmColors.inkFaint,
        navBar: NmColors.navBar,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        primary: NmColors.brandOnDark,
        background: NmColors.darkBackground,
        surface: NmColors.darkSurface,
        line: NmColors.darkLine,
        ink: NmColors.darkInk,
        inkFaint: NmColors.darkInkFaint,
        navBar: NmColors.darkSurface,
      );

  static OutlineInputBorder _field(Color color, {double width = 1}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(NmRadius.field),
        borderSide: BorderSide(color: color, width: width),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color line,
    required Color ink,
    required Color inkFaint,
    required Color navBar,
  }) {
    final scheme = ColorScheme.fromSeed(seedColor: NmColors.brand, brightness: brightness).copyWith(
      primary: primary,
      onPrimary: brightness == Brightness.light ? Colors.white : NmColors.darkBackground,
      surface: surface,
      onSurface: ink,
      onSurfaceVariant: inkFaint,
      outline: line,
      outlineVariant: line,
      error: NmColors.deal,
    );

    TextStyle t(double size, FontWeight w, {Color? color}) =>
        TextStyle(fontFamily: _font, fontFamilyFallback: _fallback, fontSize: size, fontWeight: w, color: color ?? ink);

    final text = TextTheme(
      displaySmall: t(32, FontWeight.w800), // large title
      headlineSmall: t(22, FontWeight.w700), // title
      titleLarge: t(19, FontWeight.w800), // section
      titleMedium: t(16, FontWeight.w800), // price
      bodyLarge: t(15, FontWeight.w400),
      bodyMedium: t(14, FontWeight.w400),
      labelLarge: t(15, FontWeight.w600),
      bodySmall: t(12, FontWeight.w500, color: inkFaint), // caption
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: _font,
      fontFamilyFallback: _fallback,
      textTheme: text,
      dividerColor: line,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: t(19, FontWeight.w800),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBar,
        indicatorColor: brightness == Brightness.light ? NmColors.brandSoft : NmColors.brandDark,
        labelTextStyle: WidgetStatePropertyAll(t(12, FontWeight.w600)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(NmRadius.card),
          side: BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(NmSizes.buttonHeight),
          shape: const StadiumBorder(),
          textStyle: t(15, FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(NmSizes.buttonHeight),
          shape: const StadiumBorder(),
          side: BorderSide(color: line),
          foregroundColor: ink,
          textStyle: t(15, FontWeight.w700),
        ),
      ),
      // Soft filled fields with rounded corners; green outline and icon when focused
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light ? NmColors.muted : const Color(0xFF22252B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        labelStyle: t(15, FontWeight.w500, color: inkFaint),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (s) => t(14, FontWeight.w600, color: s.contains(WidgetState.error) ? NmColors.deal : s.contains(WidgetState.focused) ? primary : inkFaint),
        ),
        hintStyle: t(16, FontWeight.w400, color: inkFaint.withValues(alpha: 0.6)),
        prefixIconColor: WidgetStateColor.resolveWith((s) => s.contains(WidgetState.focused) ? primary : inkFaint),
        suffixIconColor: inkFaint,
        errorStyle: t(12.5, FontWeight.w500, color: NmColors.deal),
        border: _field(Colors.transparent),
        enabledBorder: _field(line),
        disabledBorder: _field(line),
        focusedBorder: _field(primary, width: 1.6),
        errorBorder: _field(NmColors.deal),
        focusedErrorBorder: _field(NmColors.deal, width: 1.6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          side: BorderSide(color: brightness == Brightness.light ? NmColors.outline : line),
          selectedBackgroundColor: brightness == Brightness.light ? NmColors.brandSoft : NmColors.brandDark,
          foregroundColor: ink,
          selectedForegroundColor: ink,
          textStyle: t(14, FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(NmRadius.chip)),
        side: BorderSide(color: line),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(NmRadius.sheet))),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
