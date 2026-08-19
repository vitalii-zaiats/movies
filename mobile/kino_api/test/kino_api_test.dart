// The wrapper's two jobs, against a real server.
//
// A gRPC server in this process rather than a mocked stub: the things worth
// testing here are metadata and status codes, which is exactly what a mock
// would have to invent. The fakes below answer like the Python service does —
// mint a token when nobody sent one, refuse with NOT_FOUND for an episode
// nobody has watched — and the tests check that the client behaves as if it had
// been talking to it.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:kino_api/kino_api.dart';
import 'package:kino_api/src/generated/contracts/catalogue.pbgrpc.dart';

const _minted = 'a-freshly-minted-token';

class _FakeAccounts extends AccountsServiceBase {
  /// What the client put in `authorization`, call by call.
  final List<String?> seen = [];

  @override
  Future<Identity> whoAmI(ServiceCall call, WhoAmIRequest request) async {
    final authorization = call.clientMetadata?['authorization'];
    seen.add(authorization);

    if (authorization == null) {
      // Nobody yet: mint, and hand the token back the way the server does.
      call.headers?[sessionMetadata] = _minted;
      call.sendHeaders();
      return Identity(token: _minted, user: _guest);
    }
    return Identity(user: _guest);
  }

  User get _guest => User(
        publicId: 'ff00',
        displayName: 'Guest ff00',
        isGuest: true,
        role: Role.ROLE_USER,
        createdAt: '2026-08-18T09:00:00Z',
        lastSeenAt: '2026-08-18T09:00:00Z',
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

  /// Flipped by the test to stand in for somebody approving on their phone.
  bool approved = false;

  @override
  Future<DeviceLink> startDeviceLink(ServiceCall call, StartDeviceLinkRequest request) async =>
      DeviceLink(
        code: 'GXSNPT',
        secret: 'kept-on-the-television',
        verifyPath: '/link?code=GXSNPT',
        expiresIn: 600,
      );

  @override
  Future<DeviceSession> collectDeviceLink(
    ServiceCall call,
    CollectDeviceLinkRequest request,
  ) async {
    if (!approved) return DeviceSession(linked: false);

    call.headers?[sessionMetadata] = 'linked-token';
    call.sendHeaders();
    return DeviceSession(
      linked: true,
      identity: Identity(token: 'linked-token', user: _guest),
    );
  }
}

class _FakeWatching extends WatchingServiceBase {
  @override
  Future<Progress> getProgress(ServiceCall call, GetProgressRequest request) async {
    // What the real service says about an episode nobody has opened.
    throw GrpcError.notFound('no progress for episode ${request.episodeId}');
  }

  @override
  Future<Progress> reportProgress(ServiceCall call, ReportProgressRequest request) async =>
      Progress(
        episodeId: request.episodeId,
        positionSeconds: request.positionSeconds,
        lastWatchedAt: '2026-08-18T09:00:00Z',
      );

  @override
  Future<ForgetProgressResponse> forgetProgress(
    ServiceCall call,
    ForgetProgressRequest request,
  ) async =>
      ForgetProgressResponse();

  @override
  Future<ListHistoryResponse> listHistory(ServiceCall call, ListHistoryRequest request) async =>
      throw UnimplementedError();

  @override
  Future<ContinueWatchingResponse> continueWatching(
    ServiceCall call,
    ContinueWatchingRequest request,
  ) async =>
      throw UnimplementedError();
}

void main() {
  late Server server;
  late _FakeAccounts accounts;
  late KinoClient kino;

  setUp(() async {
    accounts = _FakeAccounts();
    server = Server.create(services: [accounts, _FakeWatching()]);
    await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

    kino = KinoClient(
      host: InternetAddress.loopbackIPv4.address,
      port: server.port!,
      tokens: MemoryTokenStore(),
      mediaBase: Uri.parse('http://kino.local:8080'),
    );
  });

  tearDown(() async {
    await kino.close();
    await server.shutdown();
  });

  test('a token handed back in metadata is kept and sent on the next call', () async {
    final first = await kino.whoAmI();
    expect(first.isGuest, isTrue);
    expect(await kino.token, _minted);

    await kino.whoAmI();
    expect(accounts.seen, [null, 'Bearer $_minted']);
  });

  test('logging out forgets the token, so the next call is nobody again', () async {
    await kino.whoAmI();
    await kino.logout();
    expect(await kino.token, isNull);

    await kino.whoAmI();
    expect(accounts.seen.last, isNull);
  });

  test('never watched is an answer, not a failure', () async {
    expect(await kino.progress(4242), isNull);
  });

  test('waiting for a phone is null, and being approved is a new identity', () async {
    final link = await kino.startLink(deviceName: 'Android TV');
    // The QR carries a URL; the server only ever knew a path.
    expect(kino.linkUrl(link).toString(), 'http://kino.local:8080/link?code=GXSNPT');

    // Nobody has said yes, which is not a refusal and not an identity either.
    expect(await kino.collectLink(link.secret), isNull);
    expect(await kino.token, isNull);

    accounts.approved = true;
    final user = await kino.collectLink(link.secret);
    expect(user?.publicId, 'ff00');
    // And this device is that person from here on.
    expect(await kino.token, 'linked-token');
  });

  test('paths become URLs, and absolute ones are left alone', () {
    final episode = Episode(id: 1, playlist: '/vod/7455/index.m3u8');
    expect(kino.streamUrl(episode).toString(), 'http://kino.local:8080/vod/7455/index.m3u8');

    final unpackaged = Episode(id: 2);
    expect(kino.streamUrl(unpackaged), isNull);

    final show = Show(id: 3, poster: 'https://kinoukr.tv/uploads/poster.jpg');
    expect(kino.posterUrl(show).toString(), 'https://kinoukr.tv/uploads/poster.jpg');
  });
}
