// This is a generated file - do not edit.
//
// Generated from contracts/catalogue.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'catalogue.pb.dart' as $0;

export 'catalogue.pb.dart';

@$pb.GrpcServiceName('catalogue.v1.Accounts')
class AccountsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  AccountsClient(super.channel, {super.options, super.interceptors});

  /// Who am I — minting a guest if the answer would have been nobody.
  $grpc.ResponseFuture<$0.Identity> whoAmI(
    $0.WhoAmIRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$whoAmI, request, options: options);
  }

  /// A *new* guest, even if the caller already had one. That's what makes it
  /// usable as "watch as someone else on the shared TV".
  $grpc.ResponseFuture<$0.Identity> startGuest(
    $0.StartGuestRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startGuest, request, options: options);
  }

  /// Keep the account, add the login: the guest row gains an email and a
  /// password, so nothing watched so far is lost.
  $grpc.ResponseFuture<$0.Identity> claim(
    $0.ClaimRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$claim, request, options: options);
  }

  $grpc.ResponseFuture<$0.Identity> login(
    $0.LoginRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$login, request, options: options);
  }

  $grpc.ResponseFuture<$0.LogoutResponse> logout(
    $0.LogoutRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$logout, request, options: options);
  }

  $grpc.ResponseFuture<$0.User> rename(
    $0.RenameRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$rename, request, options: options);
  }

  /// Signing in a device that has no keyboard.
  ///
  /// A television asks for a code, shows it (as a QR, usually), and waits. A
  /// phone opens that code in a browser and approves it as whoever is signed in
  /// there. Then the television collects a session of its own.
  ///
  /// Approval is deliberately not here: it happens in a browser, where somebody
  /// is already signed in and can see what they are agreeing to.
  $grpc.ResponseFuture<$0.DeviceLink> startDeviceLink(
    $0.StartDeviceLinkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$startDeviceLink, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeviceSession> collectDeviceLink(
    $0.CollectDeviceLinkRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$collectDeviceLink, request, options: options);
  }

  // method descriptors

  static final _$whoAmI = $grpc.ClientMethod<$0.WhoAmIRequest, $0.Identity>(
      '/catalogue.v1.Accounts/WhoAmI',
      ($0.WhoAmIRequest value) => value.writeToBuffer(),
      $0.Identity.fromBuffer);
  static final _$startGuest =
      $grpc.ClientMethod<$0.StartGuestRequest, $0.Identity>(
          '/catalogue.v1.Accounts/StartGuest',
          ($0.StartGuestRequest value) => value.writeToBuffer(),
          $0.Identity.fromBuffer);
  static final _$claim = $grpc.ClientMethod<$0.ClaimRequest, $0.Identity>(
      '/catalogue.v1.Accounts/Claim',
      ($0.ClaimRequest value) => value.writeToBuffer(),
      $0.Identity.fromBuffer);
  static final _$login = $grpc.ClientMethod<$0.LoginRequest, $0.Identity>(
      '/catalogue.v1.Accounts/Login',
      ($0.LoginRequest value) => value.writeToBuffer(),
      $0.Identity.fromBuffer);
  static final _$logout =
      $grpc.ClientMethod<$0.LogoutRequest, $0.LogoutResponse>(
          '/catalogue.v1.Accounts/Logout',
          ($0.LogoutRequest value) => value.writeToBuffer(),
          $0.LogoutResponse.fromBuffer);
  static final _$rename = $grpc.ClientMethod<$0.RenameRequest, $0.User>(
      '/catalogue.v1.Accounts/Rename',
      ($0.RenameRequest value) => value.writeToBuffer(),
      $0.User.fromBuffer);
  static final _$startDeviceLink =
      $grpc.ClientMethod<$0.StartDeviceLinkRequest, $0.DeviceLink>(
          '/catalogue.v1.Accounts/StartDeviceLink',
          ($0.StartDeviceLinkRequest value) => value.writeToBuffer(),
          $0.DeviceLink.fromBuffer);
  static final _$collectDeviceLink =
      $grpc.ClientMethod<$0.CollectDeviceLinkRequest, $0.DeviceSession>(
          '/catalogue.v1.Accounts/CollectDeviceLink',
          ($0.CollectDeviceLinkRequest value) => value.writeToBuffer(),
          $0.DeviceSession.fromBuffer);
}

