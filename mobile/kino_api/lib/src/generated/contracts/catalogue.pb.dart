// This is a generated file - do not edit.
//
// Generated from contracts/catalogue.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'catalogue.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'catalogue.pbenum.dart';

class User extends $pb.GeneratedMessage {
  factory User({
    $core.String? publicId,
    $core.String? displayName,
    $core.String? email,
    Role? role,
    $core.bool? isGuest,
    $core.String? createdAt,
    $core.String? lastSeenAt,
  }) {
    final result = create();
    if (publicId != null) result.publicId = publicId;
    if (displayName != null) result.displayName = displayName;
    if (email != null) result.email = email;
    if (role != null) result.role = role;
    if (isGuest != null) result.isGuest = isGuest;
    if (createdAt != null) result.createdAt = createdAt;
    if (lastSeenAt != null) result.lastSeenAt = lastSeenAt;
    return result;
  }

  User._();

  factory User.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory User.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'User',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'publicId')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aOS(3, _omitFieldNames ? '' : 'email')
    ..aE<Role>(4, _omitFieldNames ? '' : 'role', enumValues: Role.values)
    ..aOB(5, _omitFieldNames ? '' : 'isGuest')
    ..aOS(6, _omitFieldNames ? '' : 'createdAt')
    ..aOS(7, _omitFieldNames ? '' : 'lastSeenAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  User copyWith(void Function(User) updates) =>
      super.copyWith((message) => updates(message as User)) as User;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static User create() => User._();
  @$core.override
  User createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static User getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<User>(create);
  static User? _defaultInstance;

  /// The outside world knows a user by this, never by the row id.
  @$pb.TagNumber(1)
  $core.String get publicId => $_getSZ(0);
  @$pb.TagNumber(1)
  set publicId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPublicId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublicId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get email => $_getSZ(2);
  @$pb.TagNumber(3)
  set email($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEmail() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmail() => $_clearField(3);

  @$pb.TagNumber(4)
  Role get role => $_getN(3);
  @$pb.TagNumber(4)
  set role(Role value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasRole() => $_has(3);
  @$pb.TagNumber(4)
  void clearRole() => $_clearField(4);

  /// No email and no password: real, and only reachable from this device.
  @$pb.TagNumber(5)
  $core.bool get isGuest => $_getBF(4);
  @$pb.TagNumber(5)
  set isGuest($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsGuest() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsGuest() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get createdAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set createdAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get lastSeenAt => $_getSZ(6);
  @$pb.TagNumber(7)
  set lastSeenAt($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLastSeenAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastSeenAt() => $_clearField(7);
}

/// A user together with the token that proves it. Handed out when a session is
/// created and never again — keeping it is the client's job.
class Identity extends $pb.GeneratedMessage {
  factory Identity({
    $core.String? token,
    User? user,
  }) {
    final result = create();
    if (token != null) result.token = token;
    if (user != null) result.user = user;
    return result;
  }

  Identity._();

  factory Identity.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Identity.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Identity',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'token')
    ..aOM<User>(2, _omitFieldNames ? '' : 'user', subBuilder: User.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Identity clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Identity copyWith(void Function(Identity) updates) =>
      super.copyWith((message) => updates(message as Identity)) as Identity;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Identity create() => Identity._();
  @$core.override
  Identity createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Identity getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Identity>(create);
  static Identity? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get token => $_getSZ(0);
  @$pb.TagNumber(1)
  set token($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearToken() => $_clearField(1);

  @$pb.TagNumber(2)
  User get user => $_getN(1);
  @$pb.TagNumber(2)
  set user(User value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearUser() => $_clearField(2);
  @$pb.TagNumber(2)
  User ensureUser() => $_ensure(1);
}

class WhoAmIRequest extends $pb.GeneratedMessage {
  factory WhoAmIRequest() => create();

  WhoAmIRequest._();

  factory WhoAmIRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WhoAmIRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WhoAmIRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhoAmIRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WhoAmIRequest copyWith(void Function(WhoAmIRequest) updates) =>
      super.copyWith((message) => updates(message as WhoAmIRequest))
          as WhoAmIRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WhoAmIRequest create() => WhoAmIRequest._();
  @$core.override
  WhoAmIRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WhoAmIRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WhoAmIRequest>(create);
  static WhoAmIRequest? _defaultInstance;
}

class StartGuestRequest extends $pb.GeneratedMessage {
  factory StartGuestRequest() => create();

  StartGuestRequest._();

  factory StartGuestRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StartGuestRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StartGuestRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartGuestRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartGuestRequest copyWith(void Function(StartGuestRequest) updates) =>
      super.copyWith((message) => updates(message as StartGuestRequest))
          as StartGuestRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartGuestRequest create() => StartGuestRequest._();
  @$core.override
  StartGuestRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StartGuestRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StartGuestRequest>(create);
  static StartGuestRequest? _defaultInstance;
}

class ClaimRequest extends $pb.GeneratedMessage {
  factory ClaimRequest({
    $core.String? email,
    $core.String? password,
    $core.String? displayName,
  }) {
    final result = create();
    if (email != null) result.email = email;
    if (password != null) result.password = password;
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  ClaimRequest._();

  factory ClaimRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ClaimRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ClaimRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'email')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClaimRequest copyWith(void Function(ClaimRequest) updates) =>
      super.copyWith((message) => updates(message as ClaimRequest))
          as ClaimRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClaimRequest create() => ClaimRequest._();
  @$core.override
  ClaimRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ClaimRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ClaimRequest>(create);
  static ClaimRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get email => $_getSZ(0);
  @$pb.TagNumber(1)
  set email($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEmail() => $_has(0);
  @$pb.TagNumber(1)
  void clearEmail() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);
}

class LoginRequest extends $pb.GeneratedMessage {
  factory LoginRequest({
    $core.String? email,
    $core.String? password,
  }) {
    final result = create();
    if (email != null) result.email = email;
    if (password != null) result.password = password;
    return result;
  }

  LoginRequest._();

  factory LoginRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LoginRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LoginRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'email')
    ..aOS(2, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LoginRequest copyWith(void Function(LoginRequest) updates) =>
      super.copyWith((message) => updates(message as LoginRequest))
          as LoginRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LoginRequest create() => LoginRequest._();
  @$core.override
  LoginRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LoginRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LoginRequest>(create);
  static LoginRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get email => $_getSZ(0);
  @$pb.TagNumber(1)
  set email($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEmail() => $_has(0);
  @$pb.TagNumber(1)
  void clearEmail() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get password => $_getSZ(1);
  @$pb.TagNumber(2)
  set password($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPassword() => $_has(1);
  @$pb.TagNumber(2)
  void clearPassword() => $_clearField(2);
}

class LogoutRequest extends $pb.GeneratedMessage {
  factory LogoutRequest() => create();

  LogoutRequest._();

  factory LogoutRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LogoutRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogoutRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutRequest copyWith(void Function(LogoutRequest) updates) =>
      super.copyWith((message) => updates(message as LogoutRequest))
          as LogoutRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogoutRequest create() => LogoutRequest._();
  @$core.override
  LogoutRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LogoutRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LogoutRequest>(create);
  static LogoutRequest? _defaultInstance;
}

class LogoutResponse extends $pb.GeneratedMessage {
  factory LogoutResponse() => create();

  LogoutResponse._();

  factory LogoutResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LogoutResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LogoutResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogoutResponse copyWith(void Function(LogoutResponse) updates) =>
      super.copyWith((message) => updates(message as LogoutResponse))
          as LogoutResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogoutResponse create() => LogoutResponse._();
  @$core.override
  LogoutResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LogoutResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LogoutResponse>(create);
  static LogoutResponse? _defaultInstance;
}

class RenameRequest extends $pb.GeneratedMessage {
  factory RenameRequest({
    $core.String? displayName,
  }) {
    final result = create();
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  RenameRequest._();

  factory RenameRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RenameRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RenameRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RenameRequest copyWith(void Function(RenameRequest) updates) =>
      super.copyWith((message) => updates(message as RenameRequest))
          as RenameRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RenameRequest create() => RenameRequest._();
  @$core.override
  RenameRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RenameRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RenameRequest>(create);
  static RenameRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get displayName => $_getSZ(0);
  @$pb.TagNumber(1)
  set displayName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDisplayName() => $_has(0);
  @$pb.TagNumber(1)
  void clearDisplayName() => $_clearField(1);
}

/// Ids are 32-bit throughout this contract. There are seven thousand shows here,
/// not four billion, and 64-bit ids reach a Dart client as `Int64` from `fixnum`
/// rather than as a plain `int` — a conversion at every call site, bought with
/// headroom nothing will ever use.
class Show extends $pb.GeneratedMessage {
  factory Show({
    $core.int? id,
    $core.String? key,
    $core.String? title,
    $core.String? poster,
    $core.String? createdAt,
    $core.bool? isFilm,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (key != null) result.key = key;
    if (title != null) result.title = title;
    if (poster != null) result.poster = poster;
    if (createdAt != null) result.createdAt = createdAt;
    if (isFilm != null) result.isFilm = isFilm;
    return result;
  }

  Show._();

  factory Show.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Show.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Show',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'key')
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'poster')
    ..aOS(5, _omitFieldNames ? '' : 'createdAt')
    ..aOB(6, _omitFieldNames ? '' : 'isFilm')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Show clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Show copyWith(void Function(Show) updates) =>
      super.copyWith((message) => updates(message as Show)) as Show;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Show create() => Show._();
  @$core.override
  Show createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Show getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Show>(create);
  static Show? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get key => $_getSZ(1);
  @$pb.TagNumber(2)
  set key($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get poster => $_getSZ(3);
  @$pb.TagNumber(4)
  set poster($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPoster() => $_has(3);
  @$pb.TagNumber(4)
  void clearPoster() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get createdAt => $_getSZ(4);
  @$pb.TagNumber(5)
  set createdAt($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAt() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAt() => $_clearField(5);

  /// One episode and no more — so a client knows to stop saying "S01E01" about
  /// something that only ever had one.
  @$pb.TagNumber(6)
  $core.bool get isFilm => $_getBF(5);
  @$pb.TagNumber(6)
  set isFilm($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsFilm() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsFilm() => $_clearField(6);
}

/// A show in a browse list: how much of it is here, counted by the server.
class ShowSummary extends $pb.GeneratedMessage {
  factory ShowSummary({
    Show? show,
    $core.int? episodeCount,
    $core.int? playableCount,
  }) {
    final result = create();
    if (show != null) result.show = show;
    if (episodeCount != null) result.episodeCount = episodeCount;
    if (playableCount != null) result.playableCount = playableCount;
    return result;
  }

  ShowSummary._();

  factory ShowSummary.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ShowSummary.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShowSummary',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOM<Show>(1, _omitFieldNames ? '' : 'show', subBuilder: Show.create)
    ..aI(2, _omitFieldNames ? '' : 'episodeCount',
        fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'playableCount',
        fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShowSummary clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShowSummary copyWith(void Function(ShowSummary) updates) =>
      super.copyWith((message) => updates(message as ShowSummary))
          as ShowSummary;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShowSummary create() => ShowSummary._();
  @$core.override
  ShowSummary createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ShowSummary getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShowSummary>(create);
  static ShowSummary? _defaultInstance;

  @$pb.TagNumber(1)
  Show get show => $_getN(0);
  @$pb.TagNumber(1)
  set show(Show value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasShow() => $_has(0);
  @$pb.TagNumber(1)
  void clearShow() => $_clearField(1);
  @$pb.TagNumber(1)
  Show ensureShow() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.int get episodeCount => $_getIZ(1);
  @$pb.TagNumber(2)
  set episodeCount($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEpisodeCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpisodeCount() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get playableCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set playableCount($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlayableCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlayableCount() => $_clearField(3);
}

/// Everything the crawl knew. Kept off `Show` on purpose: that one rides along
/// inside every episode of every listing, and a synopsis per row is a page of
/// prose nobody asked for.
class ShowDetails extends $pb.GeneratedMessage {
  factory ShowDetails({
    Show? show,
    $core.String? originalTitle,
    $core.String? kind,
    $core.int? year,
    $core.int? yearEnd,
    $core.String? audio,
    $core.String? quality,
    $core.String? description,
    $core.String? duration,
    $core.String? ageRating,
    $core.Iterable<$core.String>? genres,
    $core.Iterable<$core.String>? countries,
    $core.Iterable<$core.String>? directors,
    $core.Iterable<$core.String>? starring,
    $core.String? imdbId,
    $core.double? imdbRating,
    $core.int? imdbVotes,
    $core.String? imdbUrl,
  }) {
    final result = create();
    if (show != null) result.show = show;
    if (originalTitle != null) result.originalTitle = originalTitle;
    if (kind != null) result.kind = kind;
    if (year != null) result.year = year;
    if (yearEnd != null) result.yearEnd = yearEnd;
    if (audio != null) result.audio = audio;
    if (quality != null) result.quality = quality;
    if (description != null) result.description = description;
    if (duration != null) result.duration = duration;
    if (ageRating != null) result.ageRating = ageRating;
    if (genres != null) result.genres.addAll(genres);
    if (countries != null) result.countries.addAll(countries);
    if (directors != null) result.directors.addAll(directors);
    if (starring != null) result.starring.addAll(starring);
    if (imdbId != null) result.imdbId = imdbId;
    if (imdbRating != null) result.imdbRating = imdbRating;
    if (imdbVotes != null) result.imdbVotes = imdbVotes;
    if (imdbUrl != null) result.imdbUrl = imdbUrl;
    return result;
  }

  ShowDetails._();

  factory ShowDetails.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ShowDetails.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShowDetails',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOM<Show>(1, _omitFieldNames ? '' : 'show', subBuilder: Show.create)
    ..aOS(2, _omitFieldNames ? '' : 'originalTitle')
    ..aOS(3, _omitFieldNames ? '' : 'kind')
    ..aI(4, _omitFieldNames ? '' : 'year', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'yearEnd', fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'audio')
    ..aOS(7, _omitFieldNames ? '' : 'quality')
    ..aOS(8, _omitFieldNames ? '' : 'description')
    ..aOS(9, _omitFieldNames ? '' : 'duration')
    ..aOS(10, _omitFieldNames ? '' : 'ageRating')
    ..pPS(11, _omitFieldNames ? '' : 'genres')
    ..pPS(12, _omitFieldNames ? '' : 'countries')
    ..pPS(13, _omitFieldNames ? '' : 'directors')
    ..pPS(14, _omitFieldNames ? '' : 'starring')
    ..aOS(15, _omitFieldNames ? '' : 'imdbId')
    ..aD(16, _omitFieldNames ? '' : 'imdbRating')
    ..aI(17, _omitFieldNames ? '' : 'imdbVotes', fieldType: $pb.PbFieldType.OU3)
    ..aOS(18, _omitFieldNames ? '' : 'imdbUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShowDetails clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShowDetails copyWith(void Function(ShowDetails) updates) =>
      super.copyWith((message) => updates(message as ShowDetails))
          as ShowDetails;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShowDetails create() => ShowDetails._();
  @$core.override
  ShowDetails createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ShowDetails getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShowDetails>(create);
  static ShowDetails? _defaultInstance;

  @$pb.TagNumber(1)
  Show get show => $_getN(0);
  @$pb.TagNumber(1)
  set show(Show value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasShow() => $_has(0);
  @$pb.TagNumber(1)
  void clearShow() => $_clearField(1);
  @$pb.TagNumber(1)
  Show ensureShow() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get originalTitle => $_getSZ(1);
  @$pb.TagNumber(2)
  set originalTitle($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOriginalTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearOriginalTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get kind => $_getSZ(2);
  @$pb.TagNumber(3)
  set kind($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKind() => $_has(2);
  @$pb.TagNumber(3)
  void clearKind() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get year => $_getIZ(3);
  @$pb.TagNumber(4)
  set year($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasYear() => $_has(3);
  @$pb.TagNumber(4)
  void clearYear() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get yearEnd => $_getIZ(4);
  @$pb.TagNumber(5)
  set yearEnd($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasYearEnd() => $_has(4);
  @$pb.TagNumber(5)
  void clearYearEnd() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get audio => $_getSZ(5);
  @$pb.TagNumber(6)
  set audio($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAudio() => $_has(5);
  @$pb.TagNumber(6)
  void clearAudio() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get quality => $_getSZ(6);
  @$pb.TagNumber(7)
  set quality($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasQuality() => $_has(6);
  @$pb.TagNumber(7)
  void clearQuality() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.String get description => $_getSZ(7);
  @$pb.TagNumber(8)
  set description($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDescription() => $_has(7);
  @$pb.TagNumber(8)
  void clearDescription() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get duration => $_getSZ(8);
  @$pb.TagNumber(9)
  set duration($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDuration() => $_has(8);
  @$pb.TagNumber(9)
  void clearDuration() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get ageRating => $_getSZ(9);
  @$pb.TagNumber(10)
  set ageRating($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAgeRating() => $_has(9);
  @$pb.TagNumber(10)
  void clearAgeRating() => $_clearField(10);

  @$pb.TagNumber(11)
  $pb.PbList<$core.String> get genres => $_getList(10);

  @$pb.TagNumber(12)
  $pb.PbList<$core.String> get countries => $_getList(11);

  @$pb.TagNumber(13)
  $pb.PbList<$core.String> get directors => $_getList(12);

  @$pb.TagNumber(14)
  $pb.PbList<$core.String> get starring => $_getList(13);

  @$pb.TagNumber(15)
  $core.String get imdbId => $_getSZ(14);
  @$pb.TagNumber(15)
  set imdbId($core.String value) => $_setString(14, value);
  @$pb.TagNumber(15)
  $core.bool hasImdbId() => $_has(14);
  @$pb.TagNumber(15)
  void clearImdbId() => $_clearField(15);

  @$pb.TagNumber(16)
  $core.double get imdbRating => $_getN(15);
  @$pb.TagNumber(16)
  set imdbRating($core.double value) => $_setDouble(15, value);
  @$pb.TagNumber(16)
  $core.bool hasImdbRating() => $_has(15);
  @$pb.TagNumber(16)
  void clearImdbRating() => $_clearField(16);

  @$pb.TagNumber(17)
  $core.int get imdbVotes => $_getIZ(16);
  @$pb.TagNumber(17)
  set imdbVotes($core.int value) => $_setUnsignedInt32(16, value);
  @$pb.TagNumber(17)
  $core.bool hasImdbVotes() => $_has(16);
  @$pb.TagNumber(17)
  void clearImdbVotes() => $_clearField(17);

  @$pb.TagNumber(18)
  $core.String get imdbUrl => $_getSZ(17);
  @$pb.TagNumber(18)
  set imdbUrl($core.String value) => $_setString(17, value);
  @$pb.TagNumber(18)
  $core.bool hasImdbUrl() => $_has(17);
  @$pb.TagNumber(18)
  void clearImdbUrl() => $_clearField(18);
}

/// One way to hear an episode. More than one means somebody dubbed it twice.
class Track extends $pb.GeneratedMessage {
  factory Track({
    $core.int? vodId,
    $core.String? audio,
    $core.String? playlist,
  }) {
    final result = create();
    if (vodId != null) result.vodId = vodId;
    if (audio != null) result.audio = audio;
    if (playlist != null) result.playlist = playlist;
    return result;
  }

  Track._();

  factory Track.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Track.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Track',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'vodId', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'audio')
    ..aOS(3, _omitFieldNames ? '' : 'playlist')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Track clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Track copyWith(void Function(Track) updates) =>
      super.copyWith((message) => updates(message as Track)) as Track;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Track create() => Track._();
  @$core.override
  Track createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Track getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Track>(create);
  static Track? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get vodId => $_getIZ(0);
  @$pb.TagNumber(1)
  set vodId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVodId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVodId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get audio => $_getSZ(1);
  @$pb.TagNumber(2)
  set audio($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAudio() => $_has(1);
  @$pb.TagNumber(2)
  void clearAudio() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get playlist => $_getSZ(2);
  @$pb.TagNumber(3)
  set playlist($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPlaylist() => $_has(2);
  @$pb.TagNumber(3)
  void clearPlaylist() => $_clearField(3);
}

class Episode extends $pb.GeneratedMessage {
  factory Episode({
    $core.int? id,
    $core.int? season,
    $core.int? episode,
    $core.int? episodeEnd,
    $core.String? title,
    $core.String? poster,
    $core.String? sourceUrl,
    $core.int? vodId,
    $core.String? vodUrl,
    $core.String? playlist,
    $core.Iterable<Track>? tracks,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (season != null) result.season = season;
    if (episode != null) result.episode = episode;
    if (episodeEnd != null) result.episodeEnd = episodeEnd;
    if (title != null) result.title = title;
    if (poster != null) result.poster = poster;
    if (sourceUrl != null) result.sourceUrl = sourceUrl;
    if (vodId != null) result.vodId = vodId;
    if (vodUrl != null) result.vodUrl = vodUrl;
    if (playlist != null) result.playlist = playlist;
    if (tracks != null) result.tracks.addAll(tracks);
    return result;
  }

  Episode._();

  factory Episode.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Episode.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Episode',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'season', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'episode', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'episodeEnd', fieldType: $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'title')
    ..aOS(6, _omitFieldNames ? '' : 'poster')
    ..aOS(7, _omitFieldNames ? '' : 'sourceUrl')
    ..aI(8, _omitFieldNames ? '' : 'vodId', fieldType: $pb.PbFieldType.OU3)
    ..aOS(9, _omitFieldNames ? '' : 'vodUrl')
    ..aOS(10, _omitFieldNames ? '' : 'playlist')
    ..pPM<Track>(11, _omitFieldNames ? '' : 'tracks', subBuilder: Track.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Episode clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Episode copyWith(void Function(Episode) updates) =>
      super.copyWith((message) => updates(message as Episode)) as Episode;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Episode create() => Episode._();
  @$core.override
  Episode createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Episode getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Episode>(create);
  static Episode? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get season => $_getIZ(1);
  @$pb.TagNumber(2)
  set season($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeason() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeason() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get episode => $_getIZ(2);
  @$pb.TagNumber(3)
  set episode($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEpisode() => $_has(2);
  @$pb.TagNumber(3)
  void clearEpisode() => $_clearField(3);

  /// Set when two aired as one — "13-14".
  @$pb.TagNumber(4)
  $core.int get episodeEnd => $_getIZ(3);
  @$pb.TagNumber(4)
  set episodeEnd($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEpisodeEnd() => $_has(3);
  @$pb.TagNumber(4)
  void clearEpisodeEnd() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get title => $_getSZ(4);
  @$pb.TagNumber(5)
  set title($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasTitle() => $_has(4);
  @$pb.TagNumber(5)
  void clearTitle() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get poster => $_getSZ(5);
  @$pb.TagNumber(6)
  set poster($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPoster() => $_has(5);
  @$pb.TagNumber(6)
  void clearPoster() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.String get sourceUrl => $_getSZ(6);
  @$pb.TagNumber(7)
  set sourceUrl($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSourceUrl() => $_has(6);
  @$pb.TagNumber(7)
  void clearSourceUrl() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get vodId => $_getIZ(7);
  @$pb.TagNumber(8)
  set vodId($core.int value) => $_setUnsignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasVodId() => $_has(7);
  @$pb.TagNumber(8)
  void clearVodId() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get vodUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set vodUrl($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasVodUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearVodUrl() => $_clearField(9);

  /// `{vod_url}/index.m3u8` — the only URL a player needs. Ours, never the
  /// origin's. Absent until something has been seeded for this episode.
  @$pb.TagNumber(10)
  $core.String get playlist => $_getSZ(9);
  @$pb.TagNumber(10)
  set playlist($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasPlaylist() => $_has(9);
  @$pb.TagNumber(10)
  void clearPlaylist() => $_clearField(10);

  @$pb.TagNumber(11)
  $pb.PbList<Track> get tracks => $_getList(10);
}

class EpisodeWithShow extends $pb.GeneratedMessage {
  factory EpisodeWithShow({
    Episode? episode,
    Show? show,
  }) {
    final result = create();
    if (episode != null) result.episode = episode;
    if (show != null) result.show = show;
    return result;
  }

  EpisodeWithShow._();

  factory EpisodeWithShow.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EpisodeWithShow.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EpisodeWithShow',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOM<Episode>(1, _omitFieldNames ? '' : 'episode',
        subBuilder: Episode.create)
    ..aOM<Show>(2, _omitFieldNames ? '' : 'show', subBuilder: Show.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EpisodeWithShow clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EpisodeWithShow copyWith(void Function(EpisodeWithShow) updates) =>
      super.copyWith((message) => updates(message as EpisodeWithShow))
          as EpisodeWithShow;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EpisodeWithShow create() => EpisodeWithShow._();
  @$core.override
  EpisodeWithShow createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EpisodeWithShow getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EpisodeWithShow>(create);
  static EpisodeWithShow? _defaultInstance;

  @$pb.TagNumber(1)
  Episode get episode => $_getN(0);
  @$pb.TagNumber(1)
  set episode(Episode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasEpisode() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpisode() => $_clearField(1);
  @$pb.TagNumber(1)
  Episode ensureEpisode() => $_ensure(0);

  @$pb.TagNumber(2)
  Show get show => $_getN(1);
  @$pb.TagNumber(2)
  set show(Show value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasShow() => $_has(1);
  @$pb.TagNumber(2)
  void clearShow() => $_clearField(2);
  @$pb.TagNumber(2)
  Show ensureShow() => $_ensure(1);
}

class ShowWithEpisodes extends $pb.GeneratedMessage {
  factory ShowWithEpisodes({
    ShowDetails? show,
    $core.Iterable<Episode>? episodes,
  }) {
    final result = create();
    if (show != null) result.show = show;
    if (episodes != null) result.episodes.addAll(episodes);
    return result;
  }

  ShowWithEpisodes._();

  factory ShowWithEpisodes.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ShowWithEpisodes.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ShowWithEpisodes',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOM<ShowDetails>(1, _omitFieldNames ? '' : 'show',
        subBuilder: ShowDetails.create)
    ..pPM<Episode>(2, _omitFieldNames ? '' : 'episodes',
        subBuilder: Episode.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShowWithEpisodes clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ShowWithEpisodes copyWith(void Function(ShowWithEpisodes) updates) =>
      super.copyWith((message) => updates(message as ShowWithEpisodes))
          as ShowWithEpisodes;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ShowWithEpisodes create() => ShowWithEpisodes._();
  @$core.override
  ShowWithEpisodes createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ShowWithEpisodes getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ShowWithEpisodes>(create);
  static ShowWithEpisodes? _defaultInstance;

  @$pb.TagNumber(1)
  ShowDetails get show => $_getN(0);
  @$pb.TagNumber(1)
  set show(ShowDetails value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasShow() => $_has(0);
  @$pb.TagNumber(1)
  void clearShow() => $_clearField(1);
  @$pb.TagNumber(1)
  ShowDetails ensureShow() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<Episode> get episodes => $_getList(1);
}

/// The envelope every listing uses, so paging looks the same everywhere.
///
/// `PageInfo` rather than `Page`, and `PlaylistVisibility` rather than
/// `Visibility`, because both of those are Flutter's names for something else —
/// a generated Dart client would collide with `material.dart` on the first
/// screen that drew a list.
class PageInfo extends $pb.GeneratedMessage {
  factory PageInfo({
    $core.int? total,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = create();
    if (total != null) result.total = total;
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  PageInfo._();

  factory PageInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PageInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PageInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PageInfo copyWith(void Function(PageInfo) updates) =>
      super.copyWith((message) => updates(message as PageInfo)) as PageInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PageInfo create() => PageInfo._();
  @$core.override
  PageInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PageInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PageInfo>(create);
  static PageInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get total => $_getIZ(0);
  @$pb.TagNumber(1)
  set total($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotal() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotal() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get offset => $_getIZ(2);
  @$pb.TagNumber(3)
  set offset($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => $_clearField(3);
}

class HealthRequest extends $pb.GeneratedMessage {
  factory HealthRequest() => create();

  HealthRequest._();

  factory HealthRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HealthRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HealthRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthRequest copyWith(void Function(HealthRequest) updates) =>
      super.copyWith((message) => updates(message as HealthRequest))
          as HealthRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HealthRequest create() => HealthRequest._();
  @$core.override
  HealthRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HealthRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HealthRequest>(create);
  static HealthRequest? _defaultInstance;
}

class HealthResponse extends $pb.GeneratedMessage {
  factory HealthResponse({
    $core.String? status,
    $core.int? shows,
    $core.int? episodes,
  }) {
    final result = create();
    if (status != null) result.status = status;
    if (shows != null) result.shows = shows;
    if (episodes != null) result.episodes = episodes;
    return result;
  }

  HealthResponse._();

  factory HealthResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HealthResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HealthResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'status')
    ..aI(2, _omitFieldNames ? '' : 'shows', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'episodes', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HealthResponse copyWith(void Function(HealthResponse) updates) =>
      super.copyWith((message) => updates(message as HealthResponse))
          as HealthResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HealthResponse create() => HealthResponse._();
  @$core.override
  HealthResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HealthResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HealthResponse>(create);
  static HealthResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get status => $_getSZ(0);
  @$pb.TagNumber(1)
  set status($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get shows => $_getIZ(1);
  @$pb.TagNumber(2)
  set shows($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasShows() => $_has(1);
  @$pb.TagNumber(2)
  void clearShows() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get episodes => $_getIZ(2);
  @$pb.TagNumber(3)
  set episodes($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEpisodes() => $_has(2);
  @$pb.TagNumber(3)
  void clearEpisodes() => $_clearField(3);
}

class ListShowsRequest extends $pb.GeneratedMessage {
  factory ListShowsRequest({
    $core.String? q,
    $core.bool? series,
    ShowOrder? order,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = create();
    if (q != null) result.q = q;
    if (series != null) result.series = series;
    if (order != null) result.order = order;
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  ListShowsRequest._();

  factory ListShowsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListShowsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListShowsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'q')
    ..aOB(2, _omitFieldNames ? '' : 'series')
    ..aE<ShowOrder>(3, _omitFieldNames ? '' : 'order',
        enumValues: ShowOrder.values)
    ..aI(4, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListShowsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListShowsRequest copyWith(void Function(ListShowsRequest) updates) =>
      super.copyWith((message) => updates(message as ListShowsRequest))
          as ListShowsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListShowsRequest create() => ListShowsRequest._();
  @$core.override
  ListShowsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListShowsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListShowsRequest>(create);
  static ListShowsRequest? _defaultInstance;

  /// Substring of the title.
  @$pb.TagNumber(1)
  $core.String get q => $_getSZ(0);
  @$pb.TagNumber(1)
  set q($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQ() => $_has(0);
  @$pb.TagNumber(1)
  void clearQ() => $_clearField(1);

  /// True: several episodes. False: exactly one, which is how a film looks.
  @$pb.TagNumber(2)
  $core.bool get series => $_getBF(1);
  @$pb.TagNumber(2)
  set series($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeries() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeries() => $_clearField(2);

  @$pb.TagNumber(3)
  ShowOrder get order => $_getN(2);
  @$pb.TagNumber(3)
  set order(ShowOrder value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOrder() => $_has(2);
  @$pb.TagNumber(3)
  void clearOrder() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get offset => $_getIZ(4);
  @$pb.TagNumber(5)
  set offset($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasOffset() => $_has(4);
  @$pb.TagNumber(5)
  void clearOffset() => $_clearField(5);
}

class ListShowsResponse extends $pb.GeneratedMessage {
  factory ListShowsResponse({
    PageInfo? page,
    $core.Iterable<ShowSummary>? items,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (items != null) result.items.addAll(items);
    return result;
  }

  ListShowsResponse._();

  factory ListShowsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListShowsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListShowsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOM<PageInfo>(1, _omitFieldNames ? '' : 'page',
        subBuilder: PageInfo.create)
    ..pPM<ShowSummary>(2, _omitFieldNames ? '' : 'items',
        subBuilder: ShowSummary.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListShowsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListShowsResponse copyWith(void Function(ListShowsResponse) updates) =>
      super.copyWith((message) => updates(message as ListShowsResponse))
          as ListShowsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListShowsResponse create() => ListShowsResponse._();
  @$core.override
  ListShowsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListShowsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListShowsResponse>(create);
  static ListShowsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  PageInfo get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(PageInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  PageInfo ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<ShowSummary> get items => $_getList(1);
}

class StreamShowsRequest extends $pb.GeneratedMessage {
  factory StreamShowsRequest({
    $core.String? q,
    $core.bool? series,
    ShowOrder? order,
    $core.int? limit,
  }) {
    final result = create();
    if (q != null) result.q = q;
    if (series != null) result.series = series;
    if (order != null) result.order = order;
    if (limit != null) result.limit = limit;
    return result;
  }

  StreamShowsRequest._();

  factory StreamShowsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory StreamShowsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'StreamShowsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'q')
    ..aOB(2, _omitFieldNames ? '' : 'series')
    ..aE<ShowOrder>(3, _omitFieldNames ? '' : 'order',
        enumValues: ShowOrder.values)
    ..aI(4, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamShowsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StreamShowsRequest copyWith(void Function(StreamShowsRequest) updates) =>
      super.copyWith((message) => updates(message as StreamShowsRequest))
          as StreamShowsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StreamShowsRequest create() => StreamShowsRequest._();
  @$core.override
  StreamShowsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static StreamShowsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<StreamShowsRequest>(create);
  static StreamShowsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get q => $_getSZ(0);
  @$pb.TagNumber(1)
  set q($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasQ() => $_has(0);
  @$pb.TagNumber(1)
  void clearQ() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get series => $_getBF(1);
  @$pb.TagNumber(2)
  set series($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeries() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeries() => $_clearField(2);

  @$pb.TagNumber(3)
  ShowOrder get order => $_getN(2);
  @$pb.TagNumber(3)
  set order(ShowOrder value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasOrder() => $_has(2);
  @$pb.TagNumber(3)
  void clearOrder() => $_clearField(3);

  /// Stop after this many. Zero means the whole catalogue.
  @$pb.TagNumber(4)
  $core.int get limit => $_getIZ(3);
  @$pb.TagNumber(4)
  set limit($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLimit() => $_has(3);
  @$pb.TagNumber(4)
  void clearLimit() => $_clearField(4);
}

class GetShowRequest extends $pb.GeneratedMessage {
  factory GetShowRequest({
    $core.String? key,
  }) {
    final result = create();
    if (key != null) result.key = key;
    return result;
  }

  GetShowRequest._();

  factory GetShowRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetShowRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetShowRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'key')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetShowRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetShowRequest copyWith(void Function(GetShowRequest) updates) =>
      super.copyWith((message) => updates(message as GetShowRequest))
          as GetShowRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetShowRequest create() => GetShowRequest._();
  @$core.override
  GetShowRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetShowRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetShowRequest>(create);
  static GetShowRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get key => $_getSZ(0);
  @$pb.TagNumber(1)
  set key($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearKey() => $_clearField(1);
}

class ListEpisodesRequest extends $pb.GeneratedMessage {
  factory ListEpisodesRequest({
    $core.String? show,
    $core.int? season,
    $core.String? q,
    $core.bool? playable,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = create();
    if (show != null) result.show = show;
    if (season != null) result.season = season;
    if (q != null) result.q = q;
    if (playable != null) result.playable = playable;
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  ListEpisodesRequest._();

  factory ListEpisodesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEpisodesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEpisodesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'show')
    ..aI(2, _omitFieldNames ? '' : 'season', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'q')
    ..aOB(4, _omitFieldNames ? '' : 'playable')
    ..aI(5, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..aI(6, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEpisodesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEpisodesRequest copyWith(void Function(ListEpisodesRequest) updates) =>
      super.copyWith((message) => updates(message as ListEpisodesRequest))
          as ListEpisodesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEpisodesRequest create() => ListEpisodesRequest._();
  @$core.override
  ListEpisodesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEpisodesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEpisodesRequest>(create);
  static ListEpisodesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get show => $_getSZ(0);
  @$pb.TagNumber(1)
  set show($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShow() => $_has(0);
  @$pb.TagNumber(1)
  void clearShow() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get season => $_getIZ(1);
  @$pb.TagNumber(2)
  set season($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeason() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeason() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get q => $_getSZ(2);
  @$pb.TagNumber(3)
  set q($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasQ() => $_has(2);
  @$pb.TagNumber(3)
  void clearQ() => $_clearField(3);

  /// Only the ones with a VOD behind them.
  @$pb.TagNumber(4)
  $core.bool get playable => $_getBF(3);
  @$pb.TagNumber(4)
  set playable($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPlayable() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlayable() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get limit => $_getIZ(4);
  @$pb.TagNumber(5)
  set limit($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearLimit() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get offset => $_getIZ(5);
  @$pb.TagNumber(6)
  set offset($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasOffset() => $_has(5);
  @$pb.TagNumber(6)
  void clearOffset() => $_clearField(6);
}

class ListEpisodesResponse extends $pb.GeneratedMessage {
  factory ListEpisodesResponse({
    PageInfo? page,
    $core.Iterable<EpisodeWithShow>? items,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (items != null) result.items.addAll(items);
    return result;
  }

  ListEpisodesResponse._();

  factory ListEpisodesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListEpisodesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListEpisodesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOM<PageInfo>(1, _omitFieldNames ? '' : 'page',
        subBuilder: PageInfo.create)
    ..pPM<EpisodeWithShow>(2, _omitFieldNames ? '' : 'items',
        subBuilder: EpisodeWithShow.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEpisodesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListEpisodesResponse copyWith(void Function(ListEpisodesResponse) updates) =>
      super.copyWith((message) => updates(message as ListEpisodesResponse))
          as ListEpisodesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListEpisodesResponse create() => ListEpisodesResponse._();
  @$core.override
  ListEpisodesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListEpisodesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListEpisodesResponse>(create);
  static ListEpisodesResponse? _defaultInstance;

  @$pb.TagNumber(1)
  PageInfo get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(PageInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  PageInfo ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<EpisodeWithShow> get items => $_getList(1);
}

class GetEpisodeRequest extends $pb.GeneratedMessage {
  factory GetEpisodeRequest({
    $core.int? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetEpisodeRequest._();

  factory GetEpisodeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetEpisodeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetEpisodeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEpisodeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetEpisodeRequest copyWith(void Function(GetEpisodeRequest) updates) =>
      super.copyWith((message) => updates(message as GetEpisodeRequest))
          as GetEpisodeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetEpisodeRequest create() => GetEpisodeRequest._();
  @$core.override
  GetEpisodeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetEpisodeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetEpisodeRequest>(create);
  static GetEpisodeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class HomeSection extends $pb.GeneratedMessage {
  factory HomeSection({
    $core.int? id,
    SectionKind? kind,
    $core.String? title,
    $core.String? kicker,
    $core.String? link,
    Show? show,
    Playlist? playlist,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? artwork,
    $core.Iterable<EpisodeWithShow>? items,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (kind != null) result.kind = kind;
    if (title != null) result.title = title;
    if (kicker != null) result.kicker = kicker;
    if (link != null) result.link = link;
    if (show != null) result.show = show;
    if (playlist != null) result.playlist = playlist;
    if (artwork != null) result.artwork.addEntries(artwork);
    if (items != null) result.items.addAll(items);
    return result;
  }

  HomeSection._();

  factory HomeSection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HomeSection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HomeSection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aE<SectionKind>(2, _omitFieldNames ? '' : 'kind',
        enumValues: SectionKind.values)
    ..aOS(3, _omitFieldNames ? '' : 'title')
    ..aOS(4, _omitFieldNames ? '' : 'kicker')
    ..aOS(5, _omitFieldNames ? '' : 'link')
    ..aOM<Show>(6, _omitFieldNames ? '' : 'show', subBuilder: Show.create)
    ..aOM<Playlist>(7, _omitFieldNames ? '' : 'playlist',
        subBuilder: Playlist.create)
    ..m<$core.String, $core.String>(8, _omitFieldNames ? '' : 'artwork',
        entryClassName: 'HomeSection.ArtworkEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('catalogue.v1'))
    ..pPM<EpisodeWithShow>(9, _omitFieldNames ? '' : 'items',
        subBuilder: EpisodeWithShow.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HomeSection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HomeSection copyWith(void Function(HomeSection) updates) =>
      super.copyWith((message) => updates(message as HomeSection))
          as HomeSection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HomeSection create() => HomeSection._();
  @$core.override
  HomeSection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HomeSection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HomeSection>(create);
  static HomeSection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  SectionKind get kind => $_getN(1);
  @$pb.TagNumber(2)
  set kind(SectionKind value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearKind() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get title => $_getSZ(2);
  @$pb.TagNumber(3)
  set title($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTitle() => $_has(2);
  @$pb.TagNumber(3)
  void clearTitle() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get kicker => $_getSZ(3);
  @$pb.TagNumber(4)
  set kicker($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKicker() => $_has(3);
  @$pb.TagNumber(4)
  void clearKicker() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get link => $_getSZ(4);
  @$pb.TagNumber(5)
  set link($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLink() => $_has(4);
  @$pb.TagNumber(5)
  void clearLink() => $_clearField(5);

  @$pb.TagNumber(6)
  Show get show => $_getN(5);
  @$pb.TagNumber(6)
  set show(Show value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasShow() => $_has(5);
  @$pb.TagNumber(6)
  void clearShow() => $_clearField(6);
  @$pb.TagNumber(6)
  Show ensureShow() => $_ensure(5);

  @$pb.TagNumber(7)
  Playlist get playlist => $_getN(6);
  @$pb.TagNumber(7)
  set playlist(Playlist value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPlaylist() => $_has(6);
  @$pb.TagNumber(7)
  void clearPlaylist() => $_clearField(7);
  @$pb.TagNumber(7)
  Playlist ensurePlaylist() => $_ensure(6);

  /// placement (`hero`, `tile`, `poster`, `square`, `logo`) → URL, already
  /// merged: the section's own picture wins over the one belonging to whatever
  /// it points at.
  @$pb.TagNumber(8)
  $pb.PbMap<$core.String, $core.String> get artwork => $_getMap(7);

  @$pb.TagNumber(9)
  $pb.PbList<EpisodeWithShow> get items => $_getList(8);
}

class Home extends $pb.GeneratedMessage {
  factory Home({
    $core.Iterable<HomeSection>? sections,
  }) {
    final result = create();
    if (sections != null) result.sections.addAll(sections);
    return result;
  }

  Home._();

  factory Home.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Home.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Home',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..pPM<HomeSection>(1, _omitFieldNames ? '' : 'sections',
        subBuilder: HomeSection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Home clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Home copyWith(void Function(Home) updates) =>
      super.copyWith((message) => updates(message as Home)) as Home;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Home create() => Home._();
  @$core.override
  Home createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Home getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Home>(create);
  static Home? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<HomeSection> get sections => $_getList(0);
}

class GetHomeRequest extends $pb.GeneratedMessage {
  factory GetHomeRequest({
    $core.bool? preview,
  }) {
    final result = create();
    if (preview != null) result.preview = preview;
    return result;
  }

  GetHomeRequest._();

  factory GetHomeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetHomeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetHomeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'preview')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHomeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetHomeRequest copyWith(void Function(GetHomeRequest) updates) =>
      super.copyWith((message) => updates(message as GetHomeRequest))
          as GetHomeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetHomeRequest create() => GetHomeRequest._();
  @$core.override
  GetHomeRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetHomeRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetHomeRequest>(create);
  static GetHomeRequest? _defaultInstance;

  /// Admins only: include the sections that aren't published yet.
  @$pb.TagNumber(1)
  $core.bool get preview => $_getBF(0);
  @$pb.TagNumber(1)
  set preview($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPreview() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreview() => $_clearField(1);
}

class Progress extends $pb.GeneratedMessage {
  factory Progress({
    $core.int? episodeId,
    $core.double? positionSeconds,
    $core.double? durationSeconds,
    $core.bool? completed,
    $core.double? ratio,
    $core.String? lastWatchedAt,
  }) {
    final result = create();
    if (episodeId != null) result.episodeId = episodeId;
    if (positionSeconds != null) result.positionSeconds = positionSeconds;
    if (durationSeconds != null) result.durationSeconds = durationSeconds;
    if (completed != null) result.completed = completed;
    if (ratio != null) result.ratio = ratio;
    if (lastWatchedAt != null) result.lastWatchedAt = lastWatchedAt;
    return result;
  }

  Progress._();

  factory Progress.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Progress.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Progress',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'episodeId', fieldType: $pb.PbFieldType.OU3)
    ..aD(2, _omitFieldNames ? '' : 'positionSeconds')
    ..aD(3, _omitFieldNames ? '' : 'durationSeconds')
    ..aOB(4, _omitFieldNames ? '' : 'completed')
    ..aD(5, _omitFieldNames ? '' : 'ratio')
    ..aOS(6, _omitFieldNames ? '' : 'lastWatchedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Progress clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Progress copyWith(void Function(Progress) updates) =>
      super.copyWith((message) => updates(message as Progress)) as Progress;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Progress create() => Progress._();
  @$core.override
  Progress createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Progress getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Progress>(create);
  static Progress? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get episodeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set episodeId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpisodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpisodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get positionSeconds => $_getN(1);
  @$pb.TagNumber(2)
  set positionSeconds($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPositionSeconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearPositionSeconds() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get durationSeconds => $_getN(2);
  @$pb.TagNumber(3)
  set durationSeconds($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDurationSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearDurationSeconds() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get completed => $_getBF(3);
  @$pb.TagNumber(4)
  set completed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCompleted() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompleted() => $_clearField(4);

  /// How far in, 0–1. Absent until a duration is known.
  @$pb.TagNumber(5)
  $core.double get ratio => $_getN(4);
  @$pb.TagNumber(5)
  set ratio($core.double value) => $_setDouble(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRatio() => $_has(4);
  @$pb.TagNumber(5)
  void clearRatio() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get lastWatchedAt => $_getSZ(5);
  @$pb.TagNumber(6)
  set lastWatchedAt($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasLastWatchedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastWatchedAt() => $_clearField(6);
}

class HistoryEntry extends $pb.GeneratedMessage {
  factory HistoryEntry({
    Progress? progress,
    EpisodeWithShow? episode,
  }) {
    final result = create();
    if (progress != null) result.progress = progress;
    if (episode != null) result.episode = episode;
    return result;
  }

  HistoryEntry._();

  factory HistoryEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory HistoryEntry.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'HistoryEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOM<Progress>(1, _omitFieldNames ? '' : 'progress',
        subBuilder: Progress.create)
    ..aOM<EpisodeWithShow>(2, _omitFieldNames ? '' : 'episode',
        subBuilder: EpisodeWithShow.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HistoryEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HistoryEntry copyWith(void Function(HistoryEntry) updates) =>
      super.copyWith((message) => updates(message as HistoryEntry))
          as HistoryEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HistoryEntry create() => HistoryEntry._();
  @$core.override
  HistoryEntry createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static HistoryEntry getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<HistoryEntry>(create);
  static HistoryEntry? _defaultInstance;

  @$pb.TagNumber(1)
  Progress get progress => $_getN(0);
  @$pb.TagNumber(1)
  set progress(Progress value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasProgress() => $_has(0);
  @$pb.TagNumber(1)
  void clearProgress() => $_clearField(1);
  @$pb.TagNumber(1)
  Progress ensureProgress() => $_ensure(0);

  @$pb.TagNumber(2)
  EpisodeWithShow get episode => $_getN(1);
  @$pb.TagNumber(2)
  set episode(EpisodeWithShow value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasEpisode() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpisode() => $_clearField(2);
  @$pb.TagNumber(2)
  EpisodeWithShow ensureEpisode() => $_ensure(1);
}

class ReportProgressRequest extends $pb.GeneratedMessage {
  factory ReportProgressRequest({
    $core.int? episodeId,
    $core.double? positionSeconds,
    $core.double? durationSeconds,
    $core.bool? completed,
  }) {
    final result = create();
    if (episodeId != null) result.episodeId = episodeId;
    if (positionSeconds != null) result.positionSeconds = positionSeconds;
    if (durationSeconds != null) result.durationSeconds = durationSeconds;
    if (completed != null) result.completed = completed;
    return result;
  }

  ReportProgressRequest._();

  factory ReportProgressRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReportProgressRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReportProgressRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'episodeId', fieldType: $pb.PbFieldType.OU3)
    ..aD(2, _omitFieldNames ? '' : 'positionSeconds')
    ..aD(3, _omitFieldNames ? '' : 'durationSeconds')
    ..aOB(4, _omitFieldNames ? '' : 'completed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportProgressRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReportProgressRequest copyWith(
          void Function(ReportProgressRequest) updates) =>
      super.copyWith((message) => updates(message as ReportProgressRequest))
          as ReportProgressRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReportProgressRequest create() => ReportProgressRequest._();
  @$core.override
  ReportProgressRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReportProgressRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReportProgressRequest>(create);
  static ReportProgressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get episodeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set episodeId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpisodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpisodeId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get positionSeconds => $_getN(1);
  @$pb.TagNumber(2)
  set positionSeconds($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPositionSeconds() => $_has(1);
  @$pb.TagNumber(2)
  void clearPositionSeconds() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.double get durationSeconds => $_getN(2);
  @$pb.TagNumber(3)
  set durationSeconds($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDurationSeconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearDurationSeconds() => $_clearField(3);

  /// Leave it out and the 95% rule decides. Send it when the player *knows*,
  /// because "the video element fired `ended`" beats any threshold.
  @$pb.TagNumber(4)
  $core.bool get completed => $_getBF(3);
  @$pb.TagNumber(4)
  set completed($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCompleted() => $_has(3);
  @$pb.TagNumber(4)
  void clearCompleted() => $_clearField(4);
}

class GetProgressRequest extends $pb.GeneratedMessage {
  factory GetProgressRequest({
    $core.int? episodeId,
  }) {
    final result = create();
    if (episodeId != null) result.episodeId = episodeId;
    return result;
  }

  GetProgressRequest._();

  factory GetProgressRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetProgressRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetProgressRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'episodeId', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetProgressRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetProgressRequest copyWith(void Function(GetProgressRequest) updates) =>
      super.copyWith((message) => updates(message as GetProgressRequest))
          as GetProgressRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetProgressRequest create() => GetProgressRequest._();
  @$core.override
  GetProgressRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetProgressRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetProgressRequest>(create);
  static GetProgressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get episodeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set episodeId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpisodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpisodeId() => $_clearField(1);
}

class ForgetProgressRequest extends $pb.GeneratedMessage {
  factory ForgetProgressRequest({
    $core.int? episodeId,
  }) {
    final result = create();
    if (episodeId != null) result.episodeId = episodeId;
    return result;
  }

  ForgetProgressRequest._();

  factory ForgetProgressRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ForgetProgressRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ForgetProgressRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'episodeId', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForgetProgressRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForgetProgressRequest copyWith(
          void Function(ForgetProgressRequest) updates) =>
      super.copyWith((message) => updates(message as ForgetProgressRequest))
          as ForgetProgressRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ForgetProgressRequest create() => ForgetProgressRequest._();
  @$core.override
  ForgetProgressRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ForgetProgressRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ForgetProgressRequest>(create);
  static ForgetProgressRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get episodeId => $_getIZ(0);
  @$pb.TagNumber(1)
  set episodeId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEpisodeId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEpisodeId() => $_clearField(1);
}

class ForgetProgressResponse extends $pb.GeneratedMessage {
  factory ForgetProgressResponse() => create();

  ForgetProgressResponse._();

  factory ForgetProgressResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ForgetProgressResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ForgetProgressResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForgetProgressResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ForgetProgressResponse copyWith(
          void Function(ForgetProgressResponse) updates) =>
      super.copyWith((message) => updates(message as ForgetProgressResponse))
          as ForgetProgressResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ForgetProgressResponse create() => ForgetProgressResponse._();
  @$core.override
  ForgetProgressResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ForgetProgressResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ForgetProgressResponse>(create);
  static ForgetProgressResponse? _defaultInstance;
}

class ListHistoryRequest extends $pb.GeneratedMessage {
  factory ListHistoryRequest({
    $core.bool? completed,
    $core.int? limit,
    $core.int? offset,
  }) {
    final result = create();
    if (completed != null) result.completed = completed;
    if (limit != null) result.limit = limit;
    if (offset != null) result.offset = offset;
    return result;
  }

  ListHistoryRequest._();

  factory ListHistoryRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListHistoryRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListHistoryRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'completed')
    ..aI(2, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'offset', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHistoryRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHistoryRequest copyWith(void Function(ListHistoryRequest) updates) =>
      super.copyWith((message) => updates(message as ListHistoryRequest))
          as ListHistoryRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListHistoryRequest create() => ListHistoryRequest._();
  @$core.override
  ListHistoryRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListHistoryRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListHistoryRequest>(create);
  static ListHistoryRequest? _defaultInstance;

  /// Only finished, or only not.
  @$pb.TagNumber(1)
  $core.bool get completed => $_getBF(0);
  @$pb.TagNumber(1)
  set completed($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCompleted() => $_has(0);
  @$pb.TagNumber(1)
  void clearCompleted() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get limit => $_getIZ(1);
  @$pb.TagNumber(2)
  set limit($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearLimit() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get offset => $_getIZ(2);
  @$pb.TagNumber(3)
  set offset($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOffset() => $_has(2);
  @$pb.TagNumber(3)
  void clearOffset() => $_clearField(3);
}

class ListHistoryResponse extends $pb.GeneratedMessage {
  factory ListHistoryResponse({
    PageInfo? page,
    $core.Iterable<HistoryEntry>? items,
  }) {
    final result = create();
    if (page != null) result.page = page;
    if (items != null) result.items.addAll(items);
    return result;
  }

  ListHistoryResponse._();

  factory ListHistoryResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListHistoryResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListHistoryResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOM<PageInfo>(1, _omitFieldNames ? '' : 'page',
        subBuilder: PageInfo.create)
    ..pPM<HistoryEntry>(2, _omitFieldNames ? '' : 'items',
        subBuilder: HistoryEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHistoryResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListHistoryResponse copyWith(void Function(ListHistoryResponse) updates) =>
      super.copyWith((message) => updates(message as ListHistoryResponse))
          as ListHistoryResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListHistoryResponse create() => ListHistoryResponse._();
  @$core.override
  ListHistoryResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListHistoryResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListHistoryResponse>(create);
  static ListHistoryResponse? _defaultInstance;

  @$pb.TagNumber(1)
  PageInfo get page => $_getN(0);
  @$pb.TagNumber(1)
  set page(PageInfo value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPage() => $_has(0);
  @$pb.TagNumber(1)
  void clearPage() => $_clearField(1);
  @$pb.TagNumber(1)
  PageInfo ensurePage() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<HistoryEntry> get items => $_getList(1);
}

class ContinueWatchingRequest extends $pb.GeneratedMessage {
  factory ContinueWatchingRequest({
    $core.int? limit,
  }) {
    final result = create();
    if (limit != null) result.limit = limit;
    return result;
  }

  ContinueWatchingRequest._();

  factory ContinueWatchingRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContinueWatchingRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContinueWatchingRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContinueWatchingRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContinueWatchingRequest copyWith(
          void Function(ContinueWatchingRequest) updates) =>
      super.copyWith((message) => updates(message as ContinueWatchingRequest))
          as ContinueWatchingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContinueWatchingRequest create() => ContinueWatchingRequest._();
  @$core.override
  ContinueWatchingRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContinueWatchingRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContinueWatchingRequest>(create);
  static ContinueWatchingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get limit => $_getIZ(0);
  @$pb.TagNumber(1)
  set limit($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLimit() => $_has(0);
  @$pb.TagNumber(1)
  void clearLimit() => $_clearField(1);
}

class ContinueWatchingResponse extends $pb.GeneratedMessage {
  factory ContinueWatchingResponse({
    $core.Iterable<HistoryEntry>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ContinueWatchingResponse._();

  factory ContinueWatchingResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ContinueWatchingResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ContinueWatchingResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..pPM<HistoryEntry>(1, _omitFieldNames ? '' : 'items',
        subBuilder: HistoryEntry.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContinueWatchingResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ContinueWatchingResponse copyWith(
          void Function(ContinueWatchingResponse) updates) =>
      super.copyWith((message) => updates(message as ContinueWatchingResponse))
          as ContinueWatchingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ContinueWatchingResponse create() => ContinueWatchingResponse._();
  @$core.override
  ContinueWatchingResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ContinueWatchingResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ContinueWatchingResponse>(create);
  static ContinueWatchingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<HistoryEntry> get items => $_getList(0);
}

class Playlist extends $pb.GeneratedMessage {
  factory Playlist({
    $core.int? id,
    $core.String? name,
    PlaylistVisibility? visibility,
    $core.String? createdAt,
    $core.int? count,
    $core.bool? mine,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (visibility != null) result.visibility = visibility;
    if (createdAt != null) result.createdAt = createdAt;
    if (count != null) result.count = count;
    if (mine != null) result.mine = mine;
    return result;
  }

  Playlist._();

  factory Playlist.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Playlist.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Playlist',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<PlaylistVisibility>(3, _omitFieldNames ? '' : 'visibility',
        enumValues: PlaylistVisibility.values)
    ..aOS(4, _omitFieldNames ? '' : 'createdAt')
    ..aI(5, _omitFieldNames ? '' : 'count', fieldType: $pb.PbFieldType.OU3)
    ..aOB(6, _omitFieldNames ? '' : 'mine')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Playlist clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Playlist copyWith(void Function(Playlist) updates) =>
      super.copyWith((message) => updates(message as Playlist)) as Playlist;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Playlist create() => Playlist._();
  @$core.override
  Playlist createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Playlist getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Playlist>(create);
  static Playlist? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  PlaylistVisibility get visibility => $_getN(2);
  @$pb.TagNumber(3)
  set visibility(PlaylistVisibility value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearVisibility() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get createdAt => $_getSZ(3);
  @$pb.TagNumber(4)
  set createdAt($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get count => $_getIZ(4);
  @$pb.TagNumber(5)
  set count($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCount() => $_has(4);
  @$pb.TagNumber(5)
  void clearCount() => $_clearField(5);

  /// Whether *this* caller may change it. Not a permission the client enforces
  /// — the service does that — but the answer it needs to decide whether to draw
  /// the controls at all.
  @$pb.TagNumber(6)
  $core.bool get mine => $_getBF(5);
  @$pb.TagNumber(6)
  set mine($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasMine() => $_has(5);
  @$pb.TagNumber(6)
  void clearMine() => $_clearField(6);
}

class PlaylistItem extends $pb.GeneratedMessage {
  factory PlaylistItem({
    $core.int? id,
    $core.int? position,
    EpisodeWithShow? episode,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (position != null) result.position = position;
    if (episode != null) result.episode = episode;
    return result;
  }

  PlaylistItem._();

  factory PlaylistItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlaylistItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistItem',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'position', fieldType: $pb.PbFieldType.OU3)
    ..aOM<EpisodeWithShow>(3, _omitFieldNames ? '' : 'episode',
        subBuilder: EpisodeWithShow.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaylistItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaylistItem copyWith(void Function(PlaylistItem) updates) =>
      super.copyWith((message) => updates(message as PlaylistItem))
          as PlaylistItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlaylistItem create() => PlaylistItem._();
  @$core.override
  PlaylistItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlaylistItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlaylistItem>(create);
  static PlaylistItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Dense and 0-based; the server rewrites it on every mutation.
  @$pb.TagNumber(2)
  $core.int get position => $_getIZ(1);
  @$pb.TagNumber(2)
  set position($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPosition() => $_has(1);
  @$pb.TagNumber(2)
  void clearPosition() => $_clearField(2);

  @$pb.TagNumber(3)
  EpisodeWithShow get episode => $_getN(2);
  @$pb.TagNumber(3)
  set episode(EpisodeWithShow value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEpisode() => $_has(2);
  @$pb.TagNumber(3)
  void clearEpisode() => $_clearField(3);
  @$pb.TagNumber(3)
  EpisodeWithShow ensureEpisode() => $_ensure(2);
}

class PlaylistDetail extends $pb.GeneratedMessage {
  factory PlaylistDetail({
    Playlist? playlist,
    $core.Iterable<PlaylistItem>? items,
  }) {
    final result = create();
    if (playlist != null) result.playlist = playlist;
    if (items != null) result.items.addAll(items);
    return result;
  }

  PlaylistDetail._();

  factory PlaylistDetail.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PlaylistDetail.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PlaylistDetail',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOM<Playlist>(1, _omitFieldNames ? '' : 'playlist',
        subBuilder: Playlist.create)
    ..pPM<PlaylistItem>(2, _omitFieldNames ? '' : 'items',
        subBuilder: PlaylistItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaylistDetail clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PlaylistDetail copyWith(void Function(PlaylistDetail) updates) =>
      super.copyWith((message) => updates(message as PlaylistDetail))
          as PlaylistDetail;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlaylistDetail create() => PlaylistDetail._();
  @$core.override
  PlaylistDetail createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static PlaylistDetail getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PlaylistDetail>(create);
  static PlaylistDetail? _defaultInstance;

  @$pb.TagNumber(1)
  Playlist get playlist => $_getN(0);
  @$pb.TagNumber(1)
  set playlist(Playlist value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPlaylist() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlaylist() => $_clearField(1);
  @$pb.TagNumber(1)
  Playlist ensurePlaylist() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<PlaylistItem> get items => $_getList(1);
}

class ListPlaylistsRequest extends $pb.GeneratedMessage {
  factory ListPlaylistsRequest({
    PlaylistScope? scope,
  }) {
    final result = create();
    if (scope != null) result.scope = scope;
    return result;
  }

  ListPlaylistsRequest._();

  factory ListPlaylistsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListPlaylistsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPlaylistsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aE<PlaylistScope>(1, _omitFieldNames ? '' : 'scope',
        enumValues: PlaylistScope.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPlaylistsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPlaylistsRequest copyWith(void Function(ListPlaylistsRequest) updates) =>
      super.copyWith((message) => updates(message as ListPlaylistsRequest))
          as ListPlaylistsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListPlaylistsRequest create() => ListPlaylistsRequest._();
  @$core.override
  ListPlaylistsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListPlaylistsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListPlaylistsRequest>(create);
  static ListPlaylistsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  PlaylistScope get scope => $_getN(0);
  @$pb.TagNumber(1)
  set scope(PlaylistScope value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasScope() => $_has(0);
  @$pb.TagNumber(1)
  void clearScope() => $_clearField(1);
}

class ListPlaylistsResponse extends $pb.GeneratedMessage {
  factory ListPlaylistsResponse({
    $core.Iterable<Playlist>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  ListPlaylistsResponse._();

  factory ListPlaylistsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ListPlaylistsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ListPlaylistsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..pPM<Playlist>(1, _omitFieldNames ? '' : 'items',
        subBuilder: Playlist.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPlaylistsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListPlaylistsResponse copyWith(
          void Function(ListPlaylistsResponse) updates) =>
      super.copyWith((message) => updates(message as ListPlaylistsResponse))
          as ListPlaylistsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListPlaylistsResponse create() => ListPlaylistsResponse._();
  @$core.override
  ListPlaylistsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ListPlaylistsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListPlaylistsResponse>(create);
  static ListPlaylistsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Playlist> get items => $_getList(0);
}

class GetPlaylistRequest extends $pb.GeneratedMessage {
  factory GetPlaylistRequest({
    $core.int? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  GetPlaylistRequest._();

  factory GetPlaylistRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetPlaylistRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetPlaylistRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPlaylistRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetPlaylistRequest copyWith(void Function(GetPlaylistRequest) updates) =>
      super.copyWith((message) => updates(message as GetPlaylistRequest))
          as GetPlaylistRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetPlaylistRequest create() => GetPlaylistRequest._();
  @$core.override
  GetPlaylistRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetPlaylistRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetPlaylistRequest>(create);
  static GetPlaylistRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class CreatePlaylistRequest extends $pb.GeneratedMessage {
  factory CreatePlaylistRequest({
    $core.String? name,
  }) {
    final result = create();
    if (name != null) result.name = name;
    return result;
  }

  CreatePlaylistRequest._();

  factory CreatePlaylistRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreatePlaylistRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreatePlaylistRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePlaylistRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreatePlaylistRequest copyWith(
          void Function(CreatePlaylistRequest) updates) =>
      super.copyWith((message) => updates(message as CreatePlaylistRequest))
          as CreatePlaylistRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreatePlaylistRequest create() => CreatePlaylistRequest._();
  @$core.override
  CreatePlaylistRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreatePlaylistRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreatePlaylistRequest>(create);
  static CreatePlaylistRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);
}

class CreateFromShowRequest extends $pb.GeneratedMessage {
  factory CreateFromShowRequest({
    $core.String? show,
    $core.int? season,
    $core.String? name,
    $core.bool? playableOnly,
  }) {
    final result = create();
    if (show != null) result.show = show;
    if (season != null) result.season = season;
    if (name != null) result.name = name;
    if (playableOnly != null) result.playableOnly = playableOnly;
    return result;
  }

  CreateFromShowRequest._();

  factory CreateFromShowRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CreateFromShowRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CreateFromShowRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'show')
    ..aI(2, _omitFieldNames ? '' : 'season', fieldType: $pb.PbFieldType.OU3)
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOB(4, _omitFieldNames ? '' : 'playableOnly')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateFromShowRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateFromShowRequest copyWith(
          void Function(CreateFromShowRequest) updates) =>
      super.copyWith((message) => updates(message as CreateFromShowRequest))
          as CreateFromShowRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CreateFromShowRequest create() => CreateFromShowRequest._();
  @$core.override
  CreateFromShowRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CreateFromShowRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateFromShowRequest>(create);
  static CreateFromShowRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get show => $_getSZ(0);
  @$pb.TagNumber(1)
  set show($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasShow() => $_has(0);
  @$pb.TagNumber(1)
  void clearShow() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get season => $_getIZ(1);
  @$pb.TagNumber(2)
  set season($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSeason() => $_has(1);
  @$pb.TagNumber(2)
  void clearSeason() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  /// Episodes without a VOD can't be played; keeping them would break auto-next.
  @$pb.TagNumber(4)
  $core.bool get playableOnly => $_getBF(3);
  @$pb.TagNumber(4)
  set playableOnly($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPlayableOnly() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlayableOnly() => $_clearField(4);
}

/// Anything not sent is left alone.
class UpdatePlaylistRequest extends $pb.GeneratedMessage {
  factory UpdatePlaylistRequest({
    $core.int? id,
    $core.String? name,
    PlaylistVisibility? visibility,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (visibility != null) result.visibility = visibility;
    return result;
  }

  UpdatePlaylistRequest._();

  factory UpdatePlaylistRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdatePlaylistRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdatePlaylistRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<PlaylistVisibility>(3, _omitFieldNames ? '' : 'visibility',
        enumValues: PlaylistVisibility.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePlaylistRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdatePlaylistRequest copyWith(
          void Function(UpdatePlaylistRequest) updates) =>
      super.copyWith((message) => updates(message as UpdatePlaylistRequest))
          as UpdatePlaylistRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdatePlaylistRequest create() => UpdatePlaylistRequest._();
  @$core.override
  UpdatePlaylistRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UpdatePlaylistRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdatePlaylistRequest>(create);
  static UpdatePlaylistRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  PlaylistVisibility get visibility => $_getN(2);
  @$pb.TagNumber(3)
  set visibility(PlaylistVisibility value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasVisibility() => $_has(2);
  @$pb.TagNumber(3)
  void clearVisibility() => $_clearField(3);
}

class DeletePlaylistRequest extends $pb.GeneratedMessage {
  factory DeletePlaylistRequest({
    $core.int? id,
  }) {
    final result = create();
    if (id != null) result.id = id;
    return result;
  }

  DeletePlaylistRequest._();

  factory DeletePlaylistRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeletePlaylistRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeletePlaylistRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'id', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePlaylistRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePlaylistRequest copyWith(
          void Function(DeletePlaylistRequest) updates) =>
      super.copyWith((message) => updates(message as DeletePlaylistRequest))
          as DeletePlaylistRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeletePlaylistRequest create() => DeletePlaylistRequest._();
  @$core.override
  DeletePlaylistRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeletePlaylistRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeletePlaylistRequest>(create);
  static DeletePlaylistRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get id => $_getIZ(0);
  @$pb.TagNumber(1)
  set id($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);
}

class DeletePlaylistResponse extends $pb.GeneratedMessage {
  factory DeletePlaylistResponse() => create();

  DeletePlaylistResponse._();

  factory DeletePlaylistResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory DeletePlaylistResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'DeletePlaylistResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePlaylistResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeletePlaylistResponse copyWith(
          void Function(DeletePlaylistResponse) updates) =>
      super.copyWith((message) => updates(message as DeletePlaylistResponse))
          as DeletePlaylistResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeletePlaylistResponse create() => DeletePlaylistResponse._();
  @$core.override
  DeletePlaylistResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static DeletePlaylistResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeletePlaylistResponse>(create);
  static DeletePlaylistResponse? _defaultInstance;
}

class AddItemRequest extends $pb.GeneratedMessage {
  factory AddItemRequest({
    $core.int? playlistId,
    $core.int? episodeId,
  }) {
    final result = create();
    if (playlistId != null) result.playlistId = playlistId;
    if (episodeId != null) result.episodeId = episodeId;
    return result;
  }

  AddItemRequest._();

  factory AddItemRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AddItemRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AddItemRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'playlistId', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'episodeId', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddItemRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AddItemRequest copyWith(void Function(AddItemRequest) updates) =>
      super.copyWith((message) => updates(message as AddItemRequest))
          as AddItemRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AddItemRequest create() => AddItemRequest._();
  @$core.override
  AddItemRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static AddItemRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AddItemRequest>(create);
  static AddItemRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get playlistId => $_getIZ(0);
  @$pb.TagNumber(1)
  set playlistId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlaylistId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlaylistId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get episodeId => $_getIZ(1);
  @$pb.TagNumber(2)
  set episodeId($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEpisodeId() => $_has(1);
  @$pb.TagNumber(2)
  void clearEpisodeId() => $_clearField(2);
}

class RemoveItemRequest extends $pb.GeneratedMessage {
  factory RemoveItemRequest({
    $core.int? playlistId,
    $core.int? itemId,
  }) {
    final result = create();
    if (playlistId != null) result.playlistId = playlistId;
    if (itemId != null) result.itemId = itemId;
    return result;
  }

  RemoveItemRequest._();

  factory RemoveItemRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RemoveItemRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RemoveItemRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'playlistId', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'itemId', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveItemRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RemoveItemRequest copyWith(void Function(RemoveItemRequest) updates) =>
      super.copyWith((message) => updates(message as RemoveItemRequest))
          as RemoveItemRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RemoveItemRequest create() => RemoveItemRequest._();
  @$core.override
  RemoveItemRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RemoveItemRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RemoveItemRequest>(create);
  static RemoveItemRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get playlistId => $_getIZ(0);
  @$pb.TagNumber(1)
  set playlistId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlaylistId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlaylistId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get itemId => $_getIZ(1);
  @$pb.TagNumber(2)
  set itemId($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasItemId() => $_has(1);
  @$pb.TagNumber(2)
  void clearItemId() => $_clearField(2);
}

class ReorderRequest extends $pb.GeneratedMessage {
  factory ReorderRequest({
    $core.int? playlistId,
    $core.Iterable<$core.int>? itemIds,
  }) {
    final result = create();
    if (playlistId != null) result.playlistId = playlistId;
    if (itemIds != null) result.itemIds.addAll(itemIds);
    return result;
  }

  ReorderRequest._();

  factory ReorderRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ReorderRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ReorderRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'catalogue.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'playlistId', fieldType: $pb.PbFieldType.OU3)
    ..p<$core.int>(2, _omitFieldNames ? '' : 'itemIds', $pb.PbFieldType.KU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReorderRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ReorderRequest copyWith(void Function(ReorderRequest) updates) =>
      super.copyWith((message) => updates(message as ReorderRequest))
          as ReorderRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ReorderRequest create() => ReorderRequest._();
  @$core.override
  ReorderRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ReorderRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ReorderRequest>(create);
  static ReorderRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get playlistId => $_getIZ(0);
  @$pb.TagNumber(1)
  set playlistId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlaylistId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlaylistId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.int> get itemIds => $_getList(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
