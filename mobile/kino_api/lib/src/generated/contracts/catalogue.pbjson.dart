// This is a generated file - do not edit.
//
// Generated from contracts/catalogue.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use roleDescriptor instead')
const Role$json = {
  '1': 'Role',
  '2': [
    {'1': 'ROLE_UNSPECIFIED', '2': 0},
    {'1': 'ROLE_USER', '2': 1},
    {'1': 'ROLE_ADMIN', '2': 2},
  ],
};

/// Descriptor for `Role`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List roleDescriptor = $convert.base64Decode(
    'CgRSb2xlEhQKEFJPTEVfVU5TUEVDSUZJRUQQABINCglST0xFX1VTRVIQARIOCgpST0xFX0FETU'
    'lOEAI=');

@$core.Deprecated('Use showOrderDescriptor instead')
const ShowOrder$json = {
  '1': 'ShowOrder',
  '2': [
    {'1': 'SHOW_ORDER_UNSPECIFIED', '2': 0},
    {'1': 'SHOW_ORDER_KEY', '2': 1},
    {'1': 'SHOW_ORDER_ADDED', '2': 2},
    {'1': 'SHOW_ORDER_TITLE', '2': 3},
    {'1': 'SHOW_ORDER_NEWEST', '2': 4},
    {'1': 'SHOW_ORDER_OLDEST', '2': 5},
  ],
};

/// Descriptor for `ShowOrder`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List showOrderDescriptor = $convert.base64Decode(
    'CglTaG93T3JkZXISGgoWU0hPV19PUkRFUl9VTlNQRUNJRklFRBAAEhIKDlNIT1dfT1JERVJfS0'
    'VZEAESFAoQU0hPV19PUkRFUl9BRERFRBACEhQKEFNIT1dfT1JERVJfVElUTEUQAxIVChFTSE9X'
    'X09SREVSX05FV0VTVBAEEhUKEVNIT1dfT1JERVJfT0xERVNUEAU=');

@$core.Deprecated('Use sectionKindDescriptor instead')
const SectionKind$json = {
  '1': 'SectionKind',
  '2': [
    {'1': 'SECTION_KIND_UNSPECIFIED', '2': 0},
    {'1': 'SECTION_KIND_HERO', '2': 1},
    {'1': 'SECTION_KIND_RAIL', '2': 2},
    {'1': 'SECTION_KIND_GRID', '2': 3},
    {'1': 'SECTION_KIND_BANNER', '2': 4},
  ],
};

/// Descriptor for `SectionKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List sectionKindDescriptor = $convert.base64Decode(
    'CgtTZWN0aW9uS2luZBIcChhTRUNUSU9OX0tJTkRfVU5TUEVDSUZJRUQQABIVChFTRUNUSU9OX0'
    'tJTkRfSEVSTxABEhUKEVNFQ1RJT05fS0lORF9SQUlMEAISFQoRU0VDVElPTl9LSU5EX0dSSUQQ'
    'AxIXChNTRUNUSU9OX0tJTkRfQkFOTkVSEAQ=');

@$core.Deprecated('Use playlistVisibilityDescriptor instead')
const PlaylistVisibility$json = {
  '1': 'PlaylistVisibility',
  '2': [
    {'1': 'PLAYLIST_VISIBILITY_UNSPECIFIED', '2': 0},
    {'1': 'PLAYLIST_VISIBILITY_PRIVATE', '2': 1},
    {'1': 'PLAYLIST_VISIBILITY_PUBLIC', '2': 2},
  ],
};

/// Descriptor for `PlaylistVisibility`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List playlistVisibilityDescriptor = $convert.base64Decode(
    'ChJQbGF5bGlzdFZpc2liaWxpdHkSIwofUExBWUxJU1RfVklTSUJJTElUWV9VTlNQRUNJRklFRB'
    'AAEh8KG1BMQVlMSVNUX1ZJU0lCSUxJVFlfUFJJVkFURRABEh4KGlBMQVlMSVNUX1ZJU0lCSUxJ'
    'VFlfUFVCTElDEAI=');

@$core.Deprecated('Use playlistScopeDescriptor instead')
const PlaylistScope$json = {
  '1': 'PlaylistScope',
  '2': [
    {'1': 'PLAYLIST_SCOPE_UNSPECIFIED', '2': 0},
    {'1': 'PLAYLIST_SCOPE_VISIBLE', '2': 1},
    {'1': 'PLAYLIST_SCOPE_MINE', '2': 2},
    {'1': 'PLAYLIST_SCOPE_PUBLIC', '2': 3},
  ],
};

/// Descriptor for `PlaylistScope`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List playlistScopeDescriptor = $convert.base64Decode(
    'Cg1QbGF5bGlzdFNjb3BlEh4KGlBMQVlMSVNUX1NDT1BFX1VOU1BFQ0lGSUVEEAASGgoWUExBWU'
    'xJU1RfU0NPUEVfVklTSUJMRRABEhcKE1BMQVlMSVNUX1NDT1BFX01JTkUQAhIZChVQTEFZTElT'
    'VF9TQ09QRV9QVUJMSUMQAw==');

@$core.Deprecated('Use userDescriptor instead')
const User$json = {
  '1': 'User',
  '2': [
    {'1': 'public_id', '3': 1, '4': 1, '5': 9, '10': 'publicId'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'email', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'email', '17': true},
    {
      '1': 'role',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.catalogue.v1.Role',
      '10': 'role'
    },
    {'1': 'is_guest', '3': 5, '4': 1, '5': 8, '10': 'isGuest'},
    {'1': 'created_at', '3': 6, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'last_seen_at', '3': 7, '4': 1, '5': 9, '10': 'lastSeenAt'},
  ],
  '8': [
    {'1': '_email'},
  ],
};

/// Descriptor for `User`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDescriptor = $convert.base64Decode(
    'CgRVc2VyEhsKCXB1YmxpY19pZBgBIAEoCVIIcHVibGljSWQSIQoMZGlzcGxheV9uYW1lGAIgAS'
    'gJUgtkaXNwbGF5TmFtZRIZCgVlbWFpbBgDIAEoCUgAUgVlbWFpbIgBARImCgRyb2xlGAQgASgO'
    'MhIuY2F0YWxvZ3VlLnYxLlJvbGVSBHJvbGUSGQoIaXNfZ3Vlc3QYBSABKAhSB2lzR3Vlc3QSHQ'
    'oKY3JlYXRlZF9hdBgGIAEoCVIJY3JlYXRlZEF0EiAKDGxhc3Rfc2Vlbl9hdBgHIAEoCVIKbGFz'
    'dFNlZW5BdEIICgZfZW1haWw=');

@$core.Deprecated('Use identityDescriptor instead')
const Identity$json = {
  '1': 'Identity',
  '2': [
    {'1': 'token', '3': 1, '4': 1, '5': 9, '10': 'token'},
    {
      '1': 'user',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.User',
      '10': 'user'
    },
  ],
};