@$pb.GrpcServiceName('catalogue.v1.Accounts')
abstract class AccountsServiceBase extends $grpc.Service {
  $core.String get $name => 'catalogue.v1.Accounts';

  AccountsServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.WhoAmIRequest, $0.Identity>(
        'WhoAmI',
        whoAmI_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.WhoAmIRequest.fromBuffer(value),
        ($0.Identity value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartGuestRequest, $0.Identity>(
        'StartGuest',
        startGuest_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StartGuestRequest.fromBuffer(value),
        ($0.Identity value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ClaimRequest, $0.Identity>(
        'Claim',
        claim_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ClaimRequest.fromBuffer(value),
        ($0.Identity value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LoginRequest, $0.Identity>(
        'Login',
        login_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LoginRequest.fromBuffer(value),
        ($0.Identity value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.LogoutRequest, $0.LogoutResponse>(
        'Logout',
        logout_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.LogoutRequest.fromBuffer(value),
        ($0.LogoutResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RenameRequest, $0.User>(
        'Rename',
        rename_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RenameRequest.fromBuffer(value),
        ($0.User value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StartDeviceLinkRequest, $0.DeviceLink>(
        'StartDeviceLink',
        startDeviceLink_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.StartDeviceLinkRequest.fromBuffer(value),
        ($0.DeviceLink value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.CollectDeviceLinkRequest, $0.DeviceSession>(
            'CollectDeviceLink',
            collectDeviceLink_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.CollectDeviceLinkRequest.fromBuffer(value),
            ($0.DeviceSession value) => value.writeToBuffer()));
  }

  $async.Future<$0.Identity> whoAmI_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.WhoAmIRequest> $request) async {
    return whoAmI($call, await $request);
  }

  $async.Future<$0.Identity> whoAmI(
      $grpc.ServiceCall call, $0.WhoAmIRequest request);

  $async.Future<$0.Identity> startGuest_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StartGuestRequest> $request) async {
    return startGuest($call, await $request);
  }

  $async.Future<$0.Identity> startGuest(
      $grpc.ServiceCall call, $0.StartGuestRequest request);

  $async.Future<$0.Identity> claim_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ClaimRequest> $request) async {
    return claim($call, await $request);
  }

  $async.Future<$0.Identity> claim(
      $grpc.ServiceCall call, $0.ClaimRequest request);

  $async.Future<$0.Identity> login_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LoginRequest> $request) async {
    return login($call, await $request);
  }

  $async.Future<$0.Identity> login(
      $grpc.ServiceCall call, $0.LoginRequest request);

  $async.Future<$0.LogoutResponse> logout_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.LogoutRequest> $request) async {
    return logout($call, await $request);
  }

  $async.Future<$0.LogoutResponse> logout(
      $grpc.ServiceCall call, $0.LogoutRequest request);

  $async.Future<$0.User> rename_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RenameRequest> $request) async {
    return rename($call, await $request);
  }

  $async.Future<$0.User> rename(
      $grpc.ServiceCall call, $0.RenameRequest request);

  $async.Future<$0.DeviceLink> startDeviceLink_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StartDeviceLinkRequest> $request) async {
    return startDeviceLink($call, await $request);
  }

  $async.Future<$0.DeviceLink> startDeviceLink(
      $grpc.ServiceCall call, $0.StartDeviceLinkRequest request);

  $async.Future<$0.DeviceSession> collectDeviceLink_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CollectDeviceLinkRequest> $request) async {
    return collectDeviceLink($call, await $request);
  }

  $async.Future<$0.DeviceSession> collectDeviceLink(
      $grpc.ServiceCall call, $0.CollectDeviceLinkRequest request);
}

@$pb.GrpcServiceName('catalogue.v1.Catalogue')
class CatalogueClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CatalogueClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.HealthResponse> health(
    $0.HealthRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$health, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListShowsResponse> listShows(
    $0.ListShowsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listShows, request, options: options);
  }

  /// Everything on one show's page: what the crawl knew, plus its episodes.
  $grpc.ResponseFuture<$0.ShowWithEpisodes> getShow(
    $0.GetShowRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getShow, request, options: options);
  }

  /// The whole catalogue, a show at a time.
  ///
  /// Paging exists because a browse screen wants a screenful; this exists
  /// because a phone that wants to search offline wants all eight thousand, and
  /// asking for them 50 at a time is 160 round trips. One call, one stream, and
  /// the client can draw the first rows before the last ones are read.
  $grpc.ResponseStream<$0.ShowSummary> streamShows(
    $0.StreamShowsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$streamShows, $async.Stream.fromIterable([request]),
        options: options);
  }

  $grpc.ResponseFuture<$0.ListEpisodesResponse> listEpisodes(
    $0.ListEpisodesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listEpisodes, request, options: options);
  }

