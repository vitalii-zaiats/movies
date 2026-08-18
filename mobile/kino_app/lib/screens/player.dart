/// The player, and the bookkeeping that makes "continue watching" true.
///
/// Two things happen around the video: it opens where it was left, and it says
/// where it is every ten seconds. The server decides what that means — past 95%
/// counts as finished unless the player says otherwise, and here it does say,
/// because "the video ended" beats any threshold.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kino_api/kino_api.dart';
import 'package:video_player/video_player.dart';

import '../kino.dart';

/// How often a position is worth writing down. Ten seconds of lost place is
/// nothing; a request per frame is not.
const _reportEvery = Duration(seconds: 10);

/// What one press of left or right is worth. Ten seconds is the step every
/// remote in the house already means by it.
const _step = Duration(seconds: 10);

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({required this.episode, required this.show, super.key});

  final Episode episode;
  final Show show;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  /// Held rather than looked up: `dispose` writes one last bookmark, and by
  /// then this widget is on its way out of the tree and can't reach an
  /// ancestor any more.
  late final KinoClient _kino;

  VideoPlayerController? _player;
  Timer? _ticker;
  Object? _problem;
  bool _ready = false;

  /// Which dub is playing. Null is whatever the episode came with.
  Track? _voice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) {
      _ready = true;
      _kino = Kino.of(context);
      _open();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // One last bookmark on the way out: leaving is the commonest way to stop
    // watching, and it fires no pause.
    _report();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _open({Track? voice}) async {
    final url = voice == null ? _kino.streamUrl(widget.episode) : _kino.trackUrl(voice);
    if (url == null) {
      setState(() => _problem = 'This episode was never packaged.');
      return;
    }

    final previous = _player;
    _ticker?.cancel();

    // Where to open: the voice swap carries on where the last one stopped, a
    // fresh episode asks the server where it was left.
    Duration start = previous?.value.position ?? Duration.zero;
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
      if (mounted) setState(() => _problem = problem);
      await player.dispose();
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

  void _toggle() {
    final player = _player;
    if (player == null) return;
    setState(() {
      player.value.isPlaying ? player.pause() : player.play();
    });
    _report();
  }

  void _skip(Duration by) {
    final player = _player;
    if (player == null) return;
    final at = player.value.position + by;
    player.seekTo(at < Duration.zero ? Duration.zero : at);
  }

  /// The remote, as the four keys that mean anything here.
  ///
  /// Transport only — a TV remote should never be able to change *what* is
  /// playing by accident, and back already means "leave", which is the one
  /// gesture every viewer knows.
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
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.mediaRewind:
        _skip(-_step);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.mediaFastForward:
        _skip(_step);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = _player;
    final tv = Kino.isTv(context);
    final code = episodeCode(widget.episode, isFilm: widget.show.isFilm);
    final dubs = widget.episode.tracks.where((track) => track.hasAudio()).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.show.title)),
      body: Focus(
        autofocus: true,
        onKeyEvent: _pressed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: player?.value.aspectRatio ?? 16 / 9,
              child: switch ((player, _problem)) {
                (_, final problem?) => ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('$problem', textAlign: TextAlign.center),
                    ),
                  ),
                ),
                (final ready?, _) when ready.value.isInitialized => Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(ready),
                    VideoProgressIndicator(ready, allowScrubbing: true),
                  ],
                ),
                _ => const ColoredBox(
                  color: Colors.black,
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (code != null) Text(code, style: Theme.of(context).textTheme.labelMedium),
                  Text(widget.episode.title, style: Theme.of(context).textTheme.titleMedium),
                  if (dubs.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          for (final track in dubs)
                            ChoiceChip(
                              label: Text(track.audio),
                              selected: _voice?.vodId == track.vodId,
                              // Switching voice is switching stream — same
                              // episode, another file, so the position is carried
                              // over rather than restarted.
                              onSelected: (_) => _open(voice: track),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (tv)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OK — play or pause · ◀ ▶ — 10 seconds · Back — leave'),
              ),
          ],
        ),
      ),
      // A television has nothing to tap: the same three things are the D-pad,
      // and a button nobody can reach is worse than no button.
      floatingActionButton: player == null || tv
          ? null
          : FloatingActionButton(
              onPressed: _toggle,
              child: Icon(player.value.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
    );
  }
}
