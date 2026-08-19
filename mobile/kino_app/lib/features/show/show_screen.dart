/// One title: the poster, what the crawl knew, and everything there is to play.
///
/// The poster gets the top of the screen and the page slides up over it — the
/// artwork is the best thing these sources give us, and a 110-pixel thumbnail
/// beside a paragraph wastes it. Scrolling parallaxes the picture, the text
/// covers it, and by the time the synopsis is under your thumb the poster has
/// become a title bar.
///
/// A film is a show with exactly one episode, so this screen draws both — it
/// just stops saying "S01E01" about something that only ever had one, and Play
/// sits above the synopsis, because nobody comes here to read first.
library;

import 'package:flutter/material.dart';
import 'package:kino_api/kino_api.dart';

import '../../core/async_value.dart';
import '../../core/formatting.dart';
import '../../core/genres.dart';
import '../../core/kino.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/glyph.dart';
import '../../widgets/states.dart';
import '../player/player_screen.dart';
import 'show_view_model.dart';

/// How much of the screen the poster takes before anybody scrolls. Enough to be
/// the picture rather than an illustration, short enough that the play button is
/// a thumb's reach away.
const _heroFraction = 0.62;

/// Without artwork there is nothing to give the screen to, so the header is only
/// as tall as the words in it.
const _blankHero = 260.0;

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
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final queued = await _model.queue();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          queued == null
              ? '${_model.problem}'
              : l10n.queued(queued.name, queued.count),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) => switch (_model.state) {
        // Before the title arrives there is nothing to build a header out of,
        // so these two keep an ordinary bar.
        Loading<ShowWithEpisodes>() => Scaffold(
            appBar: AppBar(title: Text(widget.showKey)),
            body: const Spinner(),
          ),
        Failure<ShowWithEpisodes>(:final error) => Scaffold(
            appBar: AppBar(title: Text(widget.showKey)),
            body: Failed(error: error, onRetry: _model.load),
          ),
        Data<ShowWithEpisodes>(:final value) => _Detail(detail: value, onQueue: _queue),
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.detail, required this.onQueue});

  final ShowWithEpisodes detail;
  final VoidCallback onQueue;

  @override
  Widget build(BuildContext context) {
    final kino = Kino.of(context);
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);

    final show = detail.show.show;
    final art = kino.posterUrl(show);
    final hero = art == null ? _blankHero : media.size.height * _heroFraction;
    // Where the header stops shrinking. `viewPadding` rather than `padding`:
    // the second is what is *left* after something above consumed the inset,
    // and getting this wrong by the height of a status bar means the header
    // never quite finishes folding.
    final bar = kToolbarHeight + media.viewPadding.top;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // `SliverLayoutBuilder` rather than a `ScrollController`: it hands
          // this sliver its own scroll offset, so the header can dissolve into
          // a bar without the rest of the page rebuilding on every frame.
          SliverLayoutBuilder(
            builder: (context, constraints) {
              final folded = (constraints.scrollOffset / (hero - bar)).clamp(0.0, 1.0);
              // The chrome does not drift between the two colours: half way
              // between paper and ink is a grey that reads as neither, and the
              // thing behind it is somebody's brightly-lit poster. So it stays
              // paper until the ground has almost arrived, then switches over
              // what's left.
              final settled = ((folded - 0.6) / 0.4).clamp(0.0, 1.0);
              final chrome = Color.lerp(paper, palette.text, settled);

              return SliverAppBar(
                pinned: true,
                stretch: true,
                expandedHeight: hero,
                backgroundColor: palette.ground,
                surfaceTintColor: Colors.transparent,
                foregroundColor: chrome,
                iconTheme: IconThemeData(color: chrome),
                title: Opacity(
                  opacity: settled,
                  child: Text(show.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                actions: [
                  if (detail.episodes.length > 1)
                    IconButton(
                      tooltip: l10n.queueWholeShow,
                      icon: const Glyph(Glyphs.queue),
                      onPressed: onQueue,
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  stretchModes: const [StretchMode.zoomBackground],
                  background: _Hero(detail: detail, art: art, folded: folded),
                ),
              );
            },
          ),
          SliverToBoxAdapter(child: _Sheet(detail: detail)),
        ],
      ),
    );
  }
}

/// The picture, a scrim, and the title standing on it.
///
/// The scrim is not decoration: a poster is somebody else's artwork, in any
/// colours they liked, and white type on the bottom third of one is unreadable
/// often enough to need the ink underneath it.
class _Hero extends StatelessWidget {
  const _Hero({required this.detail, required this.art, required this.folded});

  final ShowWithEpisodes detail;
  final Uri? art;
  final double folded;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final details = detail.show;
    final show = details.show;

