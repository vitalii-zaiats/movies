/// One title: what the crawl knew about it, and everything there is to play.
///
/// A film is a show with exactly one episode, so this screen draws both — it
/// just stops saying "S01E01" about something that only ever had one, and it
/// puts Play above the synopsis, because nobody comes here to read first.
library;

import 'package:flutter/material.dart';
import 'package:kino_api/kino_api.dart';

import '../../core/async_value.dart';
import '../../core/formatting.dart';
import '../../core/kino.dart';
import '../../core/theme.dart';
import '../../widgets/glyph.dart';
import '../../widgets/poster.dart';
import '../../widgets/states.dart';
import '../player/player_screen.dart';
import 'show_view_model.dart';

class ShowScreen extends StatefulWidget {
  const ShowScreen({required this.showKey, super.key});

  final String showKey;

  @override
  State<ShowScreen> createState() => _ShowScreenState();
}

class _ShowScreenState extends State<ShowScreen> {
  late final ShowViewModel _model;

  @override
  void initState() {
    super.initState();
    _model = ShowViewModel(Kino.read(context), widget.showKey)..load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _queue() async {
    final messenger = ScaffoldMessenger.of(context);
    final said = await _model.queue();
    messenger.showSnackBar(SnackBar(content: Text(said)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        final state = _model.state;
        final detail = state is Data<ShowWithEpisodes> ? state.value : null;

        return Scaffold(
          appBar: AppBar(
            title: Text(detail?.show.show.title ?? widget.showKey),
            actions: [
              if (detail != null && detail.episodes.length > 1)
                IconButton(
                  tooltip: 'Queue the whole show',
                  icon: const Glyph(Glyphs.queue),
                  onPressed: _queue,
                ),
            ],
          ),
          body: switch (state) {
            Loading<ShowWithEpisodes>() => const Spinner(),
            Failure<ShowWithEpisodes>(:final error) =>
              Failed(error: error, onRetry: _model.load),
            Data<ShowWithEpisodes>(:final value) => _Detail(detail: value),
          },
        );
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail});

  final ShowWithEpisodes detail;

  @override
  Widget build(BuildContext context) {
    final kino = Kino.of(context);
    final palette = Palette.of(context);
    final details = detail.show;
    final show = details.show;

    final facts = <String>[
      if (details.hasYear()) '${details.year}',
      if (details.hasDuration()) details.duration,
      if (details.hasAgeRating()) details.ageRating,
      if (details.countries.isNotEmpty) details.countries.join(', '),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Poster(url: kino.posterUrl(show), seed: show.key, width: 110),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (details.hasOriginalTitle())
                    Text(details.originalTitle.toUpperCase(), style: kicker(palette.accent)),
                  const SizedBox(height: 4),
                  Text(show.title, style: heading(25, color: palette.text)),
                  const SizedBox(height: 8),
                  if (details.hasImdbRating())
                    Text(
                      '★ ${details.imdbRating.toStringAsFixed(1)}'
                      '${details.hasImdbVotes() ? " · ${details.imdbVotes} votes" : ""}',
                      style: body(14, weight: 600, color: palette.text),
                    ),
                  if (facts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(facts.join(' · '), style: body(12, color: palette.muted)),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _PlayAction(detail: detail),
        if (details.genres.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              // Language-neutral keys on the wire — `sci-fi`, `war` — because
              // naming a genre is the reader's language, not the crawler's.
              children: [for (final genre in details.genres) Chip(label: Text(genre))],
            ),
          ),
        if (details.hasDescription())
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(details.description, style: body(14, color: palette.text)),
          ),
        // A film is one episode and the button above already plays it; listing
        // it again under a heading would be a list of one.
        if (!show.isFilm) ...[
          const SizedBox(height: 28),
          Container(height: 2, color: palette.text),
          const SizedBox(height: 10),
          Text('${detail.episodes.length} EPISODES', style: label(color: palette.text)),
          const SizedBox(height: 4),
          for (final (index, episode) in detail.episodes.indexed) ...[
            if (index > 0) const Divider(height: 1),
            _EpisodeRow(episode: episode, show: show, first: index == 0),
          ],
        ],
      ],
    );
  }
}

/// Play, and what it will play: the first episode with a stream behind it,
/// which for a film is the film. A title where nothing was ever packaged says
/// so rather than offering a button that can only disappoint.
class _PlayAction extends StatelessWidget {
  const _PlayAction({required this.detail});

  final ShowWithEpisodes detail;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final show = detail.show.show;
    final playable = detail.episodes.where((episode) => episode.hasPlaylist());

    if (playable.isEmpty) {
      return Row(
        children: [
          Glyph(Glyphs.blocked, size: 18, color: palette.faint),
          const SizedBox(width: 8),
          Text('NOTHING TO PLAY YET', style: label(color: palette.faint)),
        ],
      );
    }

    final first = playable.first;
    final code = episodeCode(first, isFilm: show.isFilm);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        autofocus: Kino.isTv(context),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => PlayerScreen(episode: first, show: show)),
        ),
        icon: const Glyph(Glyphs.play, size: 18),
        label: Text(code == null ? 'PLAY' : 'PLAY $code'),
      ),
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.episode, required this.show, this.first = false});

  final Episode episode;
  final Show show;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final playable = episode.hasPlaylist();
    final code = episodeCode(episode, isFilm: show.isFilm);
    final dubs = episode.tracks.where((track) => track.hasAudio()).length;

    return ListTile(
      dense: true,
      enabled: playable,
      leading: code == null
          ? const Glyph(Glyphs.film)
          : SizedBox(
              width: 62,
              child: Text(code, style: body(13, weight: 700, color: palette.muted)),
            ),
      title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: switch ((playable, dubs)) {
        (false, _) => Text('NO STREAM', style: body(11, weight: 600, color: palette.faint)),
        (true, > 1) =>
          Text('$dubs VOICES', style: body(11, weight: 600, color: palette.muted)),
        _ => null,
      },
      trailing: playable ? const Glyph(Glyphs.play, size: 16) : null,
      onTap: playable
          ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlayerScreen(episode: episode, show: show),
                ),
              )
          : null,
    );
  }
}
