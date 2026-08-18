/// Modernist, ported — in both lights.
///
/// The tokens are the ones `frontend/app/assets/styles/_tokens.scss` hands the
/// web app: paper ground, ink text, one red accent, and square corners, which
/// are the point of the system rather than a default nobody changed. Material's
/// instinct is the opposite on all four counts, so much of what follows is
/// turning a default off.
///
/// The dark theme is not an invention. That design system already describes a
/// dark surface — `--color-ink`, `--color-ink-text`, `--color-ink-muted`, the
/// panels it puts over artwork, and the `.on-ink` rules that lighten the accent
/// there. Dark mode is that mode, applied to the whole page instead of to a
/// caption.
library;

import 'package:flutter/material.dart';

// --- the ramp, as the web has it --------------------------------------------

const paper = Color(0xFFF3F2F2); // --color-bg
const surfaceLight = Color(0xFFEAE9E9); // --color-surface
const ink = Color(0xFF201E1D); // --color-text, and --color-ink
const inkText = Color(0xFFF3F2F2); // --color-ink-text
const inkMuted = Color(0xFFCAC8C6); // --color-ink-muted
const inkFaint = Color(0xFFA5A3A1);

const accent = Color(0xFFEC3013); // --color-accent
const accent200 = Color(0xFFFFE0D9);
const accent300 = Color(0xFFFFC4B8);
const accent500 = Color(0xFFFF563C); // what `.on-ink` reaches for
const accent700 = Color(0xFFAE1800);

const neutral200 = Color(0xFFEAE7E7);
const neutral300 = Color(0xFFD7D3D3);
const neutral500 = Color(0xFF9B9797);
const neutral600 = Color(0xFF7D7979);
const neutral800 = Color(0xFF444141);
const neutral900 = Color(0xFF2D2B2B);

/// One family, two roles. Headings are the same face at weight 800 — the system
/// has no second typeface to reach for.
const family = 'Archivo';

/// `--poster-ratio`: what these sources publish is a portrait poster, not a
/// 16:9 still.
const posterRatio = 2 / 3;