    final facts = <String>[
      if (details.hasYear()) '${details.year}',
      if (details.hasDuration()) details.duration,
      if (details.hasAgeRating()) details.ageRating,
      if (details.countries.isNotEmpty) details.countries.first,
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        if (art != null)
          Image.network(
            art.toString(),
            fit: BoxFit.cover,
            // A poster that fails is not an error state here — half of them
            // never had one.
            errorBuilder: (context, _, _) => _Blank(letter: show.key),
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : _Blank(letter: show.key),
          )
        else
          _Blank(letter: show.key),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x99201E1D), Color(0x33201E1D), Color(0xF2201E1D)],
              stops: [0, 0.45, 1],
            ),
          ),
        ),
        // The page's own colour, arriving as the header shrinks: without it a
        // pinned bar is a random crop of somebody's artwork, which reads as a
        // rendering mistake rather than as a decision. Slightly ahead of the
        // fold, because the last few percent of a collapse are the ones a short
        // page never reaches.
        Opacity(
          opacity: (folded * 1.25).clamp(0.0, 1.0),
          child: ColoredBox(color: palette.ground),
        ),
        // The words fade out as the header becomes a bar, where the same title
        // is already waiting in small type.
        Opacity(
          opacity: (1 - folded * 1.6).clamp(0.0, 1.0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (details.hasOriginalTitle())
                    Text(
                      details.originalTitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: kicker(palette.accent),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    show.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: heading(34, color: paper),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (details.hasImdbRating()) ...[
                        Text(
                          '★ ${details.imdbRating.toStringAsFixed(1)}',
                          style: body(14, weight: 700, color: paper),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(
                          facts.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(13, color: inkMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Blank extends StatelessWidget {
  const _Blank({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return ColoredBox(
      color: palette.panel,
      child: Center(
        child: Text(
          letter.isEmpty ? '?' : letter.characters.first.toUpperCase(),
          style: heading(96, color: palette.faint),
        ),
      ),
    );
  }
}

/// Everything that isn't the picture, on the page that slides over it.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.detail});

  final ShowWithEpisodes detail;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final details = detail.show;
    final show = details.show;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.ground,
        // The seam where the page meets the poster, in the system's own rule.
        border: Border(top: BorderSide(color: palette.text, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlayAction(detail: detail),
          if (details.genres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                // The wire carries language-neutral keys — `action`, `sci-fi` —
                // because what a genre is called depends on who is reading.
                // This is where that gets decided.
                children: [
                  for (final genre in details.genres)
                    Chip(label: Text(genreName(genre, language))),
                ],
              ),
            ),
          if (details.hasImdbVotes())
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                l10n.imdbVotes(details.imdbVotes).toUpperCase(),
                style: body(11, weight: 700, color: palette.faint),
              ),
            ),
          if (details.hasDescription())
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(details.description, style: body(14, color: palette.text)),
            ),
          if (details.directors.isNotEmpty || details.starring.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _Credits(details: details),
            ),
          // A film is one episode and the button above already plays it; listing
          // it again under a heading would be a list of one.
          if (!show.isFilm) ...[
            const SizedBox(height: 28),
            Container(height: 2, color: palette.text),
            const SizedBox(height: 10),
            Text(
              l10n.episodeCount(detail.episodes.length).toUpperCase(),
              style: label(color: palette.text),
            ),
            const SizedBox(height: 4),
            for (final (index, episode) in detail.episodes.indexed) ...[
              if (index > 0) const Divider(height: 1),
              _EpisodeRow(episode: episode, show: show, first: index == 0),
            ],
          ],
        ],
      ),
    );
  }
}

class _Credits extends StatelessWidget {
  const _Credits({required this.details});

  final ShowDetails details;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    final rows = <(String, String)>[
      if (details.directors.isNotEmpty) (l10n.directedBy, details.directors.join(', ')),
      // Five is where a cast list stops being information and starts being a
      // database dump.
      if (details.starring.isNotEmpty) (l10n.starring, details.starring.take(5).join(', ')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (name, value) in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 104,
                  child: Text(
                    name.toUpperCase(),
                    style: body(11, weight: 700, color: palette.faint),
                  ),
                ),
                Expanded(child: Text(value, style: body(13, color: palette.text))),
              ],
            ),
          ),
      ],
    );
  }
}

/// Play, and what it will play: the first episode with a stream behind it, which
/// for a film is the film. A title where nothing was ever packaged says so
/// rather than offering a button that can only disappoint.
class _PlayAction extends StatelessWidget {
  const _PlayAction({required this.detail});

  final ShowWithEpisodes detail;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);
    final show = detail.show.show;
    final playable = detail.episodes.where((episode) => episode.hasPlaylist());

    if (playable.isEmpty) {
      return Row(
        children: [
          Glyph(Glyphs.blocked, size: 18, color: palette.faint),
          const SizedBox(width: 8),
          Text(l10n.nothingToPlayYet.toUpperCase(), style: label(color: palette.faint)),
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
        label: Text((code == null ? l10n.play : l10n.playEpisode(code)).toUpperCase()),
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
    final l10n = AppLocalizations.of(context);
    final playable = episode.hasPlaylist();
    final code = episodeCode(episode, isFilm: show.isFilm);
    final dubs = episode.tracks.where((track) => track.hasAudio()).length;

    return ListTile(
      autofocus: first && playable && Kino.isTv(context),
      dense: true,
      enabled: playable,
      contentPadding: EdgeInsets.zero,
      leading: code == null
          ? const Glyph(Glyphs.film)
          : SizedBox(
              width: 62,
              child: Text(code, style: body(13, weight: 700, color: palette.muted)),
            ),
      title: Text(episode.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: switch ((playable, dubs)) {
        (false, _) => Text(
            l10n.noStream.toUpperCase(),
            style: body(11, weight: 600, color: palette.faint),
          ),
        (true, > 1) => Text(
            l10n.voiceCount(dubs).toUpperCase(),
            style: body(11, weight: 600, color: palette.muted),
          ),
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
