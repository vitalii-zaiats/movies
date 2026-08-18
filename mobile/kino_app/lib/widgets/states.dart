/// What a screen shows when it has nothing yet, or nothing at all.
///
/// A failure here is nearly always the same one — the device can't reach the
/// host — so the address it tried is part of the message. "Failed" on its own
/// sends somebody to the logs for a fact the screen already knew.
library;

import 'package:flutter/material.dart';

import '../core/kino.dart';
import '../core/theme.dart';

/// Not named `Loading`: that is one of the three states in `async_value.dart`,
/// and a widget with the same name would have every screen importing two of
/// them and hiding one.
class Spinner extends StatelessWidget {
  const Spinner({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
}

class Failed extends StatelessWidget {
  const Failed({required this.error, this.onRetry, super.key});

  final Object error;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: palette.panel, border: Border.all(color: palette.line)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('COULDN’T REACH THE CATALOGUE', style: kicker(palette.accent)),
            const SizedBox(height: 8),
            Text('$error', style: body(13, color: palette.text)),
            const SizedBox(height: 8),
            Text('tried $host:$grpcPort', style: body(12, color: palette.muted)),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('TRY AGAIN')),
            ],
          ],
        ),
      ),
    );
  }
}

/// Nothing wrong, nothing to show — an empty search, an empty list.
class Empty extends StatelessWidget {
  const Empty(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(message.toUpperCase(), style: label(color: palette.faint)),
      ),
    );
  }
}
