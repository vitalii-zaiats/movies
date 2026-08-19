/// Who you are here, and the four things you can do about it.
///
/// There is no signed-out state to model: the catalogue gives everybody an
/// identity on first contact, so this screen always has somebody to describe.
/// Claiming turns that guest into an account *on the same row* — nothing is
/// copied and nothing is merged, which is why "register" here doesn't start over
/// with an empty history.
library;

import 'package:flutter/foundation.dart';
import 'package:kino_api/kino_api.dart';

import '../../core/async_value.dart';

/// What just happened, as a fact rather than a sentence. This layer has no
/// `BuildContext` and therefore no language; a screen handed English cannot
/// translate it back.
enum Did { renamed, created, signedIn, signedOut, switched }

sealed class Note {
  const Note();
}

final class Done extends Note {
  const Done(this.did, this.detail);

  final Did did;

  /// The one thing the sentence needs: a name, or an email.
  final String detail;
}

final class Refused extends Note {
  const Refused(this.problem);

  /// The server's own words — usually "that email is taken", which is a
  /// correction rather than an emergency.
  final Object problem;
}

class AccountViewModel extends ChangeNotifier {
  AccountViewModel(this._kino);

  final KinoClient _kino;

  AsyncValue<User> state = const Loading();
  bool busy = false;
  Note? note;

  Future<void> load() async {
    try {
      state = Data(await _kino.whoAmI());
    } catch (problem) {
      state = Failure(problem);
    }
    notifyListeners();
  }

  Future<void> rename(String name) =>
      _do(() => _kino.rename(name.trim()), Did.renamed, (user) => user.displayName);

  /// Register: an email and a password written onto the account you already are.
  /// Everything watched as a guest stays where it is.
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
        Did.created,
        (user) => user.email,
      );

  Future<void> login({required String email, required String password}) => _do(
        () => _kino.login(email: email.trim(), password: password),
        Did.signedIn,
        (user) => user.displayName,
      );

  /// Sign out, which here means becoming a new guest — this app is never nobody,
  /// so the next call would mint one anyway.
  Future<void> logout() => _do(
        () async {
          await _kino.logout();
          return _kino.whoAmI();
        },
        Did.signedOut,
        (user) => user.displayName,
      );

  /// A second identity on the same device — "watch as somebody else".
  Future<void> newGuest() =>
      _do(() => _kino.startGuest(), Did.switched, (user) => user.displayName);

  Future<void> _do(
    Future<User> Function() work,
    Did did,
    String Function(User) detail,
  ) async {
    busy = true;
    note = null;
    notifyListeners();

    try {
      final user = await work();
      state = Data(user);
      note = Done(did, detail(user));
    } catch (problem) {
      note = Refused(problem);
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
