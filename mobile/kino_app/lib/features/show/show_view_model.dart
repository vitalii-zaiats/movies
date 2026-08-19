/// One title, fetched once and held.
library;

import 'package:flutter/foundation.dart';
import 'package:kino_api/kino_api.dart';

import '../../core/async_value.dart';

/// What came of queueing a show. A pair rather than a sentence: the view model
/// has no `BuildContext` and therefore no language, and a screen that is handed
/// English cannot translate it back.
@immutable
class Queued {
  const Queued({required this.name, required this.count});

  final String name;
  final int count;
}

class ShowViewModel extends ChangeNotifier {
  ShowViewModel(this._kino, this.showKey);

  final KinoClient _kino;
  final String showKey;

  AsyncValue<ShowWithEpisodes> state = const Loading();

  Future<void> load() async {
    state = const Loading();
    notifyListeners();
    try {
      state = Data(await _kino.show(showKey));
    } catch (problem) {
      state = Failure(problem);
    }
    notifyListeners();
  }

  /// The whole show as a queue, in one call. Null means the server refused, and
  /// [problem] says why — again in its own words rather than in a sentence this
  /// layer had no business writing.
  Object? problem;

  Future<Queued?> queue() async {
    problem = null;
    try {
      final list = await _kino.listFromShow(show: showKey);
      return Queued(name: list.playlist.name, count: list.playlist.count);
    } catch (refusal) {
      problem = refusal;
      return null;
    }
  }
}
