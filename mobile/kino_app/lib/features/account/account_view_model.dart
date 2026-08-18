/// Who you are here, and the four things you can do about it.
///
/// There is no signed-out state to model: the catalogue gives everybody an
/// identity on first contact, so this screen always has somebody to describe.
/// Claiming turns that guest into an account *on the same row* — nothing is
/// copied and nothing is merged, which is why "register" here doesn't start
/// over with an empty history.
library;

import 'package:flutter/foundation.dart';
import 'package:kino_api/kino_api.dart';

import '../../core/async_value.dart';

class AccountViewModel extends ChangeNotifier {
  AccountViewModel(this._kino);

  final KinoClient _kino;

  AsyncValue<User> state = const Loading();
  bool busy = false;

  /// The last thing that happened, for the line under the form. A refusal from
  /// the server belongs here rather than in a dialog: it is usually "that email
  /// is taken", which is a correction, not an emergency.
  String? said;
  bool wentWrong = false;

  Future<void> load() async {
    try {
      state = Data(await _kino.whoAmI());
    } catch (problem) {
      state = Failure(problem);
    }
    notifyListeners();
  }

  Future<void> rename(String name) => _do(
        () async => _kino.rename(name.trim()),
        then: (user) => 'Now known as ${user.displayName}.',
      );

  /// Register: an email and a password written onto the account you already
  /// are. Everything watched as a guest stays where it is.
  Future<void> claim({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _do(
        () => _kino.claim(
          email: email.trim(),
          password: password,
          displayName: displayName?.trim().isEmpty ?? true ? null : displayName!.trim(),
        ),
        then: (user) => 'Account created for ${user.email}.',
      );

  Future<void> login({required String email, required String password}) => _do(
        () => _kino.login(email: email.trim(), password: password),
        then: (user) => 'Signed in as ${user.displayName}.',
      );

  /// Sign out, which here means becoming a new guest — this app is never
  /// nobody, so the next call would mint one anyway.
  Future<void> logout() => _do(
        () async {
          await _kino.logout();
          return _kino.whoAmI();
        },
        then: (_) => 'Signed out. You are a guest again.',
      );

  /// A second identity on the same device — "watch as somebody else".
  Future<void> newGuest() => _do(
        () => _kino.startGuest(),
        then: (user) => 'Now watching as ${user.displayName}.',
      );

  Future<void> _do(
    Future<User> Function() work, {
    required String Function(User) then,
  }) async {
    busy = true;
    said = null;
    wentWrong = false;
    notifyListeners();

    try {
      final user = await work();
      state = Data(user);
      said = then(user);
    } catch (problem) {
      said = '$problem';
      wentWrong = true;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
