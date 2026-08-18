/// Where the session token lives between launches.
///
/// The catalogue gives everybody an identity, guest or not, and that identity
/// *is* the token — lose it and the phone is a new person with an empty history.
/// So keeping it is not an optimisation; it's the difference between an app that
/// remembers where you stopped and one that doesn't.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract class TokenStore {
  Future<String?> read();

  Future<void> save(String token);

  Future<void> clear();
}

/// For tests, and for a screen that deliberately wants to be a stranger.
class MemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> save(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}

/// The default: one string in shared preferences.
///
/// Not a keychain, on purpose. This token is worth what a guest's watch history
/// is worth, and hiding it behind a biometric prompt would only mean an app that
/// can't draw its own home screen until somebody touches the sensor. Move it the
/// day this token can buy something.
class PrefsTokenStore implements TokenStore {
  PrefsTokenStore({this.key = 'kino_session'});

  final String key;

  // Read once, then kept: every RPC asks for the token, and going to platform
  // channels on each one would put a round trip in front of every call.
  String? _cached;
  bool _loaded = false;

  @override
  Future<String?> read() async {
    if (_loaded) return _cached;
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(key);
    _loaded = true;
    return _cached;
  }

  @override
  Future<void> save(String token) async {
    _cached = token;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, token);
  }

  @override
  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
