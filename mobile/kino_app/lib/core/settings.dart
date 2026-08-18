/// The one preference this app has: which of the two themes to wear.
///
/// A `ValueNotifier` handed to `MaterialApp` through a `ListenableBuilder`,
/// rather than a state-management package for a single enum. The default is
/// `system` — the phone already knows whether it is night.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'kino_theme_mode';

class Settings extends ValueNotifier<ThemeMode> {
  Settings([super.mode = ThemeMode.system]);

  /// Read once at start-up, so the first frame is already in the right theme
  /// instead of flashing the wrong one and correcting itself.
  static Future<Settings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      return Settings(
        ThemeMode.values.firstWhere(
          (mode) => mode.name == saved,
          orElse: () => ThemeMode.system,
        ),
      );
    } catch (_) {
      // No platform channels — a test, or a host that has no preferences.
      // A theme is not worth failing to start over.
      return Settings();
    }
  }

  Future<void> choose(ThemeMode mode) async {
    if (mode == value) return;
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Kept for this run; forgotten by the next. Still better than crashing.
    }
  }
}