/// Descriptor for `Identity`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List identityDescriptor = $convert.base64Decode(
    'CghJZGVudGl0eRIUCgV0b2tlbhgBIAEoCVIFdG9rZW4SJgoEdXNlchgCIAEoCzISLmNhdGFsb2'
    'd1ZS52MS5Vc2VyUgR1c2Vy');

@$core.Deprecated('Use whoAmIRequestDescriptor instead')
const WhoAmIRequest$json = {
  '1': 'WhoAmIRequest',
};

/// Descriptor for `WhoAmIRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List whoAmIRequestDescriptor =
    $convert.base64Decode('Cg1XaG9BbUlSZXF1ZXN0');

@$core.Deprecated('Use startGuestRequestDescriptor instead')
const StartGuestRequest$json = {
  '1': 'StartGuestRequest',
};

/// Descriptor for `StartGuestRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startGuestRequestDescriptor =
    $convert.base64Decode('ChFTdGFydEd1ZXN0UmVxdWVzdA==');

@$core.Deprecated('Use claimRequestDescriptor instead')
const ClaimRequest$json = {
  '1': 'ClaimRequest',
  '2': [
    {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
    {
      '1': 'display_name',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'displayName',
      '17': true
    },
  ],
  '8': [
    {'1': '_display_name'},
  ],
};

/// Descriptor for `ClaimRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List claimRequestDescriptor = $convert.base64Decode(
    'CgxDbGFpbVJlcXVlc3QSFAoFZW1haWwYASABKAlSBWVtYWlsEhoKCHBhc3N3b3JkGAIgASgJUg'
    'hwYXNzd29yZBImCgxkaXNwbGF5X25hbWUYAyABKAlIAFILZGlzcGxheU5hbWWIAQFCDwoNX2Rp'
    'c3BsYXlfbmFtZQ==');

