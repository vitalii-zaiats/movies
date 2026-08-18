/// Where the app's one client lives, and how it is addressed.
///
/// Two addresses, not one: gRPC has a port of its own, and the streams and
/// posters come over plain HTTP from nginx. The server deliberately hands out
/// paths (`/vod/7455/index.m3u8`) rather than URLs — it has no idea what
/// address this phone reached it on — so [KinoClient.mediaBase] is where the
/// app says.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kino_api/kino_api.dart';

/// `10.0.2.2` is how the Android emulator spells "the machine I'm running on".
/// On a real phone this is the LAN address of whatever is running compose:
///
///     flutter run --dart-define=KINO_HOST=192.168.0.10 \
///                 --dart-define=KINO_HTTP=http://192.168.0.10
const host = String.fromEnvironment('KINO_HOST', defaultValue: '10.0.2.2');
const grpcPort = int.fromEnvironment('KINO_GRPC_PORT', defaultValue: 50061);
const httpBase = String.fromEnvironment('KINO_HTTP', defaultValue: 'http://10.0.2.2');

/// Whether this is a television — asked of Android, because the answer decides
/// how the whole app is driven.
///
/// Not guessed from the screen size: a landscape tablet looks exactly like a
/// TV to a layout and behaves nothing like one. `UiModeManager` already knows,
/// and [MainActivity] passes the answer over.
const _device = MethodChannel('tv.kino/device');

Future<bool> onTelevision() async {
  try {
    return await _device.invokeMethod<bool>('isTelevision') ?? false;
  } on MissingPluginException {
    // Anything that isn't our Android host — a test, a desktop build.
    return false;
  } on PlatformException {
    return false;
  }
}

/// The client, handed down the tree rather than reached for globally — a screen
/// that takes its API from an ancestor can be dropped into a test with a
/// different one. [television] rides along because every screen has to know:
/// there is nothing to tap on a TV, so what is focused *is* what is selected.
class Kino extends InheritedWidget {
  const Kino({
    required this.client,
    required super.child,
    this.television = false,
    super.key,
  });

  final KinoClient client;
  final bool television;

  static KinoClient of(BuildContext context) => _find(context).client;

  static bool isTv(BuildContext context) => _find(context).television;

  static Kino _find(BuildContext context) {
    final found = context.dependOnInheritedWidgetOfExactType<Kino>();
    assert(found != null, 'No Kino client above this widget');
    return found!;
  }

  @override
  bool updateShouldNotify(Kino old) =>
      old.client != client || old.television != television;
}

KinoClient connect() => KinoClient(
      host: host,
      port: grpcPort,
      mediaBase: Uri.parse(httpBase),
    );

/// "S01E03", or nothing at all for a film.
String? episodeCode(Episode episode, {required bool isFilm}) {
  if (isFilm) return null;
  final season = episode.season.toString().padLeft(2, '0');
  final number = episode.episode.toString().padLeft(2, '0');
  if (episode.hasEpisodeEnd()) {
    return 'S${season}E$number-${episode.episodeEnd.toString().padLeft(2, '0')}';
  }
  return 'S${season}E$number';
}

/// What a tile says under the title.
String showSubtitle(ShowSummary summary) {
  if (summary.show.isFilm) {
    return summary.playableCount > 0 ? 'film' : 'film · no stream';
  }
  return '${summary.episodeCount} episodes · ${summary.playableCount} playable';
}
