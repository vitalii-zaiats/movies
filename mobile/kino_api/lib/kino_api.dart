/// The catalogue as a Flutter package: gRPC in, generated messages out.
///
/// One import gets a screen everything it needs — the client, the messages it
/// hands back, and the token store that keeps this phone the same person
/// between launches:
///
/// ```dart
/// final kino = KinoClient(
///   host: '10.0.2.2',                          // the emulator's word for "this Mac"
///   mediaBase: Uri.parse('http://10.0.2.2:8080'),
/// );
/// await kino.whoAmI();                          // become somebody
/// final page = await kino.shows(limit: 30, order: ShowOrder.SHOW_ORDER_NEWEST);
/// ```
///
/// The messages are generated from `packages/contracts/src/contracts/catalogue.proto`
/// and are committed here, so `flutter pub get` is the whole setup. Regenerate
/// both languages at once with:
///
/// ```
/// uv run --package contracts python -m contracts.generate
/// ```
library;

export 'src/client.dart';
export 'src/generated/contracts/catalogue.pb.dart';
// The raw stubs, for calls this wrapper hasn't got round to. Anything used
// through these carries no session token unless you pass the options yourself.
export 'src/generated/contracts/catalogue.pbgrpc.dart'
    show AccountsClient, CatalogueClient, PlaylistsClient, WatchingClient;
export 'src/tokens.dart';
