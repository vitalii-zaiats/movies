/// Browse, search, and pick up where you left off.
library;

import 'package:flutter/material.dart';
import 'package:kino_api/kino_api.dart';

import '../../core/genres.dart';
import '../../core/kino.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/glyph.dart';
import '../../widgets/poster.dart';
import '../../widgets/section_head.dart';
import '../../widgets/states.dart';
import '../account/account_screen.dart';
import '../player/player_screen.dart';
import '../show/show_screen.dart';
import 'home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final HomeViewModel _model;
  late final TabController _tabs;
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    // `read` rather than `of`: this runs before the first build, and the client
    // above us never changes anyway.
    _model = HomeViewModel(Kino.read(context))..start();
    _tabs = TabController(length: Browse.values.length, vsync: this)..addListener(_tabChanged);
    _scroll.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _scroll.dispose();
    _search.dispose();
    _model.dispose();
    super.dispose();
  }

  /// Only once the tap or swipe has settled: `index` moves at the start of the
  /// animation and again at the end, and refetching twice per tab is a page of
  /// results thrown away.
  void _tabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    _model.show(Browse.values[_tabs.index]);
  }

  void _maybeLoadMore() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
      _model.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);

    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('kino'),
          actions: [
            _LanguageFilter(model: _model),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AccountScreen()),
              ),
              child: Text(
                (_model.user?.displayName ?? l10n.account).toUpperCase(),
                style: label(color: palette.muted),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: label(color: palette.text),
            unselectedLabelStyle: label(color: palette.muted),
            labelColor: palette.text,
            unselectedLabelColor: palette.muted,
            dividerColor: palette.line,
            // Square, like everything else here: a rounded pill under a tab
            // would be the only curve on the screen.
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(width: 3, color: palette.accent),
            ),
            tabs: [
              for (final tab in Browse.values) Tab(text: _tabName(l10n, tab).toUpperCase()),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _model.refresh,
          child: CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverToBoxAdapter(child: _SearchBar(model: _model, controller: _search)),
              if (_model.error != null && _model.shows.isEmpty)
                SliverToBoxAdapter(
                  child: Failed(error: _model.error!, onRetry: _model.refresh),
                ),
              if (_model.going.isNotEmpty)
                SliverToBoxAdapter(child: _ContinueRail(entries: _model.going)),
              SliverToBoxAdapter(
                child: SectionHead(
                  l10n.sectionCount(
                    _model.query.isEmpty ? l10n.newest : l10n.found,
                    _model.total,
                  ),
                ),
              ),
              SliverList.separated(
                itemCount: _model.shows.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                // On a television the first row takes focus, so a remote has
                // somewhere to be the moment the list arrives. On a phone
                // nothing is focused and nothing should be.
                itemBuilder: (context, index) => _ShowRow(
                  summary: _model.shows[index],
                  first: index == 0 && _model.going.isEmpty,
                ),
              ),
              SliverToBoxAdapter(child: _Footer(model: _model)),
            ],
          ),
        ),
      ),
    );
  }

  String _tabName(AppLocalizations l10n, Browse tab) => switch (tab) {
        Browse.all => l10n.tabAll,
        Browse.films => l10n.tabFilms,
        Browse.series => l10n.tabSeries,
        Browse.cartoons => l10n.tabCartoons,
      };
}

/// Which language to keep, as a menu rather than another row of chips: the tabs
/// already own the horizontal band under the title, and a second one there would
/// make the catalogue look like a settings screen.
///
/// The languages offered are the ones this app can name. A catalogue may hold
/// others; naming them in a language the reader doesn't have would be worse
/// than leaving them to "any".
class _LanguageFilter extends StatelessWidget {
  const _LanguageFilter({required this.model});

  final HomeViewModel model;

  static const _known = {'uk': 'Українська', 'en': 'English'};

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<String?>(
      tooltip: l10n.filterByLanguage,
      icon: Glyph(Glyphs.filter, color: model.language == null ? palette.muted : palette.accent),
      onSelected: model.spoken,
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text(l10n.anyLanguage)),
        for (final entry in _known.entries)
          PopupMenuItem(
            value: entry.key,
            child: Row(
              children: [
                Glyph(
                  model.language == entry.key ? Glyphs.check : Glyphs.dot,
                  size: 16,
                  color: model.language == entry.key ? palette.accent : palette.faint,
                ),
                const SizedBox(width: 8),
                Text(entry.value),
              ],
            ),
          ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.model, required this.controller});

  final HomeViewModel model;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: model.search,
        decoration: InputDecoration(
          hintText: l10n.searchHint,
          prefixIcon: const Padding(
            padding: EdgeInsets.all(12),
            child: Glyph(Glyphs.search, size: 18),
          ),
          suffixIcon: model.query.isEmpty
              ? null
              : IconButton(
                  icon: const Glyph(Glyphs.close, size: 16),
                  onPressed: () {
                    controller.clear();
                    model.search('');
                  },
                ),
        ),
      ),
    );
  }
}

