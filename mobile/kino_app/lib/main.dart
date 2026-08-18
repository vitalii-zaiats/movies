/// Bootstrap, and nothing else.
///
/// Everything this app knows comes from `kino_api` over gRPC; the only HTTP it
/// makes is the video player fetching a stream. The three answers gathered here
/// — the client, the saved theme, and whether this is a television — are all
/// things the first frame needs, so they are awaited before there is one.
library;

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/kino.dart';
import 'core/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = await Settings.load();
  final television = await onTelevision();

  runApp(KinoApp(client: connect(), settings: settings, television: television));
}
