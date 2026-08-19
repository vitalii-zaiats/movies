/// Bootstrap, and nothing else.
///
/// Everything this app knows comes from `kino_api` over gRPC; the only HTTP it
/// makes is the video player fetching a stream. The four answers gathered here
/// — the client, the saved theme, whether this is a television, and whether
/// anybody has been here before — are all things the first frame needs, so they
/// are awaited before there is one.
library;

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/kino.dart';
import 'core/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = await Settings.load();
  final television = await onTelevision();

  final client = connect();
  // No token means nobody has ever opened this app here. That is the whole test
  // for a first launch — no separate "have they seen the welcome" flag to fall
  // out of step with the thing it is supposed to describe.
  final firstLaunch = await client.token == null;

  runApp(
    KinoApp(
      client: client,
      settings: settings,
      television: television,
      firstLaunch: firstLaunch,
    ),
  );
}
