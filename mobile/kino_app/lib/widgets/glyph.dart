/// The app's icons, drawn rather than imported.
///
/// Material's own are rounded, soft-capped and slightly bubbly — which is a
/// perfectly good set and the wrong one here: this system has square corners,
/// hairline rules and a display face at weight 800, and rounded icons argue
/// with all three on every screen.
///
/// The obvious alternative is an icon pack, but Lucide, Feather and Phosphor
/// all cap their strokes round by default, so they lose the same argument.
/// These are the fifteen glyphs this app actually uses, on a 24-unit grid,
/// stroked at 2 with square caps and mitred joins — the same geometry as the
/// borders they sit next to.
library;

import 'package:flutter/material.dart';

/// One icon: what to draw on a 24×24 grid, and whether it is a filled shape
/// rather than a stroked outline. Transport symbols are solid because that is
/// what a play triangle is; everything else is a line.
@immutable
class GlyphSpec {
  const GlyphSpec(this.draw, {this.fill = false});

  final void Function(Path path) draw;
  final bool fill;
}

class Glyph extends StatelessWidget {
  const Glyph(this.spec, {this.size, this.color, this.weight = 2, super.key});

  final GlyphSpec spec;
  final double? size;
  final Color? color;

  /// Stroke width on the 24 grid. Left alone almost everywhere — the one place
  /// it earns its keep is over video, where a hairline disappears.
  final double weight;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final side = size ?? theme.size ?? 22;