  $grpc.ResponseFuture<$0.EpisodeWithShow> getEpisode(
    $0.GetEpisodeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getEpisode, request, options: options);
  }

  /// The front page, as a person arranged it. One call for the whole screen.
  $grpc.ResponseFuture<$0.Home> getHome(
    $0.GetHomeRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getHome, request, options: options);
  }

  // method descriptors

  static final _$health =
      $grpc.ClientMethod<$0.HealthRequest, $0.HealthResponse>(
          '/catalogue.v1.Catalogue/Health',
          ($0.HealthRequest value) => value.writeToBuffer(),
          $0.HealthResponse.fromBuffer);
  static final _$listShows =
      $grpc.ClientMethod<$0.ListShowsRequest, $0.ListShowsResponse>(
          '/catalogue.v1.Catalogue/ListShows',
          ($0.ListShowsRequest value) => value.writeToBuffer(),
          $0.ListShowsResponse.fromBuffer);
  static final _$getShow =
      $grpc.ClientMethod<$0.GetShowRequest, $0.ShowWithEpisodes>(
          '/catalogue.v1.Catalogue/GetShow',
          ($0.GetShowRequest value) => value.writeToBuffer(),
          $0.ShowWithEpisodes.fromBuffer);
  static final _$streamShows =
      $grpc.ClientMethod<$0.StreamShowsRequest, $0.ShowSummary>(
          '/catalogue.v1.Catalogue/StreamShows',
          ($0.StreamShowsRequest value) => value.writeToBuffer(),
          $0.ShowSummary.fromBuffer);
  static final _$listEpisodes =
      $grpc.ClientMethod<$0.ListEpisodesRequest, $0.ListEpisodesResponse>(
          '/catalogue.v1.Catalogue/ListEpisodes',
          ($0.ListEpisodesRequest value) => value.writeToBuffer(),
          $0.ListEpisodesResponse.fromBuffer);
  static final _$getEpisode =
      $grpc.ClientMethod<$0.GetEpisodeRequest, $0.EpisodeWithShow>(
          '/catalogue.v1.Catalogue/GetEpisode',
          ($0.GetEpisodeRequest value) => value.writeToBuffer(),
          $0.EpisodeWithShow.fromBuffer);
  static final _$getHome = $grpc.ClientMethod<$0.GetHomeRequest, $0.Home>(
      '/catalogue.v1.Catalogue/GetHome',
      ($0.GetHomeRequest value) => value.writeToBuffer(),
      $0.Home.fromBuffer);
}

@$pb.GrpcServiceName('catalogue.v1.Catalogue')
abstract class CatalogueServiceBase extends $grpc.Service {
  $core.String get $name => 'catalogue.v1.Catalogue';

  CatalogueServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.HealthRequest, $0.HealthResponse>(
        'Health',
        health_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HealthRequest.fromBuffer(value),
        ($0.HealthResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListShowsRequest, $0.ListShowsResponse>(
        'ListShows',
        listShows_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListShowsRequest.fromBuffer(value),
        ($0.ListShowsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetShowRequest, $0.ShowWithEpisodes>(
        'GetShow',
        getShow_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetShowRequest.fromBuffer(value),
        ($0.ShowWithEpisodes value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.StreamShowsRequest, $0.ShowSummary>(
        'StreamShows',
        streamShows_Pre,
        false,
        true,
        ($core.List<$core.int> value) =>
            $0.StreamShowsRequest.fromBuffer(value),
        ($0.ShowSummary value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListEpisodesRequest, $0.ListEpisodesResponse>(
            'ListEpisodes',
            listEpisodes_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListEpisodesRequest.fromBuffer(value),
            ($0.ListEpisodesResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetEpisodeRequest, $0.EpisodeWithShow>(
        'GetEpisode',
        getEpisode_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetEpisodeRequest.fromBuffer(value),
        ($0.EpisodeWithShow value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetHomeRequest, $0.Home>(
        'GetHome',
        getHome_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetHomeRequest.fromBuffer(value),
        ($0.Home value) => value.writeToBuffer()));
  }

  $async.Future<$0.HealthResponse> health_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.HealthRequest> $request) async {
    return health($call, await $request);
  }

  $async.Future<$0.HealthResponse> health(
      $grpc.ServiceCall call, $0.HealthRequest request);

  $async.Future<$0.ListShowsResponse> listShows_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListShowsRequest> $request) async {
    return listShows($call, await $request);
  }

  $async.Future<$0.ListShowsResponse> listShows(
      $grpc.ServiceCall call, $0.ListShowsRequest request);

  $async.Future<$0.ShowWithEpisodes> getShow_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetShowRequest> $request) async {
    return getShow($call, await $request);
  }

  $async.Future<$0.ShowWithEpisodes> getShow(
      $grpc.ServiceCall call, $0.GetShowRequest request);

  $async.Stream<$0.ShowSummary> streamShows_Pre($grpc.ServiceCall $call,
      $async.Future<$0.StreamShowsRequest> $request) async* {
    yield* streamShows($call, await $request);
  }

  $async.Stream<$0.ShowSummary> streamShows(
      $grpc.ServiceCall call, $0.StreamShowsRequest request);

  $async.Future<$0.ListEpisodesResponse> listEpisodes_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListEpisodesRequest> $request) async {
    return listEpisodes($call, await $request);
  }

  $async.Future<$0.ListEpisodesResponse> listEpisodes(
      $grpc.ServiceCall call, $0.ListEpisodesRequest request);

  $async.Future<$0.EpisodeWithShow> getEpisode_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetEpisodeRequest> $request) async {
    return getEpisode($call, await $request);
  }

  $async.Future<$0.EpisodeWithShow> getEpisode(
      $grpc.ServiceCall call, $0.GetEpisodeRequest request);

  $async.Future<$0.Home> getHome_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetHomeRequest> $request) async {
    return getHome($call, await $request);
  }

  $async.Future<$0.Home> getHome(
      $grpc.ServiceCall call, $0.GetHomeRequest request);
}

@$pb.GrpcServiceName('catalogue.v1.Watching')
class WatchingClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  WatchingClient(super.channel, {super.options, super.interceptors});

  /// The player checking in. Sent often — keep it small.
  $grpc.ResponseFuture<$0.Progress> reportProgress(
    $0.ReportProgressRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$reportProgress, request, options: options);
  }

  /// Where to seek to when the player opens. NOT_FOUND means "start at zero".
  $grpc.ResponseFuture<$0.Progress> getProgress(
    $0.GetProgressRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getProgress, request, options: options);
  }

  $grpc.ResponseFuture<$0.ForgetProgressResponse> forgetProgress(
    $0.ForgetProgressRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$forgetProgress, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListHistoryResponse> listHistory(
    $0.ListHistoryRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listHistory, request, options: options);
  }

  /// Started, not finished, newest first — the rail on the home screen.
  $grpc.ResponseFuture<$0.ContinueWatchingResponse> continueWatching(
    $0.ContinueWatchingRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$continueWatching, request, options: options);
  }

  // method descriptors

  static final _$reportProgress =
      $grpc.ClientMethod<$0.ReportProgressRequest, $0.Progress>(
          '/catalogue.v1.Watching/ReportProgress',
          ($0.ReportProgressRequest value) => value.writeToBuffer(),
          $0.Progress.fromBuffer);
  static final _$getProgress =
      $grpc.ClientMethod<$0.GetProgressRequest, $0.Progress>(
          '/catalogue.v1.Watching/GetProgress',
          ($0.GetProgressRequest value) => value.writeToBuffer(),
          $0.Progress.fromBuffer);
  static final _$forgetProgress =
      $grpc.ClientMethod<$0.ForgetProgressRequest, $0.ForgetProgressResponse>(
          '/catalogue.v1.Watching/ForgetProgress',
          ($0.ForgetProgressRequest value) => value.writeToBuffer(),
          $0.ForgetProgressResponse.fromBuffer);
  static final _$listHistory =
      $grpc.ClientMethod<$0.ListHistoryRequest, $0.ListHistoryResponse>(
          '/catalogue.v1.Watching/ListHistory',
          ($0.ListHistoryRequest value) => value.writeToBuffer(),
          $0.ListHistoryResponse.fromBuffer);
  static final _$continueWatching = $grpc.ClientMethod<
          $0.ContinueWatchingRequest, $0.ContinueWatchingResponse>(
      '/catalogue.v1.Watching/ContinueWatching',
      ($0.ContinueWatchingRequest value) => value.writeToBuffer(),
      $0.ContinueWatchingResponse.fromBuffer);
}