@$core.Deprecated('Use loginRequestDescriptor instead')
const LoginRequest$json = {
  '1': 'LoginRequest',
  '2': [
    {'1': 'email', '3': 1, '4': 1, '5': 9, '10': 'email'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `LoginRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List loginRequestDescriptor = $convert.base64Decode(
    'CgxMb2dpblJlcXVlc3QSFAoFZW1haWwYASABKAlSBWVtYWlsEhoKCHBhc3N3b3JkGAIgASgJUg'
    'hwYXNzd29yZA==');

@$core.Deprecated('Use logoutRequestDescriptor instead')
const LogoutRequest$json = {
  '1': 'LogoutRequest',
};

/// Descriptor for `LogoutRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutRequestDescriptor =
    $convert.base64Decode('Cg1Mb2dvdXRSZXF1ZXN0');

@$core.Deprecated('Use logoutResponseDescriptor instead')
const LogoutResponse$json = {
  '1': 'LogoutResponse',
};

/// Descriptor for `LogoutResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logoutResponseDescriptor =
    $convert.base64Decode('Cg5Mb2dvdXRSZXNwb25zZQ==');

@$core.Deprecated('Use renameRequestDescriptor instead')
const RenameRequest$json = {
  '1': 'RenameRequest',
  '2': [
    {'1': 'display_name', '3': 1, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `RenameRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List renameRequestDescriptor = $convert.base64Decode(
    'Cg1SZW5hbWVSZXF1ZXN0EiEKDGRpc3BsYXlfbmFtZRgBIAEoCVILZGlzcGxheU5hbWU=');

@$core.Deprecated('Use showDescriptor instead')
const Show$json = {
  '1': 'Show',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'key', '3': 2, '4': 1, '5': 9, '10': 'key'},
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'poster', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'poster', '17': true},
    {'1': 'created_at', '3': 5, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'is_film', '3': 6, '4': 1, '5': 8, '10': 'isFilm'},
  ],
  '8': [
    {'1': '_poster'},
  ],
};

/// Descriptor for `Show`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showDescriptor = $convert.base64Decode(
    'CgRTaG93Eg4KAmlkGAEgASgNUgJpZBIQCgNrZXkYAiABKAlSA2tleRIUCgV0aXRsZRgDIAEoCV'
    'IFdGl0bGUSGwoGcG9zdGVyGAQgASgJSABSBnBvc3RlcogBARIdCgpjcmVhdGVkX2F0GAUgASgJ'
    'UgljcmVhdGVkQXQSFwoHaXNfZmlsbRgGIAEoCFIGaXNGaWxtQgkKB19wb3N0ZXI=');

@$core.Deprecated('Use showSummaryDescriptor instead')
const ShowSummary$json = {
  '1': 'ShowSummary',
  '2': [
    {
      '1': 'show',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.Show',
      '10': 'show'
    },
    {'1': 'episode_count', '3': 2, '4': 1, '5': 13, '10': 'episodeCount'},
    {'1': 'playable_count', '3': 3, '4': 1, '5': 13, '10': 'playableCount'},
  ],
};

/// Descriptor for `ShowSummary`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showSummaryDescriptor = $convert.base64Decode(
    'CgtTaG93U3VtbWFyeRImCgRzaG93GAEgASgLMhIuY2F0YWxvZ3VlLnYxLlNob3dSBHNob3cSIw'
    'oNZXBpc29kZV9jb3VudBgCIAEoDVIMZXBpc29kZUNvdW50EiUKDnBsYXlhYmxlX2NvdW50GAMg'
    'ASgNUg1wbGF5YWJsZUNvdW50');

@$core.Deprecated('Use showDetailsDescriptor instead')
const ShowDetails$json = {
  '1': 'ShowDetails',
  '2': [
    {
      '1': 'show',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.Show',
      '10': 'show'
    },
    {
      '1': 'original_title',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'originalTitle',
      '17': true
    },
    {'1': 'kind', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'kind', '17': true},
    {'1': 'year', '3': 4, '4': 1, '5': 13, '9': 2, '10': 'year', '17': true},
    {
      '1': 'year_end',
      '3': 5,
      '4': 1,
      '5': 13,
      '9': 3,
      '10': 'yearEnd',
      '17': true
    },
    {'1': 'audio', '3': 6, '4': 1, '5': 9, '9': 4, '10': 'audio', '17': true},
    {
      '1': 'quality',
      '3': 7,
      '4': 1,
      '5': 9,
      '9': 5,
      '10': 'quality',
      '17': true
    },
    {
      '1': 'description',
      '3': 8,
      '4': 1,
      '5': 9,
      '9': 6,
      '10': 'description',
      '17': true
    },
    {
      '1': 'duration',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 7,
      '10': 'duration',
      '17': true
    },
    {
      '1': 'age_rating',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 8,
      '10': 'ageRating',
      '17': true
    },
    {'1': 'genres', '3': 11, '4': 3, '5': 9, '10': 'genres'},
    {'1': 'countries', '3': 12, '4': 3, '5': 9, '10': 'countries'},
    {'1': 'directors', '3': 13, '4': 3, '5': 9, '10': 'directors'},
    {'1': 'starring', '3': 14, '4': 3, '5': 9, '10': 'starring'},
    {
      '1': 'imdb_id',
      '3': 15,
      '4': 1,
      '5': 9,
      '9': 9,
      '10': 'imdbId',
      '17': true
    },
    {
      '1': 'imdb_rating',
      '3': 16,
      '4': 1,
      '5': 1,
      '9': 10,
      '10': 'imdbRating',
      '17': true
    },
    {
      '1': 'imdb_votes',
      '3': 17,
      '4': 1,
      '5': 13,
      '9': 11,
      '10': 'imdbVotes',
      '17': true
    },
    {
      '1': 'imdb_url',
      '3': 18,
      '4': 1,
      '5': 9,
      '9': 12,
      '10': 'imdbUrl',
      '17': true
    },
  ],
  '8': [
    {'1': '_original_title'},
    {'1': '_kind'},
    {'1': '_year'},
    {'1': '_year_end'},
    {'1': '_audio'},
    {'1': '_quality'},
    {'1': '_description'},
    {'1': '_duration'},
    {'1': '_age_rating'},
    {'1': '_imdb_id'},
    {'1': '_imdb_rating'},
    {'1': '_imdb_votes'},
    {'1': '_imdb_url'},
  ],
};

/// Descriptor for `ShowDetails`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showDetailsDescriptor = $convert.base64Decode(
    'CgtTaG93RGV0YWlscxImCgRzaG93GAEgASgLMhIuY2F0YWxvZ3VlLnYxLlNob3dSBHNob3cSKg'
    'oOb3JpZ2luYWxfdGl0bGUYAiABKAlIAFINb3JpZ2luYWxUaXRsZYgBARIXCgRraW5kGAMgASgJ'
    'SAFSBGtpbmSIAQESFwoEeWVhchgEIAEoDUgCUgR5ZWFyiAEBEh4KCHllYXJfZW5kGAUgASgNSA'
    'NSB3llYXJFbmSIAQESGQoFYXVkaW8YBiABKAlIBFIFYXVkaW+IAQESHQoHcXVhbGl0eRgHIAEo'
    'CUgFUgdxdWFsaXR5iAEBEiUKC2Rlc2NyaXB0aW9uGAggASgJSAZSC2Rlc2NyaXB0aW9uiAEBEh'
    '8KCGR1cmF0aW9uGAkgASgJSAdSCGR1cmF0aW9uiAEBEiIKCmFnZV9yYXRpbmcYCiABKAlICFIJ'
    'YWdlUmF0aW5niAEBEhYKBmdlbnJlcxgLIAMoCVIGZ2VucmVzEhwKCWNvdW50cmllcxgMIAMoCV'
    'IJY291bnRyaWVzEhwKCWRpcmVjdG9ycxgNIAMoCVIJZGlyZWN0b3JzEhoKCHN0YXJyaW5nGA4g'
    'AygJUghzdGFycmluZxIcCgdpbWRiX2lkGA8gASgJSAlSBmltZGJJZIgBARIkCgtpbWRiX3JhdG'
    'luZxgQIAEoAUgKUgppbWRiUmF0aW5niAEBEiIKCmltZGJfdm90ZXMYESABKA1IC1IJaW1kYlZv'
    'dGVziAEBEh4KCGltZGJfdXJsGBIgASgJSAxSB2ltZGJVcmyIAQFCEQoPX29yaWdpbmFsX3RpdG'
    'xlQgcKBV9raW5kQgcKBV95ZWFyQgsKCV95ZWFyX2VuZEIICgZfYXVkaW9CCgoIX3F1YWxpdHlC'
    'DgoMX2Rlc2NyaXB0aW9uQgsKCV9kdXJhdGlvbkINCgtfYWdlX3JhdGluZ0IKCghfaW1kYl9pZE'
    'IOCgxfaW1kYl9yYXRpbmdCDQoLX2ltZGJfdm90ZXNCCwoJX2ltZGJfdXJs');

@$core.Deprecated('Use trackDescriptor instead')
const Track$json = {
  '1': 'Track',
  '2': [
    {'1': 'vod_id', '3': 1, '4': 1, '5': 13, '10': 'vodId'},
    {'1': 'audio', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'audio', '17': true},
    {'1': 'playlist', '3': 3, '4': 1, '5': 9, '10': 'playlist'},
  ],
  '8': [
    {'1': '_audio'},
  ],
};

/// Descriptor for `Track`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trackDescriptor = $convert.base64Decode(
    'CgVUcmFjaxIVCgZ2b2RfaWQYASABKA1SBXZvZElkEhkKBWF1ZGlvGAIgASgJSABSBWF1ZGlviA'
    'EBEhoKCHBsYXlsaXN0GAMgASgJUghwbGF5bGlzdEIICgZfYXVkaW8=');

@$core.Deprecated('Use episodeDescriptor instead')
const Episode$json = {
  '1': 'Episode',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'season', '3': 2, '4': 1, '5': 13, '10': 'season'},
    {'1': 'episode', '3': 3, '4': 1, '5': 13, '10': 'episode'},
    {
      '1': 'episode_end',
      '3': 4,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'episodeEnd',
      '17': true
    },
    {'1': 'title', '3': 5, '4': 1, '5': 9, '10': 'title'},
    {'1': 'poster', '3': 6, '4': 1, '5': 9, '9': 1, '10': 'poster', '17': true},
    {'1': 'source_url', '3': 7, '4': 1, '5': 9, '10': 'sourceUrl'},
    {'1': 'vod_id', '3': 8, '4': 1, '5': 13, '9': 2, '10': 'vodId', '17': true},
    {
      '1': 'vod_url',
      '3': 9,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'vodUrl',
      '17': true
    },
    {
      '1': 'playlist',
      '3': 10,
      '4': 1,
      '5': 9,
      '9': 4,
      '10': 'playlist',
      '17': true
    },
    {
      '1': 'tracks',
      '3': 11,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.Track',
      '10': 'tracks'
    },
  ],
  '8': [
    {'1': '_episode_end'},
    {'1': '_poster'},
    {'1': '_vod_id'},
    {'1': '_vod_url'},
    {'1': '_playlist'},
  ],
};

/// Descriptor for `Episode`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List episodeDescriptor = $convert.base64Decode(
    'CgdFcGlzb2RlEg4KAmlkGAEgASgNUgJpZBIWCgZzZWFzb24YAiABKA1SBnNlYXNvbhIYCgdlcG'
    'lzb2RlGAMgASgNUgdlcGlzb2RlEiQKC2VwaXNvZGVfZW5kGAQgASgNSABSCmVwaXNvZGVFbmSI'
    'AQESFAoFdGl0bGUYBSABKAlSBXRpdGxlEhsKBnBvc3RlchgGIAEoCUgBUgZwb3N0ZXKIAQESHQ'
    'oKc291cmNlX3VybBgHIAEoCVIJc291cmNlVXJsEhoKBnZvZF9pZBgIIAEoDUgCUgV2b2RJZIgB'
    'ARIcCgd2b2RfdXJsGAkgASgJSANSBnZvZFVybIgBARIfCghwbGF5bGlzdBgKIAEoCUgEUghwbG'
    'F5bGlzdIgBARIrCgZ0cmFja3MYCyADKAsyEy5jYXRhbG9ndWUudjEuVHJhY2tSBnRyYWNrc0IO'
    'CgxfZXBpc29kZV9lbmRCCQoHX3Bvc3RlckIJCgdfdm9kX2lkQgoKCF92b2RfdXJsQgsKCV9wbG'
    'F5bGlzdA==');

@$core.Deprecated('Use episodeWithShowDescriptor instead')
const EpisodeWithShow$json = {
  '1': 'EpisodeWithShow',
  '2': [
    {
      '1': 'episode',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.Episode',
      '10': 'episode'
    },
    {
      '1': 'show',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.Show',
      '10': 'show'
    },
  ],
};

/// Descriptor for `EpisodeWithShow`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List episodeWithShowDescriptor = $convert.base64Decode(
    'Cg9FcGlzb2RlV2l0aFNob3cSLwoHZXBpc29kZRgBIAEoCzIVLmNhdGFsb2d1ZS52MS5FcGlzb2'
    'RlUgdlcGlzb2RlEiYKBHNob3cYAiABKAsyEi5jYXRhbG9ndWUudjEuU2hvd1IEc2hvdw==');

@$core.Deprecated('Use showWithEpisodesDescriptor instead')
const ShowWithEpisodes$json = {
  '1': 'ShowWithEpisodes',
  '2': [
    {
      '1': 'show',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.ShowDetails',
      '10': 'show'
    },
    {
      '1': 'episodes',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.Episode',
      '10': 'episodes'
    },
  ],
};

/// Descriptor for `ShowWithEpisodes`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List showWithEpisodesDescriptor = $convert.base64Decode(
    'ChBTaG93V2l0aEVwaXNvZGVzEi0KBHNob3cYASABKAsyGS5jYXRhbG9ndWUudjEuU2hvd0RldG'
    'FpbHNSBHNob3cSMQoIZXBpc29kZXMYAiADKAsyFS5jYXRhbG9ndWUudjEuRXBpc29kZVIIZXBp'
    'c29kZXM=');

@$core.Deprecated('Use pageInfoDescriptor instead')
const PageInfo$json = {
  '1': 'PageInfo',
  '2': [
    {'1': 'total', '3': 1, '4': 1, '5': 13, '10': 'total'},
    {'1': 'limit', '3': 2, '4': 1, '5': 13, '10': 'limit'},
    {'1': 'offset', '3': 3, '4': 1, '5': 13, '10': 'offset'},
  ],
};

/// Descriptor for `PageInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pageInfoDescriptor = $convert.base64Decode(
    'CghQYWdlSW5mbxIUCgV0b3RhbBgBIAEoDVIFdG90YWwSFAoFbGltaXQYAiABKA1SBWxpbWl0Eh'
    'YKBm9mZnNldBgDIAEoDVIGb2Zmc2V0');

@$core.Deprecated('Use healthRequestDescriptor instead')
const HealthRequest$json = {
  '1': 'HealthRequest',
};

/// Descriptor for `HealthRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List healthRequestDescriptor =
    $convert.base64Decode('Cg1IZWFsdGhSZXF1ZXN0');

@$core.Deprecated('Use healthResponseDescriptor instead')
const HealthResponse$json = {
  '1': 'HealthResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 9, '10': 'status'},
    {'1': 'shows', '3': 2, '4': 1, '5': 13, '10': 'shows'},
    {'1': 'episodes', '3': 3, '4': 1, '5': 13, '10': 'episodes'},
  ],
};

/// Descriptor for `HealthResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List healthResponseDescriptor = $convert.base64Decode(
    'Cg5IZWFsdGhSZXNwb25zZRIWCgZzdGF0dXMYASABKAlSBnN0YXR1cxIUCgVzaG93cxgCIAEoDV'
    'IFc2hvd3MSGgoIZXBpc29kZXMYAyABKA1SCGVwaXNvZGVz');

@$core.Deprecated('Use listShowsRequestDescriptor instead')
const ListShowsRequest$json = {
  '1': 'ListShowsRequest',
  '2': [
    {'1': 'q', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'q', '17': true},
    {'1': 'series', '3': 2, '4': 1, '5': 8, '9': 1, '10': 'series', '17': true},
    {
      '1': 'order',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.catalogue.v1.ShowOrder',
      '10': 'order'
    },
    {'1': 'limit', '3': 4, '4': 1, '5': 13, '10': 'limit'},
    {'1': 'offset', '3': 5, '4': 1, '5': 13, '10': 'offset'},
    {'1': 'kind', '3': 6, '4': 1, '5': 9, '9': 2, '10': 'kind', '17': true},
  ],
  '8': [
    {'1': '_q'},
    {'1': '_series'},
    {'1': '_kind'},
  ],
};

/// Descriptor for `ListShowsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listShowsRequestDescriptor = $convert.base64Decode(
    'ChBMaXN0U2hvd3NSZXF1ZXN0EhEKAXEYASABKAlIAFIBcYgBARIbCgZzZXJpZXMYAiABKAhIAV'
    'IGc2VyaWVziAEBEi0KBW9yZGVyGAMgASgOMhcuY2F0YWxvZ3VlLnYxLlNob3dPcmRlclIFb3Jk'
    'ZXISFAoFbGltaXQYBCABKA1SBWxpbWl0EhYKBm9mZnNldBgFIAEoDVIGb2Zmc2V0EhcKBGtpbm'
    'QYBiABKAlIAlIEa2luZIgBAUIECgJfcUIJCgdfc2VyaWVzQgcKBV9raW5k');

@$core.Deprecated('Use listShowsResponseDescriptor instead')
const ListShowsResponse$json = {
  '1': 'ListShowsResponse',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.PageInfo',
      '10': 'page'
    },
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.ShowSummary',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ListShowsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listShowsResponseDescriptor = $convert.base64Decode(
    'ChFMaXN0U2hvd3NSZXNwb25zZRIqCgRwYWdlGAEgASgLMhYuY2F0YWxvZ3VlLnYxLlBhZ2VJbm'
    'ZvUgRwYWdlEi8KBWl0ZW1zGAIgAygLMhkuY2F0YWxvZ3VlLnYxLlNob3dTdW1tYXJ5UgVpdGVt'
    'cw==');

@$core.Deprecated('Use streamShowsRequestDescriptor instead')
const StreamShowsRequest$json = {
  '1': 'StreamShowsRequest',
  '2': [
    {'1': 'q', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'q', '17': true},
    {'1': 'series', '3': 2, '4': 1, '5': 8, '9': 1, '10': 'series', '17': true},
    {
      '1': 'order',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.catalogue.v1.ShowOrder',
      '10': 'order'
    },
    {'1': 'limit', '3': 4, '4': 1, '5': 13, '10': 'limit'},
    {'1': 'kind', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'kind', '17': true},
  ],
  '8': [
    {'1': '_q'},
    {'1': '_series'},
    {'1': '_kind'},
  ],
};

/// Descriptor for `StreamShowsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List streamShowsRequestDescriptor = $convert.base64Decode(
    'ChJTdHJlYW1TaG93c1JlcXVlc3QSEQoBcRgBIAEoCUgAUgFxiAEBEhsKBnNlcmllcxgCIAEoCE'
    'gBUgZzZXJpZXOIAQESLQoFb3JkZXIYAyABKA4yFy5jYXRhbG9ndWUudjEuU2hvd09yZGVyUgVv'
    'cmRlchIUCgVsaW1pdBgEIAEoDVIFbGltaXQSFwoEa2luZBgFIAEoCUgCUgRraW5kiAEBQgQKAl'
    '9xQgkKB19zZXJpZXNCBwoFX2tpbmQ=');

@$core.Deprecated('Use getShowRequestDescriptor instead')
const GetShowRequest$json = {
  '1': 'GetShowRequest',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
  ],
};

