import 'package:material_ui/material_ui.dart';

/// The color palette. Warm neutrals only: the book covers are the one place
/// where color appears, so the interface never competes with them.
///
/// Every text color meets WCAG AA (4.5:1) on both [background] and [surface].
/// Meaning is never carried by color alone (see docs/02-design/ui-design.md).
@immutable
class BookstoreColors extends ThemeExtension<BookstoreColors> {
  const BookstoreColors({
    required this.background,
    required this.surface,
    required this.glass,
    required this.glassBorder,
    required this.glassHighlight,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.hairline,
    required this.hover,
    required this.accent,
    required this.ink,
    required this.onInk,
    required this.danger,
    required this.shadow,
  });

  /// Page background.
  final Color background;

  /// Opaque cards and fields.
  final Color surface;

  /// Translucent fill of glass panels (drawn over a blur).
  final Color glass;
  final Color glassBorder;
  final Color glassHighlight;

  final Color text;
  final Color textSecondary;
  final Color textTertiary;

  /// 1px separators.
  final Color hairline;

  /// Fill of a hovered row or icon button.
  final Color hover;

  /// The single accent: focus rings, selection, links.
  final Color accent;

  /// Primary buttons: near-black in light mode, cream in dark mode.
  final Color ink;
  final Color onInk;

  final Color danger;
  final Color shadow;

  static const light = BookstoreColors(
    background: Color(0xFFF4F0E9),
    surface: Color(0xFFFFFCF7),
    glass: Color(0xB3FFFCF7),
    glassBorder: Color(0x14201A12),
    glassHighlight: Color(0x66FFFFFF),
    text: Color(0xFF1F1B17),
    textSecondary: Color(0xFF62594F),
    textTertiary: Color(0xFF746A5F),
    hairline: Color(0xFFE2DBD0),
    hover: Color(0x0F201A12),
    accent: Color(0xFF8F4721),
    ink: Color(0xFF1F1B17),
    onInk: Color(0xFFFFFCF7),
    danger: Color(0xFF9E2A1F),
    shadow: Color(0x33201A12),
  );

  static const dark = BookstoreColors(
    background: Color(0xFF151311),
    surface: Color(0xFF201D1A),
    glass: Color(0x99262220),
    glassBorder: Color(0x1FFFFFFF),
    glassHighlight: Color(0x14FFFFFF),
    text: Color(0xFFF2EDE6),
    textSecondary: Color(0xFFB3A99D),
    textTertiary: Color(0xFF8C8378),
    hairline: Color(0xFF37322C),
    hover: Color(0x14FFFFFF),
    accent: Color(0xFFE5A078),
    ink: Color(0xFFF2EDE6),
    onInk: Color(0xFF1A1612),
    danger: Color(0xFFF0A79C),
    shadow: Color(0x80000000),
  );

  static BookstoreColors of(BuildContext context) => Theme.of(context).extension<BookstoreColors>()!;

  @override
  BookstoreColors copyWith() => this;

  @override
  BookstoreColors lerp(ThemeExtension<BookstoreColors>? other, double t) {
    if (other is! BookstoreColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BookstoreColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      glass: mix(glass, other.glass),
      glassBorder: mix(glassBorder, other.glassBorder),
      glassHighlight: mix(glassHighlight, other.glassHighlight),
      text: mix(text, other.text),
      textSecondary: mix(textSecondary, other.textSecondary),
      textTertiary: mix(textTertiary, other.textTertiary),
      hairline: mix(hairline, other.hairline),
      hover: mix(hover, other.hover),
      accent: mix(accent, other.accent),
      ink: mix(ink, other.ink),
      onInk: mix(onInk, other.onInk),
      danger: mix(danger, other.danger),
      shadow: mix(shadow, other.shadow),
    );
  }
}

/// Spacing scale. Every gap in the apps is one of these.
abstract final class Space {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Corner radii.
abstract final class Radii {
  static const double cover = 6;
  static const double control = 10;
  static const double card = 16;
  static const double panel = 22;
  static const double pill = 999;
}

/// Motion: short, and always decelerating into place.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 380);
  static const Curve curve = Curves.easeOutCubic;
}

/// Typefaces. Both are open source (SIL Open Font License) and are bundled in
/// this package under fonts/, so the apps look the same on every machine.
abstract final class Fonts {
  /// Interface text.
  /// Inter: the open-source typeface closest to Apple's SF Pro, which may
  /// only be used on Apple platforms.
  static const String ui = 'packages/bookstore_ui/Inter';
  static const List<String> uiFallback = ['Segoe UI Variable', 'Segoe UI'];

  /// Headings and book titles on covers.
  static const String display = 'packages/bookstore_ui/SourceSerif4';
}