@$pb.GrpcServiceName('catalogue.v1.Watching')
abstract class WatchingServiceBase extends $grpc.Service {
  $core.String get $name => 'catalogue.v1.Watching';

  WatchingServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ReportProgressRequest, $0.Progress>(
        'ReportProgress',
        reportProgress_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ReportProgressRequest.fromBuffer(value),
        ($0.Progress value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetProgressRequest, $0.Progress>(
        'GetProgress',
        getProgress_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetProgressRequest.fromBuffer(value),
        ($0.Progress value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ForgetProgressRequest,
            $0.ForgetProgressResponse>(
        'ForgetProgress',
        forgetProgress_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ForgetProgressRequest.fromBuffer(value),
        ($0.ForgetProgressResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.ListHistoryRequest, $0.ListHistoryResponse>(
            'ListHistory',
            listHistory_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListHistoryRequest.fromBuffer(value),
            ($0.ListHistoryResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ContinueWatchingRequest,
            $0.ContinueWatchingResponse>(
        'ContinueWatching',
        continueWatching_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.ContinueWatchingRequest.fromBuffer(value),
        ($0.ContinueWatchingResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.Progress> reportProgress_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReportProgressRequest> $request) async {
    return reportProgress($call, await $request);
  }

  $async.Future<$0.Progress> reportProgress(
      $grpc.ServiceCall call, $0.ReportProgressRequest request);

  $async.Future<$0.Progress> getProgress_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetProgressRequest> $request) async {
    return getProgress($call, await $request);
  }

  $async.Future<$0.Progress> getProgress(
      $grpc.ServiceCall call, $0.GetProgressRequest request);

  $async.Future<$0.ForgetProgressResponse> forgetProgress_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ForgetProgressRequest> $request) async {
    return forgetProgress($call, await $request);
  }

  $async.Future<$0.ForgetProgressResponse> forgetProgress(
      $grpc.ServiceCall call, $0.ForgetProgressRequest request);

  $async.Future<$0.ListHistoryResponse> listHistory_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ListHistoryRequest> $request) async {
    return listHistory($call, await $request);
  }

  $async.Future<$0.ListHistoryResponse> listHistory(
      $grpc.ServiceCall call, $0.ListHistoryRequest request);

  $async.Future<$0.ContinueWatchingResponse> continueWatching_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ContinueWatchingRequest> $request) async {
    return continueWatching($call, await $request);
  }

  $async.Future<$0.ContinueWatchingResponse> continueWatching(
      $grpc.ServiceCall call, $0.ContinueWatchingRequest request);
}

@$pb.GrpcServiceName('catalogue.v1.Playlists')
class PlaylistsClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  PlaylistsClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.ListPlaylistsResponse> listPlaylists(
    $0.ListPlaylistsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listPlaylists, request, options: options);
  }

  $grpc.ResponseFuture<$0.PlaylistDetail> getPlaylist(
    $0.GetPlaylistRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getPlaylist, request, options: options);
  }

  $grpc.ResponseFuture<$0.PlaylistDetail> createPlaylist(
    $0.CreatePlaylistRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createPlaylist, request, options: options);
  }

  /// A season, or a whole show, in one call.
  $grpc.ResponseFuture<$0.PlaylistDetail> createFromShow(
    $0.CreateFromShowRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createFromShow, request, options: options);
  }

  $grpc.ResponseFuture<$0.PlaylistDetail> updatePlaylist(
    $0.UpdatePlaylistRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updatePlaylist, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeletePlaylistResponse> deletePlaylist(
    $0.DeletePlaylistRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deletePlaylist, request, options: options);
  }

