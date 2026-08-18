/// The player: landscape, full screen, and its own controls.
///
/// Two things happen around the video. It opens where it was left, and it says
/// where it is every ten seconds — the server decides what that means, and past
/// 95% counts as finished unless the player says otherwise, which here it does,
/// because "the video ended" beats any threshold.
///
/// The rest is what a video wants and a scrolling page can't give it: the whole
/// screen, turned sideways, with chrome that gets out of the way. Material ships
/// a progress bar and nothing else, so the transport is written out here — and
/// the same three actions are the D-pad, so a remote drives this player rather
/// than a second one written for televisions.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kino_api/kino_api.dart';
import 'package:video_player/video_player.dart';

import '../../core/formatting.dart';
import '../../core/kino.dart';
import '../../core/theme.dart';
import '../../widgets/glyph.dart';

/// How often a position is worth writing down. Ten seconds of lost place is
/// nothing; a request per frame is not.
const _reportEvery = Duration(seconds: 10);

/// What one press of left or right is worth — the step every remote in the
/// house already means by it.
const _step = Duration(seconds: 10);

/// How long the chrome stays once it has been asked for.
const _linger = Duration(seconds: 4);

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({required this.episode, required this.show, super.key});

  final Episode episode;
  final Show show;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  /// Held rather than looked up: `dispose` writes one last bookmark, and by then
  /// this widget is on its way out of the tree and can't reach an ancestor.
  late final KinoClient _kino = Kino.read(context);
  late final bool _tv = Kino.readIsTv(context);

  VideoPlayerController? _player;
  Timer? _ticker;
  Timer? _hide;
  Object? _problem;
  bool _showing = true;

  /// Which dub is playing. Null is whatever the episode came with.
  Track? _voice;

  @override
  void initState() {
    super.initState();

    if (!_tv) {
      // A television is already sideways and has no accelerometer to argue
      // with; a phone has to be told, and told back on the way out.
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    _open();
    _wake();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _hide?.cancel();
    // One last bookmark on the way out: leaving is the commonest way to stop
    // watching, and it fires no pause.
    _report();
    _player?.dispose();

    if (!_tv) _standUpAgain();
    super.dispose();
  }

  /// Put the device back upright, and leave it there.
  ///
  /// Two ways of getting this wrong, both tried. `DeviceOrientation.values`
  /// *allows* every orientation rather than asking for one, and a screen
  /// already sideways has no reason to turn back. Asking for portrait and then
  /// relaxing to `values` a moment later is the same bug with a delay: on
  /// Android "unspecified" with auto-rotate off means "stay as you are", so the
  /// relax undoes the request as soon as it lands.
  ///
  /// So portrait is asked for and kept. Every screen but this one is a list, and
  /// none of them wants to be sideways.
  void _standUpAgain() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  Future<void> _open({Track? voice}) async {
    final url = voice == null ? _kino.streamUrl(widget.episode) : _kino.trackUrl(voice);
    if (url == null) {
      setState(() => _problem = 'This episode was never packaged.');
      return;
    }

    final previous = _player;
    _ticker?.cancel();

    // Where to open: a voice swap carries on where the last one stopped, a
    // fresh episode asks the server where it was left.
    var start = previous?.value.position ?? Duration.zero;
    if (previous == null) {
      final saved = await _kino.progress(widget.episode.id);
      if (saved != null && !saved.completed) {
        start = Duration(milliseconds: (saved.positionSeconds * 1000).round());
      }
    }

    final player = VideoPlayerController.networkUrl(url);
    try {
      await player.initialize();
      if (!mounted) {
        await player.dispose();
        return;
      }
      if (start > Duration.zero) await player.seekTo(start);
      await player.play();
    } catch (problem) {
      await player.dispose();
      if (mounted) setState(() => _problem = problem);
      return;
    }

    await previous?.dispose();
    if (!mounted) {
      await player.dispose();
      return;
    }

    setState(() {
      _player = player;
      _voice = voice;
      _problem = null;
    });
    _ticker = Timer.periodic(_reportEvery, (_) => _report());
    _wake();
  }

  void _report() {
    final player = _player;
    if (player == null || !player.value.isInitialized) return;

    final position = player.value.position.inMilliseconds / 1000;
    final duration = player.value.duration.inMilliseconds / 1000;
    // Fire and forget: a lost bookmark is not worth interrupting a film for.
    _kino
        .report(
          episodeId: widget.episode.id,
          positionSeconds: position,
          durationSeconds: duration > 0 ? duration : null,
          completed: player.value.position >= player.value.duration ? true : null,
        )
        .catchError((Object _) => Progress());
  }

  // --- chrome ---------------------------------------------------------------

  /// Draw the controls, and start counting down to hiding them again. A paused
  /// player keeps them: nobody pauses in order to look at the picture.
  void _wake() {
    _hide?.cancel();
    if (!_showing) setState(() => _showing = true);
    _hide = Timer(_linger, () {
      if (mounted && (_player?.value.isPlaying ?? false)) {
        setState(() => _showing = false);
      }
    });
  }

  void _toggleChrome() {
    if (!_showing) return _wake();
    _hide?.cancel();
    setState(() => _showing = false);
  }

  void _toggle() {
    final player = _player;
    if (player == null) return;
    setState(() => player.value.isPlaying ? player.pause() : player.play());
    _report();
    _wake();
  }

  void _skip(Duration by) {
    final player = _player;
    if (player == null) return;
    final at = player.value.position + by;
    player.seekTo(at < Duration.zero ? Duration.zero : at);
    _wake();
  }

  /// The remote, as the four keys that mean anything here.
  ///
  /// Transport only — a remote should never change *what* is playing by
  /// accident, and Back already means "leave", which every viewer knows.
  KeyEventResult _pressed(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.select:
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.mediaPlayPause:
        _toggle();
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.mediaRewind:
        _skip(-_step);
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.mediaFastForward:
        _skip(_step);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    final playing = player != null && player.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        onKeyEvent: _pressed,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleChrome,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (playing)
                Center(
                  child: AspectRatio(
                    aspectRatio: player.value.aspectRatio,
                    child: VideoPlayer(player),
                  ),
                )
              else if (_problem != null)
                _Failed(problem: _problem!)
              else
                const Center(child: CircularProgressIndicator(color: paper)),
              if (playing)
                AnimatedOpacity(
                  opacity: _showing ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: !_showing,
                    child: _Chrome(
                      player: player,
                      episode: widget.episode,
                      show: widget.show,
                      voice: _voice,
                      tv: _tv,
                      onToggle: _toggle,
                      onSkip: _skip,
                      onSeek: (at) {
                        player.seekTo(at);
                        _wake();
                      },
                      onVoice: (track) => _open(voice: track),
                    ),
                  ),
                ),
              // With no picture there is nothing to reveal by tapping, so the
              // way out has to stay drawn.
              if (!playing) const Align(alignment: Alignment.topLeft, child: _Back()),
            ],
          ),
        ),
      ),
    );
  }
}

