/// The two preferences this app has: which theme, and which language.
///
/// A `ChangeNotifier` handed to `MaterialApp` through a `ListenableBuilder`,
/// rather than a state-management package for two enums. Both default to
/// "whatever the system says" — the phone already knows whether it is night and
/// what language its owner reads.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'kino_theme_mode';
const _localeKey = 'kino_locale';

class Settings extends ChangeNotifier {
  // Positional, because Dart has no private named parameters and these two
  // fields are private for a reason: they change only through the methods
  // below, which also write them down.
  Settings([this._theme = ThemeMode.system, this._locale]);

  ThemeMode _theme;
  Locale? _locale;

  ThemeMode get theme => _theme;

  /// Null means "follow the system", which is not the same as English — a phone
  /// set to Ukrainian should open in Ukrainian without anybody choosing.
  Locale? get locale => _locale;

  /// Read once at start-up, so the first frame is already in the right theme
  /// and language instead of flashing the wrong ones and correcting itself.
  static Future<Settings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString(_themeKey);
      final locale = prefs.getString(_localeKey);
      return Settings(
        ThemeMode.values.firstWhere(
          (mode) => mode.name == theme,
          orElse: () => ThemeMode.system,
        ),
        locale == null || locale.isEmpty ? null : Locale(locale),
      );
    } catch (_) {
      // No platform channels — a test, or a host with no preferences. Neither
      // of these is worth failing to start over.
      return Settings();
    }
  }

  Future<void> chooseTheme(ThemeMode mode) async {
    if (mode == _theme) return;
    _theme = mode;
    notifyListeners();
    await _write(_themeKey, mode.name);
  }

  Future<void> chooseLocale(Locale? locale) async {
    if (locale?.languageCode == _locale?.languageCode) return;
    _locale = locale;
    notifyListeners();
    await _write(_localeKey, locale?.languageCode ?? '');
  }

  Future<void> _write(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Kept for this run, forgotten by the next. Still better than crashing.
    }
  }
}