  $grpc.ResponseFuture<$0.PlaylistDetail> addItem(
    $0.AddItemRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$addItem, request, options: options);
  }

  $grpc.ResponseFuture<$0.PlaylistDetail> removeItem(
    $0.RemoveItemRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$removeItem, request, options: options);
  }

  $grpc.ResponseFuture<$0.PlaylistDetail> reorder(
    $0.ReorderRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$reorder, request, options: options);
  }

  // method descriptors

  static final _$listPlaylists =
      $grpc.ClientMethod<$0.ListPlaylistsRequest, $0.ListPlaylistsResponse>(
          '/catalogue.v1.Playlists/ListPlaylists',
          ($0.ListPlaylistsRequest value) => value.writeToBuffer(),
          $0.ListPlaylistsResponse.fromBuffer);
  static final _$getPlaylist =
      $grpc.ClientMethod<$0.GetPlaylistRequest, $0.PlaylistDetail>(
          '/catalogue.v1.Playlists/GetPlaylist',
          ($0.GetPlaylistRequest value) => value.writeToBuffer(),
          $0.PlaylistDetail.fromBuffer);
  static final _$createPlaylist =
      $grpc.ClientMethod<$0.CreatePlaylistRequest, $0.PlaylistDetail>(
          '/catalogue.v1.Playlists/CreatePlaylist',
          ($0.CreatePlaylistRequest value) => value.writeToBuffer(),
          $0.PlaylistDetail.fromBuffer);
  static final _$createFromShow =
      $grpc.ClientMethod<$0.CreateFromShowRequest, $0.PlaylistDetail>(
          '/catalogue.v1.Playlists/CreateFromShow',
          ($0.CreateFromShowRequest value) => value.writeToBuffer(),
          $0.PlaylistDetail.fromBuffer);
  static final _$updatePlaylist =
      $grpc.ClientMethod<$0.UpdatePlaylistRequest, $0.PlaylistDetail>(
          '/catalogue.v1.Playlists/UpdatePlaylist',
          ($0.UpdatePlaylistRequest value) => value.writeToBuffer(),
          $0.PlaylistDetail.fromBuffer);
  static final _$deletePlaylist =
      $grpc.ClientMethod<$0.DeletePlaylistRequest, $0.DeletePlaylistResponse>(
          '/catalogue.v1.Playlists/DeletePlaylist',
          ($0.DeletePlaylistRequest value) => value.writeToBuffer(),
          $0.DeletePlaylistResponse.fromBuffer);
  static final _$addItem =
      $grpc.ClientMethod<$0.AddItemRequest, $0.PlaylistDetail>(
          '/catalogue.v1.Playlists/AddItem',
          ($0.AddItemRequest value) => value.writeToBuffer(),
          $0.PlaylistDetail.fromBuffer);
  static final _$removeItem =
      $grpc.ClientMethod<$0.RemoveItemRequest, $0.PlaylistDetail>(
          '/catalogue.v1.Playlists/RemoveItem',
          ($0.RemoveItemRequest value) => value.writeToBuffer(),
          $0.PlaylistDetail.fromBuffer);
  static final _$reorder =
      $grpc.ClientMethod<$0.ReorderRequest, $0.PlaylistDetail>(
          '/catalogue.v1.Playlists/Reorder',
          ($0.ReorderRequest value) => value.writeToBuffer(),
          $0.PlaylistDetail.fromBuffer);
}

@$pb.GrpcServiceName('catalogue.v1.Playlists')
abstract class PlaylistsServiceBase extends $grpc.Service {
  $core.String get $name => 'catalogue.v1.Playlists';

  PlaylistsServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.ListPlaylistsRequest, $0.ListPlaylistsResponse>(
            'ListPlaylists',
            listPlaylists_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.ListPlaylistsRequest.fromBuffer(value),
            ($0.ListPlaylistsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetPlaylistRequest, $0.PlaylistDetail>(
        'GetPlaylist',
        getPlaylist_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetPlaylistRequest.fromBuffer(value),
        ($0.PlaylistDetail value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreatePlaylistRequest, $0.PlaylistDetail>(
        'CreatePlaylist',
        createPlaylist_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreatePlaylistRequest.fromBuffer(value),
        ($0.PlaylistDetail value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CreateFromShowRequest, $0.PlaylistDetail>(
        'CreateFromShow',
        createFromShow_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.CreateFromShowRequest.fromBuffer(value),
        ($0.PlaylistDetail value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.UpdatePlaylistRequest, $0.PlaylistDetail>(
        'UpdatePlaylist',
        updatePlaylist_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.UpdatePlaylistRequest.fromBuffer(value),
        ($0.PlaylistDetail value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeletePlaylistRequest,
            $0.DeletePlaylistResponse>(
        'DeletePlaylist',
        deletePlaylist_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.DeletePlaylistRequest.fromBuffer(value),
        ($0.DeletePlaylistResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.AddItemRequest, $0.PlaylistDetail>(
        'AddItem',
        addItem_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.AddItemRequest.fromBuffer(value),
        ($0.PlaylistDetail value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RemoveItemRequest, $0.PlaylistDetail>(
        'RemoveItem',
        removeItem_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RemoveItemRequest.fromBuffer(value),
        ($0.PlaylistDetail value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ReorderRequest, $0.PlaylistDetail>(
        'Reorder',
        reorder_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ReorderRequest.fromBuffer(value),
        ($0.PlaylistDetail value) => value.writeToBuffer()));
  }

  $async.Future<$0.ListPlaylistsResponse> listPlaylists_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.ListPlaylistsRequest> $request) async {
    return listPlaylists($call, await $request);
  }

  $async.Future<$0.ListPlaylistsResponse> listPlaylists(
      $grpc.ServiceCall call, $0.ListPlaylistsRequest request);

  $async.Future<$0.PlaylistDetail> getPlaylist_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetPlaylistRequest> $request) async {
    return getPlaylist($call, await $request);
  }

  $async.Future<$0.PlaylistDetail> getPlaylist(
      $grpc.ServiceCall call, $0.GetPlaylistRequest request);

  $async.Future<$0.PlaylistDetail> createPlaylist_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreatePlaylistRequest> $request) async {
    return createPlaylist($call, await $request);
  }

  $async.Future<$0.PlaylistDetail> createPlaylist(
      $grpc.ServiceCall call, $0.CreatePlaylistRequest request);

  $async.Future<$0.PlaylistDetail> createFromShow_Pre($grpc.ServiceCall $call,
      $async.Future<$0.CreateFromShowRequest> $request) async {
    return createFromShow($call, await $request);
  }

  $async.Future<$0.PlaylistDetail> createFromShow(
      $grpc.ServiceCall call, $0.CreateFromShowRequest request);

  $async.Future<$0.PlaylistDetail> updatePlaylist_Pre($grpc.ServiceCall $call,
      $async.Future<$0.UpdatePlaylistRequest> $request) async {
    return updatePlaylist($call, await $request);
  }

  $async.Future<$0.PlaylistDetail> updatePlaylist(
      $grpc.ServiceCall call, $0.UpdatePlaylistRequest request);

  $async.Future<$0.DeletePlaylistResponse> deletePlaylist_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.DeletePlaylistRequest> $request) async {
    return deletePlaylist($call, await $request);
  }

  $async.Future<$0.DeletePlaylistResponse> deletePlaylist(
      $grpc.ServiceCall call, $0.DeletePlaylistRequest request);

  $async.Future<$0.PlaylistDetail> addItem_Pre($grpc.ServiceCall $call,
      $async.Future<$0.AddItemRequest> $request) async {
    return addItem($call, await $request);
  }

  $async.Future<$0.PlaylistDetail> addItem(
      $grpc.ServiceCall call, $0.AddItemRequest request);

  $async.Future<$0.PlaylistDetail> removeItem_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RemoveItemRequest> $request) async {
    return removeItem($call, await $request);
  }

  $async.Future<$0.PlaylistDetail> removeItem(
      $grpc.ServiceCall call, $0.RemoveItemRequest request);

  $async.Future<$0.PlaylistDetail> reorder_Pre($grpc.ServiceCall $call,
      $async.Future<$0.ReorderRequest> $request) async {
    return reorder($call, await $request);
  }

  $async.Future<$0.PlaylistDetail> reorder(
      $grpc.ServiceCall call, $0.ReorderRequest request);
}
