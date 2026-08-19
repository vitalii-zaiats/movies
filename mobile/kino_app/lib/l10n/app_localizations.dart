import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk'),
  ];

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles'**
  String get searchHint;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabFilms.
  ///
  /// In en, this message translates to:
  /// **'Films'**
  String get tabFilms;

  /// No description provided for @tabSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get tabSeries;

  /// No description provided for @tabCartoons.
  ///
  /// In en, this message translates to:
  /// **'Cartoons'**
  String get tabCartoons;

  /// No description provided for @continueWatching.
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get continueWatching;

  /// No description provided for @newest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get newest;

  /// No description provided for @found.
  ///
  /// In en, this message translates to:
  /// **'Found'**
  String get found;

  /// No description provided for @sectionCount.
  ///
  /// In en, this message translates to:
  /// **'{title} · {count}'**
  String sectionCount(String title, int count);

  /// No description provided for @nothingHere.
  ///
  /// In en, this message translates to:
  /// **'nothing here'**
  String get nothingHere;

  /// No description provided for @shownOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String shownOfTotal(int shown, int total);

  /// No description provided for @film.
  ///
  /// In en, this message translates to:
  /// **'film'**
  String get film;

  /// No description provided for @filmNoStream.
  ///
  /// In en, this message translates to:
  /// **'film · no stream'**
  String get filmNoStream;

  /// No description provided for @episodesAndPlayable.
  ///
  /// In en, this message translates to:
  /// **'{count} episodes · {playable} playable'**
  String episodesAndPlayable(int count, int playable);

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @playEpisode.
  ///
  /// In en, this message translates to:
  /// **'Play {code}'**
  String playEpisode(String code);

  /// No description provided for @nothingToPlayYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing to play yet'**
  String get nothingToPlayYet;

  /// No description provided for @episodeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 episode} other{{count} episodes}}'**
  String episodeCount(int count);

  /// No description provided for @noStream.
  ///
  /// In en, this message translates to:
  /// **'No stream'**
  String get noStream;

  /// No description provided for @voiceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 voice} other{{count} voices}}'**
  String voiceCount(int count);

  /// No description provided for @queueWholeShow.
  ///
  /// In en, this message translates to:
  /// **'Queue the whole show'**
  String get queueWholeShow;

  /// No description provided for @queued.
  ///
  /// In en, this message translates to:
  /// **'Queued “{name}” · {count}'**
  String queued(String name, int count);

  /// No description provided for @imdbVotes.
  ///
  /// In en, this message translates to:
  /// **'IMDb · {votes} votes'**
  String imdbVotes(int votes);

  /// No description provided for @directedBy.
  ///
  /// In en, this message translates to:
  /// **'Directed by'**
  String get directedBy;

  /// No description provided for @starring.
  ///
  /// In en, this message translates to:
  /// **'Starring'**
  String get starring;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @labelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get labelEmail;

  /// No description provided for @labelId.
  ///
  /// In en, this message translates to:
  /// **'Id'**
  String get labelId;

  /// No description provided for @labelRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get labelRole;

  /// No description provided for @labelSince.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get labelSince;

  /// No description provided for @labelLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last seen'**
  String get labelLastSeen;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'admin'**
  String get roleAdmin;

  /// No description provided for @roleUser.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get roleUser;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @renamed.
  ///
  /// In en, this message translates to:
  /// **'Now known as {name}.'**
  String renamed(String name);

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAnAccount;

  /// No description provided for @createAccountBlurb.
  ///
  /// In en, this message translates to:
  /// **'Keeps everything you have watched — the email and password are written onto this same account.'**
  String get createAccountBlurb;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @accountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created for {email}.'**
  String accountCreated(String email);

  /// No description provided for @alreadyHaveOne.
  ///
  /// In en, this message translates to:
  /// **'Already have one'**
  String get alreadyHaveOne;

  /// No description provided for @signInBlurb.
  ///
  /// In en, this message translates to:
  /// **'Signing in swaps this device to that account. The guest you are now stays where it is.'**
  String get signInBlurb;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}.'**
  String signedInAs(String name);

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @notAnEmail.
  ///
  /// In en, this message translates to:
  /// **'Doesn’t look like an email'**
  String get notAnEmail;

  /// No description provided for @shortPassword.
  ///
  /// In en, this message translates to:
  /// **'At least eight characters'**
  String get shortPassword;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @thisDevice.
  ///
  /// In en, this message translates to:
  /// **'This device'**
  String get thisDevice;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signOutBlurb.
  ///
  /// In en, this message translates to:
  /// **'Back to being a guest on this device.'**
  String get signOutBlurb;

  /// No description provided for @signedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out. You are a guest again.'**
  String get signedOut;

  /// No description provided for @watchAsSomebodyElse.
  ///
  /// In en, this message translates to:
  /// **'Watch as somebody else'**
  String get watchAsSomebodyElse;

  /// No description provided for @watchAsBlurb.
  ///
  /// In en, this message translates to:
  /// **'A second identity on this device, with its own history.'**
  String get watchAsBlurb;

  /// No description provided for @nowWatchingAs.
  ///
  /// In en, this message translates to:
  /// **'Now watching as {name}.'**
  String nowWatchingAs(String name);

  /// No description provided for @couldntReach.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t reach the catalogue'**
  String get couldntReach;

  /// No description provided for @triedAddress.
  ///
  /// In en, this message translates to:
  /// **'tried {address}'**
  String triedAddress(String address);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @sourceDidntAnswer.
  ///
  /// In en, this message translates to:
  /// **'The source didn’t answer'**
  String get sourceDidntAnswer;

  /// No description provided for @upstreamRefused.
  ///
  /// In en, this message translates to:
  /// **'The stream is registered, but the host behind it returned 502. Worth trying again later.'**
  String get upstreamRefused;

  /// No description provided for @nothingToPlay.
  ///
  /// In en, this message translates to:
  /// **'Nothing to play'**
  String get nothingToPlay;

  /// No description provided for @neverPackaged.
  ///
  /// In en, this message translates to:
  /// **'This episode was never packaged.'**
  String get neverPackaged;

  /// No description provided for @remoteHint.
  ///
  /// In en, this message translates to:
  /// **'OK — play or pause · ◀ ▶ — 10 seconds · Back — leave'**
  String get remoteHint;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareText.
  ///
  /// In en, this message translates to:
  /// **'{title} — {url}'**
  String shareText(String title, String url);

  /// No description provided for @seasonCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 season} other{{count} seasons}}'**
  String seasonCount(int count);

  /// No description provided for @seasonNumber.
  ///
  /// In en, this message translates to:
  /// **'Season {number}'**
  String seasonNumber(int number);

  /// No description provided for @voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get voice;

  /// No description provided for @defaultVoice.
  ///
  /// In en, this message translates to:
  /// **'As published'**
  String get defaultVoice;

  /// No description provided for @anyLanguage.
  ///
  /// In en, this message translates to:
  /// **'Any language'**
  String get anyLanguage;

  /// No description provided for @filterByLanguage.
  ///
  /// In en, this message translates to:
  /// **'Filter by language'**
  String get filterByLanguage;

  /// No description provided for @resumeAt.
  ///
  /// In en, this message translates to:
  /// **'Continue · {at}'**
  String resumeAt(String at);

  /// No description provided for @startAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get startAgain;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @welcomeBlurb.
  ///
  /// In en, this message translates to:
  /// **'Nothing to sign up for. The catalogue gives this device an identity of its own, and what you watch is remembered against it from the first title on.'**
  String get welcomeBlurb;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get continueAsGuest;

  /// No description provided for @signInOnAnotherDevice.
  ///
  /// In en, this message translates to:
  /// **'Sign in from your phone'**
  String get signInOnAnotherDevice;

  /// No description provided for @signInOnAnotherDeviceBlurb.
  ///
  /// In en, this message translates to:
  /// **'Typing a password with a remote is miserable. Scan a code instead and approve it where there is a keyboard.'**
  String get signInOnAnotherDeviceBlurb;

  /// No description provided for @scanThis.
  ///
  /// In en, this message translates to:
  /// **'Scan this with your phone'**
  String get scanThis;

  /// No description provided for @orOpen.
  ///
  /// In en, this message translates to:
  /// **'Or open {url} and type the code'**
  String orOpen(String url);

  /// No description provided for @codeExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String codeExpiresIn(String time);

  /// No description provided for @codeExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has run out — codes only last ten minutes.'**
  String get codeExpired;

  /// No description provided for @askForNewCode.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get askForNewCode;

  /// No description provided for @waitingForPhone.
  ///
  /// In en, this message translates to:
  /// **'Waiting for your phone…'**
  String get waitingForPhone;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @linkDevice.
  ///
  /// In en, this message translates to:
  /// **'Link a device'**
  String get linkDevice;

  /// No description provided for @linkedAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String linkedAs(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
