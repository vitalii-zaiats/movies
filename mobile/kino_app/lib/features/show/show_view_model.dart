/// One title, fetched once and held.
library;

import 'package:flutter/foundation.dart';
import 'package:kino_api/kino_api.dart';

import '../../core/async_value.dart';

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

  /// The whole show as a queue, in one call. Returns what to tell the viewer —
  /// a screen shouldn't have to know which exception means what.
  Future<String> queue() async {
    try {
      final list = await _kino.listFromShow(show: showKey);
      return 'Queued “${list.playlist.name}” · ${list.playlist.count}';
    } catch (problem) {
      return '$problem';
    }
  }
}
