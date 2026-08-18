/// Turning what the server said into what a screen shows.
///
/// Pure functions, in one file, because two screens saying "S01E03" two
/// slightly different ways is how a catalogue starts looking untended.
library;

import 'package:kino_api/kino_api.dart';

/// "S01E03", or nothing at all for a film — a title that only ever had one
/// episode should stop being told it has a first one.
String? episodeCode(Episode episode, {required bool isFilm}) {
  if (isFilm) return null;
  final season = episode.season.toString().padLeft(2, '0');
  final number = episode.episode.toString().padLeft(2, '0');
  if (episode.hasEpisodeEnd()) {
    return 'S${season}E$number-${episode.episodeEnd.toString().padLeft(2, '0')}';
  }
  return 'S${season}E$number';
}

/// What a browse row says under the title.
String showSubtitle(ShowSummary summary) {
  if (summary.show.isFilm) {
    return summary.playableCount > 0 ? 'FILM' : 'FILM · NO STREAM';
  }
  return '${summary.episodeCount} EPISODES · ${summary.playableCount} PLAYABLE';
}

/// A running time. Hours only when there are any — `04:12` beats `0:04:12`.
String clock(Duration duration) {
  final seconds = duration.inSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final rest = seconds % 60;
  final tail = '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
  return hours > 0 ? '$hours:$tail' : tail;
}

/// An ISO-8601 stamp as a date. The wire carries the instant; a screen wants the
/// day, and nobody needs to know it was a Tuesday at 09:14:22.
String day(String stamp) {
  final parsed = DateTime.tryParse(stamp);
  if (parsed == null) return stamp;
  final local = parsed.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}'
      '-${local.day.toString().padLeft(2, '0')}';
}
