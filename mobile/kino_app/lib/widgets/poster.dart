/// Posters, and what to draw when there isn't one.
///
/// Most rows have no artwork at all — the crawlers find a thumbnail for maybe
/// half of them — so the placeholder is the common case rather than an error
/// state. It is drawn from the key, so the same show is the same tone every
/// time, which turns out to be enough to recognise a tile by.
library;

import 'package:flutter/material.dart';

import '../core/theme.dart';

class Poster extends StatelessWidget {
  const Poster({
    required this.url,
    required this.seed,
    this.width = 92,
    this.aspect = posterRatio,
    super.key,
  });

  final Uri? url;
  final String seed;
  final double width;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final art = url;

    return DecoratedBox(
      // No rounded corners anywhere in this system, and a poster is where the
      // exception would be most tempting.
      decoration: BoxDecoration(border: Border.all(color: palette.line)),
      child: SizedBox(
        width: width,
        height: width / aspect,
        child: art == null
            ? _Blank(seed: seed)
            : Image.network(
                art.toString(),
                fit: BoxFit.cover,
                errorBuilder: (context, _, _) => _Blank(seed: seed),
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : _Blank(seed: seed),
              ),
      ),
    );
  }
}

class _Blank extends StatelessWidget {
  const _Blank({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    // One accent and a neutral ramp is what the system has, so a placeholder
    // picks from those rather than inventing a hue per show — a wall of random
    // colours would argue with everything else on the screen.
    final grounds = Theme.of(context).brightness == Brightness.dark
        ? const [neutral900, neutral800, Color(0xFF3A2320)]
        : const [surfaceLight, neutral200, neutral300, accent200];

    return ColoredBox(
      color: grounds[seed.hashCode.abs() % grounds.length],
      child: Center(
        child: Text(
          seed.isEmpty ? '?' : seed.characters.first.toUpperCase(),
          style: heading(24, color: palette.faint),
        ),
      ),
    );
  }
}
