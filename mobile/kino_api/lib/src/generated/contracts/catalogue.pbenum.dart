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

class Role extends $pb.ProtobufEnum {
  static const Role ROLE_UNSPECIFIED =
      Role._(0, _omitEnumNames ? '' : 'ROLE_UNSPECIFIED');
  static const Role ROLE_USER = Role._(1, _omitEnumNames ? '' : 'ROLE_USER');
  static const Role ROLE_ADMIN = Role._(2, _omitEnumNames ? '' : 'ROLE_ADMIN');

  static const $core.List<Role> values = <Role>[
    ROLE_UNSPECIFIED,
    ROLE_USER,
    ROLE_ADMIN,
  ];

  static final $core.List<Role?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static Role? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const Role._(super.value, super.name);
}

class ShowOrder extends $pb.ProtobufEnum {
  /// By key, which is what the REST layer defaults to.
  static const ShowOrder SHOW_ORDER_UNSPECIFIED =
      ShowOrder._(0, _omitEnumNames ? '' : 'SHOW_ORDER_UNSPECIFIED');
  static const ShowOrder SHOW_ORDER_KEY =
      ShowOrder._(1, _omitEnumNames ? '' : 'SHOW_ORDER_KEY');
  static const ShowOrder SHOW_ORDER_ADDED =
      ShowOrder._(2, _omitEnumNames ? '' : 'SHOW_ORDER_ADDED');
  static const ShowOrder SHOW_ORDER_TITLE =
      ShowOrder._(3, _omitEnumNames ? '' : 'SHOW_ORDER_TITLE');

  /// By release year — the fact — rather than by when a row was synced, which a
  /// bulk rebuild makes meaningless.
  static const ShowOrder SHOW_ORDER_NEWEST =
      ShowOrder._(4, _omitEnumNames ? '' : 'SHOW_ORDER_NEWEST');
  static const ShowOrder SHOW_ORDER_OLDEST =
      ShowOrder._(5, _omitEnumNames ? '' : 'SHOW_ORDER_OLDEST');

  static const $core.List<ShowOrder> values = <ShowOrder>[
    SHOW_ORDER_UNSPECIFIED,
    SHOW_ORDER_KEY,
    SHOW_ORDER_ADDED,
    SHOW_ORDER_TITLE,
    SHOW_ORDER_NEWEST,
    SHOW_ORDER_OLDEST,
  ];

  static final $core.List<ShowOrder?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 5);
  static ShowOrder? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ShowOrder._(super.value, super.name);
}

class SectionKind extends $pb.ProtobufEnum {
  static const SectionKind SECTION_KIND_UNSPECIFIED =
      SectionKind._(0, _omitEnumNames ? '' : 'SECTION_KIND_UNSPECIFIED');
  static const SectionKind SECTION_KIND_HERO =
      SectionKind._(1, _omitEnumNames ? '' : 'SECTION_KIND_HERO');
  static const SectionKind SECTION_KIND_RAIL =
      SectionKind._(2, _omitEnumNames ? '' : 'SECTION_KIND_RAIL');
  static const SectionKind SECTION_KIND_GRID =
      SectionKind._(3, _omitEnumNames ? '' : 'SECTION_KIND_GRID');

  /// Artwork and a link, with no episodes under it.
  static const SectionKind SECTION_KIND_BANNER =
      SectionKind._(4, _omitEnumNames ? '' : 'SECTION_KIND_BANNER');

  static const $core.List<SectionKind> values = <SectionKind>[
    SECTION_KIND_UNSPECIFIED,
    SECTION_KIND_HERO,
    SECTION_KIND_RAIL,
    SECTION_KIND_GRID,
    SECTION_KIND_BANNER,
  ];

  static final $core.List<SectionKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 4);
  static SectionKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const SectionKind._(super.value, super.name);
}

class PlaylistVisibility extends $pb.ProtobufEnum {
  static const PlaylistVisibility PLAYLIST_VISIBILITY_UNSPECIFIED =
      PlaylistVisibility._(
          0, _omitEnumNames ? '' : 'PLAYLIST_VISIBILITY_UNSPECIFIED');
  static const PlaylistVisibility PLAYLIST_VISIBILITY_PRIVATE =
      PlaylistVisibility._(
          1, _omitEnumNames ? '' : 'PLAYLIST_VISIBILITY_PRIVATE');

  /// An editorial act, not a sharing one: the whole install sees it, so only an
  /// admin can make one.
  static const PlaylistVisibility PLAYLIST_VISIBILITY_PUBLIC =
      PlaylistVisibility._(
          2, _omitEnumNames ? '' : 'PLAYLIST_VISIBILITY_PUBLIC');

  static const $core.List<PlaylistVisibility> values = <PlaylistVisibility>[
    PLAYLIST_VISIBILITY_UNSPECIFIED,
    PLAYLIST_VISIBILITY_PRIVATE,
    PLAYLIST_VISIBILITY_PUBLIC,
  ];

  static final $core.List<PlaylistVisibility?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static PlaylistVisibility? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlaylistVisibility._(super.value, super.name);
}

class PlaylistScope extends $pb.ProtobufEnum {
  /// Yours plus whatever is published.
  static const PlaylistScope PLAYLIST_SCOPE_UNSPECIFIED =
      PlaylistScope._(0, _omitEnumNames ? '' : 'PLAYLIST_SCOPE_UNSPECIFIED');
  static const PlaylistScope PLAYLIST_SCOPE_VISIBLE =
      PlaylistScope._(1, _omitEnumNames ? '' : 'PLAYLIST_SCOPE_VISIBLE');
  static const PlaylistScope PLAYLIST_SCOPE_MINE =
      PlaylistScope._(2, _omitEnumNames ? '' : 'PLAYLIST_SCOPE_MINE');
  static const PlaylistScope PLAYLIST_SCOPE_PUBLIC =
      PlaylistScope._(3, _omitEnumNames ? '' : 'PLAYLIST_SCOPE_PUBLIC');

  static const $core.List<PlaylistScope> values = <PlaylistScope>[
    PLAYLIST_SCOPE_UNSPECIFIED,
    PLAYLIST_SCOPE_VISIBLE,
    PLAYLIST_SCOPE_MINE,
    PLAYLIST_SCOPE_PUBLIC,
  ];

  static final $core.List<PlaylistScope?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 3);
  static PlaylistScope? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PlaylistScope._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