/// Descriptor for `GetShowRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getShowRequestDescriptor =
    $convert.base64Decode('Cg5HZXRTaG93UmVxdWVzdBIQCgNrZXkYASABKAlSA2tleQ==');

@$core.Deprecated('Use listEpisodesRequestDescriptor instead')
const ListEpisodesRequest$json = {
  '1': 'ListEpisodesRequest',
  '2': [
    {'1': 'show', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'show', '17': true},
    {
      '1': 'season',
      '3': 2,
      '4': 1,
      '5': 13,
      '9': 1,
      '10': 'season',
      '17': true
    },
    {'1': 'q', '3': 3, '4': 1, '5': 9, '9': 2, '10': 'q', '17': true},
    {
      '1': 'playable',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 3,
      '10': 'playable',
      '17': true
    },
    {'1': 'limit', '3': 5, '4': 1, '5': 13, '10': 'limit'},
    {'1': 'offset', '3': 6, '4': 1, '5': 13, '10': 'offset'},
  ],
  '8': [
    {'1': '_show'},
    {'1': '_season'},
    {'1': '_q'},
    {'1': '_playable'},
  ],
};

/// Descriptor for `ListEpisodesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEpisodesRequestDescriptor = $convert.base64Decode(
    'ChNMaXN0RXBpc29kZXNSZXF1ZXN0EhcKBHNob3cYASABKAlIAFIEc2hvd4gBARIbCgZzZWFzb2'
    '4YAiABKA1IAVIGc2Vhc29uiAEBEhEKAXEYAyABKAlIAlIBcYgBARIfCghwbGF5YWJsZRgEIAEo'
    'CEgDUghwbGF5YWJsZYgBARIUCgVsaW1pdBgFIAEoDVIFbGltaXQSFgoGb2Zmc2V0GAYgASgNUg'
    'ZvZmZzZXRCBwoFX3Nob3dCCQoHX3NlYXNvbkIECgJfcUILCglfcGxheWFibGU=');

