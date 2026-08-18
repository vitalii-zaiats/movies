/// A small catalogue app: browse, open, play, and be remembered.
///
/// Everything it knows comes from `kino_api` over gRPC — there is no HTTP call
/// anywhere in this app except the one the video player makes for the stream
/// itself.
///
/// One app, two ways of being driven. On a phone you touch things. On a
/// television there is nothing to touch: a remote moves focus around and
/// presses it, which in Flutter is `NavigationMode.directional` — and once that
/// is on, whatever is focused has to *look* focused, or the viewer is pressing
/// buttons blind.
library;

import 'package:flutter/material.dart';
import 'package:kino_api/kino_api.dart';

import 'kino.dart';
import 'screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(KinoApp(client: connect(), television: await onTelevision()));
}

class KinoApp extends StatelessWidget {
  const KinoApp({required this.client, this.television = false, super.key});

  final KinoClient client;
  final bool television;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE0552B),
      brightness: Brightness.dark,
    );

    return Kino(
      client: client,
      television: television,
      child: MaterialApp(
        title: 'kino',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: scheme,
          // Loud on purpose. On a phone this is barely used; on a TV it is the
          // only thing telling you where you are.
          focusColor: scheme.primary.withValues(alpha: 0.30),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // A remote moves focus; it doesn't tap. Without this, focus is
            // decorative and half the app can't be reached from a sofa.
            navigationMode:
                television ? NavigationMode.directional : NavigationMode.traditional,
            // Three metres away, phone-sized type is unreadable.
            textScaler: television
                ? const TextScaler.linear(1.25)
                : MediaQuery.textScalerOf(context),
          ),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
