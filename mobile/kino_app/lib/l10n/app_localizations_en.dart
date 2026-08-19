// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get searchHint => 'Search titles';

  @override
  String get tabAll => 'All';

  @override
  String get tabFilms => 'Films';

  @override
  String get tabSeries => 'Series';

  @override
  String get tabCartoons => 'Cartoons';

  @override
  String get continueWatching => 'Continue watching';

  @override
  String get newest => 'Newest';

  @override
  String get found => 'Found';

  @override
  String sectionCount(String title, int count) {
    return '$title · $count';
  }

  @override
  String get nothingHere => 'nothing here';

  @override
  String shownOfTotal(int shown, int total) {
    return '$shown of $total';
  }

  @override
  String get film => 'film';

  @override
  String get filmNoStream => 'film · no stream';

  @override
  String episodesAndPlayable(int count, int playable) {
    return '$count episodes · $playable playable';
  }

  @override
  String get play => 'Play';

  @override
  String playEpisode(String code) {
    return 'Play $code';
  }

  @override
  String get nothingToPlayYet => 'Nothing to play yet';

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String get noStream => 'No stream';

  @override
  String voiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voices',
      one: '1 voice',
    );
    return '$_temp0';
  }

  @override
  String get queueWholeShow => 'Queue the whole show';

  @override
  String queued(String name, int count) {
    return 'Queued “$name” · $count';
  }

  @override
  String imdbVotes(int votes) {
    return 'IMDb · $votes votes';
  }

  @override
  String get directedBy => 'Directed by';

  @override
  String get starring => 'Starring';

  @override
  String get account => 'Account';

  @override
  String get guest => 'Guest';

  @override
  String get labelEmail => 'Email';

  @override
  String get labelId => 'Id';

  @override
  String get labelRole => 'Role';

  @override
  String get labelSince => 'Since';

  @override
  String get labelLastSeen => 'Last seen';

  @override
  String get roleAdmin => 'admin';

  @override
  String get roleUser => 'user';

  @override
  String get yourName => 'Your name';

  @override
  String get displayName => 'Display name';

  @override
  String get save => 'Save';

  @override
  String renamed(String name) {
    return 'Now known as $name.';
  }

  @override
  String get createAnAccount => 'Create an account';

  @override
  String get createAccountBlurb =>
      'Keeps everything you have watched — the email and password are written onto this same account.';

  @override
  String get createAccount => 'Create account';

  @override
  String accountCreated(String email) {
    return 'Account created for $email.';
  }

  @override
  String get alreadyHaveOne => 'Already have one';

  @override
  String get signInBlurb =>
      'Signing in swaps this device to that account. The guest you are now stays where it is.';

  @override
  String get signIn => 'Sign in';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name.';
  }

  @override
  String get password => 'Password';

  @override
  String get fieldRequired => 'Required';

  @override
  String get notAnEmail => 'Doesn’t look like an email';

  @override
  String get shortPassword => 'At least eight characters';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get thisDevice => 'This device';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutBlurb => 'Back to being a guest on this device.';

  @override
  String get signedOut => 'Signed out. You are a guest again.';

  @override
  String get watchAsSomebodyElse => 'Watch as somebody else';

  @override
  String get watchAsBlurb =>
      'A second identity on this device, with its own history.';

  @override
  String nowWatchingAs(String name) {
    return 'Now watching as $name.';
  }

  @override
  String get couldntReach => 'Couldn’t reach the catalogue';

  @override
  String triedAddress(String address) {
    return 'tried $address';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get sourceDidntAnswer => 'The source didn’t answer';

  @override
  String get upstreamRefused =>
      'The stream is registered, but the host behind it returned 502. Worth trying again later.';

  @override
  String get nothingToPlay => 'Nothing to play';

  @override
  String get neverPackaged => 'This episode was never packaged.';

  @override
  String get remoteHint =>
      'OK — play or pause · ◀ ▶ — 10 seconds · Back — leave';

  @override
  String get share => 'Share';

  @override
  String shareText(String title, String url) {
    return '$title — $url';
  }

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seasons',
      one: '1 season',
    );
    return '$_temp0';
  }

  @override
  String seasonNumber(int number) {
    return 'Season $number';
  }

  @override
  String get voice => 'Voice';

  @override
  String get defaultVoice => 'As published';

  @override
  String get anyLanguage => 'Any language';

  @override
  String get filterByLanguage => 'Filter by language';
}