@$core.Deprecated('Use listEpisodesResponseDescriptor instead')
const ListEpisodesResponse$json = {
  '1': 'ListEpisodesResponse',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.PageInfo',
      '10': 'page'
    },
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.EpisodeWithShow',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ListEpisodesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listEpisodesResponseDescriptor = $convert.base64Decode(
    'ChRMaXN0RXBpc29kZXNSZXNwb25zZRIqCgRwYWdlGAEgASgLMhYuY2F0YWxvZ3VlLnYxLlBhZ2'
    'VJbmZvUgRwYWdlEjMKBWl0ZW1zGAIgAygLMh0uY2F0YWxvZ3VlLnYxLkVwaXNvZGVXaXRoU2hv'
    'd1IFaXRlbXM=');

@$core.Deprecated('Use getEpisodeRequestDescriptor instead')
const GetEpisodeRequest$json = {
  '1': 'GetEpisodeRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
  ],
};

/// Descriptor for `GetEpisodeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getEpisodeRequestDescriptor =
    $convert.base64Decode('ChFHZXRFcGlzb2RlUmVxdWVzdBIOCgJpZBgBIAEoDVICaWQ=');

@$core.Deprecated('Use homeSectionDescriptor instead')
const HomeSection$json = {
  '1': 'HomeSection',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {
      '1': 'kind',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.catalogue.v1.SectionKind',
      '10': 'kind'
    },
    {'1': 'title', '3': 3, '4': 1, '5': 9, '10': 'title'},
    {'1': 'kicker', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'kicker', '17': true},
    {'1': 'link', '3': 5, '4': 1, '5': 9, '9': 1, '10': 'link', '17': true},
    {
      '1': 'show',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.Show',
      '9': 2,
      '10': 'show',
      '17': true
    },
    {
      '1': 'playlist',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.Playlist',
      '9': 3,
      '10': 'playlist',
      '17': true
    },
    {
      '1': 'artwork',
      '3': 8,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.HomeSection.ArtworkEntry',
      '10': 'artwork'
    },
    {
      '1': 'items',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.EpisodeWithShow',
      '10': 'items'
    },
  ],
  '3': [HomeSection_ArtworkEntry$json],
  '8': [
    {'1': '_kicker'},
    {'1': '_link'},
    {'1': '_show'},
    {'1': '_playlist'},
  ],
};

@$core.Deprecated('Use homeSectionDescriptor instead')
const HomeSection_ArtworkEntry$json = {
  '1': 'ArtworkEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

/// Descriptor for `HomeSection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List homeSectionDescriptor = $convert.base64Decode(
    'CgtIb21lU2VjdGlvbhIOCgJpZBgBIAEoDVICaWQSLQoEa2luZBgCIAEoDjIZLmNhdGFsb2d1ZS'
    '52MS5TZWN0aW9uS2luZFIEa2luZBIUCgV0aXRsZRgDIAEoCVIFdGl0bGUSGwoGa2lja2VyGAQg'
    'ASgJSABSBmtpY2tlcogBARIXCgRsaW5rGAUgASgJSAFSBGxpbmuIAQESKwoEc2hvdxgGIAEoCz'
    'ISLmNhdGFsb2d1ZS52MS5TaG93SAJSBHNob3eIAQESNwoIcGxheWxpc3QYByABKAsyFi5jYXRh'
    'bG9ndWUudjEuUGxheWxpc3RIA1IIcGxheWxpc3SIAQESQAoHYXJ0d29yaxgIIAMoCzImLmNhdG'
    'Fsb2d1ZS52MS5Ib21lU2VjdGlvbi5BcnR3b3JrRW50cnlSB2FydHdvcmsSMwoFaXRlbXMYCSAD'
    'KAsyHS5jYXRhbG9ndWUudjEuRXBpc29kZVdpdGhTaG93UgVpdGVtcxo6CgxBcnR3b3JrRW50cn'
    'kSEAoDa2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4AUIJCgdfa2lja2Vy'
    'QgcKBV9saW5rQgcKBV9zaG93QgsKCV9wbGF5bGlzdA==');

