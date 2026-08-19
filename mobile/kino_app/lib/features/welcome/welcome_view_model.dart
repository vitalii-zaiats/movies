/// The first launch, as a state machine.
///
/// Two ways in and they are not equal: being a guest is one call and no
/// decisions, while linking is a conversation with a phone that may never
/// happen. So the second one owns most of this file — a code to show, a clock
/// running out, and a poll that has to know the difference between "not yet"
/// and "stop asking".
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kino_api/kino_api.dart';

/// Where the welcome is in its two conversations.
enum Welcome {
  /// The fork: be a guest, or fetch a code.
  choosing,

  /// A code is on screen and a phone hasn't answered yet.
  waiting,

  /// The code ran out. Recoverable — ask for another.
  expired,

  /// Somebody said yes, or the guest was minted. Either way, we're in.
  done,
}

class WelcomeViewModel extends ChangeNotifier {
  WelcomeViewModel(this._kino, {this.deviceName});

  final KinoClient _kino;

  /// What the person approving reads: "Android TV", not a package name.
  final String? deviceName;

  Welcome stage = Welcome.choosing;
  bool busy = false;
  Object? problem;

  /// Who we ended up as. Null until [stage] is [Welcome.done].
  User? user;

  DeviceLink? _link;
  Timer? _clock;
  Timer? _poll;
  int _left = 0;

  /// The code as it should be read aloud, or null when there isn't one.
  String? get code => _link?.code;

  /// What the phone should open — the QR's contents.
  Uri? get url => _link == null ? null : _kino.linkUrl(_link!);

  /// Seconds before the code stops working.
  int get secondsLeft => _left;

  /// Skip the ceremony: the catalogue gives everybody an identity, so being a
  /// guest is not a lesser mode — it is the same account, minus a way back into
  /// it from another device.
  Future<void> asGuest() async {
    busy = true;
    problem = null;
    notifyListeners();

    try {
      user = await _kino.whoAmI();
      stage = Welcome.done;
    } catch (failure) {
      problem = failure;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Ask for a code and start watching for an answer.
  Future<void> linkDevice() async {
    busy = true;
    problem = null;
    notifyListeners();

    try {
      _link = await _kino.startLink(deviceName: deviceName);
      stage = Welcome.waiting;
      _startClocks(_link!.expiresIn);
    } catch (failure) {
      problem = failure;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Back to the fork — and stop asking about a code nobody is going to approve.
  void backToChoosing() {
    _stopClocks();
    _link = null;
    problem = null;
    stage = Welcome.choosing;
    notifyListeners();
  }

  void _startClocks(int seconds) {
    _stopClocks();
    _left = seconds;

    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      _left -= 1;
      if (_left <= 0) {
        _left = 0;
        _stopClocks();
        stage = Welcome.expired;
      }
      notifyListeners();
    });

    // Two seconds, not milliseconds: the thing being waited for is a person
    // finding their phone, and a tighter poll only makes the server busier
    // while they look for it.
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _collect());
  }

  void _stopClocks() {
    _clock?.cancel();
    _poll?.cancel();
    _clock = null;
    _poll = null;
  }

  Future<void> _collect() async {
    final link = _link;
    if (link == null) return;

    try {
      final linked = await _kino.collectLink(link.secret);
      if (linked == null) return; // Still walking to the phone.

      user = linked;
      stage = Welcome.done;
      _stopClocks();
      notifyListeners();
    } on GrpcError catch (failure) {
      // The server has decided this code is finished — expired, already
      // collected, or never existed. Polling harder won't change its mind.
      _stopClocks();
      stage = Welcome.expired;
      problem = failure;
      notifyListeners();
    } catch (_) {
      // A dropped connection, most likely. The next tick tries again — which is
      // the whole reason this is a poll and not a stream.
    }
  }

  @override
  void dispose() {
    _stopClocks();
    super.dispose();
  }
}
