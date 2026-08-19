/// The first thing anybody sees, once.
///
/// It exists because of the television. On a phone, "continue as guest" is the
/// only sensible default and this screen is a courtesy; on a sofa, an email
/// field behind a D-pad is the reason people give up, so the second option here
/// is the real one — a code on the screen, a phone that scans it, and no typing
/// at all.
///
/// Shown only when this device has no session yet. Choosing either way leaves
/// one behind, so the next launch opens straight into the catalogue.
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/kino.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/glyph.dart';
import 'welcome_view_model.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({required this.onSettled, super.key});

  /// Called once there is somebody — either way in. The app swaps this screen
  /// for the catalogue rather than pushing on top of it: there is nothing to
  /// come back to.
  final VoidCallback onSettled;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late final WelcomeViewModel _model;

  @override
  void initState() {
    super.initState();
    _model = WelcomeViewModel(
      Kino.read(context),
      // What the person holding the phone will read. The server falls back to
      // the user agent, which is a version string — nobody approves that.
      deviceName: Kino.readIsTv(context) ? 'Android TV' : 'kino on this phone',
    )..addListener(_settled);
  }

  void _settled() {
    if (_model.stage == Welcome.done) widget.onSettled();
  }

  @override
  void dispose() {
    _model.removeListener(_settled);
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final tv = Kino.isTv(context);

    return Scaffold(
      backgroundColor: palette.ground,
      body: SafeArea(
        // A television draws into the bezel; nothing important goes there.
        minimum: tv ? const EdgeInsets.all(48) : EdgeInsets.zero,
        child: ListenableBuilder(
          listenable: _model,
          builder: (context, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tv ? 720 : 460),
                child: switch (_model.stage) {
                  Welcome.choosing => _Fork(model: _model),
                  Welcome.waiting => _Code(model: _model),
                  Welcome.expired => _Expired(model: _model),
                  // A frame or two between "linked" and the catalogue replacing
                  // this screen.
                  Welcome.done => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The same conversation, reached later.
///
/// A guest who continued past the welcome — or who is signing in on a
/// television months afterwards — gets here from the account screen. It skips
/// the fork and asks for a code straight away, because arriving here *is* the
/// choice.
class LinkScreen extends StatefulWidget {
  const LinkScreen({super.key});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  late final WelcomeViewModel _model;

  @override
  void initState() {
    super.initState();
    _model = WelcomeViewModel(
      Kino.read(context),
      deviceName: Kino.readIsTv(context) ? 'Android TV' : 'kino on this phone',
    )
      ..addListener(_settled)
      ..linkDevice();
  }

  void _settled() {
    if (_model.stage != Welcome.done || !mounted) return;
    // Back to the account screen, which reloads and finds somebody new.
    Navigator.of(context).pop(_model.user);
  }

  @override
  void dispose() {
    _model.removeListener(_settled);
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final tv = Kino.isTv(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.ground,
      appBar: AppBar(title: Text(l10n.linkDevice)),
      body: SafeArea(
        minimum: tv ? const EdgeInsets.all(48) : EdgeInsets.zero,
        child: ListenableBuilder(
          listenable: _model,
          builder: (context, _) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: tv ? 720 : 460),
                child: switch (_model.stage) {
                  // `linkDevice()` is already running; this is the moment before
                  // the server answers.
                  Welcome.choosing => _model.problem == null
                      ? const Center(child: CircularProgressIndicator())
                      : _Problem(problem: _model.problem!),
                  Welcome.waiting => _Code(model: _model),
                  Welcome.expired => _Expired(model: _model),
                  Welcome.done => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The two ways in.
class _Fork extends StatelessWidget {
  const _Fork({required this.model});

  final WelcomeViewModel model;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);
    final tv = Kino.isTv(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.welcome.toUpperCase(), style: kicker(palette.accent)),
        const SizedBox(height: 8),
        Text('kino', style: heading(tv ? 64 : 48, color: palette.text)),
        const SizedBox(height: 16),
        Text(l10n.welcomeBlurb, style: body(15, color: palette.muted)),
        const SizedBox(height: 32),

        // A television lands here with nothing focused otherwise, and an
        // unfocused D-pad screen is a dead end.
        _Choice(
          label: l10n.continueAsGuest,
          glyph: Glyphs.play,
          primary: true,
          autofocus: true,
          busy: model.busy,
          onPressed: model.asGuest,
        ),
        const SizedBox(height: 12),
        _Choice(
          label: l10n.signInOnAnotherDevice,
          glyph: Glyphs.newPerson,
          busy: model.busy,
          onPressed: model.linkDevice,
        ),
        const SizedBox(height: 12),
        Text(l10n.signInOnAnotherDeviceBlurb, style: body(13, color: palette.faint)),

        if (model.problem != null) ...[
          const SizedBox(height: 24),
          _Problem(problem: model.problem!),
        ],
      ],
    );
  }
}

/// A code, big enough to read from a sofa and to scan from a metre away.
class _Code extends StatelessWidget {
  const _Code({required this.model});

  final WelcomeViewModel model;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);
    final tv = Kino.isTv(context);
    final url = model.url;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.linkDevice.toUpperCase(), style: kicker(palette.accent)),
        const SizedBox(height: 8),
        Text(l10n.scanThis, style: heading(tv ? 34 : 26, color: palette.text)),
        const SizedBox(height: 24),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (url != null) ...[
              // Always on white, in both themes: a scanner reads dark-on-light,
              // and an inverted QR is one many phones simply refuse.
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: QrImageView(
                  data: url.toString(),
                  size: tv ? 220 : 180,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.code ?? '',
                    style: heading(tv ? 46 : 38, color: palette.text).copyWith(
                      // The one string here that gets read out loud and typed
                      // back in — letter spacing is what stops that going wrong.
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (url != null)
                    Text(
                      l10n.orOpen(url.host + url.path),
                      style: body(14, color: palette.muted),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.faint,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(l10n.waitingForPhone, style: body(13, color: palette.faint)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.codeExpiresIn(_clock(model.secondsLeft)),
                    style: body(13, color: palette.faint),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),
        _Choice(
          label: l10n.notNow,
          glyph: Glyphs.back,
          autofocus: true,
          // Reached from the welcome there is a fork to go back to; reached from
          // the account screen there is a screen to leave.
          onPressed: () => Navigator.of(context).canPop()
              ? Navigator.of(context).pop()
              : model.backToChoosing(),
        ),
      ],
    );
  }
}

class _Expired extends StatelessWidget {
  const _Expired({required this.model});

  final WelcomeViewModel model;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.linkDevice.toUpperCase(), style: kicker(palette.accent)),
        const SizedBox(height: 8),
        Text(l10n.codeExpired, style: heading(24, color: palette.text)),
        const SizedBox(height: 28),
        _Choice(
          label: l10n.askForNewCode,
          glyph: Glyphs.forward,
          primary: true,
          autofocus: true,
          busy: model.busy,
          onPressed: model.linkDevice,
        ),
        const SizedBox(height: 12),
        _Choice(
          label: l10n.notNow,
          glyph: Glyphs.back,
          onPressed: model.backToChoosing,
        ),
      ],
    );
  }
}

/// One full-width button. Square, like everything else here, and wide enough
/// that a D-pad can't miss it.
class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.glyph,
    required this.onPressed,
    this.primary = false,
    this.autofocus = false,
    this.busy = false,
  });

  final String label;
  final GlyphSpec glyph;
  final VoidCallback onPressed;
  final bool primary;
  final bool autofocus;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final tv = Kino.isTv(context);
    final height = tv ? 60.0 : 52.0;

    final ink = primary ? palette.onAccent : palette.text;
    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size.fromHeight(height)),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
      backgroundColor: WidgetStatePropertyAll(primary ? palette.accent : palette.panel),
      foregroundColor: WidgetStatePropertyAll(ink),
      side: WidgetStatePropertyAll(
        primary ? BorderSide.none : BorderSide(color: palette.line, width: 2),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        style: style,
        autofocus: autofocus,
        onPressed: busy ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Glyph(glyph, size: 18, color: ink),
            const SizedBox(width: 10),
            Text(label, style: heading(tv ? 18 : 15, color: ink)),
          ],
        ),
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.problem});

  final Object problem;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: palette.line, width: 2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Glyph(Glyphs.blocked, size: 18, color: palette.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.couldntReach, style: heading(15, color: palette.text)),
                const SizedBox(height: 4),
                Text('$problem', style: body(12, color: palette.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _clock(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