@$core.Deprecated('Use homeDescriptor instead')
const Home$json = {
  '1': 'Home',
  '2': [
    {
      '1': 'sections',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.HomeSection',
      '10': 'sections'
    },
  ],
};

/// Descriptor for `Home`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List homeDescriptor = $convert.base64Decode(
    'CgRIb21lEjUKCHNlY3Rpb25zGAEgAygLMhkuY2F0YWxvZ3VlLnYxLkhvbWVTZWN0aW9uUghzZW'
    'N0aW9ucw==');

@$core.Deprecated('Use getHomeRequestDescriptor instead')
const GetHomeRequest$json = {
  '1': 'GetHomeRequest',
  '2': [
    {'1': 'preview', '3': 1, '4': 1, '5': 8, '10': 'preview'},
  ],
};

/// Descriptor for `GetHomeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getHomeRequestDescriptor = $convert
    .base64Decode('Cg5HZXRIb21lUmVxdWVzdBIYCgdwcmV2aWV3GAEgASgIUgdwcmV2aWV3');

@$core.Deprecated('Use progressDescriptor instead')
const Progress$json = {
  '1': 'Progress',
  '2': [
    {'1': 'episode_id', '3': 1, '4': 1, '5': 13, '10': 'episodeId'},
    {'1': 'position_seconds', '3': 2, '4': 1, '5': 1, '10': 'positionSeconds'},
    {
      '1': 'duration_seconds',
      '3': 3,
      '4': 1,
      '5': 1,
      '9': 0,
      '10': 'durationSeconds',
      '17': true
    },
    {'1': 'completed', '3': 4, '4': 1, '5': 8, '10': 'completed'},
    {'1': 'ratio', '3': 5, '4': 1, '5': 1, '9': 1, '10': 'ratio', '17': true},
    {'1': 'last_watched_at', '3': 6, '4': 1, '5': 9, '10': 'lastWatchedAt'},
  ],
  '8': [
    {'1': '_duration_seconds'},
    {'1': '_ratio'},
  ],
};

/// Descriptor for `Progress`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List progressDescriptor = $convert.base64Decode(
    'CghQcm9ncmVzcxIdCgplcGlzb2RlX2lkGAEgASgNUgllcGlzb2RlSWQSKQoQcG9zaXRpb25fc2'
    'Vjb25kcxgCIAEoAVIPcG9zaXRpb25TZWNvbmRzEi4KEGR1cmF0aW9uX3NlY29uZHMYAyABKAFI'
    'AFIPZHVyYXRpb25TZWNvbmRziAEBEhwKCWNvbXBsZXRlZBgEIAEoCFIJY29tcGxldGVkEhkKBX'
    'JhdGlvGAUgASgBSAFSBXJhdGlviAEBEiYKD2xhc3Rfd2F0Y2hlZF9hdBgGIAEoCVINbGFzdFdh'
    'dGNoZWRBdEITChFfZHVyYXRpb25fc2Vjb25kc0IICgZfcmF0aW8=');

@$core.Deprecated('Use historyEntryDescriptor instead')
const HistoryEntry$json = {
  '1': 'HistoryEntry',
  '2': [
    {
      '1': 'progress',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.Progress',
      '10': 'progress'
    },
    {
      '1': 'episode',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.EpisodeWithShow',
      '10': 'episode'
    },
  ],
};

/// Descriptor for `HistoryEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List historyEntryDescriptor = $convert.base64Decode(
    'CgxIaXN0b3J5RW50cnkSMgoIcHJvZ3Jlc3MYASABKAsyFi5jYXRhbG9ndWUudjEuUHJvZ3Jlc3'
    'NSCHByb2dyZXNzEjcKB2VwaXNvZGUYAiABKAsyHS5jYXRhbG9ndWUudjEuRXBpc29kZVdpdGhT'
    'aG93UgdlcGlzb2Rl');

@$core.Deprecated('Use reportProgressRequestDescriptor instead')
const ReportProgressRequest$json = {
  '1': 'ReportProgressRequest',
  '2': [
    {'1': 'episode_id', '3': 1, '4': 1, '5': 13, '10': 'episodeId'},
    {'1': 'position_seconds', '3': 2, '4': 1, '5': 1, '10': 'positionSeconds'},
    {
      '1': 'duration_seconds',
      '3': 3,
      '4': 1,
      '5': 1,
      '9': 0,
      '10': 'durationSeconds',
      '17': true
    },
    {
      '1': 'completed',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'completed',
      '17': true
    },
  ],
  '8': [
    {'1': '_duration_seconds'},
    {'1': '_completed'},
  ],
};

/// Descriptor for `ReportProgressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reportProgressRequestDescriptor = $convert.base64Decode(
    'ChVSZXBvcnRQcm9ncmVzc1JlcXVlc3QSHQoKZXBpc29kZV9pZBgBIAEoDVIJZXBpc29kZUlkEi'
    'kKEHBvc2l0aW9uX3NlY29uZHMYAiABKAFSD3Bvc2l0aW9uU2Vjb25kcxIuChBkdXJhdGlvbl9z'
    'ZWNvbmRzGAMgASgBSABSD2R1cmF0aW9uU2Vjb25kc4gBARIhCgljb21wbGV0ZWQYBCABKAhIAV'
    'IJY29tcGxldGVkiAEBQhMKEV9kdXJhdGlvbl9zZWNvbmRzQgwKCl9jb21wbGV0ZWQ=');

@$core.Deprecated('Use getProgressRequestDescriptor instead')
const GetProgressRequest$json = {
  '1': 'GetProgressRequest',
  '2': [
    {'1': 'episode_id', '3': 1, '4': 1, '5': 13, '10': 'episodeId'},
  ],
};

/// Descriptor for `GetProgressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getProgressRequestDescriptor =
    $convert.base64Decode(
        'ChJHZXRQcm9ncmVzc1JlcXVlc3QSHQoKZXBpc29kZV9pZBgBIAEoDVIJZXBpc29kZUlk');

@$core.Deprecated('Use forgetProgressRequestDescriptor instead')
const ForgetProgressRequest$json = {
  '1': 'ForgetProgressRequest',
  '2': [
    {'1': 'episode_id', '3': 1, '4': 1, '5': 13, '10': 'episodeId'},
  ],
};

/// Descriptor for `ForgetProgressRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List forgetProgressRequestDescriptor = $convert.base64Decode(
    'ChVGb3JnZXRQcm9ncmVzc1JlcXVlc3QSHQoKZXBpc29kZV9pZBgBIAEoDVIJZXBpc29kZUlk');

