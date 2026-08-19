/// The catalogue, as one object.
///
/// Everything here is a thin call onto the generated stubs — the point of the
/// wrapper is the two things a raw stub can't do for you:
///
///   * the token. Every call carries it, and any call may hand a new one back
///     in `x-session-token` metadata, because the server mints a guest for
///     whoever asks for something personal without an identity. Both halves are
///     handled here, so no screen has to know that identity exists.
///   * the URLs. A playlist arrives as `/vod/7455/index.m3u8` — a path, because
///     the server has no idea what address the phone reached it on. `streamUrl`
///     is where that becomes something a player can open.
library;

import 'package:grpc/grpc.dart';

import 'generated/contracts/catalogue.pbgrpc.dart';
import 'tokens.dart';

/// Handed back by the server whenever this call created the session.
const sessionMetadata = 'x-session-token';

class KinoClient {
  /// [secure] turns on TLS. With nothing else, that means the system's own
  /// trust store — the right answer when this is reached through nginx with a
  /// real certificate.
  ///
  /// [trustedRoots] is for the other case: a stack on the LAN, with a
  /// certificate it signed itself. Pass the CA's PEM bytes (an asset, usually)
  /// and this connection trusts that one authority *in addition to* the system
  /// ones — which is a narrower thing to do than teaching all of Android to
  /// trust it, and it does not require touching the network security config.
  ///
  /// [authority] is the name to check the certificate against when it isn't the
  /// address dialled: a certificate says `kino.local`, the phone dials
  /// `192.168.0.10`, and without this those disagree and the handshake fails.
  KinoClient({
    required this.host,
    this.port = 50061,
    this.secure = false,
    List<int>? trustedRoots,
    String? authority,
    TokenStore? tokens,
    this.mediaBase,
    this.timeout = const Duration(seconds: 20),
  }) : _tokens = tokens ?? PrefsTokenStore() {
    _channel = ClientChannel(
      host,
      port: port,
      options: ChannelOptions(
        credentials: secure
            ? ChannelCredentials.secure(
                certificates: trustedRoots,
                authority: authority,
              )
            : const ChannelCredentials.insecure(),
        // A phone changes networks mid-sentence. Without a keepalive the first
        // call after the walk to the kitchen waits for a dead socket to time
        // out; with one, the channel notices and reconnects on its own.
        idleTimeout: const Duration(minutes: 5),
      ),
    );

    catalogue = CatalogueClient(_channel);
    accounts = AccountsClient(_channel);
    watching = WatchingClient(_channel);
    playlists = PlaylistsClient(_channel);
  }

  final String host;
  final int port;
  final bool secure;

  /// Where this stack is reachable over plain HTTP — `http://10.0.2.2:8080`,
  /// say. Only used to turn the server's paths into absolute URLs.
  final Uri? mediaBase;
  final Duration timeout;

  final TokenStore _tokens;

  late final ClientChannel _channel;

  /// The generated stubs, for anything this wrapper hasn't got round to. Calls
  /// made on them carry no token unless you pass [options] yourself.
  late final CatalogueClient catalogue;
  late final AccountsClient accounts;
  late final WatchingClient watching;
  late final PlaylistsClient playlists;

  Future<void> close() => _channel.shutdown();

  /// The token this client is currently somebody by.
  Future<String?> get token => _tokens.read();

  // --- the two things the wrapper is for ------------------------------------

  CallOptions get _options => CallOptions(
        timeout: timeout,
        providers: [
          (metadata, _) async {
            final token = await _tokens.read();
            if (token != null && token.isNotEmpty) {
              metadata['authorization'] = 'Bearer $token';
            }
          },
        ],
      );

  Future<R> _unary<R>(ResponseFuture<R> call) async {
    final result = await call;
    await _remember(call.headers);
    return result;
  }

  Future<void> _remember(Future<Map<String, String>> headers) async {
    final token = (await headers)[sessionMetadata];
    if (token != null && token.isNotEmpty) await _tokens.save(token);
  }

  /// An absolute URL for one of the server's paths, or null for nothing.
  Uri? resolve(String? url) {
    if (url == null || url.isEmpty) return null;
    final parsed = Uri.tryParse(url);
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed;
    // A path — `/vod/7455/index.m3u8`, `/media/12.jpg` — which only means
    // something next to the address this stack was reached on.
    return mediaBase?.resolveUri(parsed);
  }

