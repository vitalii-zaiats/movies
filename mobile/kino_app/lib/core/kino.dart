/// Where the app's one client lives, and how it is addressed.
///
/// Two addresses, not one: gRPC has a port of its own, and the streams and
/// posters come over plain HTTP from nginx. The server deliberately hands out
/// paths (`/vod/7455/index.m3u8`) rather than URLs — it has no idea what address
/// this device reached it on — so [KinoClient.mediaBase] is where the app says.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kino_api/kino_api.dart';

/// `10.0.2.2` is how the Android emulator spells "the machine I'm running on";
/// an iOS simulator shares the host's loopback and wants `127.0.0.1`. On a real
/// device it's the LAN address of whatever is running compose:
///
///     flutter run --dart-define=KINO_HOST=192.168.0.10 \
///                 --dart-define=KINO_HTTP=http://192.168.0.10
const host = String.fromEnvironment('KINO_HOST', defaultValue: '10.0.2.2');
const grpcPort = int.fromEnvironment('KINO_GRPC_PORT', defaultValue: 50061);
const httpBase = String.fromEnvironment('KINO_HTTP', defaultValue: 'http://10.0.2.2');

KinoClient connect() => KinoClient(
      host: host,
      port: grpcPort,
      mediaBase: Uri.parse(httpBase),
    );

/// Whether this is a television — asked of Android, because the answer decides
/// how the whole app is driven.
///
/// Not guessed from the screen size: a landscape tablet looks identical to a
/// layout and behaves nothing like one. `UiModeManager` already knows, and
/// `MainActivity` passes the answer over.
const _device = MethodChannel('tv.kino/device');

/// Wear the television layout anywhere:
///
///     flutter run -d macos --dart-define=KINO_TV=true
///
/// For looking at the leanback screens on a desktop, where `UiModeManager`
/// isn't. Most of that layout is testable there — a remote sends arrow keys and
/// Select, which is what a keyboard sends — and the one thing that isn't is the
/// question this flag answers.
const forcedTelevision = bool.fromEnvironment('KINO_TV');

Future<bool> onTelevision() async {
  if (forcedTelevision) return true;

  try {
    return await _device.invokeMethod<bool>('isTelevision') ?? false;
  } on MissingPluginException {
    // Anything that isn't our Android host — a test, an iOS build.
    return false;
  } on PlatformException {
    return false;
  }
}

/// The client, handed down the tree rather than reached for globally: a screen
/// that takes its API from an ancestor can be dropped into a test with another
/// one. [television] rides along because every screen has to know — there is
/// nothing to tap on a TV, so what is focused *is* what is selected.
class Kino extends InheritedWidget {
  const Kino({
    required this.client,
    required super.child,
    this.television = false,
    super.key,
  });

  final KinoClient client;
  final bool television;

  /// For `build`, where depending on an ancestor is the point.
  static KinoClient of(BuildContext context) => _watch(context).client;

  static bool isTv(BuildContext context) => _watch(context).television;

  /// For `initState`, where depending on one is an error.
  ///
  /// This widget never changes for the life of the app — it is created once in
  /// `main` — so reading it without registering a dependency is safe here and
  /// saves every screen an otherwise pointless `didChangeDependencies`.
  static KinoClient read(BuildContext context) => _read(context).client;

  static bool readIsTv(BuildContext context) => _read(context).television;

  static Kino _watch(BuildContext context) {
    final found = context.dependOnInheritedWidgetOfExactType<Kino>();
    assert(found != null, 'No Kino above this widget');
    return found!;
  }

  static Kino _read(BuildContext context) {
    final found = context.getInheritedWidgetOfExactType<Kino>();
    assert(found != null, 'No Kino above this widget');
    return found!;
  }

  @override
  bool updateShouldNotify(Kino old) =>
      old.client != client || old.television != television;
}
