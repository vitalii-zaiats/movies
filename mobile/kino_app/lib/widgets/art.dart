/// Posters, and what to draw when there isn't one.
///
/// Most rows have no artwork at all — the crawlers find a thumbnail for maybe
/// half of them — so the placeholder is not an error state, it's the common
/// case. It is drawn from the key so the same show is the same colour every
/// time, which turns out to be enough to recognise a tile by.
library;

import 'package:flutter/material.dart';

class Poster extends StatelessWidget {
  const Poster({
    required this.url,
    required this.seed,
    this.width = 92,
    this.aspect = 2 / 3,
    super.key,
  });

  final Uri? url;
  final String seed;
  final double width;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    final art = url;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
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
    // A stable hue per key, and the first letter over it.
    final hue = (seed.hashCode % 360).abs().toDouble();
    final colour = HSLColor.fromAHSL(1, hue, 0.28, 0.22).toColor();
    return ColoredBox(
      color: colour,
      child: Center(
        child: Text(
          seed.isEmpty ? '?' : seed.characters.first.toUpperCase(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }
}
