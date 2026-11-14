import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// Builds the theme used by both apps. Pass [Brightness.light] or
/// [Brightness.dark]; the two share everything except the color palette.
ThemeData buildBookstoreTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? BookstoreColors.light : BookstoreColors.dark;

  TextStyle ui(double size, FontWeight weight, Color color, {double height = 1.4, double spacing = 0}) => TextStyle(
    fontFamily: Fonts.ui,
    fontFamilyFallback: Fonts.uiFallback,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: spacing,
  );
  TextStyle display(double size, Color color) =>
      TextStyle(fontFamily: Fonts.display, fontSize: size, fontWeight: FontWeight.w600, color: color, height: 1.15, letterSpacing: -0.4);

  final textTheme = TextTheme(
    displaySmall: display(34, c.text),
    headlineSmall: display(24, c.text),
    titleLarge: display(20, c.text),
    titleMedium: ui(15, FontWeight.w600, c.text, height: 1.3),
    titleSmall: ui(13.5, FontWeight.w600, c.text, height: 1.3),
    bodyLarge: ui(15, FontWeight.w400, c.text),
    bodyMedium: ui(14, FontWeight.w400, c.text),
    bodySmall: ui(12.5, FontWeight.w400, c.textSecondary),
    labelLarge: ui(14, FontWeight.w600, c.text, height: 1.2),
    labelMedium: ui(12.5, FontWeight.w600, c.textSecondary, height: 1.2),
    labelSmall: ui(11, FontWeight.w600, c.textTertiary, height: 1.2, spacing: 0.6),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: Fonts.ui,
    fontFamilyFallback: Fonts.uiFallback,
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.ink,
      onPrimary: c.onInk,
      secondary: c.accent,
      onSecondary: c.onInk,
      error: c.danger,
      onError: c.onInk,
      surface: c.surface,
      onSurface: c.text,
    ),
    textTheme: textTheme,
    // No ink ripples: feedback is a quiet fill and scale change instead.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    hoverColor: c.hover,
    focusColor: c.accent.withValues(alpha: 0.18),
    dividerColor: c.hairline,
    textSelectionTheme: TextSelectionThemeData(cursorColor: c.accent, selectionColor: c.accent.withValues(alpha: 0.28)),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(color: c.ink, borderRadius: BorderRadius.circular(8)),
      textStyle: ui(12, FontWeight.w500, c.onInk, height: 1.2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: WidgetStateProperty.all(6),
      radius: const Radius.circular(3),
      thumbColor: WidgetStateProperty.all(c.textTertiary.withValues(alpha: 0.5)),
    ),
    extensions: [c],
  );
}