/// The colours that differ between the two themes, in one place, so a widget
/// asks for a role rather than deciding which grey it is today.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.text,
    required this.muted,
    required this.faint,
    required this.ground,
    required this.panel,
    required this.line,
    required this.accent,
    required this.onAccent,
  });

  // Defined below rather than here: inside the class body, `accent` is this
  // class's own field and shadows the token of the same name.
  static const light = _lightPalette;
  static const dark = _darkPalette;

  final Color text;
  final Color muted;
  final Color faint;
  final Color ground;
  final Color panel;
  final Color line;
  final Color accent;
  final Color onAccent;

  static Palette of(BuildContext context) =>
      Theme.of(context).extension<Palette>() ?? light;

  @override
  Palette copyWith({
    Color? text,
    Color? muted,
    Color? faint,
    Color? ground,
    Color? panel,
    Color? line,
    Color? accent,
    Color? onAccent,
  }) =>
      Palette(
        text: text ?? this.text,
        muted: muted ?? this.muted,
        faint: faint ?? this.faint,
        ground: ground ?? this.ground,
        panel: panel ?? this.panel,
        line: line ?? this.line,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
      );

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    return Palette(
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      ground: Color.lerp(ground, other.ground, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

const _lightPalette = Palette(
  text: ink,
  muted: neutral600,
  faint: neutral500,
  ground: paper,
  panel: surfaceLight,
  // `--color-divider`: the text colour at 40%, not a grey of its own.
  line: Color(0x66201E1D),
  accent: accent,
  onAccent: paper,
);

const _darkPalette = Palette(
  text: inkText,
  muted: inkMuted,
  faint: inkFaint,
  ground: ink,
  panel: neutral900,
  line: Color(0x4DF3F2F2),
  // Pure `--color-accent` on an ink ground reads as maroon; the ramp's own
  // lighter step is what the web reaches for over dark panels.
  accent: accent500,
  onAccent: ink,
);

/// Weight lives on the `wght` axis of one variable file. `fontWeight` alone
/// leans on the engine picking an instance; naming the axis leaves nothing to
/// chance, and a wrong guess is a whole app in the wrong weight.
List<FontVariation> _axis(double weight) => [FontVariation('wght', weight)];

TextStyle heading(double size, {double weight = 800, Color? color}) => TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.w800,
      fontVariations: _axis(weight),
      // −0.015em, as the web has it: at display sizes the default tracking is
      // loose enough to read as a different font.
      letterSpacing: size * -0.015,
      height: 1.12,
      color: color,
    );

TextStyle body(double size, {double weight = 400, Color? color}) => TextStyle(
      fontFamily: family,
      fontSize: size,
      fontVariations: _axis(weight),
      height: 1.45,
      color: color,
    );

/// The system's `h6`: a label, not a title — 13px, wide tracking, upper case.
/// Every section heading in the web app is one of these.
TextStyle label({Color? color}) => TextStyle(
      fontFamily: family,
      fontSize: 13,
      fontWeight: FontWeight.w800,
      fontVariations: _axis(800),
      letterSpacing: 0.08 * 13,
      color: color,
    );

/// A kicker: the small accent line above a title.
TextStyle kicker(Color color) => TextStyle(
      fontFamily: family,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      fontVariations: _axis(800),
      letterSpacing: 1.1,
      color: color,
    );

ThemeData modernist(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final palette = dark ? Palette.dark : Palette.light;

  // Square, everywhere. `--radius-*` are all `0px`, and Material rounds cards,
  // chips, fields, dialogs and buttons unless each is told otherwise.
  const square = RoundedRectangleBorder(borderRadius: BorderRadius.zero);
  final hairline = BorderSide(color: palette.line);

  final scheme = ColorScheme(
    brightness: brightness,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    secondary: palette.accent,
    onSecondary: palette.onAccent,
    error: dark ? accent300 : accent700,
    onError: palette.onAccent,
    surface: palette.ground,
    onSurface: palette.text,
    surfaceContainerHighest: palette.panel,
    outline: palette.line,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    extensions: [palette],
    scaffoldBackgroundColor: palette.ground,
    fontFamily: family,
    dividerColor: palette.line,
    // Loud on purpose: on a television this is the only thing saying where you
    // are, and on a phone it is barely seen.
    focusColor: dark ? neutral800 : accent200,
    textTheme: TextTheme(
      displaySmall: heading(42, color: palette.text),
      headlineMedium: heading(32, color: palette.text),
      headlineSmall: heading(25, color: palette.text),
      titleLarge: heading(20, color: palette.text),
      titleMedium: heading(16, color: palette.text),
      labelLarge: label(color: palette.text),
      labelMedium: body(12, weight: 600, color: palette.muted),
      bodyLarge: body(15, color: palette.text),
      bodyMedium: body(14, color: palette.text),
      bodySmall: body(12, color: palette.muted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.ground,
      foregroundColor: palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: heading(22, color: palette.text),
      shape: Border(bottom: hairline),
    ),
    dividerTheme: DividerThemeData(color: palette.line, thickness: 1, space: 1),
    cardTheme: CardThemeData(
      color: palette.panel,
      elevation: 0,
      shape: square,
      margin: EdgeInsets.zero,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.ground,
      selectedColor: palette.accent,
      side: hairline,
      shape: square,
      labelStyle: body(13, weight: 600, color: palette.text),
      secondaryLabelStyle: body(13, weight: 600, color: palette.onAccent),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.ground,
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: hairline),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: hairline),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: palette.accent, width: 2),
      ),
      hintStyle: body(14, color: palette.faint),
      labelStyle: body(13, weight: 600, color: palette.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        shape: square,
        textStyle: heading(14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        shape: square,
        side: hairline,
        textStyle: heading(14),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.accent,
        shape: square,
        textStyle: heading(14),
      ),
    ),
    listTileTheme: ListTileThemeData(
      shape: square,
      titleTextStyle: body(15, weight: 600, color: palette.text),
      subtitleTextStyle: body(12, color: palette.muted),
      iconColor: palette.muted,
      selectedColor: palette.accent,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: palette.accent,
      linearTrackColor: palette.line,
      circularTrackColor: Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.accent,
      foregroundColor: palette.onAccent,
      shape: square,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? neutral900 : ink,
      contentTextStyle: body(14, color: inkText),
      shape: square,
      behavior: SnackBarBehavior.floating,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.panel,
      shape: square,
      textStyle: body(14, color: palette.text),
    ),
    dialogTheme: DialogThemeData(backgroundColor: palette.ground, shape: square),
  );
}
