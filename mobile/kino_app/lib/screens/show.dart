/// One title: what the crawl knew about it, and everything there is to play.
///
/// A film is a show with exactly one episode, so this screen draws both — it
/// just stops saying "S01E01" when there is only ever one.
library;

import 'package:flutter/material.dart';
import 'package:kino_api/kino_api.dart';

import '../kino.dart';
import '../widgets/art.dart';
import 'player.dart';

class ShowScreen extends StatefulWidget {
  const ShowScreen({required this.showKey, super.key});

  final String showKey;

  @override
  State<ShowScreen> createState() => _ShowScreenState();
}

class _ShowScreenState extends State<ShowScreen> {
  Future<ShowWithEpisodes>? _detail;

  // The client lives above this widget, so the fetch waits until ancestors are
  // reachable — which is `didChangeDependencies`, not `initState`.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _detail ??= Kino.of(context).show(widget.showKey);
  }

  Future<void> _queue(ShowWithEpisodes detail) async {
    final kino = Kino.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final list = await kino.listFromShow(show: widget.showKey);
      messenger.showSnackBar(
        SnackBar(content: Text('Queued “${list.playlist.name}” · ${list.playlist.count}')),
      );
    } catch (problem) {
      messenger.showSnackBar(SnackBar(content: Text('$problem')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShowWithEpisodes>(
      future: _detail,
      builder: (context, snapshot) {
        final detail = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(detail?.show.show.title ?? widget.showKey),
            actions: [
              if (detail != null && detail.episodes.length > 1)
                IconButton(
                  tooltip: 'Queue the whole show',
                  icon: const Icon(Icons.playlist_add),
                  onPressed: () => _queue(detail),
                ),
            ],
          ),
          body: switch (snapshot) {
            AsyncSnapshot(hasError: true, :final error?) =>
              Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('$error'))),
            AsyncSnapshot(data: final detail?) => _Body(detail: detail),
            _ => const Center(child: CircularProgressIndicator()),
          },
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.detail});

  final ShowWithEpisodes detail;

  @override
  Widget build(BuildContext context) {
    final kino = Kino.of(context);
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
                    Text(
                      details.originalTitle,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  const SizedBox(height: 4),
                  Text(show.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (details.hasImdbRating())
                    Text(
                      '★ ${details.imdbRating.toStringAsFixed(1)}'
                      '${details.hasImdbVotes() ? " · ${details.imdbVotes} votes" : ""}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  if (facts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        facts.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
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
            child: Text(details.description),
          ),
        const SizedBox(height: 24),
        Text(
          show.isFilm ? 'Play' : '${detail.episodes.length} episodes',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final (index, episode) in detail.episodes.indexed)
          _EpisodeRow(episode: episode, show: show, first: index == 0),
      ],
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
    final playable = episode.hasPlaylist();
    final code = episodeCode(episode, isFilm: show.isFilm);
    final dubs = episode.tracks.where((track) => track.hasAudio()).length;

    return ListTile(
      autofocus: first && playable && Kino.isTv(context),
      dense: true,
      enabled: playable,
      leading: code == null
          ? const Icon(Icons.movie_outlined)
          : SizedBox(
              width: 56,
              child: Text(code, style: const TextStyle(fontFeatures: [])),
            ),
      title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: playable
          ? (dubs > 1 ? Text('$dubs voices') : null)
          : const Text('no stream'),
      trailing: playable ? const Icon(Icons.play_arrow) : null,
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
