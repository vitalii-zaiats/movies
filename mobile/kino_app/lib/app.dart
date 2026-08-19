/// The app: two scopes, two themes, two languages, and one screen to start on.
///
/// One binary in several moods and on two kinds of device. On a phone you touch
/// things; on a television there is nothing to touch — a remote moves focus and
/// presses it, which in Flutter is `NavigationMode.directional`, and once that
/// is on, whatever is focused has to *look* focused.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kino_api/kino_api.dart';

import 'core/kino.dart';
import 'core/settings.dart';
import 'core/theme.dart';
import 'features/home/home_screen.dart';
import 'features/welcome/welcome_screen.dart';
import 'l10n/app_localizations.dart';

/// The chosen theme and language, handed down so the account screen can change
/// them.
class SettingsScope extends InheritedNotifier<Settings> {
  const SettingsScope({required Settings super.notifier, required super.child, super.key});

  static Settings of(BuildContext context) {
    final found = context.dependOnInheritedWidgetOfExactType<SettingsScope>();
    assert(found != null, 'No SettingsScope above this widget');
    return found!.notifier!;
  }
}

class KinoApp extends StatelessWidget {
  const KinoApp({
    required this.client,
    required this.settings,
    this.television = false,
    this.firstLaunch = false,
    super.key,
  });

  final KinoClient client;
  final Settings settings;
  final bool television;

  /// Nobody has a session on this device yet, so ask how they'd like one.
  final bool firstLaunch;

  @override
  Widget build(BuildContext context) {
    return Kino(
      client: client,
      television: television,
      child: SettingsScope(
        notifier: settings,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => MaterialApp(
            title: 'kino',
            debugShowCheckedModeBanner: false,
            // The same design system the web app wears, in both lights.
            theme: modernist(Brightness.light),
            darkTheme: modernist(Brightness.dark),
            themeMode: settings.theme,
            // Null follows the phone; anything else is a deliberate choice made
            // on the account screen.
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
            home: _Entry(welcome: firstLaunch),
          ),
        ),
      ),
    );
  }
}

/// Which screen the app opens on.
///
/// The welcome is not a route: there is nothing to go back to once somebody is
/// signed in, and leaving it on the stack would mean a remote's Back button
/// landing on a choice that has already been made. So it is swapped out.
class _Entry extends StatefulWidget {
  const _Entry({required this.welcome});

  final bool welcome;

  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  late bool _welcome = widget.welcome;

  @override
  Widget build(BuildContext context) => _welcome
      ? WelcomeScreen(onSettled: () => setState(() => _welcome = false))
      : const HomeScreen();
}