/// What went wrong, said plainly.
///
/// Usually one of two things: this episode was never packaged, or the host the
/// stream lives on answered 502 — which ashdi does often enough to have its own
/// retry pass in the resolver. Neither is the viewer's doing and both are worth
/// reading, so this is paper on ink rather than grey on black.
class _Failed extends StatelessWidget {
  const _Failed({required this.problem});

  final Object problem;

  @override
  Widget build(BuildContext context) {
    final text = '$problem';
    final upstream = text.contains('502');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              upstream ? 'THE SOURCE DIDN’T ANSWER' : 'NOTHING TO PLAY',
              style: kicker(accent500),
            ),
            const SizedBox(height: 10),
            Text(
              upstream
                  ? 'The stream is registered, but the host behind it returned 502. '
                      'Worth trying again later.'
                  : text,
              textAlign: TextAlign.center,
              style: body(14, color: inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Back extends StatelessWidget {
  const _Back();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: IconButton(
          icon: const Glyph(Glyphs.back, color: paper),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      );
}

/// Everything drawn over the picture: what's playing at the top, transport in
/// the middle, the scrubber at the bottom. Rebuilt from the controller rather
/// than from a clock of its own — there is one source of the time here.
///
/// Always ink and paper, whatever the app's theme: this sits over video, and a
/// light scrim over a bright scene is a control nobody can find.
class _Chrome extends StatelessWidget {
  const _Chrome({
    required this.player,
    required this.episode,
    required this.show,
    required this.voice,
    required this.tv,
    required this.onToggle,
    required this.onSkip,
    required this.onSeek,
    required this.onVoice,
  });

  final VideoPlayerController player;
  final Episode episode;
  final Show show;
  final Track? voice;
  final bool tv;
  final VoidCallback onToggle;
  final void Function(Duration) onSkip;
  final void Function(Duration) onSeek;
  final void Function(Track) onVoice;

  @override
  Widget build(BuildContext context) {
    final dubs = episode.tracks.where((track) => track.hasAudio()).toList();
    final code = episodeCode(episode, isFilm: show.isFilm);

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: player,
      builder: (context, value, _) {
        final total = value.duration.inMilliseconds.toDouble();
        final at = value.position.inMilliseconds.toDouble();

        return DecoratedBox(
          // Ink at both ends, clear through the middle: the picture is the
          // point, and a scrim over all of it is chrome pretending to be a page.
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC201E1D), Colors.transparent, Color(0xE6201E1D)],
              stops: [0, 0.4, 1],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    const _Back(),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            show.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: heading(17, color: paper),
                          ),
                          if (code != null || episode.title != show.title)
                            Text(
                              [?code, episode.title].join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: body(12, color: inkMuted),
                            ),
                        ],
                      ),
                    ),
                    if (dubs.length > 1)
                      PopupMenuButton<Track>(
                        icon: const Glyph(Glyphs.voice, color: paper),
                        tooltip: 'Voice',
                        onSelected: onVoice,
                        itemBuilder: (context) => [
                          for (final track in dubs)
                            PopupMenuItem(
                              value: track,
                              child: Row(
                                children: [
                                  Glyph(
                                    track.vodId == voice?.vodId
                                        ? Glyphs.check
                                        : Glyphs.dot,
                                    size: 16,
                                    color: track.vodId == voice?.vodId ? accent500 : neutral500,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(track.audio),
                                ],
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(width: 4),
                  ],
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Key(glyph: Glyphs.rewind, onTap: () => onSkip(-_step)),
                      const SizedBox(width: 28),
                      _Key(
                        glyph: value.isPlaying ? Glyphs.pause : Glyphs.play,
                        big: true,
                        onTap: onToggle,
                      ),
                      const SizedBox(width: 28),
                      _Key(glyph: Glyphs.forward, onTap: () => onSkip(_step)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(
                    children: [
                      Text(clock(value.position), style: body(12, color: paper)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            activeTrackColor: accent500,
                            inactiveTrackColor: const Color(0x66F3F2F2),
                            thumbColor: accent500,
                            overlayShape: SliderComponentShape.noOverlay,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            // A duration can arrive after the first position
                            // does, and a seek can land past the end; either way
                            // a value off its own track is an exception rather
                            // than a picture.
                            value: total <= 0 ? 0 : at.clamp(0, total),
                            max: total <= 0 ? 1 : total,
                            onChanged: (to) => onSeek(Duration(milliseconds: to.round())),
                          ),
                        ),
                      ),
                      Text(clock(value.duration), style: body(12, color: paper)),
                    ],
                  ),
                ),
                if (tv)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'OK — PLAY OR PAUSE · ◀ ▶ — 10 SECONDS · BACK — LEAVE',
                      style: body(11, weight: 600, color: inkMuted),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Square, like everything else here — only the size changes between "the main
/// thing" and "the other two".
class _Key extends StatelessWidget {
  const _Key({required this.glyph, required this.onTap, this.big = false});

  final GlyphSpec glyph;
  final VoidCallback onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 64.0 : 48.0;
    return Material(
      color: big ? accent : const Color(0x33F3F2F2),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        onTap: onTap,
        focusColor: accent200,
        child: SizedBox(
          width: size,
          height: size,
          // Heavier over video: a two-pixel line vanishes against a bright
          // scene, and this is the one control that must never be hunted for.
          child: Glyph(glyph, color: paper, size: big ? 30 : 22, weight: 2.5),
        ),
      ),
    );
  }
}