  /// What to hand a player, or null when this episode was never packaged.
  Uri? streamUrl(Episode episode) =>
      episode.hasPlaylist() ? resolve(episode.playlist) : null;

  /// The same, for one particular dub.
  Uri? trackUrl(Track track) => resolve(track.playlist);

  Uri? posterUrl(Show show) => show.hasPoster() ? resolve(show.poster) : null;

  // --- who's watching -------------------------------------------------------

  /// Who am I — becoming somebody if the answer would have been nobody.
  ///
  /// The first call an app makes. A guest is minted server-side and the token
  /// comes back in the metadata, so from here on this phone has a history.
  Future<User> whoAmI() async {
    final identity = await _unary(accounts.whoAmI(WhoAmIRequest(), options: _options));
    if (identity.token.isNotEmpty) await _tokens.save(identity.token);
    return identity.user;
  }

  /// A brand new guest, even if this phone already was one. "Watch as somebody
  /// else" — the shared-TV case.
  Future<User> startGuest() async {
    final identity = await _unary(accounts.startGuest(StartGuestRequest(), options: _options));
    await _tokens.save(identity.token);
    return identity.user;
  }

  /// Keep this account, add a login to it. Nothing watched so far is lost.
  Future<User> claim({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final request = ClaimRequest(email: email, password: password);
    if (displayName != null) request.displayName = displayName;

    final identity = await _unary(accounts.claim(request, options: _options));
    await _tokens.save(identity.token);
    return identity.user;
  }

  Future<User> login({required String email, required String password}) async {
    final identity = await _unary(
      accounts.login(LoginRequest(email: email, password: password), options: _options),
    );
    await _tokens.save(identity.token);
    return identity.user;
  }

  /// Ends the session on the server and forgets it here. The next call starts a
  /// new guest, which is what being signed out of this app means.
  Future<void> logout() async {
    await _unary(accounts.logout(LogoutRequest(), options: _options));
    await _tokens.clear();
  }

  Future<User> rename(String displayName) =>
      _unary(accounts.rename(RenameRequest(displayName: displayName), options: _options));

  // --- browsing -------------------------------------------------------------

  Future<HealthResponse> health() =>
      _unary(catalogue.health(HealthRequest(), options: _options));

  /// [kind] is what the source called it — `film`, `series`, `cartoon`,
  /// `anime` — which is a different question from [series]: that one counts
  /// episodes, and a cartoon has the same shape as a film.
  Future<ListShowsResponse> shows({
    String? q,
    bool? series,
    String? kind,
    ShowOrder order = ShowOrder.SHOW_ORDER_UNSPECIFIED,
    int limit = 50,
    int offset = 0,
  }) {
    final request = ListShowsRequest(order: order, limit: limit, offset: offset);
    if (q != null && q.isNotEmpty) request.q = q;
    if (series != null) request.series = series;
    if (kind != null && kind.isNotEmpty) request.kind = kind;
    return _unary(catalogue.listShows(request, options: _options));
  }

  /// The whole catalogue as it arrives, rather than a page at a time.
  Stream<ShowSummary> allShows({
    String? q,
    bool? series,
    String? kind,
    ShowOrder order = ShowOrder.SHOW_ORDER_UNSPECIFIED,
    int limit = 0,
  }) {
    final request = StreamShowsRequest(order: order, limit: limit);
    if (q != null && q.isNotEmpty) request.q = q;
    if (series != null) request.series = series;
    if (kind != null && kind.isNotEmpty) request.kind = kind;

    final call = catalogue.streamShows(request, options: _options);
    _unawaited(_remember(call.headers));
    return call;
  }

  Future<ShowWithEpisodes> show(String key) =>
      _unary(catalogue.getShow(GetShowRequest(key: key), options: _options));

  Future<ListEpisodesResponse> episodes({
    String? show,
    int? season,
    String? q,
    bool? playable,
    int limit = 50,
    int offset = 0,
  }) {
    final request = ListEpisodesRequest(limit: limit, offset: offset);
    if (show != null) request.show = show;
    if (season != null) request.season = season;
    if (q != null && q.isNotEmpty) request.q = q;
    if (playable != null) request.playable = playable;
    return _unary(catalogue.listEpisodes(request, options: _options));
  }

  Future<EpisodeWithShow> episode(int id) =>
      _unary(catalogue.getEpisode(GetEpisodeRequest(id: id), options: _options));

  /// The front page, arranged by whoever runs this install.
  Future<Home> home({bool preview = false}) =>
      _unary(catalogue.getHome(GetHomeRequest(preview: preview), options: _options));

  // --- watching -------------------------------------------------------------

  /// The player checking in. Cheap by design — call it every ten seconds.
  Future<Progress> report({
    required int episodeId,
    required double positionSeconds,
    double? durationSeconds,
    bool? completed,
  }) {
    final request = ReportProgressRequest(
      episodeId: episodeId,
      positionSeconds: positionSeconds,
    );
    if (durationSeconds != null) request.durationSeconds = durationSeconds;
    if (completed != null) request.completed = completed;
    return _unary(watching.reportProgress(request, options: _options));
  }

  /// Where to open at — or null, which means the beginning.
  ///
  /// The server says NOT_FOUND for "never watched", which is an answer rather
  /// than a failure, so it arrives here as null instead of an exception.
  Future<Progress?> progress(int episodeId) async {
    try {
      return await _unary(
        watching.getProgress(GetProgressRequest(episodeId: episodeId), options: _options),
      );
    } on GrpcError catch (error) {
      if (error.code == StatusCode.notFound) return null;
      rethrow;
    }
  }

  Future<void> forget(int episodeId) => _unary(
        watching.forgetProgress(
          ForgetProgressRequest(episodeId: episodeId),
          options: _options,
        ),
      );

  Future<ListHistoryResponse> history({bool? completed, int limit = 50, int offset = 0}) {
    final request = ListHistoryRequest(limit: limit, offset: offset);
    if (completed != null) request.completed = completed;
    return _unary(watching.listHistory(request, options: _options));
  }

  /// Started and unfinished, newest first.
  Future<List<HistoryEntry>> continueWatching({int limit = 20}) async {
    final response = await _unary(
      watching.continueWatching(ContinueWatchingRequest(limit: limit), options: _options),
    );
    return response.items;
  }

  // --- playlists ------------------------------------------------------------

  Future<List<Playlist>> lists({
    PlaylistScope scope = PlaylistScope.PLAYLIST_SCOPE_UNSPECIFIED,
  }) async {
    final response =
        await _unary(playlists.listPlaylists(ListPlaylistsRequest(scope: scope), options: _options));
    return response.items;
  }

  Future<PlaylistDetail> list(int id) =>
      _unary(playlists.getPlaylist(GetPlaylistRequest(id: id), options: _options));

  Future<PlaylistDetail> createList(String name) => _unary(
        playlists.createPlaylist(CreatePlaylistRequest(name: name), options: _options),
      );

  /// A season, or a whole show, as a queue in one call.
  Future<PlaylistDetail> listFromShow({
    required String show,
    int? season,
    String? name,
    bool playableOnly = true,
  }) {
    final request = CreateFromShowRequest(show: show, playableOnly: playableOnly);
    if (season != null) request.season = season;
    if (name != null) request.name = name;
    return _unary(playlists.createFromShow(request, options: _options));
  }

  /// Rename it, or publish it. What isn't passed is left alone.
  Future<PlaylistDetail> updateList(int id, {String? name, PlaylistVisibility? visibility}) {
    final request = UpdatePlaylistRequest(id: id);
    if (name != null) request.name = name;
    if (visibility != null) request.visibility = visibility;
    return _unary(playlists.updatePlaylist(request, options: _options));
  }

  Future<void> deleteList(int id) =>
      _unary(playlists.deletePlaylist(DeletePlaylistRequest(id: id), options: _options));

  Future<PlaylistDetail> addToList(int playlistId, int episodeId) => _unary(
        playlists.addItem(
          AddItemRequest(playlistId: playlistId, episodeId: episodeId),
          options: _options,
        ),
      );

  Future<PlaylistDetail> removeFromList(int playlistId, int itemId) => _unary(
        playlists.removeItem(
          RemoveItemRequest(playlistId: playlistId, itemId: itemId),
          options: _options,
        ),
      );

  Future<PlaylistDetail> reorderList(int playlistId, List<int> itemIds) => _unary(
        playlists.reorder(
          ReorderRequest(playlistId: playlistId, itemIds: itemIds),
          options: _options,
        ),
      );
}

/// A future whose result nobody is waiting for, and whose failure nobody should
/// be woken up by — remembering a token is best-effort.
void _unawaited(Future<void> work) {
  work.catchError((Object _) {});
}
