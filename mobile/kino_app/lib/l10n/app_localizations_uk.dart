// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get searchHint => 'Пошук за назвою';

  @override
  String get tabAll => 'Усе';

  @override
  String get tabFilms => 'Фільми';

  @override
  String get tabSeries => 'Серіали';

  @override
  String get tabCartoons => 'Мультфільми';

  @override
  String get continueWatching => 'Продовжити перегляд';

  @override
  String get newest => 'Найновіше';

  @override
  String get found => 'Знайдено';

  @override
  String sectionCount(String title, int count) {
    return '$title · $count';
  }

  @override
  String get nothingHere => 'тут порожньо';

  @override
  String shownOfTotal(int shown, int total) {
    return '$shown з $total';
  }

  @override
  String get film => 'фільм';

  @override
  String get filmNoStream => 'фільм · без потоку';

  @override
  String episodesAndPlayable(int count, int playable) {
    return 'епізодів: $count · доступно: $playable';
  }

  @override
  String get play => 'Дивитись';

  @override
  String playEpisode(String code) {
    return 'Дивитись $code';
  }

  @override
  String get nothingToPlayYet => 'Поки нема чого дивитись';

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count епізоду',
      many: '$count епізодів',
      few: '$count епізоди',
      one: '$count епізод',
    );
    return '$_temp0';
  }

  @override
  String get noStream => 'Без потоку';

  @override
  String voiceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count озвучки',
      many: '$count озвучок',
      few: '$count озвучки',
      one: '$count озвучка',
    );
    return '$_temp0';
  }

  @override
  String get queueWholeShow => 'Додати весь серіал у чергу';

  @override
  String queued(String name, int count) {
    return 'У черзі «$name» · $count';
  }

  @override
  String imdbVotes(int votes) {
    return 'IMDb · голосів: $votes';
  }

  @override
  String get directedBy => 'Режисер';

  @override
  String get starring => 'У ролях';

  @override
  String get account => 'Акаунт';

  @override
  String get guest => 'Гість';

  @override
  String get labelEmail => 'Пошта';

  @override
  String get labelId => 'Ід';

  @override
  String get labelRole => 'Роль';

  @override
  String get labelSince => 'Від';

  @override
  String get labelLastSeen => 'Востаннє';

  @override
  String get roleAdmin => 'адмін';

  @override
  String get roleUser => 'користувач';

  @override
  String get yourName => 'Ваше ім’я';

  @override
  String get displayName => 'Як вас показувати';

  @override
  String get save => 'Зберегти';

  @override
  String renamed(String name) {
    return 'Тепер ви $name.';
  }

  @override
  String get createAnAccount => 'Створити акаунт';

  @override
  String get createAccountBlurb =>
      'Усе переглянуте лишається: пошта й пароль записуються в цей самий акаунт.';

  @override
  String get createAccount => 'Створити';

  @override
  String accountCreated(String email) {
    return 'Акаунт створено для $email.';
  }

  @override
  String get alreadyHaveOne => 'Уже маю акаунт';

  @override
  String get signInBlurb =>
      'Вхід переводить цей пристрій на той акаунт. Гість, яким ви є зараз, нікуди не дінеться.';

  @override
  String get signIn => 'Увійти';

  @override
  String signedInAs(String name) {
    return 'Ви увійшли як $name.';
  }

  @override
  String get password => 'Пароль';

  @override
  String get fieldRequired => 'Обов’язкове поле';

  @override
  String get notAnEmail => 'Не схоже на пошту';

  @override
  String get shortPassword => 'Щонайменше вісім символів';

  @override
  String get appearance => 'Вигляд';

  @override
  String get themeSystem => 'Як у системі';

  @override
  String get themeLight => 'Світла';

  @override
  String get themeDark => 'Темна';

  @override
  String get language => 'Мова';

  @override
  String get languageSystem => 'Як у системі';

  @override
  String get thisDevice => 'Цей пристрій';

  @override
  String get signOut => 'Вийти';

  @override
  String get signOutBlurb => 'Повернутись до гостя на цьому пристрої.';

  @override
  String get signedOut => 'Ви вийшли. Знову гість.';

  @override
  String get watchAsSomebodyElse => 'Дивитись як хтось інший';

  @override
  String get watchAsBlurb =>
      'Друга особистість на цьому пристрої, зі своєю історією.';

  @override
  String nowWatchingAs(String name) {
    return 'Тепер дивитесь як $name.';
  }

  @override
  String get couldntReach => 'Не вдалося дістатись каталогу';

  @override
  String triedAddress(String address) {
    return 'пробував $address';
  }

  @override
  String get tryAgain => 'Спробувати ще';

  @override
  String get sourceDidntAnswer => 'Джерело не відповіло';

  @override
  String get upstreamRefused =>
      'Потік зареєстровано, але вузол за ним віддав 502. Варто спробувати пізніше.';

  @override
  String get nothingToPlay => 'Нема чого відтворювати';

  @override
  String get neverPackaged => 'Цей епізод так і не спакували.';

  @override
  String get remoteHint => 'OK — пауза · ◀ ▶ — 10 секунд · Назад — вийти';

  @override
  String get share => 'Поділитись';

  @override
  String shareText(String title, String url) {
    return '$title — $url';
  }

  @override
  String seasonCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сезону',
      many: '$count сезонів',
      few: '$count сезони',
      one: '$count сезон',
    );
    return '$_temp0';
  }

  @override
  String seasonNumber(int number) {
    return 'Сезон $number';
  }

  @override
  String get voice => 'Озвучка';

  @override
  String get defaultVoice => 'Як опубліковано';

  @override
  String get anyLanguage => 'Будь-яка мова';

  @override
  String get filterByLanguage => 'Фільтр за мовою';
}
