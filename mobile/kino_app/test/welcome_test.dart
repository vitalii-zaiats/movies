// Signing in a device that has no keyboard, against a real server.
//
// The interesting half of this feature is a wait: a code goes up on a
// television and nothing happens until somebody, elsewhere, says yes. So the
// test drives the view model rather than the screen — a widget test's clock is
// fake and the polling here is deliberately real seconds, and mixing the two is
// how you get a test that passes by never running the code.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grpc/grpc.dart';
import 'package:kino_api/kino_api.dart';
import 'package:kino_api/src/generated/contracts/catalogue.pbgrpc.dart';
import 'package:kino_app/features/welcome/welcome_view_model.dart';

/// A server where the phone answers on the [approveAfter]-th poll.
class _Accounts extends AccountsServiceBase {
  _Accounts({this.approveAfter = 1});

  final int approveAfter;
  int polls = 0;
  String? askedFor;

  @override
  Future<DeviceLink> startDeviceLink(ServiceCall call, StartDeviceLinkRequest request) async {
    askedFor = request.hasDeviceName() ? request.deviceName : null;
    return DeviceLink(
      code: 'GXSNPT',
      secret: 'not-the-code',
      verifyPath: '/link?code=GXSNPT',
      expiresIn: 600,
    );
  }

  @override
  Future<DeviceSession> collectDeviceLink(
    ServiceCall call,
    CollectDeviceLinkRequest request,
  ) async {
    polls += 1;
    if (polls < approveAfter) return DeviceSession(linked: false);

    return DeviceSession(
      linked: true,
      identity: Identity(
        token: 'linked-token',
        user: User(publicId: 'aa11', displayName: 'Настя', isGuest: false),
      ),
    );
  }

  @override
  Future<Identity> whoAmI(ServiceCall call, WhoAmIRequest request) async => Identity(
        token: 'guest-token',
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

Future<(Server, KinoClient, MemoryTokenStore)> _serve(_Accounts accounts) async {
  final server = Server.create(services: [accounts]);
  await server.serve(address: InternetAddress.loopbackIPv4, port: 0);

  final tokens = MemoryTokenStore();
  final client = KinoClient(
    host: InternetAddress.loopbackIPv4.address,
    port: server.port!,
    tokens: tokens,
    mediaBase: Uri.parse('http://kino.local'),
  );
  return (server, client, tokens);
}

void main() {
  test('shows a code, then signs in when the phone approves', () async {
    // Not on the first poll: "not yet" is the ordinary answer and the model has
    // to keep waiting through it rather than treat it as a refusal.
    final accounts = _Accounts(approveAfter: 2);
    final (server, client, tokens) = await _serve(accounts);
    final model = WelcomeViewModel(client, deviceName: 'Android TV');

    await model.linkDevice();

    expect(model.stage, Welcome.waiting);
    expect(model.code, 'GXSNPT');
    expect(accounts.askedFor, 'Android TV');
    // The QR carries a URL, not a path: the server never knew this address.
    expect(model.url.toString(), 'http://kino.local/link?code=GXSNPT');
    // The secret is what collects the session, and it is not what is on screen.
    expect(model.code, isNot('not-the-code'));

    // Polls are two seconds apart; two of them, plus room to answer.
    await Future<void>.delayed(const Duration(seconds: 5));

    expect(model.stage, Welcome.done);
    expect(model.user?.displayName, 'Настя');
    // And this device is that person from now on — including after a restart.
    expect(await tokens.read(), 'linked-token');

    model.dispose();
    await client.close().timeout(const Duration(seconds: 2), onTimeout: () {});
    await server.shutdown().timeout(const Duration(seconds: 2), onTimeout: () {});
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('a guest is one call and no waiting', () async {
    final (server, client, tokens) = await _serve(_Accounts());
    final model = WelcomeViewModel(client);

    await model.asGuest();

    expect(model.stage, Welcome.done);
    expect(model.user?.isGuest, isTrue);
    expect(await tokens.read(), 'guest-token');

    model.dispose();
    await client.close().timeout(const Duration(seconds: 2), onTimeout: () {});
    await server.shutdown().timeout(const Duration(seconds: 2), onTimeout: () {});
  });
}
