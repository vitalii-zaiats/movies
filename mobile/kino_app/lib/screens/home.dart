/// Browse, search, and pick up where you left off.
///
/// The first thing this screen does is become somebody: `whoAmI` mints a guest
/// server-side and the token is kept on the device, so "continue watching" has
/// something to be about before anybody has signed up for anything.
library;

import 'package:flutter/material.dart';
import 'package:kino_api/kino_api.dart';

import '../kino.dart';
import '../widgets/art.dart';
import 'show.dart';
import 'player.dart';

const _pageSize = 30;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();

  User? _me;
  List<HistoryEntry> _going = [];
  final List<ShowSummary> _shows = [];
  int _total = 0;
  bool _loading = false;
  bool _series = false;
  String _query = '';
  Object? _problem;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
  }

  // Not `initState`: the client comes from an ancestor, and an ancestor is not
  // something a widget may look up until its dependencies are in place.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_me == null && _problem == null) _start();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final kino = Kino.of(context);
    try {
      final me = await kino.whoAmI();
      if (!mounted) return;
      setState(() => _me = me);
      await _refresh();
    } catch (problem) {
      if (mounted) setState(() => _problem = problem);
    }
  }

  Future<void> _refresh() async {
    final kino = Kino.of(context);
    setState(() {
      _problem = null;
      _shows.clear();
      _total = 0;
    });

    final going = await kino.continueWatching(limit: 12);
    if (!mounted) return;
    setState(() => _going = going);
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    if (_total != 0 && _shows.length >= _total) return;

    setState(() => _loading = true);
    final kino = Kino.of(context);
    try {
      final page = await kino.shows(
        q: _query.isEmpty ? null : _query,
        series: _series ? true : null,
        order: _query.isEmpty
            ? ShowOrder.SHOW_ORDER_NEWEST
            : ShowOrder.SHOW_ORDER_TITLE,
        limit: _pageSize,
        offset: _shows.length,
      );
      if (!mounted) return;
      setState(() {
        _shows.addAll(page.items);
        _total = page.page.total;
      });
    } catch (problem) {
      if (mounted) setState(() => _problem = problem);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _maybeLoadMore() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  void _find(String query) {
    setState(() => _query = query.trim());
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('kino'),
        actions: [
          if (_me != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  _me!.displayName,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _searchBar()),
            if (_problem != null)
              SliverToBoxAdapter(child: _Problem(problem: _problem!, retry: _refresh)),
            if (_going.isNotEmpty) SliverToBoxAdapter(child: _continueRail()),
            SliverToBoxAdapter(child: _heading()),
            SliverList.builder(
              itemCount: _shows.length,
              // On a television the first row takes focus, so the remote has
              // somewhere to be the moment the list arrives. On a phone nothing
              // is focused and nothing should be.
              itemBuilder: (context, index) => _ShowRow(
                summary: _shows[index],
                first: index == 0 && _going.isEmpty,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: _loading
                      ? const CircularProgressIndicator()
                      : Text(
                          _shows.isEmpty ? 'nothing here' : '${_shows.length} of $_total',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: _find,
              decoration: InputDecoration(
                hintText: 'Search titles',
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _search.clear();
                          _find('');
                        },
                      ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // The catalogue is mostly films; one switch is the whole filter.
          FilterChip(
            label: const Text('Series'),
            selected: _series,
            onSelected: (on) {
              setState(() => _series = on);
              _refresh();
            },
          ),
        ],
      ),
    );
  }

  Widget _heading() {
    final label = _query.isEmpty ? 'Newest' : 'Found';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _continueRail() {
    final kino = Kino.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text('Continue watching', style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _going.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = _going[index];
              final show = entry.episode.show;
              final ratio = entry.progress.hasRatio() ? entry.progress.ratio : 0.0;
              return SizedBox(
                width: 92,
                child: InkWell(
                  autofocus: index == 0 && Kino.isTv(context),
                  focusColor: Theme.of(context).focusColor,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PlayerScreen(
                        episode: entry.episode.episode,
                        show: show,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Poster(url: kino.posterUrl(show), seed: show.key),
                      const SizedBox(height: 6),
                      Text(
                        show.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: ratio, minHeight: 3),
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

class _ShowRow extends StatelessWidget {
  const _ShowRow({required this.summary, this.first = false});

  final ShowSummary summary;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final kino = Kino.of(context);
    final show = summary.show;
    return ListTile(
      autofocus: first && Kino.isTv(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Poster(url: kino.posterUrl(show), seed: show.key, width: 54),
      title: Text(show.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(showSubtitle(summary)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ShowScreen(showKey: show.key)),
      ),
    );
  }
}

class _Problem extends StatelessWidget {
  const _Problem({required this.problem, required this.retry});

  final Object problem;
  final Future<void> Function() retry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$problem'),
              const SizedBox(height: 8),
              // Nearly always the same thing: the phone can't reach the host.
              // Saying which address it tried beats saying "failed".
              Text(
                'tried $host:$grpcPort',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: retry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
