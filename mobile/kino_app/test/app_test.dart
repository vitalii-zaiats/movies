// The app, booted against a gRPC server running in the same process.
//
// It is worth the fakes below: the thing most likely to break here is not a
// widget but the shape of a call — a guest minted on the first frame, a page of
// shows drawn from what came back. A mocked client would have proved that the
// test's own idea of the API is self-consistent, which is not the same thing.

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:kino_api/kino_api.dart';
import 'package:kino_api/src/generated/contracts/catalogue.pbgrpc.dart';
import 'package:kino_app/app.dart';
import 'package:kino_app/core/settings.dart';

class _Accounts extends AccountsServiceBase {
  @override
  Future<Identity> whoAmI(ServiceCall call, WhoAmIRequest request) async => Identity(
        token: 'token',
        user: User(publicId: 'ff00', displayName: 'Guest ff00', isGuest: true),
      );

  @override
  Future<Identity> startGuest(ServiceCall call, StartGuestRequest request) async =>
      throw UnimplementedError();
  @override
  Future<Identity> claim(ServiceCall call, ClaimRequest request) async =>
      throw UnimplementedError();
  @override
  Future<Identity> login(ServiceCall call, LoginRequest request) async =>
      throw UnimplementedError();
  @override
  Future<LogoutResponse> logout(ServiceCall call, LogoutRequest request) async =>
      LogoutResponse();
  @override
  Future<User> rename(ServiceCall call, RenameRequest request) async =>
      throw UnimplementedError();
}

class _Watching extends WatchingServiceBase {
  @override
  Future<ContinueWatchingResponse> continueWatching(
    ServiceCall call,
    ContinueWatchingRequest request,
  ) async =>
      ContinueWatchingResponse();

  @override
  Future<Progress> reportProgress(ServiceCall call, ReportProgressRequest request) async =>
      throw UnimplementedError();
  @override
  Future<Progress> getProgress(ServiceCall call, GetProgressRequest request) async =>
      throw GrpcError.notFound();
  @override
  Future<ForgetProgressResponse> forgetProgress(
          ServiceCall call, ForgetProgressRequest request) async =>
      ForgetProgressResponse();
  @override
  Future<ListHistoryResponse> listHistory(ServiceCall call, ListHistoryRequest request) async =>
      throw UnimplementedError();
}

class _Catalogue extends CatalogueServiceBase {
  @override
  Future<ListShowsResponse> listShows(ServiceCall call, ListShowsRequest request) async =>
      ListShowsResponse(
        page: PageInfo(total: 2, limit: request.limit, offset: request.offset),
        items: [
          ShowSummary(
            show: Show(id: 1, key: 'marave', title: 'Мараве', isFilm: true),
            episodeCount: 1,
            playableCount: 1,
          ),
          ShowSummary(
            show: Show(id: 2, key: 'rickandmorty', title: 'Rick and Morty'),
            episodeCount: 61,
            playableCount: 60,
          ),
        ],
      );

  @override
  Future<HealthResponse> health(ServiceCall call, HealthRequest request) async =>
      HealthResponse(status: 'ok');
  @override
  Future<ShowWithEpisodes> getShow(ServiceCall call, GetShowRequest request) async =>
      throw UnimplementedError();
  @override
  Stream<ShowSummary> streamShows(ServiceCall call, StreamShowsRequest request) =>
      const Stream.empty();
  @override
  Future<ListEpisodesResponse> listEpisodes(ServiceCall call, ListEpisodesRequest request) async =>
      throw UnimplementedError();
  @override
  Future<EpisodeWithShow> getEpisode(ServiceCall call, GetEpisodeRequest request) async =>
      throw UnimplementedError();
  @override
  Future<Home> getHome(ServiceCall call, GetHomeRequest request) async => Home();
}

void main() {
  testWidgets('boots as a guest and draws what the catalogue sent', (tester) async {
    // A phone-shaped window: the home screen draws rows below this width and a
    // grid of posters above it, and the assertions below are about the rows.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final server = Server.create(services: [_Accounts(), _Watching(), _Catalogue()]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    final client = KinoClient(
      host: InternetAddress.loopbackIPv4.address,
      port: server.port!,
      // No platform channels in a widget test, and nothing here should outlive
      // the test anyway.
      tokens: MemoryTokenStore(),
      mediaBase: Uri.parse('http://kino.local'),
    );

    // `runAsync`, because the calls below are real sockets: inside a widget
    // test the clock is fake and a plain `pumpAndSettle` would settle long
    // before the server had said anything.
    await tester.runAsync(() async {
      await tester.pumpWidget(KinoApp(client: client, settings: Settings()));
      for (var frame = 0; frame < 10; frame++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();

    // The name is drawn as one of the system's labels, so it arrives upper
    // case — see `theme.dart`.
    expect(find.text('GUEST FF00'), findsOneWidget);
    expect(find.text('Мараве'), findsOneWidget);
    // Upper case because the design system says so — see `theme.dart`.
    expect(find.text('FILM'), findsOneWidget);
    expect(find.text('61 EPISODES · 60 PLAYABLE'), findsOneWidget);
    expect(find.text('2 of 2'), findsOneWidget);

    // Widen it and the same catalogue comes back as cards. The tile has room
    // for a count but not for the second half of the row's sentence, which is
    // how the two layouts can be told apart from here.
    tester.view.physicalSize = const Size(2400, 1600);
    tester.view.devicePixelRatio = 2;
    await tester.pump();

    expect(find.text('61 EPISODES · 60 PLAYABLE'), findsNothing);
    expect(find.text('61 EPISODES'), findsOneWidget);

    // Shutting both down is real I/O too. Bounded, because a channel with a
    // half-open connection can wait a long time and this is a teardown, not an
    // assertion.
    await tester.runAsync(() async {
      await client.close().timeout(const Duration(seconds: 2), onTimeout: () {});
      await server.shutdown().timeout(const Duration(seconds: 2), onTimeout: () {});
    });
  });
}
