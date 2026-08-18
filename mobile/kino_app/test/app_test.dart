// The app, booted against a gRPC server running in the same process.
//
// It is worth the fakes below: the thing most likely to break here is not a
// widget but the shape of a call — a guest minted on the first frame, a page of
// shows drawn from what came back. A mocked client would have proved that the
// test's own idea of the API is self-consistent, which is not the same thing.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:kino_api/kino_api.dart';
import 'package:kino_api/src/generated/contracts/catalogue.pbgrpc.dart';
import 'package:kino_app/main.dart';

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
      await tester.pumpWidget(KinoApp(client: client));
      for (var frame = 0; frame < 10; frame++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await tester.pump();
      }
    });
    await tester.pump();

    expect(find.text('Guest ff00'), findsOneWidget);
    expect(find.text('Мараве'), findsOneWidget);
    expect(find.text('film'), findsOneWidget);
    expect(find.text('61 episodes · 60 playable'), findsOneWidget);
    expect(find.text('2 of 2'), findsOneWidget);

    await client.close();
    await server.shutdown();
  });
}
