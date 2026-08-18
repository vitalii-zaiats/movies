/// What the home screen knows, and how it changes.
///
/// A `ChangeNotifier` rather than `setState` inside the widget: the screen has
/// four moving parts — who you are, what you were watching, a page of results
/// and a query — and keeping them in the widget means every one of them is also
/// a rebuild decision. Here they are fields, the widget is a function of them,
/// and the whole thing can be exercised without a `WidgetTester`.
library;

import 'package:flutter/foundation.dart';
import 'package:kino_api/kino_api.dart';

/// A screenful. Small enough to arrive quickly, large enough that scrolling
/// doesn't fetch on every flick.
const _pageSize = 30;

class HomeViewModel extends ChangeNotifier {
  HomeViewModel(this._kino);

  final KinoClient _kino;

  User? user;
  List<HistoryEntry> going = const [];
  final List<ShowSummary> shows = [];
  int total = 0;
  bool loading = false;
  bool seriesOnly = false;
  String query = '';
  Object? error;

  bool get exhausted => total != 0 && shows.length >= total;

  /// The first thing the app does: become somebody. A guest is minted
  /// server-side and the token kept on the device, so "continue watching" has
  /// something to be about before anyone has signed up for anything.
  Future<void> start() async {
    try {
      user = await _kino.whoAmI();
      notifyListeners();
    } catch (problem) {
      error = problem;
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    error = null;
    shows.clear();
    total = 0;
    notifyListeners();

    try {
      going = await _kino.continueWatching(limit: 12);
      user ??= await _kino.whoAmI();
      notifyListeners();
    } catch (problem) {
      error = problem;
      notifyListeners();
      return;
    }
    await loadMore();
  }

  Future<void> loadMore() async {
    if (loading || exhausted) return;
    loading = true;
    notifyListeners();

    try {
      final page = await _kino.shows(
        q: query.isEmpty ? null : query,
        series: seriesOnly ? true : null,
        // Newest first while browsing; by title once there's a query, because
        // "closest match" is not something the server ranks and alphabetical at
        // least doesn't pretend to.
        order: query.isEmpty ? ShowOrder.SHOW_ORDER_NEWEST : ShowOrder.SHOW_ORDER_TITLE,
        limit: _pageSize,
        offset: shows.length,
      );
      shows.addAll(page.items);
      total = page.page.total;
      error = null;
    } catch (problem) {
      error = problem;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String text) {
    query = text.trim();
    return refresh();
  }

  Future<void> onlySeries(bool only) {
    seriesOnly = only;
    return refresh();
  }
}