@$core.Deprecated('Use forgetProgressResponseDescriptor instead')
const ForgetProgressResponse$json = {
  '1': 'ForgetProgressResponse',
};

/// Descriptor for `ForgetProgressResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List forgetProgressResponseDescriptor =
    $convert.base64Decode('ChZGb3JnZXRQcm9ncmVzc1Jlc3BvbnNl');

@$core.Deprecated('Use listHistoryRequestDescriptor instead')
const ListHistoryRequest$json = {
  '1': 'ListHistoryRequest',
  '2': [
    {
      '1': 'completed',
      '3': 1,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'completed',
      '17': true
    },
    {'1': 'limit', '3': 2, '4': 1, '5': 13, '10': 'limit'},
    {'1': 'offset', '3': 3, '4': 1, '5': 13, '10': 'offset'},
  ],
  '8': [
    {'1': '_completed'},
  ],
};

/// Descriptor for `ListHistoryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listHistoryRequestDescriptor = $convert.base64Decode(
    'ChJMaXN0SGlzdG9yeVJlcXVlc3QSIQoJY29tcGxldGVkGAEgASgISABSCWNvbXBsZXRlZIgBAR'
    'IUCgVsaW1pdBgCIAEoDVIFbGltaXQSFgoGb2Zmc2V0GAMgASgNUgZvZmZzZXRCDAoKX2NvbXBs'
    'ZXRlZA==');

@$core.Deprecated('Use listHistoryResponseDescriptor instead')
const ListHistoryResponse$json = {
  '1': 'ListHistoryResponse',
  '2': [
    {
      '1': 'page',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.PageInfo',
      '10': 'page'
    },
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.HistoryEntry',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ListHistoryResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listHistoryResponseDescriptor = $convert.base64Decode(
    'ChNMaXN0SGlzdG9yeVJlc3BvbnNlEioKBHBhZ2UYASABKAsyFi5jYXRhbG9ndWUudjEuUGFnZU'
    'luZm9SBHBhZ2USMAoFaXRlbXMYAiADKAsyGi5jYXRhbG9ndWUudjEuSGlzdG9yeUVudHJ5UgVp'
    'dGVtcw==');

@$core.Deprecated('Use continueWatchingRequestDescriptor instead')
const ContinueWatchingRequest$json = {
  '1': 'ContinueWatchingRequest',
  '2': [
    {'1': 'limit', '3': 1, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `ContinueWatchingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List continueWatchingRequestDescriptor =
    $convert.base64Decode(
        'ChdDb250aW51ZVdhdGNoaW5nUmVxdWVzdBIUCgVsaW1pdBgBIAEoDVIFbGltaXQ=');

@$core.Deprecated('Use continueWatchingResponseDescriptor instead')
const ContinueWatchingResponse$json = {
  '1': 'ContinueWatchingResponse',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.HistoryEntry',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ContinueWatchingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List continueWatchingResponseDescriptor =
    $convert.base64Decode(
        'ChhDb250aW51ZVdhdGNoaW5nUmVzcG9uc2USMAoFaXRlbXMYASADKAsyGi5jYXRhbG9ndWUudj'
        'EuSGlzdG9yeUVudHJ5UgVpdGVtcw==');

@$core.Deprecated('Use playlistDescriptor instead')
const Playlist$json = {
  '1': 'Playlist',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {
      '1': 'visibility',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.catalogue.v1.PlaylistVisibility',
      '10': 'visibility'
    },
    {'1': 'created_at', '3': 4, '4': 1, '5': 9, '10': 'createdAt'},
    {'1': 'count', '3': 5, '4': 1, '5': 13, '10': 'count'},
    {'1': 'mine', '3': 6, '4': 1, '5': 8, '10': 'mine'},
  ],
};

/// Descriptor for `Playlist`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playlistDescriptor = $convert.base64Decode(
    'CghQbGF5bGlzdBIOCgJpZBgBIAEoDVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRJACgp2aXNpYm'
    'lsaXR5GAMgASgOMiAuY2F0YWxvZ3VlLnYxLlBsYXlsaXN0VmlzaWJpbGl0eVIKdmlzaWJpbGl0'
    'eRIdCgpjcmVhdGVkX2F0GAQgASgJUgljcmVhdGVkQXQSFAoFY291bnQYBSABKA1SBWNvdW50Eh'
    'IKBG1pbmUYBiABKAhSBG1pbmU=');

@$core.Deprecated('Use playlistItemDescriptor instead')
const PlaylistItem$json = {
  '1': 'PlaylistItem',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'position', '3': 2, '4': 1, '5': 13, '10': 'position'},
    {
      '1': 'episode',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.EpisodeWithShow',
      '10': 'episode'
    },
  ],
};

/// Descriptor for `PlaylistItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playlistItemDescriptor = $convert.base64Decode(
    'CgxQbGF5bGlzdEl0ZW0SDgoCaWQYASABKA1SAmlkEhoKCHBvc2l0aW9uGAIgASgNUghwb3NpdG'
    'lvbhI3CgdlcGlzb2RlGAMgASgLMh0uY2F0YWxvZ3VlLnYxLkVwaXNvZGVXaXRoU2hvd1IHZXBp'
    'c29kZQ==');

@$core.Deprecated('Use playlistDetailDescriptor instead')
const PlaylistDetail$json = {
  '1': 'PlaylistDetail',
  '2': [
    {
      '1': 'playlist',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.catalogue.v1.Playlist',
      '10': 'playlist'
    },
    {
      '1': 'items',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.PlaylistItem',
      '10': 'items'
    },
  ],
};

/// Descriptor for `PlaylistDetail`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List playlistDetailDescriptor = $convert.base64Decode(
    'Cg5QbGF5bGlzdERldGFpbBIyCghwbGF5bGlzdBgBIAEoCzIWLmNhdGFsb2d1ZS52MS5QbGF5bG'
    'lzdFIIcGxheWxpc3QSMAoFaXRlbXMYAiADKAsyGi5jYXRhbG9ndWUudjEuUGxheWxpc3RJdGVt'
    'UgVpdGVtcw==');

@$core.Deprecated('Use listPlaylistsRequestDescriptor instead')
const ListPlaylistsRequest$json = {
  '1': 'ListPlaylistsRequest',
  '2': [
    {
      '1': 'scope',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.catalogue.v1.PlaylistScope',
      '10': 'scope'
    },
  ],
};

/// Descriptor for `ListPlaylistsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPlaylistsRequestDescriptor = $convert.base64Decode(
    'ChRMaXN0UGxheWxpc3RzUmVxdWVzdBIxCgVzY29wZRgBIAEoDjIbLmNhdGFsb2d1ZS52MS5QbG'
    'F5bGlzdFNjb3BlUgVzY29wZQ==');

@$core.Deprecated('Use listPlaylistsResponseDescriptor instead')
const ListPlaylistsResponse$json = {
  '1': 'ListPlaylistsResponse',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.catalogue.v1.Playlist',
      '10': 'items'
    },
  ],
};