class _ContinueRail extends StatelessWidget {
  const _ContinueRail({required this.entries});

  final List<HistoryEntry> entries;

  // A horizontal list has to be given a height, and a title is two lines of a
  // font whose real line height comes from its own metrics — so any number
  // written here is an estimate, and one that is 0.3px short still paints the
  // yellow-and-black stripes.
  //
  // So the estimate only *reserves* the space; the title is `Flexible` and takes
  // what it needs of it. Too little and it ellipsizes, which is what `maxLines`
  // is for; too much and there is a gap nobody notices.
  static const _posterWidth = 92.0;
  static const _titleSize = 13.0;
  static const _barHeight = 4.0;

  double _height(BuildContext context) {
    final poster = _posterWidth / posterRatio;
    final title = (MediaQuery.textScalerOf(context).scale(_titleSize) * 1.45 * 2).ceilToDouble();
    return poster + 8 + title + 6 + _barHeight;
  }

  @override
  Widget build(BuildContext context) {
    final kino = Kino.of(context);
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHead(l10n.continueWatching),
        SizedBox(
          height: _height(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final show = entry.episode.show;
              final ratio = entry.progress.hasRatio() ? entry.progress.ratio : 0.0;

              return SizedBox(
                width: _posterWidth,
                child: InkWell(
                  autofocus: index == 0 && Kino.isTv(context),
                  focusColor: Theme.of(context).focusColor,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlayerScreen(
                        episode: entry.episode.episode,
                        show: show,
                      ),
                    ),
                  ),
                  child: Column(
                    // `min` with a `Flexible` title: the tile takes the height
                    // it needs and the bar sits under the words, while the
                    // reserved height above still rules out an overflow.
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Poster(url: kino.posterUrl(show), seed: show.key, width: _posterWidth),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          show.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: body(_titleSize, weight: 600, color: palette.text),
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: ratio, minHeight: _barHeight),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One row of the catalogue, as tall as its poster.
///
/// The poster used to be a 56-pixel stamp beside two lines of text, which
/// wasted the one thing these sources reliably give us and left half the row
/// empty. It is now the height of the row, and the space beside it carries what
/// a browse list is actually scanned for: a score, a year, and what kind of
/// thing this is.
class _ShowRow extends StatelessWidget {
  const _ShowRow({required this.summary, this.first = false});

  final ShowSummary summary;
  final bool first;

  /// Wide enough to read a title off, short enough that six rows still fit on a
  /// phone screen.
  static const _poster = 78.0;

  /// Three is what fits on one line at this width; a fourth wraps and turns a
  /// row into a paragraph.
  static const _mostGenres = 3;

  @override
  Widget build(BuildContext context) {
    final kino = Kino.of(context);
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final show = summary.show;

    final facts = <String>[
      if (summary.hasImdbRating()) '★ ${summary.imdbRating.toStringAsFixed(1)}',
      if (summary.hasYear()) '${summary.year}',
      if (show.isFilm)
        (summary.playableCount > 0 ? l10n.film : l10n.filmNoStream)
      else
        l10n.episodesAndPlayable(summary.episodeCount, summary.playableCount),
    ];

    return InkWell(
      autofocus: first && Kino.isTv(context),
      focusColor: Theme.of(context).focusColor,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ShowScreen(showKey: show.key)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Poster(url: kino.posterUrl(show), seed: show.key, width: _poster),
            const SizedBox(width: 14),
            Expanded(
              // The text column is as tall as the poster and no taller: a long
              // title takes the space the genres would have used, rather than
              // growing the row and leaving the artwork stranded at the top.
              child: SizedBox(
                height: _poster / posterRatio,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        show.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: heading(18, color: palette.text),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      facts.join(' · ').toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(11, weight: 700, color: palette.muted),
                    ),
                    const SizedBox(height: 10),
                    if (summary.genres.isNotEmpty)
                      // Language-neutral keys on the wire; named here, in the
                      // reader's language. Clipped rather than wrapped — a row
                      // that grows a line because a film has five genres is a
                      // list that never lines up.
                      ClipRect(
                        child: Wrap(
                          spacing: 6,
                          clipBehavior: Clip.hardEdge,
                          children: [
                            for (final genre in summary.genres.take(_mostGenres))
                              _GenreTag(name: genreName(genre, language)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A genre, small. Not `Chip`: that one is built for tapping and comes with the
/// padding to prove it, and these are labels rather than controls.
class _GenreTag extends StatelessWidget {
  const _GenreTag({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(border: Border.all(color: palette.line)),
      child: Text(name, style: body(11, weight: 600, color: palette.muted)),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.model});

  final HomeViewModel model;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: switch (model) {
          HomeViewModel(loading: true) => const CircularProgressIndicator(),
          HomeViewModel(shows: [], error: null) => Empty(l10n.nothingHere),
          _ => Text(
              l10n.shownOfTotal(model.shows.length, model.total),
              style: body(12, color: palette.faint),
            ),
        },
      ),
    );
  }
}