    return SizedBox(
      width: side,
      height: side,
      child: CustomPaint(
        painter: _GlyphPainter(
          spec: spec,
          color: color ?? theme.color ?? Theme.of(context).colorScheme.onSurface,
          weight: weight,
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.spec, required this.color, required this.weight});

  final GlyphSpec spec;
  final Color color;
  final double weight;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    spec.draw(path);

    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = spec.fill ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = weight
        // Square and mitred: the same corners the rest of the system has.
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.miter
        ..isAntiAlias = true,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.spec != spec || old.color != color || old.weight != weight;
}

// --- the set ----------------------------------------------------------------
// Each one is a function so the tear-off can be a compile-time constant, and
// so the shapes read as geometry rather than as an SVG path string nobody can
// check by eye.

void _search(Path p) {
  p
    ..addRect(const Rect.fromLTWH(4, 4, 10, 10))
    // Starting a pixel clear of the corner: touching it, the frame and the
    // handle merge into one shape that reads as a crossed-out box.
    ..moveTo(15.5, 15.5)
    ..lineTo(20, 20);
}

void _close(Path p) {
  p
    ..moveTo(5, 5)
    ..lineTo(19, 19)
    ..moveTo(19, 5)
    ..lineTo(5, 19);
}

void _back(Path p) {
  p
    ..moveTo(20, 12)
    ..lineTo(5, 12)
    ..moveTo(11, 6)
    ..lineTo(5, 12)
    ..lineTo(11, 18);
}

void _play(Path p) {
  p
    ..moveTo(6, 4)
    ..lineTo(20, 12)
    ..lineTo(6, 20)
    ..close();
}

void _pause(Path p) {
  p
    ..addRect(const Rect.fromLTWH(6, 4, 4, 16))
    ..addRect(const Rect.fromLTWH(14, 4, 4, 16));
}

/// Skip back: two chevrons and the wall they stop at.
void _rewind(Path p) {
  p
    ..moveTo(12, 5)
    ..lineTo(5, 12)
    ..lineTo(12, 19)
    ..moveTo(20, 5)
    ..lineTo(13, 12)
    ..lineTo(20, 19);
}

void _forward(Path p) {
  p
    ..moveTo(12, 5)
    ..lineTo(19, 12)
    ..lineTo(12, 19)
    ..moveTo(4, 5)
    ..lineTo(11, 12)
    ..lineTo(4, 19);
}

/// Voices: a square speech panel with two lines in it.
void _voice(Path p) {
  p
    ..addRect(const Rect.fromLTWH(3, 4, 18, 13))
    ..moveTo(7, 20)
    ..lineTo(7, 17)
    ..moveTo(7, 9)
    ..lineTo(17, 9)
    ..moveTo(7, 13)
    ..lineTo(13, 13);
}

/// Queue: a stack of lines with a plus beside it.
void _queue(Path p) {
  p
    ..moveTo(3, 6)
    ..lineTo(15, 6)
    ..moveTo(3, 11)
    ..lineTo(15, 11)
    ..moveTo(3, 16)
    ..lineTo(10, 16)
    ..moveTo(17, 13)
    ..lineTo(17, 21)
    ..moveTo(13, 17)
    ..lineTo(21, 17);
}

/// A reel of film: the frame, and its sprockets.
void _film(Path p) {
  p
    ..addRect(const Rect.fromLTWH(3, 5, 18, 14))
    ..moveTo(7, 5)
    ..lineTo(7, 19)
    ..moveTo(17, 5)
    ..lineTo(17, 19);
}

/// Nothing here: the universal no, with the system's straight edges.
void _blocked(Path p) {
  p
    ..addRect(const Rect.fromLTWH(4, 4, 16, 16))
    ..moveTo(4, 20)
    ..lineTo(20, 4);
}

/// Out: a door, and the way through it.
void _out(Path p) {
  p
    ..moveTo(13, 4)
    ..lineTo(4, 4)
    ..lineTo(4, 20)
    ..lineTo(13, 20)
    ..moveTo(10, 12)
    ..lineTo(21, 12)
    ..moveTo(16, 7)
    ..lineTo(21, 12)
    ..lineTo(16, 17);
}

/// Somebody else: shoulders, a head, and a plus.
void _newPerson(Path p) {
  p
    ..addRect(const Rect.fromLTWH(5, 3, 8, 8))
    ..moveTo(3, 21)
    ..lineTo(3, 16)
    ..lineTo(15, 16)
    ..lineTo(15, 21)
    ..moveTo(18, 5)
    ..lineTo(18, 13)
    ..moveTo(14, 9)
    ..lineTo(22, 9);
}

/// Shown, and hidden: an eye, and an eye with a line through it.
void _eye(Path p) {
  p
    ..moveTo(2, 12)
    ..lineTo(12, 5)
    ..lineTo(22, 12)
    ..lineTo(12, 19)
    ..close()
    ..addRect(const Rect.fromLTWH(9, 9, 6, 6));
}

void _eyeShut(Path p) {
  _eye(p);
  p
    ..moveTo(3, 21)
    ..lineTo(21, 3);
}

void _check(Path p) {
  p
    ..moveTo(4, 12)
    ..lineTo(10, 18)
    ..lineTo(20, 6);
}

void _dot(Path p) {
  p.addRect(const Rect.fromLTWH(8, 8, 8, 8));
}

/// The set, by what it means rather than by what it looks like.
abstract final class Glyphs {
  static const search = GlyphSpec(_search);
  static const close = GlyphSpec(_close);
  static const back = GlyphSpec(_back);
  static const play = GlyphSpec(_play, fill: true);
  static const pause = GlyphSpec(_pause, fill: true);
  static const rewind = GlyphSpec(_rewind);
  static const forward = GlyphSpec(_forward);
  static const voice = GlyphSpec(_voice);
  static const queue = GlyphSpec(_queue);
  static const film = GlyphSpec(_film);
  static const blocked = GlyphSpec(_blocked);
  static const out = GlyphSpec(_out);
  static const newPerson = GlyphSpec(_newPerson);
  static const eye = GlyphSpec(_eye);
  static const eyeShut = GlyphSpec(_eyeShut);
  static const check = GlyphSpec(_check);
  static const dot = GlyphSpec(_dot);
}