/// Descriptor for `ListPlaylistsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listPlaylistsResponseDescriptor = $convert.base64Decode(
    'ChVMaXN0UGxheWxpc3RzUmVzcG9uc2USLAoFaXRlbXMYASADKAsyFi5jYXRhbG9ndWUudjEuUG'
    'xheWxpc3RSBWl0ZW1z');

@$core.Deprecated('Use getPlaylistRequestDescriptor instead')
const GetPlaylistRequest$json = {
  '1': 'GetPlaylistRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
  ],
};

/// Descriptor for `GetPlaylistRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPlaylistRequestDescriptor =
    $convert.base64Decode('ChJHZXRQbGF5bGlzdFJlcXVlc3QSDgoCaWQYASABKA1SAmlk');

@$core.Deprecated('Use createPlaylistRequestDescriptor instead')
const CreatePlaylistRequest$json = {
  '1': 'CreatePlaylistRequest',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
  ],
};

/// Descriptor for `CreatePlaylistRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createPlaylistRequestDescriptor =
    $convert.base64Decode(
        'ChVDcmVhdGVQbGF5bGlzdFJlcXVlc3QSEgoEbmFtZRgBIAEoCVIEbmFtZQ==');

@$core.Deprecated('Use createFromShowRequestDescriptor instead')
const CreateFromShowRequest$json = {
  '1': 'CreateFromShowRequest',
  '2': [
    {'1': 'show', '3': 1, '4': 1, '5': 9, '10': 'show'},
    {
      '1': 'season',
      '3': 2,
      '4': 1,
      '5': 13,
      '9': 0,
      '10': 'season',
      '17': true
    },
    {'1': 'name', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'name', '17': true},
    {'1': 'playable_only', '3': 4, '4': 1, '5': 8, '10': 'playableOnly'},
  ],
  '8': [
    {'1': '_season'},
    {'1': '_name'},
  ],
};

/// Descriptor for `CreateFromShowRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List createFromShowRequestDescriptor = $convert.base64Decode(
    'ChVDcmVhdGVGcm9tU2hvd1JlcXVlc3QSEgoEc2hvdxgBIAEoCVIEc2hvdxIbCgZzZWFzb24YAi'
    'ABKA1IAFIGc2Vhc29uiAEBEhcKBG5hbWUYAyABKAlIAVIEbmFtZYgBARIjCg1wbGF5YWJsZV9v'
    'bmx5GAQgASgIUgxwbGF5YWJsZU9ubHlCCQoHX3NlYXNvbkIHCgVfbmFtZQ==');

@$core.Deprecated('Use updatePlaylistRequestDescriptor instead')
const UpdatePlaylistRequest$json = {
  '1': 'UpdatePlaylistRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'name', '17': true},
    {
      '1': 'visibility',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.catalogue.v1.PlaylistVisibility',
      '9': 1,
      '10': 'visibility',
      '17': true
    },
  ],
  '8': [
    {'1': '_name'},
    {'1': '_visibility'},
  ],
};

/// Descriptor for `UpdatePlaylistRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updatePlaylistRequestDescriptor = $convert.base64Decode(
    'ChVVcGRhdGVQbGF5bGlzdFJlcXVlc3QSDgoCaWQYASABKA1SAmlkEhcKBG5hbWUYAiABKAlIAF'
    'IEbmFtZYgBARJFCgp2aXNpYmlsaXR5GAMgASgOMiAuY2F0YWxvZ3VlLnYxLlBsYXlsaXN0Vmlz'
    'aWJpbGl0eUgBUgp2aXNpYmlsaXR5iAEBQgcKBV9uYW1lQg0KC192aXNpYmlsaXR5');

@$core.Deprecated('Use deletePlaylistRequestDescriptor instead')
const DeletePlaylistRequest$json = {
  '1': 'DeletePlaylistRequest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 13, '10': 'id'},
  ],
};

/// Descriptor for `DeletePlaylistRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePlaylistRequestDescriptor = $convert
    .base64Decode('ChVEZWxldGVQbGF5bGlzdFJlcXVlc3QSDgoCaWQYASABKA1SAmlk');

@$core.Deprecated('Use deletePlaylistResponseDescriptor instead')
const DeletePlaylistResponse$json = {
  '1': 'DeletePlaylistResponse',
};

/// Descriptor for `DeletePlaylistResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deletePlaylistResponseDescriptor =
    $convert.base64Decode('ChZEZWxldGVQbGF5bGlzdFJlc3BvbnNl');

@$core.Deprecated('Use addItemRequestDescriptor instead')
const AddItemRequest$json = {
  '1': 'AddItemRequest',
  '2': [
    {'1': 'playlist_id', '3': 1, '4': 1, '5': 13, '10': 'playlistId'},
    {'1': 'episode_id', '3': 2, '4': 1, '5': 13, '10': 'episodeId'},
  ],
};

/// Descriptor for `AddItemRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List addItemRequestDescriptor = $convert.base64Decode(
    'Cg5BZGRJdGVtUmVxdWVzdBIfCgtwbGF5bGlzdF9pZBgBIAEoDVIKcGxheWxpc3RJZBIdCgplcG'
    'lzb2RlX2lkGAIgASgNUgllcGlzb2RlSWQ=');

@$core.Deprecated('Use removeItemRequestDescriptor instead')
const RemoveItemRequest$json = {
  '1': 'RemoveItemRequest',
  '2': [
    {'1': 'playlist_id', '3': 1, '4': 1, '5': 13, '10': 'playlistId'},
    {'1': 'item_id', '3': 2, '4': 1, '5': 13, '10': 'itemId'},
  ],
};

/// Descriptor for `RemoveItemRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeItemRequestDescriptor = $convert.base64Decode(
    'ChFSZW1vdmVJdGVtUmVxdWVzdBIfCgtwbGF5bGlzdF9pZBgBIAEoDVIKcGxheWxpc3RJZBIXCg'
    'dpdGVtX2lkGAIgASgNUgZpdGVtSWQ=');

@$core.Deprecated('Use reorderRequestDescriptor instead')
const ReorderRequest$json = {
  '1': 'ReorderRequest',
  '2': [
    {'1': 'playlist_id', '3': 1, '4': 1, '5': 13, '10': 'playlistId'},
    {'1': 'item_ids', '3': 2, '4': 3, '5': 13, '10': 'itemIds'},
  ],
};

/// Descriptor for `ReorderRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List reorderRequestDescriptor = $convert.base64Decode(
    'Cg5SZW9yZGVyUmVxdWVzdBIfCgtwbGF5bGlzdF9pZBgBIAEoDVIKcGxheWxpc3RJZBIZCghpdG'
    'VtX2lkcxgCIAMoDVIHaXRlbUlkcw==');
