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

/// Where a phone stops and a window begins. Not a device check: a phone held
/// sideways and a small window are the same problem and want the same answer.
const _wide = 700.0;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    // Coming back from the background is the other way progress changes without
    // this screen doing anything: it may have moved on another device, or in
    // this app before it was suspended.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _model.refreshRail();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    final tv = Kino.isTv(context);

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
                SliverToBoxAdapter(
                  child: _ContinueRail(entries: _model.going, onReturn: _model.refreshRail),
                ),
              SliverToBoxAdapter(
                child: SectionHead(
                  l10n.sectionCount(
                    _model.query.isEmpty ? l10n.newest : l10n.found,
                    _model.total,
                  ),
                ),
              ),
              // A phone gets rows; anything wider gets the web app's grid of
              // posters. One column of 78-pixel stamps across a desktop window
              // is three quarters empty space, and the artwork is the best
              // thing these sources give us.
              if (MediaQuery.sizeOf(context).width < _wide)
                SliverList.separated(
                  itemCount: _model.shows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  // On a television the first row takes focus, so a remote has
                  // somewhere to be the moment the list arrives. On a phone
                  // nothing is focused and nothing should be.
                  itemBuilder: (context, index) => _ShowRow(
                    summary: _model.shows[index],
                    first: index == 0 && _model.going.isEmpty,
                    onReturn: _model.refreshRail,
                  ),
                )
              else
                SliverPadding(
                  // A television cuts its own edges off — overscan is still
                  // real on panels people own — so the grid keeps clear of
                  // them. A window doesn't, and 16 is the system's margin.
                  padding: EdgeInsets.fromLTRB(
                    tv ? 48 : 16,
                    tv ? 24 : 0,
                    tv ? 48 : 16,
                    tv ? 32 : 0,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      // `--grid-card` from the web's tokens is 200; a
                      // television sits three metres away and reads bigger
                      // type, so its cards are wider or the titles clip.
                      maxCrossAxisExtent: tv ? 180 : 200,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      // Poster plus the caption under it. The tile lets its
                      // body take whatever is left, so a rounding error here
                      // costs a pixel of white rather than a stripe of orange.
                      childAspectRatio: tv ? 0.55 : 0.58,
                    ),
                    itemCount: _model.shows.length,
                    itemBuilder: (context, index) => _ShowTile(
                      summary: _model.shows[index],
                      first: index == 0 && _model.going.isEmpty,
                      onReturn: _model.refreshRail,
                    ),
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
  const _ContinueRail({required this.entries, required this.onReturn});

  final List<HistoryEntry> entries;

  /// Called when whatever this opened is closed again — the one moment the rail
  /// is reliably out of date.
  final Future<void> Function() onReturn;

  // A horizontal list has to be given a height, and a title is two lines of a
  // font whose real line height comes from its own metrics — so any number
  // written here is an estimate, and one that is 0.3px short still paints the
  // yellow-and-black stripes.
  //
  // So the estimate only *reserves* the space; the title is `Flexible` and takes
  // what it needs of it. Too little and it ellipsizes, which is what `maxLines`
  // is for; too much and there is a gap nobody notices.
  static const _titleSize = 13.0;
  static const _barHeight = 4.0;

  /// A phone's rail is a strip of thumbnails; a television's is the size of the
  /// cards beside it and no larger. A television reads at about 960dp however
  /// many pixels the panel has, so 240 there is a quarter of the screen — twice
  /// the width of a grid card, which is what made the rail look enormous.
  static double _poster(BuildContext context) => Kino.isTv(context) ? 160 : 92;

  /// Titles wrap to two lines on a phone and one on a television, where the
  /// type is scaled up and the band would otherwise eat half the screen.
  static int _titleLines(BuildContext context) => Kino.isTv(context) ? 1 : 2;

  /// What the focus frame costs vertically: 4 of padding and 4 of border, top
  /// and bottom. Left out of this sum once already, and the title paid for it —
  /// it came out sliced through the middle of its letters.
  static const _frame = 16.0;

  double _height(BuildContext context) {
    final poster = _poster(context) / posterRatio;
    final lines = _titleLines(context);
    final title =
        (MediaQuery.textScalerOf(context).scale(_titleSize) * 1.45 * lines).ceilToDouble();
    // Two extra pixels of slack: a font's real line height comes from its own
    // metrics, and being a fraction short here is what paints the stripes.
    return poster + 8 + title + 6 + _barHeight + _frame + 2;
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
            // Clear of the panel's own edges, like the grid below it.
            padding: EdgeInsets.symmetric(horizontal: Kino.isTv(context) ? 48 : 16),
            itemCount: entries.length,
            separatorBuilder: (_, _) => SizedBox(width: Kino.isTv(context) ? 24 : 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final show = entry.episode.show;
              final ratio = entry.progress.hasRatio() ? entry.progress.ratio : 0.0;

              return SizedBox(
                width: _poster(context),
                child: _Resumable(
                  autofocus: index == 0 && Kino.isTv(context),
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute<void>(
                          builder: (_) => PlayerScreen(
                            episode: entry.episode.episode,
                            show: show,
                          ),
                        ),
                      )
                      .then((_) => onReturn()),
                  child: Column(
                    // `min` with a `Flexible` title: the tile takes the height
                    // it needs and the bar sits under the words, while the
                    // reserved height above still rules out an overflow.
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Poster(url: kino.posterUrl(show), seed: show.key, width: _poster(context)),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          show.title,
                          maxLines: _titleLines(context),
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
/// One tile of the rail, with the same focus ring the cards have: on a
/// television, what is focused *is* what is selected, and a tinted background
/// doesn't say so from a sofa.
class _Resumable extends StatefulWidget {
  const _Resumable({required this.child, required this.onTap, this.autofocus = false});

  final Widget child;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  State<_Resumable> createState() => _ResumableState();
}

class _ResumableState extends State<_Resumable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);

    return InkWell(
      autofocus: widget.autofocus,
      onFocusChange: (has) => setState(() => _focused = has),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(
            color: _focused ? palette.accent : Colors.transparent,
            width: 4,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _ShowRow extends StatelessWidget {
  const _ShowRow({required this.summary, required this.onReturn, this.first = false});

  final ShowSummary summary;
  final Future<void> Function() onReturn;
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
      // A title page is where watching usually starts, so coming back from one
      // is the commonest moment for the rail to be stale.
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => ShowScreen(showKey: show.key)))
          .then((_) => onReturn()),
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

/// The web app's card, as a widget: a poster, then the title under it.
///
/// The caption is two rows rather than one. Sharing a line with the count
/// clipped most titles mid-word — "Розслідуванн" — which on a television is the
/// only thing being read from across a room.
class _ShowTile extends StatefulWidget {
  const _ShowTile({required this.summary, required this.onReturn, this.first = false});

  final ShowSummary summary;
  final Future<void> Function() onReturn;
  final bool first;

  @override
  State<_ShowTile> createState() => _ShowTileState();
}

class _ShowTileState extends State<_ShowTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final kino = Kino.of(context);
    final palette = Palette.of(context);
    final l10n = AppLocalizations.of(context);
    final show = widget.summary.show;

    final note = show.isFilm
        ? (widget.summary.playableCount > 0 ? l10n.film : l10n.filmNoStream)
        : l10n.episodeCount(widget.summary.episodeCount);

    return InkWell(
      autofocus: widget.first && Kino.isTv(context),
      onFocusChange: (has) => setState(() => _focused = has),
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => ShowScreen(showKey: show.key)))
          .then((_) => widget.onReturn()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          // Focus has to be unmistakable at three metres, and a tinted
          // background is not: the accent takes the whole frame instead.
          border: Border.all(
            color: _focused ? palette.accent : palette.line,
            width: _focused ? 3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: posterRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Poster(
                    url: kino.posterUrl(show),
                    seed: show.key,
                    // The frame is the card's; the poster fills it.
                    width: double.infinity,
                    bordered: false,
                  ),
                  // The score, on the artwork rather than under it: it is the
                  // thing most people choose by, and the caption below has room
                  // for one line of title and nothing else.
                  //
                  // Top right, on ink: a poster is somebody else's picture in
                  // colours they chose, and light type laid straight on one is
                  // unreadable often enough to need a ground of its own.
                  if (widget.summary.hasImdbRating())
                    Positioned(
                      top: 0,
                      right: 0,
                      child: ColoredBox(
                        color: const Color(0xE6201E1D),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          child: Text(
                            '★ ${widget.summary.imdbRating.toStringAsFixed(1)}',
                            style: body(11, weight: 700, color: paper),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Not `spaceBetween`: with a one-line title that opened a
                  // hole the height of a line and made every card look empty.
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        show.title,
                        // One line on a television. Two lines of 1.25-scaled
                        // type don't fit a compact card, and a title sliced
                        // through the middle of its letters is worse than one
                        // that ends in an ellipsis — the whole name is on the
                        // page this opens anyway.
                        maxLines: Kino.isTv(context) ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: body(13, weight: 600, color: palette.text),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      note.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(10, weight: 700, color: palette.accent),
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
